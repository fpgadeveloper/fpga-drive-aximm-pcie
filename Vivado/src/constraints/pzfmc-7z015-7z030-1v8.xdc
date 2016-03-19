
# ----------------------------------------------------------------------------
# PCIe Reset - Bank 13
# ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN V13  [get_ports {perst_n      }];  # "V13.BANK13_LVDS_12_P.JX3.86.PCIE_RST_N"

# ----------------------------------------------------------------------------
# PCIe MGTs - Bank 112
# ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN AB7  [get_ports {pcie_7x_mgt_rxn      }];  # "AB7.MGTRX0_N.JX3.10.PCIE-RX0_N"
set_property PACKAGE_PIN AA7  [get_ports {pcie_7x_mgt_rxp      }];  # "AA7.MGTRX0_P.JX3.8.PCIE-RX0_P"
set_property PACKAGE_PIN AB3  [get_ports {pcie_7x_mgt_txn      }];  # "AB3.MGTTX0_N.JX3.15.PCIE-TX0_N"
set_property PACKAGE_PIN AA3  [get_ports {pcie_7x_mgt_txp      }];  # "AA3.MGTTX0_P.JX3.13.PCIE-TX0_P"

# ----------------------------------------------------------------------------
# MGT REF CLKS - Bank 112 -- added manually due to capacitors
# ----------------------------------------------------------------------------
set_property PACKAGE_PIN V9   [get_ports {ref_clk_clk_n   }];  # "V9.MGTREFCLKC0_N.JX3.3.PCIE-JREFCLK_N"
set_property PACKAGE_PIN U9   [get_ports {ref_clk_clk_p   }];  # "U9.MGTREFCLKC0_P.JX3.1.PCIE-JREFCLK_P"

# ----------------------------------------------------------------------------
# IOSTANDARD Constraints
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];

