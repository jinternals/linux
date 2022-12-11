#!/bin/sh

# Author : Mradul Pandey

NAMESPACE_PREFIX=namespace
VETH_ENDPOINT_PREFIX=veth0
ETH_ENDPOINT_PREFIX=eth0
SUBNET=10.11.0.0/16
BRIDGE_IP=10.11.0.1
NAMESPACE_1_IP=10.11.0.2
NAMESPACE_2_IP=10.11.0.3
BRIDGE_NAME=br0


echo "Creating network namespace"
ip netns add "${NAMESPACE_PREFIX}-1"
ip netns add "${NAMESPACE_PREFIX}-2"

ip link add "${VETH_ENDPOINT_PREFIX}.1" type veth peer name "${ETH_ENDPOINT_PREFIX}.1"
ip link add "${VETH_ENDPOINT_PREFIX}.2" type veth peer name "${ETH_ENDPOINT_PREFIX}.2"

ip link set "${ETH_ENDPOINT_PREFIX}.1" netns "${NAMESPACE_PREFIX}-1"
ip link set "${ETH_ENDPOINT_PREFIX}.2" netns "${NAMESPACE_PREFIX}-2"

ip link set "${VETH_ENDPOINT_PREFIX}.1" up
ip link set "${VETH_ENDPOINT_PREFIX}.2" up

ip netns exec "${NAMESPACE_PREFIX}-1" ip link set lo up
ip netns exec "${NAMESPACE_PREFIX}-2" ip link set lo up

ip netns exec "${NAMESPACE_PREFIX}-1" ip link set "${ETH_ENDPOINT_PREFIX}.1" up
ip netns exec "${NAMESPACE_PREFIX}-2" ip link set "${ETH_ENDPOINT_PREFIX}.2" up

echo "Assign ip address eth0.x interface"
ip netns exec "${NAMESPACE_PREFIX}-1" ip addr add "${NAMESPACE_1_IP}/16" dev "${ETH_ENDPOINT_PREFIX}.1"
ip netns exec "${NAMESPACE_PREFIX}-2" ip addr add "${NAMESPACE_2_IP}/16" dev "${ETH_ENDPOINT_PREFIX}.2"


echo "Setup bridge"
ip link add "${BRIDGE_NAME}" type bridge
ip link set "${BRIDGE_NAME}" up

ip link set "${VETH_ENDPOINT_PREFIX}.1" master "${BRIDGE_NAME}"
ip link set "${VETH_ENDPOINT_PREFIX}.2" master "${BRIDGE_NAME}"

ip addr add "${BRIDGE_IP}/16" dev "${BRIDGE_NAME}"

ip netns exec "${NAMESPACE_PREFIX}-1" ip route add default via "${BRIDGE_IP}"
ip netns exec "${NAMESPACE_PREFIX}-2" ip route add default via "${BRIDGE_IP}"

ip netns exec "${NAMESPACE_PREFIX}-1" ping -c 2 "${NAMESPACE_2_IP}"
ip netns exec "${NAMESPACE_PREFIX}-2" ping -c 2 "${NAMESPACE_1_IP}"

bash -c 'echo 1' > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -s "${SUBNET}" ! -o "${BRIDGE_NAME}" -j MASQUERADE
