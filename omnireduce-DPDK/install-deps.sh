#!/bin/bash

if [ $(id -u) != 0 ]; then
    echo "You must run this script as root"
    exit 1
fi
pushd .
# Install deps
apt-get update
apt-get install -y \
    autotools-dev \
    bison \
    build-essential \
    ca-certificates \
    chrpath \
    coreutils \
    debhelper \
    dh-python \
    dpatch \
    ethtool \
    flex \
    gcc \
    gfortran \
    git \
    graphviz \
    iproute2 \
    kmod \
    libboost-program-options-dev \
    libboost-chrono-dev \
    libboost-system-dev \
    libboost-thread-dev \
    libc6-dev \
    libelf1 \
    libgfortran3 \
    libglib2.0-0 \
    libhiredis-dev \
    libjpeg-dev \
    libltdl-dev \
    libmnl-dev \
    libnl-3-200 \
    libnl-3-dev \
    libnl-route-3-200 \
    libnl-route-3-dev \
    libnuma-dev \
    libnuma1 \
    libpng-dev \
    libpython3-dev \
    libssl1.0.0 \
    linux-headers-$(uname -r) \
    linux-modules-$(uname -r) \
    lsb-release \
    lsof \
    m4 \
    net-tools \
    openssh-client \
    openssh-server \
    pciutils \
    perl \
    pkg-config \
    python3 \
    python3-dev \
    python3-distutils \
    swig \
    tk \
    udev \
    vim \
    wget && rm -rf /var/lib/apt/lists/*

# Allow OpenSSH to talk to other nodes without asking for confirmation
mkdir -p /var/run/sshd && cat /etc/ssh/ssh_config | grep -v 'StrictHostKeyChecking' > /etc/ssh/ssh_config.new
echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config.new
mv /etc/ssh/ssh_config.new /etc/ssh/ssh_config

# Install MLNX driver 
export MOFED_VER=5.3-1.0.0.1
mkdir -p /tmp/mofed
cd /tmp/mofed
wget http://content.mellanox.com/ofed/MLNX_OFED-${MOFED_VER}/MLNX_OFED_LINUX-${MOFED_VER}-ubuntu18.04-$(uname -m).tgz
tar -xzvf *.tgz &&
*/mlnxofedinstall --user-space-only --without-fw-update --upstream-libs --dpdk --force
cd /tmp
rm -rf mofed

# Install Open MPI
mkdir /tmp/openmpi
cd /tmp/openmpi
wget -q https://www.open-mpi.org/software/ompi/v4.1/downloads/openmpi-4.1.1.tar.gz
tar zxf openmpi-4.1.1.tar.gz
cd openmpi-4.1.1
./configure --enable-orterun-prefix-by-default
make -j $(nproc) all
make install
ldconfig
rm -rf /tmp/openmpi

# Create a wrapper for OpenMPI to allow running as root by default
# Configure OpenMPI to run good defaults:
#   --bind-to none --map-by slot --mca btl_tcp_if_exclude lo,docker0
mv /usr/local/bin/mpirun /usr/local/bin/mpirun.real
echo '#!/bin/bash' > /usr/local/bin/mpirun
echo 'mpirun.real --allow-run-as-root "$@"' >> /usr/local/bin/mpirun
chmod a+x /usr/local/bin/mpirun
echo "hwloc_base_binding_policy = none" >> /usr/local/etc/openmpi-mca-params.conf
echo "rmaps_base_mapping_policy = slot" >> /usr/local/etc/openmpi-mca-params.conf
echo "btl_tcp_if_exclude = lo,docker0" >> /usr/local/etc/openmpi-mca-params.conf

# Install conda
popd
wget https://repo.anaconda.com/archive/Anaconda3-2022.10-Linux-x86_64.sh
sh Anaconda3-2022.10-Linux-x86_64.sh -b
/home/ubuntu/anaconda3/bin/conda init
source ~/.bashrc

# Create conda environment
conda env create --prefix ../env --file environment.yml

