{ pkgsLib, ... }@args:

with pkgsLib.types;

{
  types = {
    template = functionTo lines;

    file = coercedTo package builtins.toString path;

    content = import ./submodules/content/type.nix args;
    image = import ./submodules/image/type.nix args;
    page = import ./submodules/page/type.nix args;
    post = import ./submodules/post/type.nix args;
    style = import ./submodules/style/type.nix args;
  };
}
