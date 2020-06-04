let debian = ../systems/debian/debian.dhall
in debian // {
    iso_urls = [
      "debian-10.4.0-amd64-netinst.iso",
      "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-10.4.0-amd64-netinst.iso"
    ],
    iso_checksum = "ab3763d553330e90869487a6843c88f1d4aa199333ff16b653e60e59ac1fc60b",
    os_name = "debian-10"
}
