let iso_urls = [
  "iso-cd/debian-10.3.0-amd64-xfce-CD-1.iso",
  "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-10.3.0-amd64-xfce-CD-1.iso"
]
let iso_checksum_type = "sha256"
let iso_checksum = "47671cf75c68b8f0a2169857a7e2fe371553de3c956b87688604cc920bceb52e"
let guest_os_type = "Debian_64"

in {
iso_urls = iso_urls,
iso_checksum_type = iso_checksum_type,
iso_checksum = iso_checksum,
guest_os_type = guest_os_type
}
