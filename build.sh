#!/bin/bash

set -e

# build the flatter binary and the shared library
if [ "$(uname)" = "Linux" ]; then
    make linux
    cp flatter-linux flatn/flatter
    echo "Done"
elif [ "$(uname)" = "Darwin" ]; then
    make darwin
	cp flatter-darwin flatn/flatter
	echo "Done"
elif [ "$(uname -o 2>/dev/null)" = "Msys" ] || [[ "$(uname)" == MINGW* ]] || [[ "$(uname)" == MSYS* ]]; then
    make windows
    cp flatter-windows.exe flatn/flatter.exe
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
