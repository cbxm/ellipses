param([string]$EventType = "default")

switch ($EventType) {
    "stop"           { [System.Media.SystemSounds]::Hand.Play() }          # Task complete
    "subagent-stop"  { [System.Media.SystemSounds]::Hand.Play() }          # Subagent done
    "idle"           { [System.Media.SystemSounds]::Hand.Play() }          # Needs input
    default          { [System.Media.SystemSounds]::Hand.Play() }
}
