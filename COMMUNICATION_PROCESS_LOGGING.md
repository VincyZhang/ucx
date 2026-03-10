# UCX 实际通讯过程中的设备和协议打印增强

## 概述
本文档描述如何在实际通讯过程中（而不仅仅是初始化阶段）打印通讯设备和协议信息的详细实现步骤。

## 实现目标

在以下关键通讯操作时添加设备和协议信息：
1. **连接建立 (Connection Establishment)**
2. **数据发送 (Data Transmission)**
3. **数据接收 (Data Reception)**
4. **连接断开 (Connection Termination)**

## TCP 通讯过程中的打印位置

### 1. 连接建立时 (tcp_ep.c)

**文件:** `src/uct/tcp/tcp_ep.c`

**关键函数:** `uct_tcp_ep_connect_to_ep_v2()` (约第 920 行)

**需要添加的日志:**
```c
// 在连接状态变为 CONNECTED 时
ucs_info("[UCX TCP] Connection Established: Device=%s, RemoteAddr=%s, "
         "Protocol=TCP, LocalAddr=%s",
         iface->if_name, 
         ucs_sockaddr_str((struct sockaddr *)&ep->peer_addr, 
                         ip_addr_str, sizeof(ip_addr_str)),
         ucs_sockaddr_str((struct sockaddr *)&iface->config.ifaddr,
                         local_addr_str, sizeof(local_addr_str)));
```

### 2. 数据发送时 (tcp_ep.c)

**函数:** `uct_tcp_ep_progress_data_tx()` (约第 1400+ 行)

**关键位置:** 当数据实际被发送到网络时

**需要添加的日志:**
```c
ucs_trace("[UCX TCP TX] Sending data: Device=%s, Bytes=%zu, RemoteAddr=%s",
          iface->if_name, 
          bytes_sent,
          ucs_sockaddr_str((struct sockaddr *)&ep->peer_addr, 
                          ip_addr_str, sizeof(ip_addr_str)));
```

### 3. 数据接收时 (tcp_ep.c)

**函数:** `uct_tcp_ep_progress_data_rx()` 

**关键位置:** 当从网络接收数据时

**需要添加的日志:**
```c
ucs_trace("[UCX TCP RX] Receiving data: Device=%s, Bytes=%zu, RemoteAddr=%s",
          iface->if_name,
          bytes_received,
          ucs_sockaddr_str((struct sockaddr *)&ep->peer_addr,
                          ip_addr_str, sizeof(ip_addr_str)));
```

### 4. 连接关闭时 (tcp_ep.c)

**函数:** `uct_tcp_ep_disconnect_internal()` 或类似的清理函数

**需要添加的日志:**
```c
ucs_info("[UCX TCP] Connection Closed: Device=%s, RemoteAddr=%s, Reason=%s",
         iface->if_name,
         ucs_sockaddr_str((struct sockaddr *)&ep->peer_addr,
                         ip_addr_str, sizeof(ip_addr_str)),
         reason_str);
```

## InfiniBand 通讯过程中的打印位置

### 1. QP (Queue Pair) 创建和连接

**文件:** `src/uct/ib/ud/base/ud_ep.c` 或 `src/uct/ib/rc/base/rc_ep.c`

**需要添加的日志:**
```c
ucs_info("[UCX IB] QP Created: Device=%s, QPN=%u, PSN=%u, Protocol=%s, Type=%s",
         uct_ib_device_name(&md->dev),
         qp->qp_num,
         qp_init_attr->qp_init_attr_mask,
         protocol_name,  // "RC" or "UD"
         qp_type_str);   // Reliable Connected or Unreliable Datagram
```

### 2. IB 数据发送时

**文件:** 相应的协议文件 (rc_ep.c 或 ud_ep.c)

**关键函数:** `uct_rc_ep_post_send()` 或 `uct_ud_ep_post_send()`

**需要添加的日志:**
```c
ucs_trace("[UCX IB %s TX] Posting Send: Device=%s, NumSGE=%u, "
          "OpType=%s, RemoteQPN=%u",
          protocol_name,
          uct_ib_device_name(&md->dev),
          sr->num_sge,
          opcode_str,  // SEND, RDMA_WRITE, RDMA_READ, etc.
          ep->remote_qp_num);
```

### 3. IB 数据接收时

**关键函数:** CQ poll/completion 函数

**需要添加的日志:**
```c
ucs_trace("[UCX IB %s RX] Completion Received: Device=%s, "
          "NumBytes=%u, OpType=%s, RemoteQPN=%u",
          protocol_name,
          uct_ib_device_name(&md->dev),
          wc.byte_len,
          completion_type_str,
          wc.src_qp);
```

## 配置和使用

### 编译和运行

```bash
# 启用 DEBUG 日志级别
export UCX_LOG_LEVEL=debug
export UCX_DEBUG_LOG_FILE=ucx_communication.log

# 运行应用
./your_app
```

