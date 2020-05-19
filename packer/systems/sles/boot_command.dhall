{
  command = \(autoinst : Text) -> \(other: Text) -> [
    "<esc><enter><wait>",
    "linux netdevice=eth0 netsetup=dhcp install=cd:/",
    " lang=en_US autoyast=http://{{ .HTTPIP }}:{{ .HTTPPort }}/${autoinst}",
    " textmode=1",
    other,
    "<enter><wait>",
    "<wait10><wait10><wait10><wait10><wait10><wait10>"
  ]
}
