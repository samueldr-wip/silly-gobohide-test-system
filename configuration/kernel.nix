{ pkgs, ... }:

{
  wip.kernel.package = pkgs.callPackage (
    { stdenv }:

    stdenv.mkDerivation {
      version = "6.1.0";
      src = builtins.fetchGit /Users/samuel/tmp/linux/gobohide;
    }
  ) {};
}
