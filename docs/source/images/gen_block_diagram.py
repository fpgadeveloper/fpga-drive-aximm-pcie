#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Opsero Electronic Design Inc.
"""
Generate the block diagrams for the FPGA Drive FMC reference design docs.

One diagram per device family, each drawn from the family's block-design
script (Vivado/src/bd/bd_<family>.tcl) and the address map of the exported XSA:

    fpgadrv-block-zynqmp.png      Zynq UltraScale+  (bd_zynqmp.tcl, xdma)
    fpgadrv-block-versal.png      Versal            (bd_versal.tcl, qdma)
    fpgadrv-block-zynq.png        Zynq-7000         (bd_zynq.tcl,   axi_pcie)
    fpgadrv-block-microblaze.png  MicroBlaze        (bd_mb.tcl,     axi_pcie / axi_pcie3 / xdma)

Every diagram has the same structure, left to right: the processor and its
DDR memory -> AXI interconnect -> one PCIe Root Port IP per active M.2 slot ->
the gigabit transceivers -> the FMC connector and the M.2 slots of the FPGA
Drive FMC Gen4 / M.2 M-key Stack FMC. The upper (blue) arrows are the
processor's accesses into PCIe space (ECAM / control registers and the BAR
window), the lower (green) arrows are the SSD's DMA into DDR memory.

The PNGs are written next to this script (i.e. into docs/source/images/).

Usage (from anywhere):
    python3 docs/source/images/gen_block_diagram.py
"""

import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon, FancyArrowPatch
from matplotlib.lines import Line2D

# ---- palette (shared with the other Opsero reference-design block diagrams) --
C_PS_FILL      = "#D9D9D9"; C_PS_EDGE      = "#7F7F7F"   # processor / DDR column
C_FAB_FILL     = "#F2F2F2"; C_FAB_EDGE     = "#BFBFBF"   # FPGA fabric container
C_MAC_FILL     = "#E8E8F2"; C_MAC_EDGE     = "#8C8CC0"   # soft logic (lavender)
C_GT_FILL      = "#F3EFE2"; C_GT_EDGE      = "#BFB585"   # hard blocks: PCIe, GT (cream)
C_FMC_FILL     = "#DCE6F2"; C_FMC_EDGE     = "#9DB7D4"   # external FMC (blue-grey)
C_SLOT_FILL    = "#FFFFFF"                                # M.2 slots (white on FMC)
C_CLK_FILL     = "#FDE9D9"; C_CLK_EDGE     = "#E0B090"   # clocking (peach)
C_CTRL_FILL    = "#ECECEC"; C_CTRL_EDGE    = "#BFBFBF"   # notes / control caption
C_AXARR_FILL   = "#EDF3D4"; C_AXARR_EDGE   = "#A6B85A"   # DMA arrows (pale green)
C_LINKARR_FILL = "#DAE8F5"; C_LINKARR_EDGE = "#6F9FCF"   # host access + link arrows
C_REFCLK_LINE  = "#C8823C"                                # refclk arrows (orange)
C_THIN         = "#8C8C8C"                                # sideband / interrupts
C_MUTED        = "#6E6E6E"
TXT = "#1A1A1A"


def box(ax, x, y, w, h, fc, ec, label, fs=10, lw=1.2, weight="normal",
        txtcolor=None, ls="-", z=2):
    ax.add_patch(plt.Rectangle((x, y), w, h, fc=fc, ec=ec, lw=lw, ls=ls,
                               zorder=z))
    if label:
        ax.text(x + w / 2, y + h / 2, label, ha="center", va="center",
                fontsize=fs, color=txtcolor or TXT, weight=weight,
                zorder=z + 1, linespacing=1.25)


def titled_box(ax, x, y, w, h, fc, ec, title, body, title_fs=9.5, body_fs=7.6,
               lw=1.2, txtcolor=None, title_dy=2.4, ls="-"):
    """A box() with a bold title line at the top and a smaller body below it."""
    box(ax, x, y, w, h, fc, ec, "", lw=lw, ls=ls)
    cx = x + w / 2
    ax.text(cx, y + h - title_dy, title, ha="center", va="center",
            fontsize=title_fs, weight="bold", color=txtcolor or TXT, zorder=3,
            linespacing=1.15)
    ax.text(cx, y + (h - title_dy * 1.9) / 2, body, ha="center", va="center",
            fontsize=body_fs, color=txtcolor or TXT, zorder=3, linespacing=1.3)


