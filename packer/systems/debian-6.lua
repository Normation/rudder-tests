dofile("systems/debian/debian.lua")

iso_url = "https://cdimage.debian.org/cdimage/archive/6.0.10/amd64/iso-cd/debian-6.0.10-amd64-netinst.iso"
iso_checksum = "sha256:e7563ecea95e1352f0c36cc2fcac1a3bb13ce11715e5c4c9712ff4f05128f896"

os_version = "6"
os_script = "systems/debian/scripts/os_agent.sh"
boot_command = command("archive.debian.org","debian-installer/allow_unauthenticated=true <wait>")

