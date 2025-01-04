from setuptools import setup, find_packages

import os
import sys
import shutil
import subprocess

PACKAGE = 'pyflatter'

def build_binary():
    # if on MacOS, build the dylib
    if sys.platform == 'darwin':
        subprocess.run(['make', 'flatter-darwin', 'libflatter.dylib'])

        # clean
        root = os.path.join(os.getcwd(), PACKAGE)
        assert os.path.exists(root)
        binary = os.path.join(root, 'bin')
        try:
            shutil.rmtree(binary)
        except FileNotFoundError:
            pass
        os.mkdir(binary)

        # copy flatter to PACKAGE/bin
        # copy libflatter.dylib to PACKAGE/bin
        shutil.copy2('flatter-darwin', binary)
        shutil.copy2('libflatter.dylib', binary)

    if sys.platform == 'linux':
        subprocess.run(['make', 'flatter-linux', 'libflatter.so'])

        # clean
        print(os.getcwd())
        root = os.path.join(os.getcwd(), PACKAGE)
        assert os.path.exists(root)
        binary = os.path.join(root, 'bin')
        try:
            shutil.rmtree(binary)
        except FileNotFoundError:
            pass
        os.mkdir(binary)

        # copy flatter to PACKAGE/bin
        # copy libflatter.so to PACKAGE/bin
        shutil.copy2('flatter-linux', binary)
        shutil.copy2('libflatter.so', binary)

    else:
        # die
        raise NotImplementedError("This build script is only supported on MacOS")

build_binary()

setup(
    name=PACKAGE,
    version="0.1.0",
    packages=find_packages(),
    install_requires=[],
    zip_safe=False,
    package_data={
        PACKAGE: ['bin/']
    },
)
