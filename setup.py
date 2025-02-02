import os
import subprocess
from setuptools import setup, find_packages
from setuptools.command.build_py import build_py
from setuptools.command.install import install
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
    def initialize_options(self):
        super().initialize_options()

    def finalize_options(self):
        super().finalize_options()
        # Mark this as not a pure python package
        self.root_is_pure = False
        # Set the platform tag
        self.plat_name = 'macosx_11_0_arm64' if os.uname().sysname == 'Darwin' else 'linux_x86_64'

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
)
