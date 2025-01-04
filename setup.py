from setuptools import setup, find_packages
from setuptools.command.build_ext import build_ext

import subprocess
import sys
import os
import shutil

PACKAGE = 'flattery'

def build_binary():
    # if on MacOS, build the dylib
    if sys.platform == 'darwin':
        subprocess.run(['make', 'flatter', 'libflatter.dylib'])

        # clean
        root = os.path.join(os.getcwd(), PACKAGE)
        binary = os.path.join(root, 'bin')
        shutil.rmtree(binary)
        os.mkdir(binary)

        # copy flatter to PACKAGE/bin
        # copy libflatter.dylib to PACKAGE/bin
        shutil.copy2('flatter', os.path.join(binary, 'flatter'))
        shutil.copy2('libflatter.dylib', os.path.join(binary, 'libflatter.dylib'))

    else:
        # die
        raise NotImplementedError("This build script is only supported on MacOS")

build_binary()

setup(
    name="flattery",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[],
    zip_safe=False,
    package_data={
        'flattery': ['bin/']
    },
)
