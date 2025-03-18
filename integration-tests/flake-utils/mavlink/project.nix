{
  name = "mavlink-root";
  subprojects = {
    consumer-py = import ./consumer-py/project.nix;
    example = import ./example/project.nix;
  };
  # tools.uv.enable = true;
}
