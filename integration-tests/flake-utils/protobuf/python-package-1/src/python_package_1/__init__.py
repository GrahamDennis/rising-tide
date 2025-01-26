from example.v1 import greeter_pb2


def hello() -> str:
    return "Hello from python-package-1!"


def bar() -> str:
    return "BaR"


def hello_from_package_1() -> greeter_pb2.SayHelloRequest:
    return greeter_pb2.SayHelloRequest(name="Python Package 1")


def cli() -> None:
    print(hello())
