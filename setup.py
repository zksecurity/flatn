import sys
import platform as pf
from wheel.bdist_wheel import bdist_wheel
from setuptools import setup, find_packages

PACKAGE = 'flatn'

class CustomBdistWheel(bdist_wheel):
    def finalize_options(self):
        super().finalize_options()
        self.root_is_pure = False

    def get_tag(self):
        python, abi, plat = super().get_tag()
        if sys.platform == 'darwin':
            plat = f'macosx_11_0_{pf.machine()}'
        elif sys.platform.startswith('linux'):
            plat = f'manylinux1_{pf.machine()}'
        return python, abi, plat

setup(
    name=PACKAGE,
    description='Flatter Library Distribution Package',
    author='Mathias Hall-Andersen',
    author_email='mathias@hall-andersen.dk',
    long_description=open('README.md').read(),
    long_description_content_type='text/markdown',
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
