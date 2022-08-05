"""A setuptools based setup module.
See:
https://packaging.python.org/en/latest/distributing.html
https://github.com/pypa/sampleproject
Reference:
https://github.com/pypa/sampleproject/blob/master/setup.py
https://setuptools.readthedocs.io/en/latest/setuptools.html#automatic-script-creation
"""


from setuptools import setup, find_packages


setup(
    name='cryptotvgen',

    # Versions should comply with PEP440.  For a discussion on single-sourcing
    # the version across setup.py and the project code, see
    # https://packaging.python.org/en/latest/single_source_version.html
    version='1.1.0',

    description='Cryptographic Hardware Test Vectors Generator',
    long_description='Cryptographic Hardware Test Vectors Generator for SuperCop software library.',

    # The project's main homepage.
    url='https://cryptography.gmu.edu/athena/index.php?id=download',

    packages=find_packages(),

    # Author details
    author='Ekawat (Ice) Homsirikamol, William Diehl',
    author_email='ekawat@gmail.com, wdiehl@vt.edu',

    license='GPLv3',

    # See https://pypi.python.org/pypi?%3Aaction=list_classifiers
    classifiers=[
        # How mature is this project? Common values are
        #   3 - Alpha
        #   4 - Beta
        #   5 - Production/Stable
        'Development Status :: 4 - Beta',

        # Indicate who your project is intended for
        'Intended Audience :: Science/Research',
        'Topic :: Scientific/Engineering :: Electronic Design Automation (EDA)',


        # Pick your license as you wish (should match "license" above)
        'License :: OSI Approved :: GNU General Public License v3 (GPLv3)',

        # Specify the Python versions you support here. In particular, ensure
        # that you indicate whether you support Python 2, Python 3 or both.
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
    ],

    # What does your project relate to?
    keywords='test vectors generation hardware development',

    # You can just specify the packages manually here if your project is
    # simple. Or you can use find_packages().
    #packages=find_packages(exclude=['contrib', 'docs', 'tests']),

    # Alternatively, if you want to distribute just a my_module.py, uncomment
    # this:
    py_modules=['cryptotvgen'],
    
    python_requires='>=3.6.5',

    # List run-time dependencies here.  These will be installed by pip when
    # your project is installed. For an analysis of "install_requires" vs pip's
    # requirements files see:
    # https://packaging.python.org/en/latest/requirements.html
    install_requires=[
        "cffi>=1.14.1",
        "importlib_resources;python_version<'3.7'"
    ],

    # List additional groups of dependencies here (e.g. development
    # dependencies). You can install these using the following syntax,
    # for example:
    # $ pip install -e .[dev,test]
    extras_require={
        'dev': [],
        # 'test': ['nose'],
    },
    
    package_data={'cryptotvgen': ['lwc_cffi.mk']},
    include_package_data=True,

    # To provide executable scripts, use entry points in preference to the
    # "scripts" keyword. Entry points provide cross-platform support and allow
    # pip to create the appropriate form of executable for the target platform.
    entry_points={
        'console_scripts': [
            'cryptotvgen=cryptotvgen:cli.run_cryptotvgen',
        ],
    }
)
