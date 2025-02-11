import pytest

import package_1


def test_package1():
    pass


def test_bar():
    assert package_1.bar() == "BaR"


def test_cli(capsys: pytest.CaptureFixture[str]):
    package_1.cli()
    captured = capsys.readouterr()
    assert captured.out == "Hello from package-1!\n"
