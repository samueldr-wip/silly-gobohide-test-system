{ pkgs, ... }:

{
  wip.kernel.package = pkgs.callPackage (
    { stdenv }:

    stdenv.mkDerivation {
      version = "7.0.0";
      src = builtins.fetchGit /Users/samuel/tmp/linux/gobohide;
    }
  ) {};
}
