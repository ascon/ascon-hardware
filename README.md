#  NIST LWC Hardware API reference implementation of [Ascon v1.2](ascon.iaik.tugraz.at)
- Hardware Design Group: Institute of Applied Information Processing and Communications
- Primary Hardware Designers: Robert Primas, https://rprimas.github.io, rprimas@gmail.com
- Academic advisors: Stefan Mangard, https://www.iaik.tugraz.at/person/stefan-mangard/, stefan.mangard@iaik.tugraz.at
- LWC candidate: Ascon

### Available Variants:
- **v1** : `ascon128v12 + asconhashv12, 32-bit interface, 1 permutation round per clock cycle`
- **v1_8bit** : `ascon128v12 + asconhashv12, 8-bit interface, 1 permutation round per clock cycle`
- **v1_16bit** : `ascon128v12 + asconhashv12, 16-bit interface, 1 permutation round per clock cycle`
- **v2** : `ascon128av12 + asconhashav12, 32-bit interface, 1 permutation round per clock cycle`
- **v3** : `ascon128v12 + asconhashv12, 32-bit interface, 2 permutation rounds per clock cycle`
- **v4** : `ascon128av12 + asconhashav12, 32-bit interface, 2 permutation rounds per clock cycle`
- **v5** : `ascon128v12 + asconhashv12, 32-bit interface, 3 permutation rounds per clock cycle`
- **v6** : `ascon128av12 + asconhashav12, 32-bit interface, 4 permutation rounds per clock cycle`

### Quick Start:
- Install LWC testvecor generation scripts:  
`pip3 install software/cryptotvgen`
- Compile software reference implementations:  
`cryptotvgen --prepare_libs --candidates_dir=software/ascon_ref`
- Install the GHDL open-source VHDL simulator (tested with version 0.37 and 1.0):  
`sudo apt install ghdl`
- Execute VHDL testbench for v1 (or other variants):  
`cd hardware/ascon_lwc`
`python3 test_v1.py`
`bash test_all.sh`

## LWC Hardware API Development Package
This code is based on the development package for GMU's [Hardware API for Lightweight Cryptography](https://cryptography.gmu.edu/athena/index.php?id=LWC). Please refer to the latest [LWC Hardware API](https://cryptography.gmu.edu/athena/LWC/LWC_HW_API.pdf) and [LWC Hardware API Implementer’s Guide](https://cryptography.gmu.edu/athena/LWC/LWC_HW_Implementers_Guide.pdf) for further details.

This package is divided into two primary parts: **Hardware** and **Software**
## Hardware
- RTL VHDL code of a generic PreProcessor, PostProcessor, and Header FIFO, common for all LWC candidates ([LWC_rtl](hardware/LWC_rtl))
- Universal testbench common for all the API-compliant designs ([LWC_tb](hardware/LWC_tb))
- Reference implementation of the Ascon authenticated cipher with a hash functionality (AEAD+Hash) ([ascon_lwc](hardware/ascon_lwc))
- Template of the CryptoCore (CryptoCore_templete.vhd)
- Template of design_pkg.vhd (design_pkg_templete.vhd)
- `process_failures.py`: Python script for post-processing testbench-generated log of failed test-vectors ('failed_test_vectors.txt')
- `makefiles`, `scripts`, `lwc.mk`: simulation makefiles and scripts.

The subfolders of ascon_lwc include:
- `src_rtl`: RTL VHDL code of the Ascon core
- `KAT`: Known-Answer Tests.
- `scripts`: Sample Vivado and ModelSim simulation scripts.

### LWC Package Configuration Options

#### `design_pkg.vhd` constants
Definition and initialization of these constants _MUST_ be present in the user-provided `design_pkg.vhd` file. Please refer to [ascon_lwc design_pkg](hardware/ascon_lwc/src_rtl/v1/design_pkg.vhd) for an example.
- `CCW`: Specifies the bus width (in bits) of `CryptoCore`'s PDI data and can be 8, 16, or 32. 
- `CCSW`: Specifies the bus width (in bits) of `CryptoCore`'s SDI data and is expected to be equal to `CCW`.
- `CCWdiv8`: Needs to be set equal to `CCW / 8`.
- `TAG_SIZE`: specifies the tag size in bits.
- `HASH_VALUE_SIZE`: specifies the hash size in bits. Only used in hash mode.
 
#### `NIST_LWAPI_pkg.vhd` configurable constants
- `W` (integer *default=32*): Controls the width of the external bus for PDI data bits. The width of sdi_data (`SW`) is set to this value. Valid values are 8, 16, 32.
  Supported combinations of (`W`, `CCW`) are (32, 32), (32, 16), (32, 8), (16, 16), and (8, 8).
- `ASYNC_RSTN` (boolean *default=false*): When `True` an asynchronous active-low reset is used instead of a synchronous active-high reset throughout the LWC package and the testbench. `ASYNC_RSTN` can be set to `true` _only if_ the `CryptoCore` provides support for using active-low asyncronous resets for all of its resettable registers. Please see the provided `ascon_core` as an example.

### Testbench Parameters
Testbench parameters are exposed as VHDL generics in the `LWC_TB` testbench top-level entity.
Some notable generics include:
- `G_MAX_FAILURES`: number of maximum failures before stopping the simulation (default: 100)
- `G_TEST_MODE`(integer): see "Test Mode"below. (default: 0)
- `G_PERIOD`(time): simulation clock period (default: 10 ns)
- `G_FNAME_PDI`, `G_FNAME_SDI`, `G_FNAME_DO`(string): Paths to testvector input and expected output files.
- `G_FNAME_LOG`(string): Path to the testbench-generated log file.
- `G_FNAME_FAILED_TVS`(string): Path to testbench-generated file containing all failed test-vectors. It will be an empty file if all test vectors passed. (default: "failed_test_vectors.txt")

Please see [LWC_TB.vhd](hardware/LWC_tb/LWC_TB.vhd) for the full list of testbench generics.

Note: Commercial and open-source simulators provide mechanisms for overriding the value of top-level testbench generics without the need to manually change the VHDL file.

#### Measurement Mode
- The `LWC_TB` now includes an experimental measurement mode intended to aid designers with verification of formulas for execution times and latencies. To activate this mode, set `G_TEST_MODE` to 4. Measurement Mode yields results in simulator reports and two file formats: txt and csv. The corresponding output files can be specified by the `G_FNAME_TIMING` and `G_FNAME_TIMING_CSV` generics, respectively.  Run this mode with `ascon_lwc` example for a sample of the output. Note, this mode is still being actively developed and may have outstanding issues.

## Software
The software subdirectory contains:
- [`cryptotvgen`](software/cryptotvgen): Python utility and library for the cryptographic hardware test-vector generation.
  `cryptotvgen` can prepare and build software implementations of LWC candidates from user-provided `C` reference code or a [SUPERCOP](https://bench.cr.yp.to/supercop.html) release and generate testvectors for various testing scenarios. The reference software implementation needs to be organized according to `SUPERCOP` package structure with the `C` reference code residing inside the `ref` subfolder of `crypto_aead` and `crypto_hash` directories. Please see [cryptotvgen's documentation](software/cryptotvgen/README.md) for updated installation and usage instructions.

- [ascon_ref](software/ascon_ref): Ascon AEAD and hash C reference implementation. Folder follows SUPERCOP package structure.

