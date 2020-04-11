let debian = ../../systems/debian/debian.dhall
in debian // {
    iso_urls = [
      "debian-10.3.0-amd64-netinst.iso",
      "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-10.3.0-amd64-netinst.iso"
    ],
    iso_checksum = "6a901b5abe43d88b39d627e1339d15507cc38f980036b928f835e0f0e957d3d8",
    os_name = "debian-10"
}
