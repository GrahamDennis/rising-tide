{
  name = "mavlink-root";
  subprojects = {
    consumer-py = import ./consumer-py/project.nix;
    example = import ./example/project.nix;
    mavlink2cue = import ./mavlink2cue/project.nix;
  };
  tools.uv.enable = true;
}
