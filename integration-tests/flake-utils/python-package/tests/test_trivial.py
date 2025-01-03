from python_package import hello


def test_trivial():
    pass


def test_nontrivial():
    assert hello() == "Hello from python-package!"
