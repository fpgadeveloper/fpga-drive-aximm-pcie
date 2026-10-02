# Test the SSDs in Linux

This page applies to both Linux flows ([PetaLinux](petalinux) and [Yocto](yocto)): once
the board has booted and you are logged in, the SSDs are tested the same way. The
examples were captured on the Yocto images; the PetaLinux images print the same
information.

The tools used here are included in the images: `lspci` (pciutils), `nvme`
(nvme-cli — in all Yocto images and in the Zynq-7000 / Zynq UltraScale+ PetaLinux images;
on the Versal PetaLinux images enable it with `petalinux-config -c rootfs`), `fdisk`, `mkfs.ext4`/`mke2fs`, `blkid` and `dd`. The Versal images
also carry the `single_*_test.sh` / `dual_*_test.sh` speed-test scripts described below.
Most of the commands need root privileges: on the Yocto images, prefix them with `sudo`;
on the PetaLinux images, use `sudo` as the `petalinux` user.

## 1. Check that the PCIe link is up

The kernel reports each Root Port as it probes it. Look for `PCIe Link is UP` and the SSD
being found on bus 01:

```
dmesg | grep -iE "pcie link|nvme"
```

On a Zynq UltraScale+ two-slot design (here the ZCU106 HPC0 with two SSDs) you should see
one host bridge per M.2 slot:

```none
xilinx-xdma-pcie 400000000.axi-pcie: PCIe Link is UP
xilinx-xdma-pcie 500000000.axi-pcie: PCIe Link is UP
nvme nvme0: pci function 0000:01:00.0
nvme nvme1: pci function 0001:01:00.0
nvme nvme0: 4/0/0 default/read/poll queues
nvme nvme1: 4/0/0 default/read/poll queues
 nvme0n1: p1
 nvme1n1: p1
```

## 2. Check the enumeration and the link speed / width with lspci

```
lspci
```

Each M.2 slot appears as its own PCI domain: the Root Port (a Xilinx bridge) on bus 00 and
the SSD on bus 01. For the two-slot ZCU106 HPC0 design:

```none
0000:00:00.0 PCI bridge: Xilinx Corporation Device 9134
0000:01:00.0 Non-Volatile memory controller: Samsung Electronics Co Ltd NVMe SSD Controller PM9A1/PM9A3/980PRO
0001:00:00.0 PCI bridge: Xilinx Corporation Device 9134
0001:01:00.0 Non-Volatile memory controller: Samsung Electronics Co Ltd NVMe SSD Controller PM9A1/PM9A3/980PRO
```

The Root Port's device ID identifies the design: `9134` (Zynq UltraScale+, x4), `9131`
(Zynq UltraScale+, x1), `b048` (Versal QDMA), `7124` / `7012` (Zynq-7000, x4 / x1). Recent
`lspci` versions may print a product name such as "SmartSSD" for some of these IDs; that
is just the PCI ID database's name for the Xilinx ID, not a description of the design.

To check the negotiated link, compare the link capability (`LnkCap`) with the link status
(`LnkSta`):

```
lspci -vv | grep -E "^[0-9a-f]|LnkCap:|LnkSta:"
```

UltraZed-EV (Gen3 x4 design) with a PCIe Gen4 SSD in each slot:

```none
0000:00:00.0 PCI bridge: Xilinx Corporation SmartSSD (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 8GT/s, Width x4, ASPM not supported
		LnkSta:	Speed 8GT/s, Width x4
0000:01:00.0 Non-Volatile memory controller: Samsung Electronics Co Ltd NVMe SSD Controller PM9A1/PM9A3/980PRO (prog-if 02 [NVM Express])
		LnkCap:	Port #0, Speed 16GT/s, Width x4, ASPM L1, Exit Latency L1 <64us
		LnkSta:	Speed 8GT/s (downgraded), Width x4
```

The SSD reports `(downgraded)` because it is capable of Gen4 (16 GT/s) and the design is
Gen3: that is expected. What matters is that the `LnkSta` of the Root Port matches the
design's maximum speed and lane count (see the [link table](design.md#pcie-link-per-target)).

VCK190 (Gen4 x4 design), same SSDs:

```none
0000:00:00.0 PCI bridge: Xilinx Corporation Device b048 (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 16GT/s, Width x4, ASPM not supported
		LnkSta:	Speed 16GT/s, Width x4
0000:01:00.0 Non-Volatile memory controller: Samsung Electronics Co Ltd NVMe SSD Controller PM9A1/PM9A3/980PRO (prog-if 02 [NVM Express])
		LnkCap:	Port #0, Speed 16GT/s, Width x4, ASPM L1, Exit Latency L1 <64us
		LnkSta:	Speed 16GT/s, Width x4
```

The same information is available without `lspci`:

```
cat /sys/class/nvme/nvme0/device/current_link_speed /sys/class/nvme/nvme0/device/current_link_width
```