### 查看日志

```bash
# 查看所有通讯操作
grep "\[UCX.*\]" ucx_communication.log

# 只看 TCP 连接
grep "\[UCX TCP\] Connection" ucx_communication.log

# 只看 IB QP 创建
grep "\[UCX IB.*QP Created" ucx_communication.log

# 查看发送和接收（详细跟踪）
grep "\[UCX.*TX\]\|\[UCX.*RX\]" ucx_communication.log
```

## 预期输出示例

### TCP 通讯过程：
```
[UCX TCP] Interface Initialized: Device=eth0, Protocol=TCP, AF_Count=2, TX_Size=8216, RX_Size=65544
[UCX TCP] Connection Established: Device=eth0, RemoteAddr=192.168.1.100:5000, Protocol=TCP, LocalAddr=192.168.1.50:12345
[UCX TCP TX] Sending data: Device=eth0, Bytes=4096, RemoteAddr=192.168.1.100:5000
[UCX TCP RX] Receiving data: Device=eth0, Bytes=2048, RemoteAddr=192.168.1.100:5000
[UCX TCP TX] Sending data: Device=eth0, Bytes=8192, RemoteAddr=192.168.1.100:5000
[UCX TCP] Connection Closed: Device=eth0, RemoteAddr=192.168.1.100:5000, Reason=remote_peer_disconnected
```

### InfiniBand 通讯过程：
```
[UCX IB] Registering InfiniBand component with 2 transport layers
[UCX IB] Registered IB transport layer: rc_verbs
[UCX IB] Registered IB transport layer: ud_verbs
[UCX IB] QP Created: Device=mlx5_0, QPN=42, PSN=12345, Protocol=RC, Type=RC
[UCX IB RC TX] Posting Send: Device=mlx5_0, NumSGE=1, OpType=SEND, RemoteQPN=50
[UCX IB RC RX] Completion Received: Device=mlx5_0, NumBytes=1024, OpType=RECV, RemoteQPN=50
[UCX IB RC TX] Posting Send: Device=mlx5_0, NumSGE=2, OpType=RDMA_WRITE, RemoteQPN=50
```

## 关键信息解释

### 设备信息
- **Device Name**: 网络接口 (eth0, eth1) 或 InfiniBand 设备 (mlx5_0)
- **Local Address**: 本地绑定的 IP 地址和端口
- **Remote Address**: 远端对等节点的地址和端口

### 协议信息
- **Protocol**: TCP/RDMA/InfiniBand
- **Type**: RC (Reliable Connected), UD (Unreliable Datagram)
- **Operation**: SEND, RECV, RDMA_WRITE, RDMA_READ, ATOMIC

### 性能指标
- **Bytes**: 传输的字节数
- **NumSGE**: Scatter-Gather 元素数量（IB）
- **QPN**: Queue Pair Number (IB)
- **PSN**: Packet Sequence Number (IB)

## 调试技巧

### 1. 跟踪特定设备的通讯
```bash
export UCX_LOG_LEVEL=debug
./your_app 2>&1 | grep "Device=eth0"
```

### 2. 统计通讯量
```bash
grep "\[UCX.*TX\]" ucx_communication.log | wc -l
grep "\[UCX.*RX\]" ucx_communication.log | wc -l
```

### 3. 性能分析
```bash
# 计算平均传输大小
grep "\[UCX.*TX\]" ucx_communication.log | \
  awk '{sum+=$NF; count++} END {print "Average:", sum/count}'
```

## 修改清单

| 文件 | 函数 | 修改位置 | 日志类型 |
|------|------|---------|--------|
| tcp_ep.c | uct_tcp_ep_connect_to_ep_v2 | 连接成功后 | INFO |
| tcp_ep.c | uct_tcp_ep_progress_data_tx | 数据发送时 | TRACE |
| tcp_ep.c | uct_tcp_ep_progress_data_rx | 数据接收时 | TRACE |
| tcp_ep.c | 清理函数 | 连接关闭时 | INFO |
| rc_ep.c | uct_rc_ep_post_send | send posting | TRACE |
| ud_ep.c | uct_ud_ep_post_send | send posting | TRACE |
| 其他 | CQ handlers | 完成处理 | TRACE |

## 性能考虑

- **INFO 级别日志**: 用于重要事件（连接建立/关闭）
- **TRACE 级别日志**: 用于高频操作（发送/接收），仅在需要时启用
- **性能影响**: 日志级别为 INFO 时影响可忽略；DEBUG 级别可能有 5-10% 性能开销

## 下一步

完整的代码实现需要：
1. 在 tcp_ep.c 中修改连接和数据路径函数
2. 在 IB 相关文件中添加 QP 和完成处理的日志
3. 添加辅助函数来格式化地址和操作名称
4. 编译和测试以验证输出格式
