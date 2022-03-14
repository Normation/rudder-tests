guest_os_type = "Linux_64"
os_arch = "amd64"
os_start = "systems/slackware/scripts/os_start.sh"
os_stop = "systems/slackware/scripts/os_stop.sh"
system_dir = "slackware"
distro = "slackware"
boot_command = [[
<wait><enter><wait5>
<wait><enter>
<wait>root<enter>
<wait>fdisk /dev/sda<enter>
<wait>o<enter>n<enter>p<enter>1<enter><enter><enter>w<enter>
<wait>setup<enter>
<wait>t<enter><enter>f<enter><enter><wait10><enter>
<wait>1<enter>a<enter><wait10>
<wait>e<spacebar>f<spacebar>kk<spacebar>t<spacebar>t<spacebar>x<spacebar>x<spacebar>x<spacebar>y<spacebar><enter>
<wait>f<enter>
<wait10><wait10><wait10><wait10><wait10><wait10>
<wait10><wait10><wait10><wait10><wait10><wait10>
<wait10><wait10><wait10><wait10><wait10><wait10>
<wait10><wait10><wait10><wait10><wait10><wait10>
<wait10><wait10><wait10><wait10><wait10><wait10>
<wait10><wait10><wait10><wait10><wait10><wait10>
<wait>s<enter>
<wait><enter><enter><enter><enter>
<wait><enter><enter>
<wait><enter>
<wait><enter>
<wait><enter>slackware<enter>local<enter>n<enter><enter><enter>
<wait><enter>
<wait>n
<wait>n<enter>
<wait>f<up><up><up><up><up><up><up><up><up><up><up><up><up><up><up><up><up><up><up><up><up><up><up><up><up><up><up><enter>
<wait>v<enter>
<wait>n<enter>
<wait>e<wait><enter><wait><enter><enter>
<wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10>
<wait><enter><wait10><wait10>
root<enter>
sed -i 's/use_authtok//g' /etc/pam.d/system-auth<enter>
sed -i 's/.*password.*requisite.*pam_pwquality.so.*//g' /etc/pam.d/system-auth<enter>
groupadd vagrant<enter>
useradd -d /home/vagrant -s /bin/bash -g vagrant vagrant<enter>
echo -e "vagrant\nvagrant" | passwd vagrant<enter>
mkdir /home/vagrant<enter>
chown -R vagrant:vagrant /home/vagrant<enter>
echo "vagrant        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers<enter>
/etc/rc.d/rc.sshd restart<enter>
]]
