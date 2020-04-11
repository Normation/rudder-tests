let debian = ../../systems/debian/debian.dhall
let boot = ../../systems/debian/boot_command.dhall

in debian // {
    iso_urls = [
      "debian-6.0.10-amd64-netinst.iso",
      "https://cdimage.debian.org/cdimage/archive/6.0.10/amd64/iso-cd/debian-6.0.10-amd64-netinst.iso"
    ],
    iso_checksum = "e7563ecea95e1352f0c36cc2fcac1a3bb13ce11715e5c4c9712ff4f05128f896",
    os_name = "debian-6",
    boot_command = boot.command "archive.debian.org" "debian-installer/allow_unauthenticated=true <wait>"
}
