# UCX Communication Device and Protocol Logging

## Overview
This document describes the enhancements made to UCX (Unified Communication X) to add detailed logging of communication devices and communication protocols during initialization.

## Modifications Made

### 1. Core UCX Component Initialization (src/uct/base/uct_component.c)

#### Change 1.1: Enhanced `uct_init()` function
**Location:** Lines 30-35
**Change:** Added info-level logging for each transport layer being initialized

**Before:**
```c
void UCS_F_CTOR uct_init()
{
    uct_self_init();
    uct_tcp_init();
    uct_sysv_init();
    uct_posix_init();
}
```

**After:**
```c
void UCS_F_CTOR uct_init()
{
    ucs_info("========================================");
    ucs_info("Initializing UCX Transport Layers (TLs)");
    ucs_info("========================================");
    ucs_info("Starting self transport layer");
    uct_self_init();
    ucs_info("Starting TCP transport layer");
    uct_tcp_init();
    ucs_info("Starting SYSV IPC transport layer");
    uct_sysv_init();
    ucs_info("Starting POSIX shared memory transport layer");
    uct_posix_init();
    ucs_info("========================================");
    ucs_info("UCX Transport Layer Initialization Done");
    ucs_info("========================================");
}
```

**Benefit:** Provides visibility into which transport layers are being initialized and in what order.

#### Change 1.2: Enhanced `uct_query_components()` function
**Location:** Lines 63-67
**Change:** Added logging when registering components

**Before:**
```c
ucs_list_for_each(component, &uct_components_list, list) {
    *(components++) = component;
    ucs_vfs_obj_add_dir(NULL, component, "uct/component/%s",
                        component->name);
}
```

**After:**
```c
ucs_list_for_each(component, &uct_components_list, list) {
    *(components++) = component;
    ucs_vfs_obj_add_dir(NULL, component, "uct/component/%s",
                        component->name);
    ucs_info("[UCX] Registered Component: %s", component->name);
}
```

**Benefit:** Shows all registered components and their names.

### 2. TCP Transport Layer (src/uct/tcp/tcp_md.c)

#### Change 2.1: Enhanced `uct_tcp_md_open()` function
**Location:** Lines 94-97
**Change:** Added info-level logging when TCP memory domain is opened

**Before:**
```c
    *md_p = &tcp_md->super;
    return UCS_OK;
```

**After:**
```c
    *md_p = &tcp_md->super;
    ucs_info("[UCX TCP] Memory Domain Opened: Component=%s, Name=%s, AF_Prio_Count=%u, Bridge_Enable=%d",
             UCT_TCP_NAME, md_name, tcp_md->config.af_prio_count, tcp_md->config.bridge_enable);
    return UCS_OK;
```

**Benefit:** Shows TCP component configuration including address family priority count and bridge settings.

### 3. TCP Interface Layer (src/uct/tcp/tcp_iface.c)

#### Change 3.1: Enhanced `uct_tcp_query_devices()` function
**Location:** Lines 1030-1040
**Change:** Added detailed logging of discovered network devices

**Added Code:**
```c
    /* Print discovered TCP network devices */
    ucs_info("[UCX TCP] Query Devices Results:");
    ucs_info("  - Total Network Devices Found: %u", num_devices);
    for (i = 0; i < num_devices; i++) {
        ucs_info("    * Device Name: %s, Type: NET", devices[i].name);
    }
```

**Benefit:** Shows all available TCP network devices detected on the system.

#### Change 3.2: Enhanced TCP Interface Initialization
**Location:** Lines 860-867 (after `uct_tcp_iface_listener_init()`)
**Change:** Added info-level logging when TCP interface is fully initialized

**Added Code:**
```c
    ucs_info("[UCX TCP] Interface Initialized: Device=%s, Protocol=TCP, AF_Count=%u, "
             "TX_Size=%zu, RX_Size=%zu",
             self->if_name, tcp_md->config.af_prio_count,
             self->config.tx_seg_size, self->config.rx_seg_size);
```

**Benefit:** Shows specific interface configuration including segment sizes for TX and RX.

