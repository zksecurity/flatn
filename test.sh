#!/bin/bash

set -e

rm -rf test-env
mkdir -p test-env
cd test-env
python3 -m venv venv
. venv/bin/activate
PYTHONPATH= pip install ../dist/*.whl
python3 ../tests.py
deactivate
cd ..
