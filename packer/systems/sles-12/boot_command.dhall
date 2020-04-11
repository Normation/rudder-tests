[
"<esc><enter><wait>",
"linux netdevice=eth0 netsetup=dhcp install=cd:/",
" lang=en_US autoyast=http://{{ .HTTPIP }}:{{ .HTTPPort }}/sles12-autoinst.xml",
" textmode=1",
"<enter><wait>",
"<wait10><wait10><wait10><wait10><wait10><wait10>"
]
