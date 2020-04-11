#!/bin/sh

set -xe

# Temporary
if [ $(uname -m) = "x86_64" ]
then
  curl -L -s -o /usr/bin/jq "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" && chmod +x /usr/bin/jq || true
elif [ $(uname -m) = "i386" ]
then
  curl -L -s -o /usr/bin/jq "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux32" && chmod +x /usr/bin/jq || true
fi

# add common useful files
for user in root vagrant
do
  home=`getent passwd ${user} | cut -d: -f6`
  rsync -rl /tmp/files/ "${home}"/
done


