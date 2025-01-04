import os
import sys
import subprocess
import pkg_resources

PACKAGE = 'pyflatter'

# get file path
path_bin = pkg_resources.resource_filename(PACKAGE, 'bin')

if sys.platform == 'darwin':
    path_flatter = os.path.join(path_bin, 'flatter-darwin')
    path_dylib = os.path.join(path_bin, 'libflatter.dylib')
elif sys.platform == 'linux':
    path_flatter = os.path.join(path_bin, 'flatter-linux')
    path_dylib = os.path.join(path_bin, 'libflatter.so')
else:
    raise NotImplementedError("This build script is only supported on MacOS and Linux")

# sanity: check if the file exists
assert os.path.exists(path_bin)
assert os.path.exists(path_flatter)
assert os.path.exists(path_dylib)

def flatter(
    lattice,
    verbose=False,
    quiet=False,
    alpha=None,
    rhf=None,
    delta=None,
    logcond=None,
):
    '''
    '''

    args = [
        'flatter',
    ]

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

    # if we are on MacOS add libflatter.dylib to DYLD_LIBRARY_PATH

    env = {}
    if sys.platform == 'darwin':
        env['DYLD_LIBRARY_PATH'] = path_dylib
    elif sys.platform == 'linux':
        env['LD_PRELOAD'] = path_dylib
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

    # send the lattice to flatter
    rows = ['[' + ' '.join(map(str, row)) + ']' for row in lattice]
    matrix = '[' + '\n'.join(rows) + ']'
    proc.stdin.write(matrix)
    proc.stdin.close()

    # read the output

def reduce(
    lattice,
    alpha=None,
    rhf=None,
    delta=None,
    logcond=None,
):
    return flatter(
        lattice,
        alpha=alpha,
        rhf=rhf,
        delta=delta,
        logcond=logcond,
    )
