{ pkgs, ... }:

{
  wip.kernel.package = pkgs.callPackage (
    { stdenv }:

    stdenv.mkDerivation (finalAttrs: {
      version =
        let
          # Keep the version information "evergreen"
          makefile = builtins.readFile (finalAttrs.src + "/Makefile");
          data =
            builtins.filter
            (s: builtins.isString s && (builtins.match "^(VERSION|PATCHLEVEL|SUBLEVEL|EXTRAVERSION) =.*$" s) != null)
            (builtins.split "\n" makefile)
          ;
          info =
            builtins.listToAttrs (
              builtins.map (
                s:
                let
                  getPart = builtins.elemAt (builtins.match "([^ ]*) *= *(.*)" s);
                in
                { name = getPart 0; value = getPart 1; }
              )
              data
            )
          ;
        in
          builtins.concatStringsSep "" [
            info.VERSION
            "."
            info.PATCHLEVEL
            "."
            info.SUBLEVEL
            info.EXTRAVERSION
          ]
      ;
      src = builtins.fetchGit /Users/samuel/tmp/linux/gobohide;
    })
  ) {};
}
