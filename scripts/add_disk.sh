#!/bin/bash
set -x
VM=$1
DISK_PATH=$2
DISK_SIZE=$3 #In MB
NAME=$4
if [ ! -f $DISK_PATH ]
then
  # Create the new disk on the host
  VBoxManage createmedium disk --filename $DISK_PATH --size $DISK_SIZE --format VDI
  # Shutdown the VM
  VBoxManage controlvm $VM poweroff
  # GET the controller device name
  DEVICE_ID=$(VBoxManage showvminfo $VM | grep "Storage Controller Name" | grep -i "sata" | sed 's/Storage Controller Name (\(.*\)):.*/\1/g')
  NEXT_PORT=$(VBoxManage showvminfo $VM | sed -n "s/Storage Controller Port Count ($DEVICE_ID)\:\s\+//p")
  DEVICE_NAME=$(VBoxManage showvminfo $VM | sed -n "s/Storage Controller Name ($DEVICE_ID)\:\s\+//p")
  VBoxManage storageattach $VM --medium $DISK_PATH.vdi --storagectl "$DEVICE_NAME" --port "$NEXT_PORT" --type hdd
  #VBoxManage startvm $VM --type headless
  vagrant reload $NAME
  vagrant ssh $NAME -c "/vagrant/scripts/format_disk.sh $NEXT_PORT"
fi
