# Tested on CentOS 7

yum install -y patch git epel-release
# Build dependencies
yum install -y gcc lmdb-devel openssl-devel pcre-devel pam-devel libxml2-devel libtool bison flex
# Development dependencies
yum install -y gdb valgrind
# Clone repo and build with options similar to Rudder packaging
su vagrant -c "cd && git clone https://github.com/cfengine/core.git && cd core \
                  && ./autogen.sh --prefix=/opt/rudder --with-workdir=/var/rudder/cfengine-community --enable-debug \
                  && make -j2"
