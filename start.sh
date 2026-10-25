#!/bin/bash

echo "Starting Lab..."

if [[ ! -d "/run/media/baguette/TOSHIBA EXT" ]]; then
    echo "ERROR: Hard drive not found. Please plug it in and ensure it is mounted."
    exit 1
fi

PREFIX=/home/baguette/UFG/IC/RedTeam
PYTHON=$PREFIX/.calderavenv/bin/python

LAB=$PREFIX/LAB
CALDERA=$PREFIX/caldera
VELOCIRAPTOR=$LAB/crucible-assets/velociraptor

echo "Preparing virtual environment..."
source $PREFIX/.calderavenv/bin/activate

echo "Starting Caldera..."
cd $CALDERA
$PYTHON server.py --insecure > $LAB/caldera.log &
echo $! > $LAB/caldera.pid
cat $LAB/caldera.pid

echo "Give me that sudo..."
sudo :

echo "Mounting Docker virtual drive..."
sudo mount -o loop "/run/media/baguette/TOSHIBA EXT/docker-storage.img" /mnt/docker-ext
sudo rc-service docker start

echo "Starting libvirtd..."
sudo rc-service libvirtd start

echo "Modifying host firewall to allow Velociraptor routing..."
sudo iptables -I INPUT 1 -s 192.168.100.0/24 -p tcp --dport 8002 -j ACCEPT
sudo iptables -t nat -I PREROUTING 1 -s 192.168.100.0/24 -p tcp --dport 8002 -j RETURN

echo "Starting Velociraptor..."
cd $VELOCIRAPTOR
./velociraptor --config server.config.yaml frontend > $LAB/veloricaptor.log &
echo $! > $LAB/velociraptor.pid
cat $LAB/velociraptor.pid

echo "Booting Crucible Windows virtual machine..."
virsh --connect qemu:///system start crucible-win10

echo "The environment is up and running. Give the systems ~2 mins to initialize."
echo -en "Caldera:\thttp://127.0.0.1:8888\n"
echo -en "Velociraptor:\thttps://127.0.0.1:8889\n"
echo -en "MLflow:\thttp://127.0.0.1:5000\n"
