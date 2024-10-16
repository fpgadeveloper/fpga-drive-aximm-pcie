
# Opsero Electronic Design Inc. Copyright 2024

# GT LOC constraints are required in the configuration of the PCIe IPs.
# The following code constructs a nested dictionary that contains the GT assignments for
# each target board for FPGA Drive FMC Gen4.

# To use the dictionary:
#   * Get the GT quad:    dict get $gt_loc_dict <target> <ssd index> quad
#   * Get the PCIe LOC:   dict get $gt_loc_dict <target> <ssd index> pcie

dict set gt_loc_dict auboard 0 quad GTH_Quad_225
dict set gt_loc_dict auboard 0 pcie X0Y0
dict set gt_loc_dict kc705_hpc 0 quad GTX_Quad_118
dict set gt_loc_dict kc705_hpc 0 pcie X0Y0
dict set gt_loc_dict kc705_lpc 0 quad GTX_Quad_117
dict set gt_loc_dict kc705_lpc 0 pcie X0Y0
dict set gt_loc_dict kcu105_hpc 0 quad GTH_Quad_228
dict set gt_loc_dict kcu105_hpc 0 pcie X0Y2
dict set gt_loc_dict kcu105_hpc 1 quad GTH_Quad_227
dict set gt_loc_dict kcu105_hpc 1 pcie X0Y1
dict set gt_loc_dict kcu105_lpc 0 quad GTH_Quad_226
dict set gt_loc_dict kcu105_lpc 0 pcie X0Y1
dict set gt_loc_dict pz_7015 0 quad GTP_Quad_112
dict set gt_loc_dict pz_7015 0 pcie 
dict set gt_loc_dict pz_7030 0 quad GTP_Quad_112
dict set gt_loc_dict pz_7030 0 pcie 
dict set gt_loc_dict uzev 0 quad GTH_Quad_225
dict set gt_loc_dict uzev 0 pcie X0Y1
dict set gt_loc_dict uzev 1 quad GTH_Quad_224
dict set gt_loc_dict uzev 1 pcie X0Y0
dict set gt_loc_dict vc707_hpc1 0 quad GTX_Quad_119
dict set gt_loc_dict vc707_hpc1 0 pcie X1Y1
dict set gt_loc_dict vc707_hpc2 0 quad GTX_Quad_117
dict set gt_loc_dict vc707_hpc2 0 pcie X1Y1
dict set gt_loc_dict vc709_hpc 0 quad GTH_Quad_119
dict set gt_loc_dict vc709_hpc 0 pcie X0Y2
dict set gt_loc_dict vcu118 0 quad GTY_Quad_121
dict set gt_loc_dict vcu118 0 pcie X0Y1
dict set gt_loc_dict vcu118 1 quad GTY_Quad_126
dict set gt_loc_dict vcu118 1 pcie X0Y3
dict set gt_loc_dict zc706_hpc 0 quad GTX_Quad_109
dict set gt_loc_dict zc706_hpc 0 pcie 
dict set gt_loc_dict zc706_lpc 0 quad GTX_Quad_111
dict set gt_loc_dict zc706_lpc 0 pcie 
dict set gt_loc_dict vck190_fmcp1 0 quad GTY_Quad_201
dict set gt_loc_dict vck190_fmcp1 0 pcie X1Y0
dict set gt_loc_dict vck190_fmcp1 1 quad GTY_Quad_202
dict set gt_loc_dict vck190_fmcp1 1 pcie X1Y2
dict set gt_loc_dict vck190_fmcp2 0 quad GTY_Quad_204
dict set gt_loc_dict vck190_fmcp2 0 pcie X1Y0
dict set gt_loc_dict vck190_fmcp2 1 quad GTY_Quad_205
dict set gt_loc_dict vck190_fmcp2 1 pcie X1Y2
dict set gt_loc_dict vmk180_fmcp1 0 quad GTY_Quad_201
dict set gt_loc_dict vmk180_fmcp1 0 pcie X1Y0
dict set gt_loc_dict vmk180_fmcp1 1 quad GTY_Quad_202
dict set gt_loc_dict vmk180_fmcp1 1 pcie X1Y2
dict set gt_loc_dict vmk180_fmcp2 0 quad GTY_Quad_204
dict set gt_loc_dict vmk180_fmcp2 0 pcie X1Y0
dict set gt_loc_dict vmk180_fmcp2 1 quad GTY_Quad_205
dict set gt_loc_dict vmk180_fmcp2 1 pcie X1Y2
dict set gt_loc_dict vpk120 0 quad GTYP_Quad_200
dict set gt_loc_dict vpk120 0 pcie X1Y0
dict set gt_loc_dict vpk180 0 quad GTYP_Quad_200
dict set gt_loc_dict vpk180 0 pcie X1Y0
dict set gt_loc_dict vek280 0 quad GTYP_Quad_205
dict set gt_loc_dict vek280 0 pcie X1Y1
dict set gt_loc_dict vek280 1 quad GTYP_Quad_206
dict set gt_loc_dict vek280 1 pcie X1Y2
dict set gt_loc_dict vcu118_fmcp 0 quad GTY_Quad_121
dict set gt_loc_dict vcu118_fmcp 0 pcie X0Y1
dict set gt_loc_dict vcu118_fmcp 1 quad GTY_Quad_126
dict set gt_loc_dict vcu118_fmcp 1 pcie X0Y3
dict set gt_loc_dict zcu104 0 quad GTH_Quad_226
dict set gt_loc_dict zcu104 0 pcie X0Y0
dict set gt_loc_dict zcu106_hpc0 0 quad GTH_Quad_226
dict set gt_loc_dict zcu106_hpc0 0 pcie X0Y1
dict set gt_loc_dict zcu106_hpc0 1 quad GTH_Quad_227
dict set gt_loc_dict zcu106_hpc0 1 pcie X0Y0
dict set gt_loc_dict zcu106_hpc1 0 quad GTH_Quad_223
dict set gt_loc_dict zcu106_hpc1 0 pcie X0Y0
dict set gt_loc_dict zcu111 0 quad GTY_Quad_129
dict set gt_loc_dict zcu111 0 pcie X0Y0
dict set gt_loc_dict zcu111 1 quad GTY_Quad_130
dict set gt_loc_dict zcu111 1 pcie X0Y1
dict set gt_loc_dict zcu208 0 quad GTY_Quad_130
dict set gt_loc_dict zcu208 0 pcie X0Y0
dict set gt_loc_dict zcu208 1 quad GTY_Quad_131
dict set gt_loc_dict zcu208 1 pcie X0Y1
dict set gt_loc_dict zcu216 0 quad GTY_Quad_130
dict set gt_loc_dict zcu216 0 pcie X0Y0
dict set gt_loc_dict zcu216 1 quad GTY_Quad_131
dict set gt_loc_dict zcu216 1 pcie X0Y1
