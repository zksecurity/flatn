from pathlib import Path
from setuptools import setup, find_packages
from setuptools.command.build_py import build_py
from setuptools.command.build_ext import build_ext

from wheel.bdist_wheel import bdist_wheel

import os
import sys
import shutil
import subprocess

PACKAGE = 'pyflatter'

class CustomBuildPy(build_py):
    def run(self):
        # run the parent class
        super().run()
        return

        # Get the build directory
        build_dir = Path(self.build_lib) / PACKAGE / "bin"
        build_dir.mkdir(parents=True, exist_ok=True)

        # Create the bin directory in the build location
        print(os.listdir(os.getcwd()))
        # env = os.environ.copy()
        # env['PWD'] = os.getcwd()

        # if on MacOS, build the .dylib
        if sys.platform == 'darwin':
            # a clean build in the temporary directory
            subprocess.run([
                'make',
                'flatter-darwin',
                'libflatter.dylib'
            ]).check_returncode()

            # copy flatter to PACKAGE/bin
            # copy libflatter.dylib to PACKAGE/bin
            shutil.copy2('flatter-darwin', build_dir / 'flatter')
            shutil.copy2('libflatter.dylib', build_dir / 'libflatter.dylib')
            os.chmod(build_dir / 'flatter', 0o755)

            #print absolute path of the file
            print(os.path.abspath(build_dir))

        # if on Linux, build the .so
        elif sys.platform == 'linux':
            # a clean build in the temporary directory
            subprocess.run([
                'make',
                'flatter-linux',
                'libflatter.so'
            ]).check_returncode()

            # copy flatter to PACKAGE/bin
            # copy libflatter.so to PACKAGE/bin
            shutil.copy2('flatter-linux', build_dir / 'flatter')
            shutil.copy2('libflatter.so', build_dir / 'libflatter.so')
            os.chmod(build_dir / 'flatter', 0o755)

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
        python_tag = "py3"
        abi_tag = "none"
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
        PACKAGE: [
            'bin/*',
        ]
    },
    cmdclass={
        'bdist_wheel': CustomBdistWheel,
        'build_py': CustomBuildPy,
    },
    package_dir={"": "."},
)
