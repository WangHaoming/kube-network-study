
# add a new network namespace
ip netns add netns1

# start up the "lo" NIC
ip netns exec netns1 ip link set dev lo up
# ping lo
ip netns exec netns1 ping 127.0.0.1

# add veth pair
ip link add veth0 type veth peer name veth1
ip link set veth1 netns netns1


# config IP for veth pair
ip netns exec netns1 ifconfig veth1 10.0.0.1/24 up
ifconfig veth0 10.0.0.2/24 up
ip netns exec netns1 ping 10.0.0.2


# check route in network namespace netns1
ip netns exec netns1 route
# check if can access public network from the network namesapce
ip netns exec netns1 curl ifconfig.me


# check device ID of ens4 NIC
cat /sys/class/net/ens4/iflink


# create a network bridge
ip link add name br0 type bridge
ip link set br0 up

ip addr add 1.2.3.102/24 dev veth1
ip addr add 1.2.3.101/24 dev veth0

# link veth0 to br0
ip link set dev veth0 master br0


#  ping test

ping -c 1 -I veth0 1.2.3.102

# tcpdunp
tcpdump -n -i veth1
tcpdump -n -i veth0
tcpdump -n -i br0


#  ping from veth0
ping -c 1 -I veth0 1.2.3.102



# delete 1 route make it work
ip route del 1.2.3.0/24 dev veth1