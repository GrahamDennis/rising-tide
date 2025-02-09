import package_1
import requests
from requests import Response


def hello() -> str:
    return "Hello from package-2!"


def bar() -> str:
    return "BaR"


def hello_from_package_1() -> str:
    return package_1.hello()


def use_requests() -> Response:
    return requests.get("http://neverssl.com")


def cli() -> None:
    print(hello())
