#!/bin/bash
# UCX 通讯过程通讯设备和协议打印实现指南

cat << 'EOF'
=============================================================================
UCX 通讯过程中打印通讯设备和协议信息 - 实现总结
=============================================================================

本文档总结了如何在 UCX 实际通讯过程中添加通讯设备和协议的打印信息。

## 已实现的修改

### 1. TCP 连接建立时 (tcp_cm.c)
文件: src/uct/tcp/tcp_cm.c
函数: uct_tcp_cm_change_conn_state()
修改位置: 当状态变为 UCT_TCP_EP_CONN_STATE_CONNECTED 时

添加的日志:
  [UCX TCP] Connected: LocalDevice=eth0, LocalAddr=192.168.1.50:5000, 
           RemoteAddr=192.168.1.100:6000, Protocol=TCP

包含信息:
  - 本地网络设备名称 (eth0, eth1 等)
  - 本地绑定地址和端口
  - 远端对等地址和端口
  - 通讯协议 (TCP)

### 2. TCP 连接关闭时 (tcp_cm.c)
修改位置: 当状态变为 UCT_TCP_EP_CONN_STATE_CLOSED 时

添加的日志:
  [UCX TCP] Disconnected: LocalDevice=eth0, RemoteAddr=192.168.1.100:6000, 
           Protocol=TCP, PreviousState=CONNECTED

包含信息:
  - 本地网络设备
  - 远端地址（仅当从 CONNECTED 状态关闭时）
  - 协议类型
  - 前一个状态

### 3. TCP 数据发送时 (tcp_ep.c)
函数: uct_tcp_ep_am_short()
修改位置: 成功发送后添加日志

添加的日志:
  [UCX TCP TX] Sending AM Short: Device=eth0, Length=1024, AMID=5, Dest=192.168.1.100:6000

包含信息:
  - 通讯设备
  - 发送数据长度 (字节)
  - Active Message ID
  - 目标地址

## 日志级别说明

- INFO 日志: 连接建立/断开等重要事件
- TRACE 日志: 每次数据传输 (高频操作)

## 使用方法

### 查看所有通讯操作
```bash
export UCX_LOG_LEVEL=debug
./your_app 2>&1 | grep "\[UCX TCP\]"
```

### 查看连接建立过程
```bash
./your_app 2>&1 | grep "\[UCX TCP\] Connected"
```

### 查看发送详情
```bash
./your_app 2>&1 | grep "\[UCX TCP TX\]"
```

### 保存日志到文件
```bash
export UCX_DEBUG_LOG_FILE=communication.log
./your_app
tail -f communication.log
```

## 实现要点

### 1. 获取本地网络设备名称
通过 iface->if_name 获取 (在 uct_tcp_iface_t 结构中)

### 2. 获取地址信息
使用 ucs_sockaddr_str() 函数将 struct sockaddr 转换为易读格式:
  - 本地地址: &iface->config.ifaddr
  - 远端地址: &ep->peer_addr

### 3. 获取连接状态
通过 ep->conn_state 检查是否真的连接:
  - UCT_TCP_EP_CONN_STATE_CONNECTED: 已连接
  - UCT_TCP_EP_CONN_STATE_CLOSED: 已关闭

### 4. 日志消息格式
使用标准格式便于日志解析:
  [UCX <PROTOCOL>] <EVENT>: <Details>

## 进一步改进方向

1. **接收数据日志** (tcp_ep_progress_data_rx)
   - 记录接收的数据大小
   - 接收数据的来源

2. **PUT/GET 操作日志**
   - 记录远程内存访问操作
   - RDMA 数据量和目标地址

3. **错误和重试日志**
   - 连接失败原因
   - 重试次数和间隔

4. **性能指标**
   - 连接建立时间
   - 数据传输延迟
   - 吞吐量统计

5. **InfiniBand 特定日志**
   - QP 创建日志
   - 完成队列事件日志
   - 路径迁移日志

## 编译和测试

```bash
# 重新编译 UCX
cd ucx
make clean
make -j$(nproc)
make install

# 测试新日志
export UCX_LOG_LEVEL=info
./test_program 2>&1 | grep "\[UCX TCP\]"
```

## 验证清单

- [ ] 连接建立时打印设备和地址
- [ ] 发送数据时打印详细信息  
- [ ] 连接关闭时打印日志
- [ ] 日志格式一致且易于解析
- [ ] 日志级别适当（INFO/TRACE）
- [ ] 不影响性能（使用条件日志）
- [ ] 支持远程调试和分析

## 示例输出

```
========================================
TCP 单向通讯示例
========================================
[UCX TCP] Connected: LocalDevice=eth0, LocalAddr=192.168.1.50:5000, RemoteAddr=192.168.1.100:6000, Protocol=TCP

[UCX TCP TX] Sending AM Short: Device=eth0, Length=1024, AMID=5, Dest=192.168.1.100:6000
[UCX TCP TX] Sending AM Short: Device=eth0, Length=2048, AMID=5, Dest=192.168.1.100:6000
[UCX TCP TX] Sending AM Short: Device=eth0, Length=4096, AMID=5, Dest=192.168.1.100:6000

[UCX TCP] Disconnected: LocalDevice=eth0, RemoteAddr=192.168.1.100:6000, Protocol=TCP, PreviousState=CONNECTED

========================================
多设备场景示例
========================================
[UCX TCP] Connected: LocalDevice=eth0, LocalAddr=192.168.1.50:5000, RemoteAddr=192.168.1.100:6000, Protocol=TCP
[UCX TCP] Connected: LocalDevice=eth1, LocalAddr=192.168.2.50:5001, RemoteAddr=192.168.2.100:6001, Protocol=TCP

[UCX TCP TX] Sending AM Short: Device=eth0, Length=8192, AMID=5, Dest=192.168.1.100:6000
[UCX TCP TX] Sending AM Short: Device=eth1, Length=8192, AMID=5, Dest=192.168.2.100:6001

[UCX TCP] Disconnected: LocalDevice=eth0, RemoteAddr=192.168.1.100:6000, Protocol=TCP, PreviousState=CONNECTED
[UCX TCP] Disconnected: LocalDevice=eth1, RemoteAddr=192.168.2.100:6001, Protocol=TCP, PreviousState=CONNECTED
```

## 参考资源

- UCX 源代码: src/uct/tcp/
- 关键文件:
  * tcp_cm.c - 连接管理
  * tcp_ep.c - 端点和通讯操作
  * tcp.h - 数据结构定义

EOF
