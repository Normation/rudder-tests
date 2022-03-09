dofile("systems/debian/debian.lua")

iso_url = "https://cdimage.debian.org/cdimage/archive/7.11.0/amd64/iso-cd/debian-7.11.0-amd64-netinst.iso"
iso_checksum = "sha256:2876fb786f203bc732ec1bd2ca4c8faea19d0a97c5936d69f3406ef92ff49bd"

os_version = "7"
os_script = "systems/debian/scripts/os_agent.sh"
boot_command = command("archive.debian.org","")
