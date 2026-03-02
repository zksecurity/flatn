import unittest
import flatn


# Two small lattices with known reduced forms (default quality).
LATTICE_4X4 = [
    [1, 0, 331, 303],
    [0, 1, 456, 225],
    [0, 0, 628, 0],
    [0, 0, 0, 628],
]
EXPECTED_4X4 = [
    [-9, 1, -11, 10],
    [16, -2, -12, 2],
    [12, 23, 16, 19],
    [3, 35, -3, -8],
]

LATTICE_5X5 = [
    [-21, -3, -27, 28, 10],
    [44, 21, 31, -7, -46],
    [-47, -8, 16, 2, 46],
    [-50, -8, -26, 39, -31],
    [45, 14, -15, -14, -34],
]
EXPECTED_5X5 = [
    [-2, 6, 1, -12, 12],
    [-19, -30, -6, 3, 12],
    [-4, 33, -20, 13, 10],
    [-24, 10, 20, 23, 10],
    [-33, 7, 3, -13, -17],
]


class TestReduceDefault(unittest.TestCase):
    """Basic reduction with default quality settings."""

    def test_4x4(self):
        self.assertEqual(flatn.reduce(LATTICE_4X4), EXPECTED_4X4)

    def test_5x5(self):
        self.assertEqual(flatn.reduce(LATTICE_5X5), EXPECTED_5X5)


class TestReduceQualityParams(unittest.TestCase):
    """Ensure quality parameters are correctly forwarded to flatter."""

    def _is_reduced(self, original, result):
        """Check that result is a valid reduced basis (same rank, shorter vectors)."""
        self.assertEqual(len(result), len(original))
        self.assertEqual(len(result[0]), len(original[0]))
        # first vector should be no longer than original first vector
        norm_orig = sum(x * x for x in original[0])
        norm_red = sum(x * x for x in result[0])
        self.assertLessEqual(norm_red, norm_orig)

    def test_delta(self):
        for delta in [0.5, 0.75, 0.9, 0.99]:
            res = flatn.reduce(LATTICE_4X4, delta=delta)
            self._is_reduced(LATTICE_4X4, res)

    def test_rhf(self):
        for rhf in [1.05, 1.02, 1.01]:
            res = flatn.reduce(LATTICE_4X4, rhf=rhf)
            self._is_reduced(LATTICE_4X4, res)

    def test_alpha(self):
        for alpha in [0.1, 0.06, 0.04]:
            res = flatn.reduce(LATTICE_4X4, alpha=alpha)
            self._is_reduced(LATTICE_4X4, res)

    def test_delta_larger_lattice(self):
        res = flatn.reduce(LATTICE_5X5, delta=0.99)
        self._is_reduced(LATTICE_5X5, res)

    def test_rhf_larger_lattice(self):
        res = flatn.reduce(LATTICE_5X5, rhf=1.01)
        self._is_reduced(LATTICE_5X5, res)


class TestReduceValidation(unittest.TestCase):
    """Input validation in the Python wrapper."""

    def test_too_few_rows(self):
        with self.assertRaises(ValueError):
            flatn.reduce([[1, 0]])

    def test_inconsistent_row_lengths(self):
        with self.assertRaises(ValueError):
            flatn.reduce([[1, 0], [1]])

    def test_delta_out_of_range_low(self):
        with self.assertRaises(ValueError):
            flatn.reduce(LATTICE_4X4, delta=0.1)

    def test_delta_out_of_range_high(self):
        with self.assertRaises(ValueError):
            flatn.reduce(LATTICE_4X4, delta=1.5)


if __name__ == '__main__':
    unittest.main()
