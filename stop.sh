#!/bin/bash

echo "Terminating Lab..."

PREFIX=/home/baguette/UFG/IC/RedTeam
PYTHON=$PREFIX/.calderavenv/bin/python

LAB=$PREFIX/LAB
CALDERA=$PREFIX/caldera
VELOCIRAPTOR=$LAB/crucible-assets/velociraptor

echo "Stopping Caldera..."
if [[ -f "$LAB/caldera.pid" ]]; then
    PID=$(cat $LAB/caldera.pid)
    if kill -n 9 $PID 2>/dev/null; then
        kill $PID
        echo "Caldera stopped."
    else
        echo "Caldera was not running."
    fi
    rm $LAB/caldera.pid
else
    echo "Caldera PID file not found. Process may have already been killed."
fi

echo "Stopping Velociraptor..."
if [[ -f "$LAB/velociraptor.pid" ]]; then
    PID=$(cat $LAB/velociraptor.pid)
    if kill -n 9 $PID 2>/dev/null; then
        kill $PID
        echo "Velociraptor stopped."
    else
        echo "Velociraptor was not running."
    fi
    rm $LAB/velociraptor.pid
else
    echo "Velociraptor PID file not found. Process may have already been killed."
fi

echo "Disconnecting Crucible Windows virtual machine..."
virsh --connect qemu:///system destroy crucible-win10 2>/dev/null || echo "VM already powered off."

echo "Give me that sudo..."
sudo :

echo "Stopping libvirtd..."
sudo rc-service libvirtd stop

echo "Stopping Docker virtual drive..."
sudo rc-service docker stop
sudo umount /mnt/docker-ext

echo "Removing Velociraptor routing firewall rules..."
sudo iptables -D INPUT -s 192.168.100.0/24 -p tcp --dport 8002 -j ACCEPT 2>/dev/null || true
sudo iptables -t nat -D PREROUTING -s 192.168.100.0/24 -p tcp --dport 8002 -j RETURN 2>/dev/null || true

echo "You can now safely unmount the external drive."
