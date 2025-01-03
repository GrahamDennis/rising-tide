import pytest


# We don't want these tests showing up in the VSCode testing panel.
def test_bar() -> None:
    pytest.fail("Always fails")
