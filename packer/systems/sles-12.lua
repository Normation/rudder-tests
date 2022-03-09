dofile("systems/sles/sles.lua")

iso_url = "http://192.168.180.1/iso/SLES/SLE-12-SP4-Server-DVD-x86_64-GM-DVD1.iso"
iso_checksum = "sha256:1f08a451442881b979bf8c3136e0a38132922b93cce5d3e68cf26bdd71df0f0e"

os_version = "12-sp4"
os_script = "systems/sles/scripts/os_server.sh"
boot_command = command("sles-" .. os_version .. "-autoinst.xml")
