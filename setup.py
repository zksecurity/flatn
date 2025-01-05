from setuptools import setup, find_packages
from setuptools.command.build_py import build_py

from wheel.bdist_wheel import bdist_wheel

import os
import sys
import shutil
import subprocess

PACKAGE = 'pyflatter'

class CustomBuildPy(build_py):
    def run(self):
        # create the /bin directory
        root = os.path.join(os.getcwd(), PACKAGE)
        assert os.path.exists(root)
        binary = os.path.join(root, 'bin')
        assert os.path.exists(binary)

        env = os.environ.copy()
        env['PWD'] = os.getcwd()

        # if on MacOS, build the .dylib
        if sys.platform == 'darwin':
            # a clean build in the temporary directory
            subprocess.run([
                'make',
                'flatter-darwin',
                'libflatter.dylib'
            ], env=env).check_returncode()

            # copy flatter to PACKAGE/bin
            # copy libflatter.dylib to PACKAGE/bin
            shutil.copy2('flatter-darwin', binary)
            shutil.copy2('libflatter.dylib', binary)

        # if on Linux, build the .so
        elif sys.platform == 'linux':
            # a clean build in the temporary directory
            subprocess.run([
                'make',
                'flatter-linux',
                'libflatter.so'
            ], env=env).check_returncode()

            # copy flatter to PACKAGE/bin
            # copy libflatter.so to PACKAGE/bin
            shutil.copy2('flatter-linux', binary)
            shutil.copy2('libflatter.so', binary)

        else:
            # die
            raise NotImplementedError("This build script is only supported on MacOS and Linux")

class CustomBdistWheel(bdist_wheel):
    def finalize_options(self):
        bdist_wheel.finalize_options(self)
        # Mark this as platform specific
        self.root_is_pure = False

    def get_tag(self):
        # Override platform tag
        python_tag, abi_tag, platform_tag = bdist_wheel.get_tag(self)
        print(f'platform_tag: {platform_tag}')
        return python_tag, abi_tag, platform_tag

setup(
    name=PACKAGE,
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        "setuptools",
    ],
    zip_safe=False,
    package_data={
        PACKAGE: ['bin/*'],
    },
    data_files=[
        ('', [
            'Makefile',
            'gmp-6.3.0.tar.xz',
            'fplll-5.3.2.tar.gz',
            'mpfr-4.2.1.tar.gz',
            'flatter.tar.gz'
        ]),
    ],
    cmdclass={
        'bdist_wheel': CustomBdistWheel,
        'build_py': CustomBuildPy,
    },
    package_dir={"": "."},
)
