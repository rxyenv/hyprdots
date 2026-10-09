#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { printf "${CYAN}:: %s${NC}\n" "$*"; }
success() { printf "${GREEN}✓  %s${NC}\n" "$*"; }
warn()    { printf "${YELLOW}!  %s${NC}\n" "$*"; }
die()     { printf "${RED}✗  %s${NC}\n" "$*" >&2; exit 1; }

WRITE_FAILURES=0

SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME <performance|balanced|status>

Profiles:
  performance  Push CPU/GPU/runtime tunables toward max responsiveness
  balanced     Restore saner laptop defaults for heat/battery/noise
  status       Show current CPU/GPU tuning state

Notes:
  - Run with sudo.
  - Runtime tuning only. No permanent bootloader/kernel changes.
  - Targets Intel CPU + NVIDIA laptop on Linux.
EOF
}

require_root() {
    [[ "${EUID}" -eq 0 ]] || die "Run with sudo: sudo ./$SCRIPT_NAME <profile>"
}

have_cmd() {
    command -v "$1" >/dev/null 2>&1
}

write_if_exists() {
    local value="$1"
    local path="$2"
    [[ -e "$path" ]] || return 1
    if ! printf '%s' "$value" >"$path"; then
        warn "Failed to write $path"
        WRITE_FAILURES=$((WRITE_FAILURES + 1))
        return 1
    fi
}

set_cpu_governor() {
    local governor="$1"
    local changed=0
    local cpu

    shopt -s nullglob
    for cpu in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor; do
        write_if_exists "$governor" "$cpu" && changed=1 || true
    done
    shopt -u nullglob

    if (( changed )); then
        success "CPU governor -> $governor"
    else
        warn "CPU governor interface not found"
    fi
}

set_intel_epp() {
    local pref="$1"
    local changed=0
    local policy

    shopt -s nullglob
    for policy in /sys/devices/system/cpu/cpufreq/policy*/energy_performance_preference; do
        write_if_exists "$pref" "$policy" && changed=1 || true
    done
    shopt -u nullglob

    if (( changed )); then
        success "Intel EPP -> $pref"
    else
        warn "Intel EPP interface not found"
    fi
}

set_intel_turbo() {
    local state="$1"
    local path="/sys/devices/system/cpu/intel_pstate/no_turbo"

    if write_if_exists "$state" "$path"; then
        if [[ "$state" == "0" ]]; then
            success "Intel turbo -> enabled"
        else
            success "Intel turbo -> limited"
        fi
    else
        warn "Intel turbo control not found"
    fi
}

set_vm_profile() {
    local swappiness="$1"
    local dirty_bg="$2"
    local dirty="$3"
    local laptop_mode="$4"

    write_if_exists "$swappiness" /proc/sys/vm/swappiness || true
    write_if_exists "$dirty_bg" /proc/sys/vm/dirty_background_ratio || true
    write_if_exists "$dirty" /proc/sys/vm/dirty_ratio || true
    write_if_exists "$laptop_mode" /proc/sys/vm/laptop_mode || true
    info "VM tunables attempted; write failures reported above"
}

set_thp() {
    local mode="$1"
    local path="/sys/kernel/mm/transparent_hugepage/enabled"

    if [[ -e "$path" ]]; then
        if write_if_exists "$mode" "$path"; then success "THP -> $mode"; fi
    else
        warn "THP control not found"
    fi
}

set_pcie_aspm() {
    local mode="$1"
    local path="/sys/module/pcie_aspm/parameters/policy"

    if write_if_exists "$mode" "$path"; then
        success "PCIe ASPM -> $mode"
    else
        warn "PCIe ASPM control not found"
    fi
}

