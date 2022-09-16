dofile("systems/sles/sles.lua")

iso_url = "http://192.168.180.1/iso/SLES/SLE-15-SP2-Full-x86_64-GM-Media1.iso"
iso_checksum = "sha256:938dd99becf3bf29d0948a52d04bcd1952ea72621a334f33ddb5e83909116b55"

os_version = "15-sp2"
os_script = "systems/sles/scripts/os_server.sh"
boot_command = command("sles-" .. os_version .. "-autoinst.xml")
