import os
import subprocess
from setuptools import setup, find_packages
from setuptools.command.build_py import build_py
from setuptools.command.install import install
from wheel.bdist_wheel import bdist_wheel

PACKAGE = 'flad'
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
        self.root_is_pure = False

    def copy_artifacts(self, files):

        #current working dir
        print(os.getcwd())
        print(os.listdir(os.getcwd()))
        print(self.build_lib)
        print()
        for (src, dst) in files:
            self.copy_file(
                src,
                os.path.join(self.build_lib, DIR_DEST, dst)
            )

    def run(self):
        print('Running bdist_wheel' * 100)
        platform = os.uname().sysname
        if platform == 'Darwin':
            subprocess.check_call(['make', MACOS_TARGET])
            self.copy_artifacts(MACOS_FILES)
        elif platform == 'Linux':
            subprocess.check_call(['make', LINUX_TARGET])
            self.copy_artifacts(LINUX_FILES)
        else:
            raise ValueError(f'Unssported platform "{platform}"')
        print('Done ' * 100)

setup(
    name=PACKAGE,
    packages=find_packages(),
    package_data={
        PACKAGE: [dst for (_, dst) in MACOS_FILES + LINUX_FILES],
    },
    cmdclass={
        'bdist_wheel': CustomBdistWheel,
    },
)
