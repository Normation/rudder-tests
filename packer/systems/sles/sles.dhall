let boot = ../../systems/sles/boot_command.dhall
in {
    guest_os_type = "Sles_64",
    os_arch = "amd64",
    os_start = "systems/sles/scripts/os_start.sh",
    os_stop = "systems/sles/scripts/os_stop.sh",
    boot_command = boot.command "" "",
    system_dir = "sles"
}

