[
"<esc><wait>",
"install <wait>",
" preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <wait>",
"debian-installer=en_US.UTF-8 <wait>",
"auto <wait>",
"kbd-chooser/method=fr <wait>",
"keyboard-configuration/xkb-keymap=fr <wait>",
"netcfg/get_hostname={{ .Name }} <wait>",
"netcfg/get_domain=local <wait>",
"fb=false <wait>",
"debconf/frontend=noninteractive <wait>",
"console-setup/ask_detect=false <wait>",
"console-keymaps-at/keymap=fr <wait>",
"grub-installer/bootdev=/dev/sda <wait>",
"<enter><wait>"
]
