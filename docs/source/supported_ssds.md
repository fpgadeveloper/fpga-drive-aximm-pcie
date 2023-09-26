# Supported SSDs

## Selecting SSDs

The [FPGA Drive FMC Gen4] is an adapter that has been designed to support PCIe Gen1 to Gen4. If you are using an
M2 SSD that supports PCIe Gen1,2,3 or 4, then it terms of the physical hardware, it is fully compatible with the 
FPGA Drive FMC. In reality there are other layers involved that can cause incompatibility or usage issues (eg. 
the version of PetaLinux used, the version of NVMe built into the SSD, the transceiver settings in the Vivado 
design, etc).

To minimize your chances of running into incompatibility issues, we recommend always using the latest reference 
designs in our [Github repo]. We also recommend using newer SSDs rather than older models that are no longer 
available, or that are likely to have older versions of the NVMe protocol built into them.

## List of tested SSDs

The following is a list of SSDs that have been tested with the FPGA Drive FMC and the reference
design. This is by no means a comprehensive list and we have intentionally not provided web links to the 
specific SSDs as the market for M2 SSDs is constantly changing. We rely to some degree on customer experiences 
to keep this list as up-to-date and as useful as possible.

| SSD (brand and model)                                                 | Keying  |
|-----------------------------------------------------------------------|---------|
| Crucial P5                                                            | M       |
| Delkin Industrial M2 SSD (PN: MB1HFRCFD-80000-2)                      | B+M     |
| Intel Optane Memory                                                   | B+M     |
| Kingston KC2500                                                       | M       |
| Samsung 950 PRO                                                       | M       |
| Samsung 970 EVO                                                       | M       |
| Western Digital Black SN750                                           | M       |

You can help us maintain this list by communicating [your experiences] to us or by simply
contributing to the documentation on our [Github repo].

[your experiences]: https://opsero.com/contact-us
[FPGA Drive FMC Gen4]: https://www.fpgadrive.com/docs/fpga-drive-fmc-gen4/overview/
[Github repo]: https://github.com/fpgadeveloper/fpga-drive-aximm-pcie

