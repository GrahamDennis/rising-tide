import package_1


def hello() -> str:
    return "Hello from package-2!"


def bar() -> str:
    return "BaR"


def hello_from_package_1() -> str:
    return package_1.hello()


def cli() -> None:
    print(hello())
