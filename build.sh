#!/bin/bash

set -e

rm -rf .tmp-venv
python3 -m venv .tmp-venv
source .tmp-venv/bin/activate
pip install build wheel setuptools
python -m build

rm -rf /tmp/flatn
mkdir -p /tmp/flatn
cp dist/* /tmp/flatn
cp tests.py /tmp/flatn
cd /tmp/flatn
ls -l
python3 -m venv .venv
source .venv/bin/activate
pip install *.whl
python tests.py
