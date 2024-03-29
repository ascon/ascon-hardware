#  NIST LWC Hardware Reference Design of [Ascon v1.2](https://ascon.iaik.tugraz.at)

- Hardware Design Group: Institute of Applied Information Processing and Communications, Graz, Austria
- Primary Hardware Designers:
  - Robert Primas (https://rprimas.github.io, rprimas 'at' proton.me)
- LWC candidate: Ascon
- LWC Hardware API version: 1.2.0

[Ascon](https://ascon.iaik.tugraz.at) is a family of authenticated encryption and hashing algorithms designed to be lightweight and easy to implement, even with added countermeasures against side-channel attacks. Ascon has been selected as new standard for lightweight cryptography in the [NIST Lightweight Cryptography competition](https://www.nist.gov/news-events/news/2023/02/nist-selects-lightweight-cryptography-algorithms-protect-small-devices) (2019–2023). Ascon has also been selected as the primary choice for lightweight authenticated encryption in the final portfolio of the [CAESAR competition](https://competitions.cr.yp.to/caesar.html) (2014-2019).

*This code base contains a VHDL implementation of Ascon. I recently also published a Verilog implementation of Ascon that uses a similar but simpler crypto core interface and has a considerably reduced code size. Also, the Verilog implementation comes with a more permissive CC0 license. The Verilog implementation is available [here](https://github.com/rprimas/ascon-verilog).*

## Available Variants

- **v1** : `ascon128v12 + asconhashv12, 32-bit interface, 1 permutation round per clock cycle`
- **v1_8bit** : `ascon128v12 + asconhashv12, 8-bit interface, 1 permutation round per clock cycle`
- **v1_16bit** : `ascon128v12 + asconhashv12, 16-bit interface, 1 permutation round per clock cycle`
- **v2** : `ascon128av12 + asconhashav12, 32-bit interface, 1 permutation round per clock cycle`
- **v3** : `ascon128v12 + asconhashv12, 32-bit interface, 2 permutation rounds per clock cycle`
- **v4** : `ascon128av12 + asconhashav12, 32-bit interface, 2 permutation rounds per clock cycle`
- **v5** : `ascon128v12 + asconhashv12, 32-bit interface, 3 permutation rounds per clock cycle`
- **v6** : `ascon128av12 + asconhashav12, 32-bit interface, 4 permutation rounds per clock cycle`

## Folders

- `hardware`: HDL sources and testbench scripts.
- `software`: Software reference implementation and Known-Answer-Test (KAT) generation scripts.

## Quick Start

- Install the GHDL open-source VHDL simulator (tested with version 0.37 and 1.0 and 2.0):
  - `sudo apt install ghdl`
- Execute VHDL testbench for v1 (or other variants):
  - `cd hardware/ascon_lwc`
  - `make v1`

## Generating new Testvectors from Software

- Install testvector generation scripts:
  - `pip install software/cryptotvgen`
- Compile Ascon software reference implementations:
  - `cryptotvgen --prepare_libs --candidates_dir=software/ascon_ref`
- Locate testvector generation scripts:
  - `cd software/cryptotvgen/examples`
- Run (and optionally modify) a testvector generation script:
  - `python genkat_v1.py`
- Replace existing testvectors (KAT) of v1 with the newly generated ones:
  - `mv testvectors/v1_32 testvectors/v1`
  - `rm -r ../../../hardware/ascon_lwc/KAT/v1`
  - `mv testvectors/v1 ../../../hardware/ascon_lwc/KAT`
- Execute VHDL testbench for v1:
  - `cd ../../../hardware/ascon_lwc`
  - `make v1`

## Acknowledgements

This code base is based on version 1.2.0 of the [LWC Hardware API Development Package](https://github.com/GMUCERG/LWC) that was mainly developed by the Cryptographic Engineering Research Group [(CERG)](https://cryptography.gmu.edu) at George Mason University (GMU).

Parts of the development package have been developed by the Department of Electrical and Computer Engineering [(ECE)](https://www.ei.tum.de/en/ei/welcome/) at Technical University of Munich (TUM).

The Ascon-specific modifications have been developed by the Institute of Applied Information Processing and Communications [(IAIK)](https://iaik.tugraz.at/) at Graz University of Technology (TUG).

