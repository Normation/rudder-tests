let sles = ../../systems/sles/sles.dhall
let boot = ../../systems/sles/boot_command.dhall
let os_name = "sles-15"
in sles // {
    iso_urls = [
      "iso/SLE-15-Installer-DVD-x86_64-GM-DVD1.iso"
    ],
    iso_checksum = "06bd8b78ef0ca6d5ff5000688727953e894805dc3de59060d74441f0fd0539ab",
    os_name = os_name,
    boot_command = boot.command "${os_name}-autoinst.xml" ""
}