def harrow(ax, x0, x1, yc, label, fc, ec, double=False, bh=1.1, hh=2.0,
           hl=1.6, fs=7.4, lw=1.0, lab_dy=2.9, lab_color=None):
    """Horizontal block arrow from x0 to x1 (head at x1; both ends if double)."""
    if double:
        lo, hi = min(x0, x1), max(x0, x1)
        pts = [(lo, yc), (lo + hl, yc + hh), (lo + hl, yc + bh),
               (hi - hl, yc + bh), (hi - hl, yc + hh), (hi, yc),
               (hi - hl, yc - hh), (hi - hl, yc - bh),
               (lo + hl, yc - bh), (lo + hl, yc - hh)]
    else:
        s = 1.0 if x1 >= x0 else -1.0
        neck = x1 - s * hl
        pts = [(x0, yc + bh), (neck, yc + bh), (neck, yc + hh),
               (x1, yc), (neck, yc - hh), (neck, yc - bh), (x0, yc - bh)]
    ax.add_patch(Polygon(pts, closed=True, fc=fc, ec=ec, lw=lw, zorder=2))
    if label:
        ax.text((x0 + x1) / 2, yc + lab_dy, label, ha="center", va="center",
                fontsize=fs, color=lab_color or TXT, zorder=3, linespacing=1.15)


def varrow(ax, xc, y0, y1, fc, ec, bw=1.0, hw=1.9, hl=1.5, lw=1.0):
    """Double-headed vertical block arrow between y0 and y1."""
    lo, hi = min(y0, y1), max(y0, y1)
    pts = [(xc, lo), (xc + hw, lo + hl), (xc + bw, lo + hl),
           (xc + bw, hi - hl), (xc + hw, hi - hl), (xc, hi),
           (xc - hw, hi - hl), (xc - bw, hi - hl),
           (xc - bw, lo + hl), (xc - hw, lo + hl)]
    ax.add_patch(Polygon(pts, closed=True, fc=fc, ec=ec, lw=lw, zorder=2))


def route(ax, pts, color, lw=1.3, ls="-"):
    """Thin elbow arrow through the points in pts (head at the last point)."""
    xs, ys = zip(*pts[:-1])
    ax.add_line(Line2D(list(xs) + [pts[-2][0]], list(ys) + [pts[-2][1]],
                       color=color, lw=lw, ls=ls, zorder=3,
                       solid_capstyle="butt", solid_joinstyle="miter"))
    ax.add_patch(FancyArrowPatch(pts[-2], pts[-1], arrowstyle="-|>",
                                 mutation_scale=9, lw=lw, color=color,
                                 zorder=3, shrinkA=0, shrinkB=0))


def refclk_arrow(ax, p0, p1, label, lab_xy, fs=6.8, lw=1.6):
    """Thin single-line arrow for a reference-clock net (head at p1)."""
    ax.add_patch(FancyArrowPatch(p0, p1, arrowstyle="-|>", mutation_scale=11,
                                 lw=lw, color=C_REFCLK_LINE, zorder=3,
                                 shrinkA=0, shrinkB=0))
    ax.text(lab_xy[0], lab_xy[1], label, ha="center", va="center",
            fontsize=fs, color=C_REFCLK_LINE, zorder=4, weight="bold",
            linespacing=1.15)


