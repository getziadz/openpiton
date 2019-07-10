# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/).

## [Unreleased]
### Added
- AXI4 memory controller option on vc707
- Multicore Verilator simulation using DPI alternative to existing PLI
- Simulation of OpenPiton+Ariane with VCS

### Changed
- Remove BUFG and clock gating latches for FPGA targets
- Remove inferred latches in all dynamic_node variants, l2_pipe1_ctrl and uart_mux
- Update storage_addr_trans* to include different board configurations for Ariane
- Update Ariane version. This includes several bugfixes and improvements
- Update RISC-V peripherals (new PLIC, updated debug module with support for multi-hart debug)
- OS stability improvements from LR/SC invalidation fix

## Release 11

### Added

- Support for Verilator simulation

For Ariane:
- Support for Pitonstream
- Support for RISC-V compliant debug
- Device tree generator
- RISC-V compliant interrupt controllers (PLIC, CLINT)
- Support for SMP Linux
- Support for Ariane builds on the Genesys2, Nexys Video and VC707 FPGA boards

### Changed

For Ariane:
- Updated to Ariane v4.1
- Bugfixes in write-through cache system of Ariane

