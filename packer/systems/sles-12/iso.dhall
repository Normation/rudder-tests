let iso_urls = [
    "iso/SLE-12-SP1-Server-DVD-x86_64-GM-DVD1.iso"
]
let iso_checksum_type = "sha256"
let iso_checksum = "e1c0ba860f593d60c2c138a0cd35e2a3c65304b4c988b4c9f6051bff89871f62"
let guest_os_type = "sles12-64"

in {
iso_urls = iso_urls,
iso_checksum_type = iso_checksum_type,
iso_checksum = iso_checksum,
guest_os_type = guest_os_type
}
