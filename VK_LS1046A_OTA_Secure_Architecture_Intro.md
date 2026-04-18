# LS1046A Multi‑Core OTA + Secure Boot Architecture (Introduction)

**Document version:** 1.0  
**Date:** 2026-04-18  
**Target platform:** NXP Layerscape LS1046A (Yocto scarthgap, U‑Boot FIT boot)  
**Purpose:** Introduce the solution architecture for a commercial delivery: OTA A/B, multi-core independence, deterministic role shift, and an optional security layer with runtime bypass for OTA bundle verification.

---

## 1. Initial Repository Layout (Baseline)

The baseline solution consists of two Yocto layers:

- **meta-vk-custom**: OTA system logic, images, initramfs, role handling, boot scripts
- **meta-vk-secure**: optional security overlay; can be delivered as a standalone private repository

### 1.1 meta-vk-custom (functional layer)

**Responsibilities**
- Builds the system images and initramfs
- Defines OTA update flow and A/B rootfs behavior
- Provides U‑Boot boot scripts for multi-core coordination
- Provides runtime services: role manager, health check, update agent
- Produces shared environment FIT payload used for boot-cycle coordination

**Key outputs**
- `fitImage` (kernel + DTB + initramfs in FIT container)
- `core-image-ota` rootfs image (shared rootfs A/B)
- `shared-env.itb` (shared environment FIT)
- `boot-ota.scr` (U‑Boot script image)

### 1.2 meta-vk-secure (security overlay layer)

**Responsibilities**
- Enforces FIT signature verification in U‑Boot
- Signs FIT artifacts (shared-env.itb)
- Adds dm-verity rootfs integrity support
- Adds LUKS data partition encryption tooling
- Adds OTA bundle verification tooling
- Provides key generation and signing helper scripts (offline)

**Delivery model**
- Recommended as a **separate private repository** for commercial delivery due to access control, audit scope, and licensing separation.

---

## 2. FIT Image Enablement (Kernel + DTB + Initramfs)

The LS1046A platform boots via U‑Boot. The architecture uses **FIT images** so that kernel, device tree, and initramfs can be packaged and (optionally) signed as a single boot artifact.

### 2.1 FIT configuration approach

A machine include file (example: `ls1046a-fitimage.inc`) is used to enable FIT output:

- `KERNEL_IMAGETYPE = "fitImage"`
- `KERNEL_CLASSES += "kernel-fitimage"`
- `INITRAMFS_IMAGE = "core-image-minimal-initramfs"`
- `INITRAMFS_IMAGE_BUNDLE = "0"` (initramfs remains a separate FIT node)

### 2.2 Why initramfs is a separate FIT node

Keeping initramfs as a separate FIT node provides:
- Explicit U‑Boot loading of kernel / fdt / ramdisk
- Cleaner signing boundaries
- Easier debugging and replacement in development (still subject to signature enforcement in secure mode)

---

## 3. Multi‑Core Architecture

The system is designed for **three independent cores** running the same software stack, with coordination via a shared environment and deterministic role rotation.

### 3.1 Storage layout (conceptual)

**Shared storage (eMMC/SD)**
- RootFS slot A
- RootFS slot B
- Shared environment partition (shared-env.itb or extracted env file)

**Per-core dedicated storage (×3)**
- FIT slot A (kernel+dtb+initramfs)
- FIT slot B (kernel+dtb+initramfs)
- Per-core U‑Boot environment
- Per-core data partition (persistent; not overwritten by OTA)

### 3.2 Independence principle

- Rootfs is shared and updated only by the **Master** core.
- FIT images are per-core and updated **independently** by each core.
- Data partitions are per-core and remain persistent across updates.

---

## 4. Boot Shift / Role Rotation Mechanism

To improve resiliency and avoid a single point of failure, roles rotate deterministically on each boot cycle.

### 4.1 Roles

- **Master**: coordinates shared resources, performs shared rootfs updates, confirms shared rootfs state.
- **Slave**: runs workload; does not update shared rootfs.
- **Backup**: standby; can become master on next shift cycle.

### 4.2 Deterministic rotation formula

Define:

- `core_id` ∈ {1,2,3}
- `boot_cycle` is an integer counter
- Role list: `ROLES = [Master, Slave, Backup]`

Then role is computed as:
