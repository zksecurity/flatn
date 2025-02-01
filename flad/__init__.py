import os
import sys
import subprocess
import importlib.resources as pkg_resources

PACKAGE = 'flad'

# get file path
with pkg_resources.path(PACKAGE, 'bin') as path_bin:
    assert os.path.exists(path_bin), f"Path {path_bin} does not exist"
    __path_flatter = path_bin / 'flatter'
    __path_dylib = path_bin

# sanity: check if the file exists
assert os.path.exists(path_bin), f"Path {path_bin} does not exist"
assert os.path.exists(__path_flatter), f"Path {__path_flatter} does not exist"
assert os.path.exists(__path_dylib), f"Path {__path_dylib} does not exist"

def flatter(
    lattice,
    verbose=False,
    quiet=False,
    alpha=None,
    rhf=None,
    delta=None,
    logcond=None,
):
    """Flatter lattice reduction algorithm.

    Args:
        lattice: A list of lists representing the lattice
        verbose (bool): Enable verbose output
        quiet (bool): Do not output lattice
        alpha (float, optional): Reduce to given parameter alpha
        rhf (float, optional): Reduce analogous to given root hermite factor. Defaults to 1.0219
        delta (float, optional): Reduce analogous to LLL with particular delta (approximate)
        logcond (float, optional): Bound on condition number

    Only one of alpha, rhf, or delta should be specified for reduction quality.

    The input/output format follows the FPLLL format.
    """

    args = [str(__path_flatter)]

    if verbose:
        args.append('-v')

    if quiet:
        args.append('-q')

    if alpha:
        args += ['-a', f'{alpha}']

    if rhf:
        args += ['-r', f'{rhf}']

    if delta:
        args += ['-d', f'{delta}']

    if logcond:
        args += ['-l', f'{logcond}']

    # sanity check: all rows should have the same length
    assert len(lattice) >= 2, "Lattice should have at least 2 rows"
    assert all(len(row) == len(lattice[0]) for row in lattice)

    # if we are on MacOS add libflatter.dylib to DYLD_LIBRARY_PATH
    env = {}
    if sys.platform == 'darwin':
        env['DYLD_LIBRARY_PATH'] = str(__path_dylib)
    elif sys.platform == 'linux':
        env['LD_PRELOAD'] = str(__path_dylib)
    else:
        raise NotImplementedError("This build script is only supported on MacOS and Linux")

    proc = subprocess.Popen(
        args,
        env=env,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        bufsize=1,
        universal_newlines=True
    )

    assert proc.stdin is not None
    assert proc.stdout is not None

    # send the lattice to flatter
    rows = ['[' + ' '.join(map(str, row)) + ']' for row in lattice]
    matrix = '[' + '\n'.join(rows) + ']'
    proc.stdin.write(matrix)
    proc.stdin.close()

    # read the output from stdout
    rows = []
    first_line = True
    last_line = False
    for line in proc.stdout:
        line = line.strip()
        assert not last_line
        if first_line:
            assert line.startswith('[[')
            assert line.endswith(']')
            rows.append([int(v) for v in line[2:-1].split(' ')])
        elif line[0] == '[':
            assert line[-1] == ']'
            rows.append([int(v) for v in line[1:-1].split(' ')])
        elif line[0] == ']':
            last_line = True
        else:
            raise ValueError(f"Unexpected output from flatter: {line}")
        first_line = False

    assert proc.wait() == 0, f"flatter failed with exit code {proc.returncode}"

    # sanity check: all rows should have the same length
    assert len(rows) >= 2, "Lattice should have at least 2 rows"
    assert all(len(row) == len(rows[0]) for row in rows)
    return rows

def reduce(
    lattice,
    alpha=None,
    rhf=None,
    delta=None,
    logcond=None,
):
    """Performs LLL (Lenstra-Lenstra-Lovász) lattice reduction.

    Args:
        lattice: A list of lists representing the input lattice basis vectors
        alpha (float, optional): Reduction quality parameter alpha (higher means more reduced)
        rhf (float, optional): Target root Hermite factor to achieve
        delta (float, optional): LLL parameter delta between 0.25 and 1.0 (higher means more reduced)
        logcond (float, optional): Maximum allowed log of condition number

    Only one of alpha, rhf, or delta should be specified to control reduction quality.
    Returns the LLL-reduced basis as a list of lists.
    """
    return flatter(
        lattice,
        alpha=alpha,
        rhf=rhf,
        delta=delta,
        logcond=logcond,
    )
