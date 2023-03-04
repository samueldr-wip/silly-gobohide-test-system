{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    mkOption
    optionalString
    types
  ;
  gobohide = pkgs.callPackage (
    { stdenv
    , lib
    , fetchFromGitHub
    , pkg-config
    , autoconf, automake
    , gettext
    , libnl
    }:

    stdenv.mkDerivation rec {
      name = "GoboHide-${version}";
      version = "1.3";
      
      src = fetchFromGitHub {
        owner = "gobolinux";
        repo = "GoboHide";
        rev = "${version}";
        sha256 = "0f5aag33lanh00yv64va50apwg4qv8rnd7jqpl8avdfh8aznk9fi";
      };

      buildInputs = [
        autoconf
        automake 
        pkg-config
        gettext
        libnl
      ];

      preConfigure = ''
        patchShebangs autogen.sh
        ./autogen.sh
      '';

      meta = with lib; {
        description = "GoboHide userspace client";
        homepage    = https://github.com/gobolinux/GoboHide;
        license     = licenses.gpl2Plus;
        #maintainers = with maintainers; [ samueldr ];
        platforms   = platforms.linux;
      };
    }
  ) {};
in
{
  config = {
    examples.wip-gobohide.extraUtils.packages = [
      { package = gobohide; }
    ];
  };
}
