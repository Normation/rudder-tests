dofile("systems/sles/sles.lua")

iso_url = "http://192.168.180.1/iso/SLES/SLE-15-Packages-x86_64-GM-DVD1.iso"
iso_checksum = "sha256:06bd8b78ef0ca6d5ff5000688727953e894805dc3de59060d74441f0fd0539ab"

os_version = 15
os_script = "systems/sles/scripts/os_server.sh"
boot_command = command("sles-" .. os_version .. "-autoinst.xml")
