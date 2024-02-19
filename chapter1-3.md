# Linux bridge

## veth的连通性

创建veth peer，然后给两个veth配置IP，启动网络接口设备

```
ip link add veth0 type veth peer name veth1
ip addr add 192.168.0.2/24 dev veth1
ip addr add 192.168.0.3/24 dev veth0
ip link set veth1 up
ip link set veth0 up
```

尝试从veth0去ping

```
ping -c 1 -I veth0 192.168.0.2
```

ping失败，可是使用`tcpdump -n -i veth0`来抓取在veth0上的网络包。发现在veth0和veth1两个网络接口上抓包都可以收到从veth0发过来的ARP寻址请求，但是不发送reply。

```
00:50:23.064530 ARP, Request who-has 192.168.0.2 tell 192.168.0.3, length 28
00:50:24.088517 ARP, Request who-has 192.168.0.2 tell 192.168.0.3, length 28
00:50:25.112480 ARP, Request who-has 192.168.0.2 tell 192.168.0.3, length 28
00:55:19.034665 ARP, Request who-has 192.168.0.2 tell 192.168.0.3, length 28
```
尝试修改如下网络配置，就可以ping通

```
echo 1 > /proc/sys/net/ipv4/conf/veth1/accept_local
echo 1 > /proc/sys/net/ipv4/conf/veth2/accept_local
echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter
```

另一个发现是从`lo`接口上抓取数据数据包，发现从veth0发送的ICMP数据包，`lo`接口也接受到了，感觉是数据包是陷阱过`lo`然后在发往`veth0`和`veth1`。

`echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter` 
rp_filter 是 Linux 内核提供的一个安全特性，旨在防止 IP 欺骗攻击。它通过检查进入的数据包的源 IP 地址是否有一个合理的路径返回到源地址来工作。如果没有，这些数据包会被丢弃。这是一种确保网络流量有效性的方法，有助于提高网络安全性。
值 0 代表禁用 rp_filter，意味着系统不会丢弃那些没有从接收它们的同一接口上发送回应的数据包的能力的数据包。这可能会使系统对 IP 欺骗攻击更加脆弱。

该命令通过修改`/proc/sys/net/ipv4/conf/veth1/accept_local`的值来配置Linux内核的网络行为。具体来说，它使得名为veth1的网络接口接受发往本地（localhost，即127.0.0.1）IP地址的数据包。

在Linux网络栈的默认配置下，发往127.0.0.0/8网段的数据包只能在lo（回环接口）上接收。这意味着，即使是发往127.0.0.1的数据包，如果不是从lo接口发出的，也不会被接收。这种行为在大多数情况下是预期的，因为127.0.0.0/8地址被设计为仅在本地机器上通信使用。


## 把Veth连接的bridge上




