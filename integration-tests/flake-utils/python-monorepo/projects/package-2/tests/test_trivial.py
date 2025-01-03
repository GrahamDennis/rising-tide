import package_1

import package_2


def test_package_1():
    assert package_1.hello() == "Hello from package-1!"


def test_package_2():
    assert package_2.hello() == "Hello from package-2!"


def test_package_2_importing_package_1():
    assert package_2.hello_from_package_1() == "Hello from package-1!"
