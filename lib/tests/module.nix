# injector context
{ foo, ... }:
# module context
{
  inherit foo;
}