set_block_scheduler() {
    local dev scheduler chosen

    shopt -s nullglob
    for dev in /sys/block/*/queue/scheduler; do
        scheduler="$(<"$dev")"
        chosen=""

        case "$(basename "$(dirname "$(dirname "$dev")")")" in
            nvme*)
                [[ "$scheduler" == *"[none]"* || "$scheduler" == *"none"* ]] && chosen="none"
                ;;
            sd*)
                if [[ "$scheduler" == *"mq-deadline"* ]]; then
                    chosen="mq-deadline"
                elif [[ "$scheduler" == *"bfq"* ]]; then
                    chosen="bfq"
                fi
                ;;
        esac

        [[ -n "$chosen" ]] || continue
        if write_if_exists "$chosen" "$dev"; then
            success "I/O scheduler $(basename "$(dirname "$(dirname "$dev")")") -> $chosen"
        fi
    done
    shopt -u nullglob
}

set_nvidia_perf() {
    if ! have_cmd nvidia-smi; then
        warn "nvidia-smi not installed"
        return
    fi

    nvidia-smi -pm 1 >/dev/null 2>&1 && success "NVIDIA persistence mode -> on" || warn "Could not enable NVIDIA persistence mode"
}

set_nvidia_balanced() {
    if ! have_cmd nvidia-smi; then
        warn "nvidia-smi not installed"
        return
    fi

    nvidia-smi -pm 0 >/dev/null 2>&1 && success "NVIDIA persistence mode -> off" || warn "Could not disable NVIDIA persistence mode"
}

set_power_profile() {
    local profile="$1"

    if have_cmd powerprofilesctl; then
        powerprofilesctl set "$profile" && success "powerprofilesctl -> $profile" || warn "powerprofilesctl failed"
    fi
}

show_status() {
    local governor="n/a"
    local epp="n/a"
    local turbo="n/a"
    local swappiness="n/a"
    local aspm="n/a"
    local thp="n/a"

    [[ -r /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]] && governor="$(</sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
    [[ -r /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference ]] && epp="$(</sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference)"
    [[ -r /sys/devices/system/cpu/intel_pstate/no_turbo ]] && turbo="$(</sys/devices/system/cpu/intel_pstate/no_turbo)"
    [[ -r /proc/sys/vm/swappiness ]] && swappiness="$(</proc/sys/vm/swappiness)"
    [[ -r /sys/module/pcie_aspm/parameters/policy ]] && aspm="$(</sys/module/pcie_aspm/parameters/policy)"
    [[ -r /sys/kernel/mm/transparent_hugepage/enabled ]] && thp="$(</sys/kernel/mm/transparent_hugepage/enabled)"

    printf 'CPU governor: %s\n' "$governor"
    printf 'Intel EPP: %s\n' "$epp"
    printf 'Intel turbo(no_turbo): %s\n' "$turbo"
    printf 'VM swappiness: %s\n' "$swappiness"
    printf 'PCIe ASPM: %s\n' "$aspm"
    printf 'THP: %s\n' "$thp"

    if have_cmd nvidia-smi; then
        if ! nvidia-smi --query-gpu=name,persistence_mode,pstate,clocks.current.graphics,temperature.gpu,utilization.gpu --format=csv,noheader; then
            warn "nvidia-smi present, but NVIDIA driver is not active"
        fi
    else
        printf 'NVIDIA: nvidia-smi unavailable\n'
    fi
}

apply_performance() {
    set_power_profile performance
    set_cpu_governor performance
    set_intel_epp performance
    set_intel_turbo 0
    set_vm_profile 10 5 20 0
    set_thp always
    set_pcie_aspm performance
    set_block_scheduler
    set_nvidia_perf
}

apply_balanced() {
    set_power_profile balanced
    set_cpu_governor powersave
    set_intel_epp balance_performance
    set_intel_turbo 0
    set_vm_profile 30 10 20 0
    set_thp madvise
    set_pcie_aspm powersupersave
    set_block_scheduler
    set_nvidia_balanced
}

main() {
    local mode="${1:-}"

    case "$mode" in
        performance)
            require_root
            apply_performance
            ;;
        balanced)
            require_root
            apply_balanced
            ;;
        status)
            show_status
            ;;
        -h|--help|help|"")
            usage
            ;;
        *)
            die "Unknown mode: $mode"
            ;;
    esac
    (( WRITE_FAILURES == 0 )) || die "$WRITE_FAILURES tuning writes failed"
}

main "$@"
