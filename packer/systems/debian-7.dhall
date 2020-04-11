let debian = ../../systems/debian/debian.dhall
let boot = ../../systems/debian/boot_command.dhall

in debian // {
    iso_urls = [
      "debian-7.11.0-amd64-netinst.iso",
      "https://cdimage.debian.org/cdimage/archive/7.11.0/amd64/iso-cd/debian-7.11.0-amd64-netinst.iso"
    ],
    iso_checksum = "62876fb786f203bc732ec1bd2ca4c8faea19d0a97c5936d69f3406ef92ff49bd",
    os_name = "debian-7",
    boot_command = boot.command "archive.debian.org" ""
}