# -----------------------------------------------------------------------------
# Per-family content. Every string here comes from the block-design scripts
# (Vivado/src/bd/), Vivado/src/bd/gt_locs.tcl, the constraints and the address
# map of the exported XSA for the named targets.
# -----------------------------------------------------------------------------
FAMILIES = {
    "zynqmp": dict(
        out="fpgadrv-block-zynqmp.png",
        title="Zynq UltraScale+ designs  —  ZCU104, ZCU106, ZCU111, ZCU208, ZCU216, UltraZed-EV",
        proc_title="Zynq\nUltraScale+\nPS",
        proc_body="Arm Cortex-A53\n\nstandalone app\n(ssd_test)\nor Linux\n(PetaLinux / Yocto)\n\n"
                  "pl_clk0\n100 MHz",
        ddr="PS DDR4",
        host_lbl=("M_AXI_HPM0_FPD", "M_AXI_HPM1_FPD"),
        dma_lbl=("S_AXI_HP0_FPD", "S_AXI_HP1_FPD"),
        ic_title="AXI Interconnect",
        ic_body=("periph_intercon_0\n+ HP0 interconnect", "periph_intercon_1\n+ HP1 interconnect"),
        rp_title=("xdma_0", "xdma_1"),
        rp_body=(
            "DMA/Bridge Subsystem for PCIe\nAXI Bridge mode, Root Port\n\n"
            "S_AXI_LITE  ECAM  0x4_0000_0000 (512 MB)\n"
            "S_AXI_B  BAR window  0xA000_0000 (256 MB)\n"
            "M_AXI_B  SSD DMA → DDR\n\n"
            "Gen3 (8 GT/s), PCIE40E4 block",
            "DMA/Bridge Subsystem for PCIe\nAXI Bridge mode, Root Port\n\n"
            "S_AXI_LITE  ECAM  0x5_0000_0000 (512 MB)\n"
            "S_AXI_B  BAR window  0xB000_0000 (256 MB)\n"
            "M_AXI_B  SSD DMA → DDR\n\n"
            "Gen3 (8 GT/s), PCIE40E4 block"),
        gt_body="GTH / GTY\nquad\n\n4 lanes\n(1 lane on\nLPC / HPC1)",
        link=("x4 @ 8 GT/s\nFMC DP0–3", "x4 @ 8 GT/s\nFMC DP4–7"),
        irq="interrupt_out + MSI vectors → pl_ps_irq0",
        notes="Two-slot designs: ZCU106 HPC0, ZCU111, ZCU208, ZCU216, UltraZed-EV.\n"
              "One-slot, one-lane designs: ZCU104 (LPC) and ZCU106 HPC1 — xdma_0 only, x1 @ 8 GT/s,\n"
              "SSD2 power and clock disabled (disable_ssd2_pwr = 1).\n"
              "AXI clock: 250 MHz (x4) / 125 MHz (x1).  PERST# from a proc_sys_reset on axi_ctl_aresetn.",
    ),
    "versal": dict(
        out="fpgadrv-block-versal.png",
        title="Versal designs  —  VCK190, VMK180, VEK280, VHK158, VPK120, VPK180",
        proc_title="Versal\nCIPS (PS)",
        proc_body="Arm Cortex-A72\n\nstandalone app\n(ssd_test, sets\nVADJ over I2C)\nor Linux\n(PetaLinux / Yocto)\n\n"
                  "pl0_ref_clk",
        ddr="DDR via\nNoC (axi_noc_0)",
        host_lbl=("M_AXI_FPD (BAR)\nM_AXI_LPD (ECAM)", ""),
        dma_lbl=("NoC S08_AXI", ""),
        ic_title="SmartConnect",
        ic_body=("smc_m_axi_fpd\nsmc_m_axi_lpd\nsmc_m_axi_bridge", "(shared with\nslot 1)"),
        rp_title=("qdma_0  +  qdma_support_0", "qdma_1  +  qdma_support_1"),
        rp_body=(
            "QDMA Subsystem for PCIe\nAXI Bridge mode, Root Port\n\n"
            "S_AXI_LITE  ECAM  0x8400_0000 (64 MB)\n"
            "S_AXI_BRIDGE  BAR  0xA800_0000 (64 MB)\n"
            "         + 0x4_8000_0000 (1 GB, 64-bit)\n"
            "M_AXI_BRIDGE  SSD DMA → NoC → DDR\n\n"
            "PCIe hard block + pcie_phy + GT wizard",
            "QDMA Subsystem for PCIe\nAXI Bridge mode, Root Port\n\n"
            "S_AXI_LITE  ECAM  0x8800_0000 (128 MB)\n"
            "S_AXI_BRIDGE  BAR  0xAC00_0000 (64 MB)\n"
            "         + 0x4_C000_0000 (1 GB, 64-bit)\n"
            "M_AXI_BRIDGE  SSD DMA → NoC → DDR\n\n"
            "PCIe hard block + pcie_phy + GT wizard"),
        gt_body="GTY / GTYP\nquad\n\n4 lanes",
        link=("x4 @ 16 GT/s (Gen4)\nFMC+ DP0–3", "x4 @ 16 GT/s (Gen4)\nFMC+ DP4–7"),
        irq="interrupt_out + MSI vectors → pl_ps_irq0..5",
        notes="Two-slot designs (Gen4, 16 GT/s): VCK190 FMCP1/FMCP2, VMK180 FMCP1/FMCP2, VEK280.\n"
              "One-slot designs (Gen5 IP, 32 GT/s): VHK158, VPK120, VPK180 — qdma_0 only, BAR 0xA800_0000 (128 MB),\n"
              "SSD2 power and clock disabled.  Addresses shown are those of the two-slot designs.\n"
              "VADJ: enabled at 1.5 V by U-Boot (Linux) or by the standalone app; on by default on the VEK280.",
    ),
    "zynq": dict(
        out="fpgadrv-block-zynq.png",
        title="Zynq-7000 designs  —  ZC706 (HPC / LPC), PicoZed 7015 / 7030 (LPC)",
        proc_title="Zynq-7000\nPS",
        proc_body="Arm Cortex-A9\n\nstandalone app\n(ssd_test)\nor Linux\n(PetaLinux / Yocto)\n\n"
                  "FCLK_CLK0\n100 MHz",
        ddr="PS DDR3",
        host_lbl=("M_AXI_GP0 (CTL)\nM_AXI_GP1 (BAR)", ""),
        dma_lbl=("S_AXI_HP0", ""),
        ic_title="AXI Interconnect",
        ic_body=("periph_intercon_0/1\nmem_intercon", ""),
        rp_title=("axi_pcie_0", ""),
        rp_body=(
            "AXI Memory Mapped to PCI Express\n(Gen2 IP), Root Port\n\n"
            "S_AXI_CTL  ECAM / regs  0x4000_0000 (256 MB)\n"
            "S_AXI  BAR window  0x8000_0000 (1 GB)\n"
            "M_AXI  SSD DMA → DDR\n\n"
            "ZC706: Gen2 (5 GT/s)\nPicoZed 7015 / 7030: Gen1 (2.5 GT/s)", ""),
        gt_body="GTX / GTP\nquad\n\n4 lanes\n(ZC706 HPC)\n1 lane\n(LPC)",
        link=("x4 (ZC706 HPC)\nx1 (LPC)\nFMC DP0–3", ""),
        irq="interrupt_out → IRQ_F2P",
        notes="One M.2 slot (SSD1) in every Zynq-7000 design; SSD2 power and clock are disabled.\n"
              "PERST# and the axi_pcie AXI reset come from a proc_sys_reset driven by FCLK_RESET0_N.\n"
              "Linux: the 256 MB control window needs CONFIG_VMSPLIT_2G (see the advanced section).",
    ),
    "microblaze": dict(
        out="fpgadrv-block-microblaze.png",
        title="MicroBlaze designs  —  KC705, KCU105, VC707, VC709, VCU118  (standalone only)",
        proc_title="MicroBlaze\n(soft CPU)",
        proc_body="local memory\n(app runs here)\n\nstandalone app\n(ssd_test)\n\n"
                  "AXI UART Lite\n115200 baud\nAXI timer, IIC,\nGPIO, flash",
        ddr="DDR3 / DDR4\n(MIG)",
        host_lbl=("M_AXI_DP\n(periph)", "M_AXI_DP\n(periph)"),
        dma_lbl=("MIG S_AXI", "MIG S_AXI"),
        ic_title="AXI Interconnect",
        ic_body=("microblaze_0_axi_periph\n+ axi_smc (→ MIG)", "(shared with\nslot 1)"),
        rp_title=("axi_pcie_0", "axi_pcie_1"),
        rp_body=(
            "KC705, VC707: axi_pcie (Gen2, 5 GT/s)\n"
            "KCU105, VC709: axi_pcie3 (Gen3, 8 GT/s)\n"
            "VCU118: xdma (Gen3, 8 GT/s)\n\n"
            "S_AXI_CTL / S_AXI_LITE  control + ECAM\n"
            "S_AXI  BAR window (256 MB):\n"
            "  0x7000_0000  KC705, VC707, VC709\n"
            "  0x6000_0000  KCU105, VCU118\n"
            "M_AXI  SSD DMA → DDR",
            "KCU105 HPC: axi_pcie3 (Gen3)\n"
            "VCU118: xdma (Gen3)\n\n"
            "S_AXI_CTL / S_AXI_LITE  control + ECAM\n"
            "S_AXI  BAR window  0x7000_0000 (256 MB)\n"
            "M_AXI  SSD DMA → DDR"),
        gt_body="GTX / GTH /\nGTY quad\n\n4 lanes\n(1 lane on\nLPC)",
        link=("x4 (HPC / FMC+)\nx1 (LPC)\nFMC DP0–3", "x4\nFMC DP4–7"),
        irq="interrupt_out (+ MSI on xdma) → AXI INTC",
        notes="Two-slot designs: KCU105 HPC and VCU118.  One-slot designs: KC705 HPC/LPC, KCU105 LPC,\n"
              "VC707 HPC1/HPC2, VC709 HPC.  The standalone application is linked to MicroBlaze local memory\n"
              "and combined with the bitstream into fpgadrv_boot.bit.  These designs have no Linux flow.",
    ),
}


