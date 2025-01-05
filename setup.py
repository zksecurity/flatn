from pathlib import Path
from setuptools import setup, find_packages

from wheel.bdist_wheel import bdist_wheel

PACKAGE = 'pyflatter'

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
    },
    package_dir={"": "."},
)
