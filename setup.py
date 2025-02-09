import sys
import platform as pf
from wheel.bdist_wheel import bdist_wheel

PACKAGE = 'flatn'
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

def tag():
    machine = pf.machine()
    platform = sys.platform
    if platform == 'darwin':
        if machine == 'x86_64':
            return 'macosx_11_0_x86_64'
        elif machine == 'arm64':
            return 'macosx_11_0_arm64'
    elif platform.startswith('linux'):
        if machine == 'aarch64':
            return 'linux_aarch64'
        elif machine == 'x86_64':
            return 'linux_x86_64'
    raise ValueError(f"Unsupported machine type: {machine}")

class CustomBdistWheel(bdist_wheel):
    def finalize_options(self):
        super().finalize_options()
        self.root_is_pure = False
        self.plat_name_supplied = True
        self.plat_name = tag()

    def get_tag(self):
        python, abi, _plat = super().get_tag()
        return python, abi, tag()

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
