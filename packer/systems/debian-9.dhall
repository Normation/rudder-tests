let debian = ../../systems/debian/debian.dhall
in debian // {
    iso_urls = [
      "debian-9.12.0-amd64-netinst.iso",
      "https://cdimage.debian.org/cdimage/archive/9.12.0/amd64/iso-cd/debian-9.12.0-amd64-netinst.iso"
    ],
    iso_checksum = "3c47f64693435b0b42b6ef59624edbffa7c4004317d9f9a3f04ecb6a4e30f191",
    os_name = "debian-9"
}
