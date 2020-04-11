let iso_urls = [
  "iso/ubuntu-18.04.3-server-amd64.iso",
  "http://cdimage.ubuntu.com/ubuntu/releases/bionic/release/ubuntu-18.04.3-server-amd64.iso"
]
let iso_checksum_type = "sha256"
let iso_checksum = "7d8e0055d663bffa27c1718685085626cb59346e7626ba3d3f476322271f573e"
let guest_os_type = "Ubuntu_64"

in {
iso_urls = iso_urls,
iso_checksum_type = iso_checksum_type,
iso_checksum = iso_checksum,
guest_os_type = guest_os_type
}