On a one-lane design (ZCU104, ZCU106 HPC1) this prints `8.0 GT/s PCIe` and `1`, and the
kernel log says
`limited by 8.0 GT/s PCIe x1 link at 0000:00:00.0 (capable of 63.012 Gb/s with 16.0 GT/s PCIe x4 link)`.
That is expected: these connectors have only one gigabit transceiver routed to the FMC.

## 3. Identify the SSDs with nvme-cli

```
nvme list
```

```none
Node                  Generic               SN                   Model                                    Namespace  Usage                      Format           FW Rev
--------------------- --------------------- -------------------- ---------------------------------------- ---------- -------------------------- ---------------- --------
/dev/nvme0n1          /dev/ng0n1            S5P2NU0W........     Samsung SSD 980 PRO 1TB                  0x1         57.40  GB /   1.00  TB    512   B +  0 B   5B2QGXA7
/dev/nvme1n1          /dev/ng1n1            S5P2NU0W........     Samsung SSD 980 PRO 1TB                  0x1        110.93  GB /   1.00  TB    512   B +  0 B   5B2QGXA7
```

Other useful commands:

```
nvme id-ctrl /dev/nvme0      # controller identification (model, firmware, capabilities)
nvme smart-log /dev/nvme0n1  # health: temperature, media_errors, num_err_log_entries
```

A healthy SSD reports `critical_warning : 0` and `media_errors : 0` in the SMART log.

## 4. Partition, format and mount

```{warning}
Partitioning and formatting erase the SSD. Make sure you are working on the right
device (`/dev/nvme0n1`, `/dev/nvme1n1`, ...) and that it holds no data you need.
```

1. Create one partition spanning the whole SSD:
   ```
   fdisk /dev/nvme0n1
   ```
   In `fdisk`, type `n` (new partition), `p` (primary), `1`, accept the default first and
   last sectors, then `w` to write the partition table. (`parted` is also available in the Yocto images.)
2. Check that the partition exists with `lsblk`:
   ```none
   nvme0n1     259:0    0 931.5G  0 disk
   `-nvme0n1p1 259:1    0 931.5G  0 part
   ```
3. Create a file system on it:
   ```
   mkfs.ext4 /dev/nvme0n1p1
   ```
4. Mount it:
   ```
   mkdir -p /mnt/ssd1
   mount /dev/nvme0n1p1 /mnt/ssd1
   ```

From there you can copy files to and from the SSD like any other disk. Repeat for
`/dev/nvme1n1` on the designs with two slots. On the PetaLinux images, partitions with a
file system on them are also auto-mounted under `/run/media/` at the next boot.

## 5. Measure the throughput

### With dd

A simple sequential read of the raw device (read-only, so it does not touch your data):

```
dd if=/dev/nvme0n1 of=/dev/null bs=1M count=4096 iflag=direct
```

A sequential write through the file system (to the SSD mounted at `/mnt/ssd1` above):

```
dd if=/dev/zero of=/mnt/ssd1/test.img bs=1M count=2048 oflag=direct conv=fsync
dd if=/mnt/ssd1/test.img of=/dev/null bs=1M iflag=direct
rm /mnt/ssd1/test.img
```

### With the speed-test scripts (Versal images)

The Versal PetaLinux and Yocto images include four scripts in `/usr/bin` that time a 4 GB
(one SSD) or 2 x 4 GB (two SSDs in parallel) transfer to a file on a mounted SSD. Run the
write test first: the read test reads back the file that it created.

```
single_write_test.sh /mnt/ssd1
single_read_test.sh  /mnt/ssd1
dual_write_test.sh   /mnt/ssd1 /mnt/ssd2
dual_read_test.sh    /mnt/ssd1 /mnt/ssd2
```

Each script prints the amount of data, the elapsed time and the resulting speed in MB/s.

### What to expect

Typical figures for a single `dd` stream (1 MiB blocks, O_DIRECT, one SSD at a time) with a
Samsung 980 PRO 1TB on the Yocto images:

| Design | Link | Sequential read | Sequential write |
|--------|------|-----------------|------------------|
| ZCU104 (LPC) | Gen3 x1 | ~610 MB/s | — |
| ZCU106 HPC1 | Gen3 x1 | ~615 MB/s | ~410 MB/s |
| ZCU106 HPC0 | Gen3 x4 | 700 – 750 MB/s | ~585 MB/s |
| UltraZed-EV | Gen3 x4 | 790 – 970 MB/s | ~585 MB/s |
| VCK190 FMCP1 / FMCP2 | Gen4 x4 | 1.6 – 2.4 GB/s | 925 – 975 MB/s |

These numbers are limited by a single `dd` process on the Arm cores (and, for writes, by
the SSD itself), not by the PCIe link: a Gen3 x4 link carries close to 4 GB/s. Running
several transfers in parallel (for example both SSDs at once, or several `dd` processes on
different regions of one SSD) gives a higher aggregate. Results also vary between SSD
models and with how full the SSD is. On the one-lane designs the x1 link
(about 985 MB/s at Gen3) is the limit.

If you measure much lower figures, check the link speed and width as described in
step 2 first: a link that trained at Gen1 or with fewer lanes than the design supports
points to a hardware or seating problem (see [troubleshooting](troubleshooting)).