### 4. InfiniBand Transport Layer (src/uct/ib/base/ib_md.c)

#### Change 4.1: Enhanced `uct_ib_init()` function
**Location:** Lines 1620-1635
**Change:** Added detailed logging for IB component and transport layer registration

**Before:**
```c
void UCS_F_CTOR uct_ib_init()
{
    UCS_MODULE_FRAMEWORK_DECLARE(uct_ib);
    ssize_t i;

    ucs_list_add_head(&uct_ib_ops, &UCT_IB_MD_OPS_NAME(verbs).list);
    uct_component_register(&uct_ib_component);

    for (i = 0; i < ucs_static_array_size(uct_ib_tls); i++) {
        uct_tl_register(&uct_ib_component, uct_ib_tls[i]);
    }

    UCS_MODULE_FRAMEWORK_LOAD(uct_ib, 0);
}
```

**After:**
```c
void UCS_F_CTOR uct_ib_init()
{
    UCS_MODULE_FRAMEWORK_DECLARE(uct_ib);
    ssize_t i;

    ucs_list_add_head(&uct_ib_ops, &UCT_IB_MD_OPS_NAME(verbs).list);
    uct_component_register(&uct_ib_component);
    ucs_info("[UCX IB] Registering InfiniBand component with %zu transport layers", 
             ucs_static_array_size(uct_ib_tls));

    for (i = 0; i < ucs_static_array_size(uct_ib_tls); i++) {
        uct_tl_register(&uct_ib_component, uct_ib_tls[i]);
        ucs_info("[UCX IB] Registered IB transport layer: %s", uct_ib_tls[i]->name);
    }

    UCS_MODULE_FRAMEWORK_LOAD(uct_ib, 0);
}
```

**Benefit:** Shows IB component details and all registered transport layers (RC, UD, DC, etc.).

## Expected Output

When UCX is initialized with these changes, you'll see log messages like:

```
========================================
Initializing UCX Transport Layers (TLs)
========================================
Starting self transport layer
Starting TCP transport layer
[UCX TCP] Memory Domain Opened: Component=tcp, Name=NULL, AF_Prio_Count=2, Bridge_Enable=0
[UCX TCP] Query Devices Results:
  - Total Network Devices Found: 2
    * Device Name: eth0, Type: NET
    * Device Name: eth1, Type: NET
Starting SYSV IPC transport layer
Starting POSIX shared memory transport layer
========================================
UCX Transport Layer Initialization Done
========================================
[UCX] Registered Component: self
[UCX] Registered Component: tcp
[UCX] Registered Component: sysv
[UCX] Registered Component: posix
```

If InfiniBand devices are present:
```
[UCX IB] Registering InfiniBand component with 3 transport layers
[UCX IB] Registered IB transport layer: rc_mlx5
[UCX IB] Registered IB transport layer: ud_mlx5
[UCX IB] Registered IB transport layer: dc_mlx5
```

And when TCP interface is opened on a specific device:
```
[UCX TCP] Interface Initialized: Device=eth0, Protocol=TCP, AF_Count=2, TX_Size=8216, RX_Size=65544
```

## Configuration

These logs are printed at `ucs_info()` level, which means they will appear when:
- UCX_LOG_LEVEL is set to DEBUG or higher
- Or in the default INFO level output

To see these messages, you can:
```bash
export UCX_LOG_LEVEL=info
export UCX_DEBUG_LOG_FILE=ucx_debug.log  # Optional
```

## Files Modified

1. `src/uct/base/uct_component.c` - 2 changes
2. `src/uct/tcp/tcp_md.c` - 1 change
3. `src/uct/tcp/tcp_iface.c` - 2 changes
4. `src/uct/ib/base/ib_md.c` - 1 change

**Total Lines Added:** ~25 logging statements

## Benefits

1. **Visibility:** Clear understanding of which communication protocols are available
2. **Device Discovery:** See all network devices and their types
3. **Configuration Verification:** Confirm transport layer configurations
4. **Debugging:** Easier troubleshooting of initialization issues
5. **Performance Analysis:** Understanding available transport layers helps with performance tuning
