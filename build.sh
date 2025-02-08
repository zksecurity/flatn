#!/bin/bash

set -e

# build the flatter binary and the shared library
if [ "$(uname)" = "Linux" ]; then
    make linux
    cp libflatter.so flad/
    cp flatter-linux flad/flatter
    echo "Done"
elif [ "$(uname)" = "Darwin" ]; then
    make darwin
    cp libflatter.dylib flad/
	cp flatter-darwin flad/flatter
	echo "Done"
else
    echo "Unsupported platform: $(uname)"
    exit 1
fi

# build the wheel
python -m venv .venv
source .venv/bin/activate
pip install build wheel setuptools
python -m build
