from setuptools import setup, find_packages

from wheel.bdist_wheel import bdist_wheel

import os
import sys
import shutil
import subprocess

PACKAGE = 'pyflatter'

def build_binary():
    # if on MacOS, build the dylib
    if sys.platform == 'darwin':
        subprocess.run(['make', 'flatter-darwin', 'libflatter.dylib']).check_returncode()

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

    elif sys.platform == 'linux':
        subprocess.run(['make', 'flatter-linux', 'libflatter.so']).check_returncode()

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



class CustomBdistWheel(bdist_wheel):
    def finalize_options(self):
        bdist_wheel.finalize_options(self)
        # Mark this as platform specific
        self.root_is_pure = False

    def get_tag(self):
        # Override platform tag
        python_tag, abi_tag, platform_tag = bdist_wheel.get_tag(self)
        # For macOS arm64:
        # platform_tag = 'macosx_11_0_arm64'
        # For macOS x86_64:
        # platform_tag = 'macosx_10_9_x86_64'
        # For Linux:
        # platform_tag = 'linux_x86_64'
        return python_tag, abi_tag, platform_tag

setup(
    name=PACKAGE,
    version="0.1.0",
    packages=find_packages(),
    install_requires=[],
    zip_safe=False,
    package_data={
        PACKAGE: ['bin/*'],
    },
    cmdclass={
        'bdist_wheel': CustomBdistWheel,
    },
)
