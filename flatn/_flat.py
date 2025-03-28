
import os
import subprocess
import importlib.resources as pkg_resources

PACKAGE = 'flatn'
BIN_NAME = 'flatter'

# get file path
with pkg_resources.path(PACKAGE, '') as path_bin:
    assert os.path.exists(path_bin), f"Path {path_bin} does not exist"
    __path_flatter = path_bin / BIN_NAME

# sanity: check if the file exists
assert os.path.exists(path_bin), f"Path {path_bin} does not exist"
assert os.path.exists(__path_flatter), f"Path {__path_flatter} does not exist"

def run_flatter_raw(
    lattice_str: str,
    verbose: bool = False,
    quiet: bool = False,
    alpha: float | None = None,
    rhf: float | None = None,
    delta: float | None = None,
    logcond: float | None = None,
):
    """Run flatter command directly with a string input.

    This is primarily useful for debugging.

    Args:
        lattice_str: String representation of the lattice in FPLLL format
        verbose (bool): Enable verbose output
        quiet (bool): Do not output lattice
        alpha (float, optional): Reduce to given parameter alpha
        rhf (float, optional): Reduce analogous to given root hermite factor. Defaults to 1.0219
        delta (float, optional): Reduce analogous to LLL with particular delta (approximate)
        logcond (float, optional): Bound on condition number

    Returns:
        subprocess.CompletedProcess: Result of running the flatter command
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

    # Run flatter command and return proc directly
    return subprocess.run(args, input=lattice_str, text=True, capture_output=True)

def reduce(
    lattice: list[list[int]],
    verbose: bool = False,
    quiet: bool = False,
    alpha: float | None = None,
    rhf: float | None = None,
    delta: float | None = None,
    logcond: float | None = None,
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

    # sanity check: all rows should have the same length
    if len(lattice) < 2:
        raise ValueError("Lattice should have at least 2 rows")
    if not all(len(row) == len(lattice[0]) for row in lattice):
        raise ValueError("Every row needs the same number of entries")
    if delta is not None and not (0.25 <= delta <= 1.0):
        raise ValueError("Invalid delta")

    # Convert lattice to string format
    rows = ['[' + ' '.join(map(str, row)) + ']' for row in lattice]
    matrix = '[' + '\n'.join(rows) + ']'

    # Run flatter command
    proc = run_flatter_raw(
        matrix,
        verbose=verbose,
        quiet=quiet,
        alpha=alpha,
        rhf=rhf,
        delta=delta,
        logcond=logcond
    )

    if proc.returncode != 0:
        raise RuntimeError(f"flatter failed with exit code {proc.returncode}")

    # Parse output
    rows = []
    first_line = True
    last_line = False
    for line in proc.stdout.splitlines():
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

    # sanity check: all rows should have the same length
    assert len(rows) >= 2, "Lattice should have at least 2 rows"
    assert all(len(row) == len(rows[0]) for row in rows)
    return rows
