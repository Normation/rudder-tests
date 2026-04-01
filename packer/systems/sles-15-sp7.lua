dofile("systems/sles/sles.lua")

iso_url = "http://192.168.213.1/iso/SLE-15-SP7-Full-x86_64-GM-Media1.iso"
iso_checksum = "sha256:cd9430420726219f9c73aa7a389b43057e1d9c610d279b7f71d3687c06d8e66c"

os_version = "15-sp7"
os_script = "systems/sles/scripts/os_server.sh"
boot_command = command("sles-" .. os_version .. "-autoinst.xml")
