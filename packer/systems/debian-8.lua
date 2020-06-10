dofile("systems/debian/debian.lua")

iso_urls = {
    "debian-8.11.1-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/archive/8.11.1/amd64/iso-cd/debian-8.11.1-amd64-netinst.iso"
}
iso_checksum = "ea444d6f8ac95fd51d2aedb8015c57410d1ad19b494cedec6914c17fda02733c"

os_version = "8"
os_script = "systems/debian/scripts/os_agent.sh"
