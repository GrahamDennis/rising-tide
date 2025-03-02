import grpc
import grpc.aio
from example.v1 import greeter_pb2, greeter_pb2_grpc
from example_extended.v1 import greeter_pb2 as greeter_pb2_extended


def hello() -> str:
    return "Hello from python-package-1!"


def bar() -> str:
    return "BaR"


def hello_from_package_1() -> greeter_pb2.SayHelloRequest:
    return greeter_pb2.SayHelloRequest(name="Python Package 1")


def check_typing_of_lists_in_generated_packages() -> greeter_pb2.SayHelloRequest:
    # mypy appears to have an issue with lists in generated packages unless there is a `google` directory
    # in MYPYPATH. Rising-tide has a fix for this, and the return inside the for loop will
    # only successfully type check if the fix is applied.
    message_list = greeter_pb2_extended.MessageList()
    for message in message_list.messages:
        return message
    return greeter_pb2.SayHelloRequest()


def check_typing_in_exception() -> None:
    try:
        foo = check_typing_of_lists_in_generated_packages()
    except grpc.aio.AioRpcError as e:
        print(f"error code {e.code()}")
        raise
    foo.name


async def check_typing_of_asynchronous_rpc(
    stub: greeter_pb2_grpc.GreeterServiceAsyncStub,
) -> greeter_pb2.SayHelloResponse:
    return await stub.SayHello(greeter_pb2.SayHelloRequest(name="Python Package 1"))


def cli() -> None:
    print(hello())
