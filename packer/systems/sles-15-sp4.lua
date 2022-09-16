dofile("systems/sles/sles.lua")

iso_url = "http://192.168.213.1/iso/SLE-15-SP4-Full-x86_64-GM-Media1.iso"
iso_checksum = "sha256:1727b873723229f824e6141248b284020f4b8536c8df8d3be7ec255078103fc3"

os_version = "15-sp4"
os_script = "systems/sles/scripts/os_server.sh"
boot_command = command("sles-" .. os_version .. "-autoinst.xml")