def draw(fam):
    spec = FAMILIES[fam]
    dual = bool(spec["rp_title"][1])

    fig, ax = plt.subplots(figsize=(17.0, 10.6), dpi=120)
    ax.set_xlim(0, 170)
    ax.set_ylim(0, 106)
    ax.axis("off")

    # rows: slot 0 (top) and slot 1 (bottom)
    r0_y0, r_h = 55.0, 33.0
    r1_y0 = 17.0
    rows = [(r0_y0, r0_y0 + r_h / 2)]
    if dual:
        rows.append((r1_y0, r1_y0 + r_h / 2))

    # ---- processor column ---------------------------------------------------
    ps_x0, ps_w = 2.0, 18.0
    ps_r = ps_x0 + ps_w
    titled_box(ax, ps_x0, 91.0, ps_w, 11.0, C_PS_FILL, C_PS_EDGE, spec["ddr"],
               "", title_fs=9.6, title_dy=5.5, lw=1.3)
    varrow(ax, ps_x0 + ps_w / 2, 88.0, 91.0, C_AXARR_FILL, C_AXARR_EDGE,
           bw=0.9, hw=1.7, hl=1.2)
    box(ax, ps_x0, 17.0, ps_w, 71.0, C_PS_FILL, C_PS_EDGE, "", lw=1.3)
    ax.text(ps_x0 + ps_w / 2, 80.5, spec["proc_title"], ha="center",
            va="center", fontsize=11.0, weight="bold", color=TXT,
            linespacing=1.2)
    ax.text(ps_x0 + ps_w / 2, 52.0, spec["proc_body"], ha="center",
            va="center", fontsize=7.6, color=TXT, linespacing=1.4)

    # ---- fabric container ---------------------------------------------------
    fab_x0, fab_x1 = 24.0, 124.0
    ax.add_patch(plt.Rectangle((fab_x0, 13.0), fab_x1 - fab_x0, 80.0,
                               fc=C_FAB_FILL, ec=C_FAB_EDGE, lw=1.3, zorder=1))
    ax.text((fab_x0 + fab_x1) / 2, 94.0, "Programmable logic and hard PCIe / GT blocks",
            ha="center", va="bottom", fontsize=11.5, weight="bold", color=TXT)

    ic_x, ic_w = 33.0, 17.0
    rp_x, rp_w = 58.0, 41.0
    gt_x, gt_w = 105.0, 13.0

    # ---- external FMC -------------------------------------------------------
    fmc_x0, fmc_x1 = 132.0, 167.0
    ax.add_patch(plt.Rectangle((fmc_x0, 13.0), fmc_x1 - fmc_x0, 80.0,
                               fc=C_FMC_FILL, ec=C_FMC_EDGE, lw=1.3, zorder=1))
    ax.text((fmc_x0 + fmc_x1) / 2, 94.0, "External to the FPGA", ha="center",
            va="bottom", fontsize=11.5, weight="bold", color=TXT)
    ax.text((fmc_x0 + fmc_x1) / 2, 88.5,
            "FPGA Drive FMC Gen4 (OP063)\nor M.2 M-key Stack FMC (OP073)",
            ha="center", va="center", fontsize=8.2, weight="bold", color=TXT,
            linespacing=1.25)
    slot_x, slot_w = 141.0, 23.0
    clk_x, clk_w = 133.5, 6.0

    for i, (y0, yc) in enumerate(rows):
        # interconnect
        if i == 0 or fam in ("zynqmp",):
            titled_box(ax, ic_x, y0 + 3.0, ic_w, r_h - 6.0, C_MAC_FILL,
                       C_MAC_EDGE, spec["ic_title"], spec["ic_body"][i],
                       title_fs=8.6, body_fs=6.9, title_dy=2.6)
        # processor <-> interconnect: host access (upper) and DMA (lower)
        if i == 0 or fam == "zynqmp":
            harrow(ax, ps_r, ic_x, yc + 5.0, spec["host_lbl"][i],
                   C_LINKARR_FILL, C_LINKARR_EDGE, lab_dy=4.0, fs=6.6)
            harrow(ax, ic_x, ps_r, yc - 5.0, spec["dma_lbl"][i],
                   C_AXARR_FILL, C_AXARR_EDGE, lab_dy=-3.4, fs=6.6)
        else:
            # shared interconnect: drop a connector from the slot-0 box
            ax.add_line(Line2D([ic_x + ic_w / 2, ic_x + ic_w / 2],
                               [r0_y0 + 3.0, yc + 6.5], color=C_MAC_EDGE,
                               lw=1.2, ls=(0, (3, 2)), zorder=1.5))
            titled_box(ax, ic_x, yc - 6.5, ic_w, 13.0, C_MAC_FILL, C_MAC_EDGE,
                       "", spec["ic_body"][i], body_fs=6.9, ls=(0, (3, 2)))
        # interconnect <-> root port
        ic_r = ic_x + ic_w
        harrow(ax, ic_r, rp_x, yc + 5.0, "BAR / ECAM", C_LINKARR_FILL,
               C_LINKARR_EDGE, lab_dy=3.2, fs=6.4)
        harrow(ax, rp_x, ic_r, yc - 5.0, "SSD DMA", C_AXARR_FILL,
               C_AXARR_EDGE, lab_dy=-3.2, fs=6.4)
        # root port IP
        titled_box(ax, rp_x, y0 + 1.0, rp_w, r_h - 2.0, C_GT_FILL, C_GT_EDGE,
                   spec["rp_title"][i], spec["rp_body"][i], title_fs=9.4,
                   body_fs=6.9, title_dy=2.6, lw=1.3)
        # transceivers
        titled_box(ax, gt_x, y0 + 7.0, gt_w, r_h - 14.0, C_GT_FILL, C_GT_EDGE,
                   "GT", spec["gt_body"], title_fs=9.0, body_fs=6.7,
                   title_dy=2.4)
        harrow(ax, rp_x + rp_w, gt_x, yc, "", C_GT_FILL, C_GT_EDGE,
               double=True, bh=1.0, hh=1.9, hl=1.2)
        # M.2 slot on the FMC
        slot_name = "M.2 slot  SSD1" if i == 0 else "M.2 slot  SSD2"
        titled_box(ax, slot_x, y0 + 4.0, slot_w, r_h - 8.0, C_SLOT_FILL,
                   C_FMC_EDGE, slot_name,
                   "M-key NVMe SSD\n(PCIe Gen1 – Gen4)\n\nPERST#  ←  FPGA",
                   title_fs=8.8, body_fs=7.0, title_dy=2.6)
        # serial link GT <-> FMC slot
        harrow(ax, gt_x + gt_w, slot_x, yc + 2.0, "", C_LINKARR_FILL,
               C_LINKARR_EDGE, double=True, bh=1.3, hh=2.4, hl=1.3)
        ax.text((gt_x + gt_w + slot_x) / 2 + 1.0, yc + 8.6, spec["link"][i],
                ha="center", va="center", fontsize=6.5, color=TXT, zorder=3,
                linespacing=1.15)
        # 100 MHz reference clock from the FMC
        box(ax, clk_x, y0 + 4.0, clk_w, 7.0, C_CLK_FILL, C_CLK_EDGE,
            "100\nMHz", fs=6.4)
        refclk_arrow(ax, (clk_x, y0 + 7.5), (gt_x + gt_w, y0 + 8.5),
                     "GBTCLK%d" % i, (126.0, y0 + 11.6), fs=6.4)
        # PERST# (and the SSD2 power/clock disable) to the FMC
        route(ax, [(rp_x + rp_w * 0.55, y0 + 1.0), (rp_x + rp_w * 0.55, y0 - 1.6),
                   (slot_x + 5.0, y0 - 1.6), (slot_x + 5.0, y0 + 4.0)], C_THIN,
              lw=1.1)
        ax.text(rp_x + rp_w + 3.0, y0 - 0.2, "PERST#%d" % i, ha="center",
                va="center", fontsize=6.2, color=C_MUTED, zorder=4)
        # interrupts back to the processor
        route(ax, [(rp_x + 3.0, y0 + 1.0), (rp_x + 3.0, y0 - 1.2),
                   (ps_r + 2.0, y0 - 1.2), (ps_r, y0 - 1.2)], C_THIN, lw=1.0,
              ls=(0, (4, 2)))
        if i == 0:
            ax.text((ps_r + rp_x) / 2 + 2.0, y0 - 2.6, "IRQ", ha="center",
                    va="center", fontsize=6.2, color=C_MUTED, zorder=4)

    # single-slot designs: show the disabled SSD2 slot
    if not dual:
        titled_box(ax, slot_x, r1_y0 + 4.0, slot_w, r_h - 8.0, C_SLOT_FILL,
                   C_FMC_EDGE, "M.2 slot  SSD2",
                   "not used by these designs\n\n3.3 V and 100 MHz clock\nswitched off by\n"
                   "disable_ssd2_pwr = 1",
                   title_fs=8.8, body_fs=6.8, title_dy=2.6, ls=(0, (4, 2)))
        route(ax, [(rp_x + rp_w * 0.8, r0_y0 + 1.0), (rp_x + rp_w * 0.8, r1_y0 + 15.0),
                   (slot_x, r1_y0 + 15.0)], C_THIN, lw=1.1)
        ax.text(rp_x + rp_w * 0.8 + 9.0, r1_y0 + 17.0, "disable_ssd2_pwr",
                ha="center", va="center", fontsize=6.2, color=C_MUTED, zorder=4)
    else:
        ax.text(slot_x + slot_w / 2, r1_y0 + 1.8,
                "disable_ssd2_pwr = 0 (SSD2 powered)", ha="center",
                va="center", fontsize=6.2, color=C_MUTED, zorder=4)

    # ---- interrupts and notes strip -----------------------------------------
    titled_box(ax, 2.0, 1.0, 165.0, 10.5, C_CTRL_FILL, C_CTRL_EDGE,
               "Interrupts: " + spec["irq"], spec["notes"], title_fs=8.0,
               body_fs=7.0, title_dy=1.9)

    ax.text(85.0, 104.5, spec["title"], ha="center", va="center",
            fontsize=13.0, weight="bold", color=TXT)

    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), spec["out"])
    fig.savefig(out, bbox_inches="tight", pad_inches=0.15, facecolor="white")
    plt.close(fig)
    print("wrote", out)


def main():
    for fam in FAMILIES:
        draw(fam)


if __name__ == "__main__":
    main()
