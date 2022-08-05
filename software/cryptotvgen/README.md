# cryptotvgen
Automatic test vector generation for hardware implementations of NIST Lightweight Cryptography (LWC) candidates using GMU LWC Hardware API package.

## Requirements
OS: Tested on Linux and macOS

Dependencies:
- Python 3.6.5+
- GNU Make 3.82+
- C compiler (e.g. gcc or clang)

## Installation
To install as symlinks (recommended):
```
$ python3 -m pip install -e .
```
The LWC source directory should be kept in its current location, but all updates
to this directory should be immediately accessible.

Alternatively, to install as a copy:
```
$ python3 -m pip install .
```
If using the latter command, remember to run it again following any git pulls or updates to the source distribution.

To uninstall:
```
$ python3 -m pip uninstall cryptotvgen
```

## Running `cryptotvgen` Executable
If Python script installation directory is included in the user's `$PATH`, the executable should be accessible right after installation:
```
$ cryptotvgen -h
```
Otherwise, either add the installed script to `$PATH` or run cryptotvgen as a module:
```
$ python3 -m cryptotvgen.cli -h
```

### Run Modes
One of the following run modes must be selected:
- `--prepare_libs`: Build dynamically shared libraries required for test vector generation. Can optionally automatically download and extract a SUPERCOP distribution.
- `--gen_random`: Generate random AEAD test vectors.
- `--gen_custom`: Randomly generate multiple AEAD or hash test vectors with the specified fields.
- `--gen_single`: Generate a single AEAD test vector based on the provided values of inputs.
- `--gen_hash`: Generates 20 test vectors for hash only.
- `--gen_test_routine`: Generates AEAD test vectors for the common sizes of AD and PT.
- `--gen_test_combined`: Generate interleaved combined AEAD and hash test vectors.

Run `cryptotvgen -h` for help and further details on available options.


To use arbitrary user-provided C reference implementation for test vectors
generation, use `--candidates_dir=<PATH TO REF CODE>` during `--prepare_libs`
step. `<PATH TO REF CODE>` is the path to the directory containing the
reference implementation, organized according to `SUPERCOP` package structure
with the `C` reference code residing inside the `ref` subfolder of
`crypto_aead` and `crypto_hash` directories. The reference code will be built
into a dynamically linked library in `<PATH TO REF CODE>/lib` subfolder.
To use the prepared reference library for test vector generation, add
`--lib_path=<PATH TO REF CODE>/lib` to the test vector generation
command options.

### Examples:

- To build the libraries for the reference C implementation of `dummy_lwc` available in [software/dummy_lwc_ref](../dummy_lwc_ref/) run:
```
$ cryptotvgen --prepare_libs --candidates_dir=software/dummy_lwc_ref
```
Replace `software/dummy_lwc_ref` with the relative/absolute path to the subfolder containing `crypto_aead` and `crypto_hash` folders containing the reference implementation of an algorithm. 
This could also be the root to an already extracted SUPERCOP distribution. The built libraries will be in then available in `software/dummy_lwc_ref/lib` folder.

- To generate a random AEAD test vector for `dummy_lwc` using the reference C libraries already built in in `software/dummy_lwc_ref/lib` run:
```
$ cryptotvgen --gen_random 1 --lib_path=software/dummy_lwc_ref/lib --aead=dummy_lwc
```

To generate hash test vectors 2 to 5 with MODE=1:
```
$ cryptotvgen --gen_hash 5 5 1 --lib_path=software/dummy_lwc_ref/lib --hash dummy_lwc
```

- To automatically download, extract, and build reference library of all LWC Round 2 candidates from the latest available version of SUPERCOP:
```
$ cryptotvgen --prepare_libs 
```
The downloaded tarball will be cached in `$HOME/.cryptotvgen/cache`. 
The source code of reference implementations of the LWC candidates will be extracted to the corresponding `$HOME/.cryptotvgen/supercop/crypto_*` folders.
The built libraries will be kept in the default location of `$HOME/.cryptotvgen/supercop/lib`. 
Running subsequent test vector generation commands will use these libraries by default and there will be no need to specify `--lib_path` 
(unless you want to use a different location).

The `--supercop_version` switch can be used to specify a valid SUPERCOP version (in `YYYYMMDD` format, e.g. 20191221) different from the default value:
```
$ cryptotvgen --prepare_libs --supercop_version=20200702
```
As previously mentioned you can also manually download and extract the SUPERCOP distribution and specify its path with using the `--candidates_dir` option. 
In that case you need to specify the path to the built libraries for the subsequent test vector generation commands by adding the `--lib_path` option.

You can filter also the list of candidates that should be built. To only build SUPERCOP variants starting with name 'ace' or 'xoodyak':
```
$ cryptotvgen --prepare_libs ace xoodyak
```
This will only build `aceae128v1` (AEAD) and `acehash256v1` (hash) variants of the LWC candidate "Ace" and  `xoodyakv1` (AEAD and hash) variants of "Xoodyak".


- After the `cryptotvgen --prepare_libs` you can generate test vectors for any of the LWC candidates.
At least one of `--aead <ALGORITHM-VARIANT>` or `--hash <ALGORITHM-VARIANT>`  (or both) need to be provided with the correct name of the AEAD or hash variant.
Some candidates may provide more than one AEAD and/or hash variants.

- To generate hash test vector #5 with MODE=0 (All random data, see help for meaning of MODEs) for `xoodyakv1`:
```
$ cryptotvgen --hash xoodyakv1 --gen_hash 5 5 1 
```
- To generate hash test vector #5 with MODE=1 (see help for details) for `acehash256v1`:
```
$ cryptotvgen --hash acehash256v1 --gen_hash 5 5 1 
```

To generate combined AEAD+hash test vectors with random data for LWC candidate "ACE" (`aceae128v1` and `acehash256v1`):
```
$ cryptotvgen --aead aceae128v1 --hash acehash256v1 --gen_test_combine 1 10 0
```
The test vectors are interleaved as encrypt, decrypt, and hash.

For more information see help:
```
$ cryptotvgen -h
```


## Using as Python Library
See the example scripts in the [examples](./examples) sub-folder as well as [hardware/dummy_lwc/test_all.py](../../hardware/dummy_lwc/test_all.py).

1. [examples/dummy_lwc.py](examples/dummy_lwc.py): generate AEAD and hash test vectors for `dummy_lwc` core.

    Usage : `dummy_lwc.py <io-bits> [<max_block_per_sgmt>]`
    - The `io-bits` argument is mandatory and specifies the I/O of the top level `LWC` module. Valid values: {8, 16, 32}
    - The `max_block_per_sgmt` argument is optional and is only used for multi-segment test vectors. It specifies the maximum blocks per segment.
    
    To generate test vectors for 32 bit width I/O:
    ```
    $ dummy_lwc.py 32
    ```
    To generate multi-segment test vectors for 16 bit width I/O and maximum of 2 blocks per segment:
    ```
    $ dummy_lwc.py 16 2
    ```

 1. [examples/gimli24v1.py](examples/gimli24v1.py) generate AEAD and hash test vectors for `gimli24v1` NIST Round 2 LWC candidate.

