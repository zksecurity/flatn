import os
import subprocess
import platform as pf
import sys
from setuptools import setup, find_packages, Extension
from setuptools.command.build_py import build_py
from setuptools.command.install import install
from distutils.command.bdist import bdist
from wheel.bdist_wheel import bdist_wheel

PACKAGE = 'flad'
VERSION = '0.1.0'
MACOS_FILES = [
    ('flatter-darwin', 'flatter'),
    ('libflatter.dylib', 'libflatter.dylib'),
]
MACOS_TARGET = 'darwin'
LINUX_FILES = [
    ('flatter-linux', 'flatter'),
    ('libflatter.so', 'libflatter.so'),
]
LINUX_TARGET = 'linux'
DIR_BUILD = 'build'
DIR_DEST = PACKAGE

class CustomBdistWheel(bdist_wheel):
    def finalize_options(self):
        super().finalize_options()
        # Mark this as not a pure python package
        self.root_is_pure = False
        # This is a platform wheel
        self.plat_name_supplied = True

        # Only support Linux and MacOS
        machine = pf.machine()
        platform = sys.platform
        if platform == 'darwin':
            if machine == 'x86_64':
                self.plat_name = 'macosx_11_0_x86_64'
            elif machine == 'arm64':
                self.plat_name = 'macosx_11_0_arm64'
        elif platform.startswith('linux'):
            if machine == 'aarch64':
                self.plat_name = 'linux_aarch64'
            elif machine == 'x86_64':
                self.plat_name = 'linux_x86_64'
            else:
                raise ValueError(f"Unsupported machine type: {machine}")
        else:
            raise ValueError("This package only supports Linux and MacOS platforms")

    def get_tag(self):
        # Override get_tag to specify platform-specific tags
        python, abi, plat = super().get_tag()
        if sys.platform == 'darwin':
            plat = 'macosx_11_0_arm64'
        elif sys.platform.startswith('linux'):
            plat = 'linux_x86_64'
        else:
            raise ValueError("This package only supports Linux and MacOS platforms")
        return python, abi, plat

setup(
    name=PACKAGE,
    version=VERSION,
    description='Flatter Library Distribution Package',
    author='Mathias Hall-Andersen',
    author_email='mathias@hall-andersen.dk',
    packages=find_packages(),
    package_data={
        PACKAGE: [
            'flatter',
            'libflatter.*',
        ]
    },
    exclude_package_data={
        '': ['*.tar.gz', '*.tar.xz', '*.zip'],
    },
    cmdclass={
        'bdist_wheel': CustomBdistWheel,
    },
    python_requires='>=3.4',
    # Indicate this is not a pure Python package by setting ext_modules
    ext_modules=[],
    has_ext_modules=lambda: True,
    platforms=['linux', 'darwin'],
)
