function ask --description "Ask Claude a system/CLI question"
    if test (count $argv) -eq 0
        echo "Usage: ask <question>"
        return 1
    end

    set -l prompt (string join " " $argv)

    # Gather system context via fastfetch JSON
    set -l ff_json (fastfetch --json 2>/dev/null)

    # Parse relevant fields using jq
    set -l os_name (echo $ff_json | jq -r '.[] | select(.type == "OS") | .result.prettyName // empty')
    set -l os_like (echo $ff_json | jq -r '.[] | select(.type == "OS") | .result.idLike // empty')
    set -l kernel (echo $ff_json | jq -r '.[] | select(.type == "Kernel") | "\(.result.release) (\(.result.architecture))"')
    set -l host_name (echo $ff_json | jq -r '.[] | select(.type == "Title") | .result.hostName // empty')
    set -l host_model (echo $ff_json | jq -r '.[] | select(.type == "Host") | .result.version // empty')
    set -l cpu (echo $ff_json | jq -r '.[] | select(.type == "CPU") | "\(.result.name) (\(.result.cores.online) cores)"')
    set -l gpu (echo $ff_json | jq -r '[.[] | select(.type == "GPU") | .result[] | "\(.vendor) \(.name)"] | join(", ")')
    set -l mem_total (echo $ff_json | jq -r '.[] | select(.type == "Memory") | (.result.total / 1073741824 | floor | tostring) + "GB"')
    set -l de (echo $ff_json | jq -r '.[] | select(.type == "DE") | "\(.result.prettyName) \(.result.version)"')
    set -l wm (echo $ff_json | jq -r '.[] | select(.type == "WM") | "\(.result.prettyName) (\(.result.protocolName))"')
    set -l display (echo $ff_json | jq -r '.[] | select(.type == "Display") | .result[0] | "\(.output.width)x\(.output.height) @ \(.output.refreshRate | floor)Hz"')
    set -l disk_fs (echo $ff_json | jq -r '.[] | select(.type == "Disk") | .result[0].filesystem // empty')
    set -l locale (echo $ff_json | jq -r '.[] | select(.type == "Locale") | .result // empty')
    set -l battery (echo $ff_json | jq -r '.[] | select(.type == "Battery") | .result[0] | "\(.capacity)% (\(.status))"')

    # Package managers (count > 0)
    set -l pkg_managers (echo $ff_json | jq -r '
        .[] | select(.type == "Packages") | .result |
        to_entries | map(select(.value > 0 and .key != "all")) |
        map("\(.key): \(.value)") | join(", ")
    ')

    set -l system_prompt "You are a helpful assistant for command-line and system administration questions.

System context:
- Hostname: $host_name
- Hardware: $host_model
- OS: $os_name (based on: $os_like)
- Kernel: $kernel
- CPU: $cpu
- GPU: $gpu
- Memory: $mem_total
- Filesystem: $disk_fs
- Desktop: $de
- Window Manager: $wm
- Display: $display
- Battery: $battery
- Packages: $pkg_managers
- Locale: $locale
- Shell: fish

The user is working in a terminal environment and asking about CLI tools, system configuration, troubleshooting, or related topics. Provide clear explanations with relevant context. Include example commands when helpful. You can assume the user has general technical familiarity but may not know specifics of every tool."

    claude -p --model sonnet --system-prompt "$system_prompt" "$prompt"
end
