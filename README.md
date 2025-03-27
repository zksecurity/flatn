# Flatn - Python Wrapper for Flatter

Flatn is a Python wrapper around the execellent [flatter](https://github.com/keeganryan/flatter) lattice reduction library, providing a simple and convenient way to perform lattice reduction operations from Python code.

Lattice reduction is an important technique in computational number theory and cryptanalysis that transforms a given set of basis vectors into a "nicer" (shorter) basis for the same lattice.
If you found this package, you probably know why you want to do this...

## Installation

You can install Flatn using pip:

```bash
pip install flatn
```

Currently, only `darwin/aarch64`, `linux/x86_64`, and `linux/arm64` are supported. No dependencies are required: all the flatter dependencies are statically linked into the binary.

## Usage Example

The library provides two main functions:

- `reduce()`: The main function for lattice reduction
- `run_flatter_raw()`: Lowest-level function for debugging: simply calls the `flatter` binary.

Here is a simple example:

```python
import flatn

# define a lattice as a list of basis vectors
lattice = [
    [1, 0, 331, 303],
    [0, 1, 456, 225],
    [0, 0, 628, 0],
    [0, 0, 0, 628]
]

# derform lattice reduction
reduced_basis = flatn.reduce(lattice)

print(reduced_basis)
# output:
# [[-9, 1, -11, 10],
#  [16, -2, -12, 2],
#  [12, 23, 16, 19],
#  [3, 35, -3, -8]]

# You can also control the reduction quality with parameters:
# - alpha: higher means more reduced
# - rhf: target root Hermite factor
# - delta: LLL parameter (between 0.25 and 1.0)
# - logcond: maximum allowed log of condition number

# For example, specifying delta:
reduced_basis = flatn.reduce(lattice, delta=0.99)
```
