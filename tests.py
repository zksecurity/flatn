import flad

res = flad.reduce([
    [1, 0, 331, 303],
    [0, 1, 456, 225],
    [0, 0, 628, 0],
    [0, 0, 0, 628]
])

assert res == [
    [-9, 1, -11, 10],
    [16, -2, -12, 2],
    [12, 23, 16, 19],
    [3, 35, -3, -8]
]

res = flad.reduce([
    [-21, -3, -27, 28, 10],
    [44, 21, 31, -7, -46],
    [-47, -8, 16, 2, 46],
    [-50, -8, -26, 39, -31],
    [45, 14, -15, -14, -34]
])

assert res == [
    [-2, 6, 1, -12, 12],
    [-19, -30, -6, 3, 12],
    [-4, 33, -20, 13, 10],
    [-24, 10, 20, 23, 10],
    [-33, 7, 3, -13, -17]
]

print("All tests passed.")
