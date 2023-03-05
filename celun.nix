let
  rev = "f4e681b896aae165506b7963eb6ac6d6c032145f";
  sha256 = "0mwqzinvacb8xd5wdv13l2b481n8xzm9dvh07ghs5pgifspi7skw";
in
builtins.fetchTarball {
  url = "https://github.com/celun/celun/archive/${rev}.tar.gz";
  inherit sha256;
}
