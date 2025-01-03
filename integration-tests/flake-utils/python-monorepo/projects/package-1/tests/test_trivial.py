from package_1 import hello


def test_trivial():
    pass


def test_nontrivial():
    assert hello() == "Hello from package-1!"
