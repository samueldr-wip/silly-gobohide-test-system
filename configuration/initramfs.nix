{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    mkOption
    optionalString
    types
  ;

  inherit (pkgs)
    runCommand
    writeScript
    writeScriptBin
    writeText
    writeTextFile
    writeTextDir

    mkExtraUtils

    busybox
    glibc
  ;

  writeScriptDir = name: text: writeTextFile {inherit name text; executable = true; destination = "${name}";};

  cfg = config.examples.wip-gobohide;

  # Alias to `output.extraUtils` for internal usage.
  inherit (cfg.output) extraUtils;
in
{

  options.examples.wip-gobohide = {
    extraUtils = {
      packages = mkOption {
        # TODO: submodule instead of `attrs` when we extract this
        type = with types; listOf (oneOf [package attrs]);
      };
    };
    output = {
      extraUtils = mkOption {
        type = types.package;
        internal = true;
      };
    };
  };

  config = {
    wip.stage-1.enable = true;
    wip.stage-1.archive.additionalListEntries = {
      "/Users" = {
        type = "dir";
        mode = "755";
      };
      "/Users/SYSTEM" = {
        type = "dir";
        mode = "755";
      };
      "/Users/SYSTEM/upperdir" = {
        type = "dir";
        mode = "755";
      };
      "/Users/SYSTEM/workdir" = {
        type = "dir";
        mode = "755";
      };
      "/Users/SYSTEM/overlaid" = {
        type = "dir";
        mode = "755";
      };
    };
    wip.stage-1.archive.contents = {
      "/etc/issue" = writeTextDir "/etc/issue" ''

        Gobohide test system
        ====================

      '';

      # https://git.busybox.net/busybox/tree/examples/inittab
      "/etc/inittab" = writeTextDir "/etc/inittab" ''
        # Allow root login on the `console=` param.
        # (Or when missing, a default console may be launched on e.g. serial)
        # No console will be available on other valid consoles.
        console::respawn:${extraUtils}/bin/getty -l ${extraUtils}/bin/login 0 console

        # Launch all setup tasks
        ::sysinit:${extraUtils}/bin/sh -l -c ${extraUtils}/bin/mount-basic-mounts
        ::sysinit:${extraUtils}/bin/sh -l -c ${extraUtils}/bin/network-setup
        ::wait:${extraUtils}/bin/sh -l -c ${extraUtils}/bin/gobohide-init

        ::restart:${extraUtils}/bin/init
        ::ctrlaltdel:${extraUtils}/bin/poweroff
      '';

      "/etc/passwd" = writeTextDir "/etc/passwd" ''
        SYSTEM::0:0:SYSTEM:/Users/SYSTEM:${extraUtils}/bin/sh
      '';

      "/etc/profile" = writeScriptDir "/etc/profile" ''
        export LD_LIBRARY_PATH="${extraUtils}/lib"
        export PATH="${extraUtils}/bin"
      '';

      # Place init under /etc/ to make / prettier
      init = writeScriptDir "/init" ''
        #!${extraUtils}/bin/sh

        echo
        echo "::"
        echo ":: Launching busybox linuxrc"
        echo "::"
        echo

        . /etc/profile

        exec linuxrc
      '';

      extraUtils = runCommand "wip-gobohide--initramfs-extraUtils" {
        passthru = {
          inherit extraUtils;
        };
      } ''
        mkdir -p $out/${builtins.storeDir}
        cp -prv ${extraUtils} $out/${builtins.storeDir}
      '';

      # POSIX requires /bin/sh
      "/bin/sh" = runCommand "wip-gobohide--initramfs-extraUtils-bin-sh" {} ''
        mkdir -p $out/bin
        ln -s ${extraUtils}/bin/sh $out/bin/sh
      '';
    };

    examples.wip-gobohide.extraUtils.packages = [
      {
        package = busybox;
        extraCommand = ''
          (cd $out/bin/; ln -s busybox linuxrc)
        '';
      }

      (writeScriptBin "mount-basic-mounts" ''
        #!/bin/sh

        PS4=" $ "
        #set -x
        mkdir -p /proc /sys /dev /run /tmp
        mount -t proc proc /proc
        mount -t sysfs sys /sys
        mount -t devtmpfs devtmpfs /dev
      '')

      (writeScriptBin "network-setup" ''
        #!/bin/sh

        PS4=" $ "
        #set -x
        hostname gobohide-test
        ip link set lo up
      '')

      (writeScriptBin "gobohide-init" ''
        #!/bin/sh

        set -e
        PS4=" $ "
        #set -x

        move_to_line() {
          printf '\e[%d;0H' "$@" > /dev/tty0
        }

        ${
        # See https://github.com/torvalds/linux/blob/b01fe98d34f3bed944a93bd8119fed80c856fad8/usr/default_cpio_list
        "rmdir /root"
        }

        # Wait for kernel messages to settle a bit
        sleep 2

        move_to_line 999

        printf "\n\n... initializing\n"
        (
        set +e
        set -x

        # This cannot be hidden by gobohide, it only hides directories or symlinks.
        rm /init

        # Hide everything else
        gobohide --hide /bin
        gobohide --hide /dev
        gobohide --hide /etc
        gobohide --hide /nix
        gobohide --hide /proc
        gobohide --hide /run
        gobohide --hide /sys
        gobohide --hide /tmp
        )

        printf "\n\n:: Checking overlayfs.\n\n"

        (
        set -x

        # Testing overlayfs
        mount -t overlay overlay -o lowerdir=/etc,upperdir=/Users/SYSTEM/upperdir,workdir=/Users/SYSTEM/workdir /Users/SYSTEM/overlaid

        touch /Users/SYSTEM/overlaid/success
        mkdir /Users/SYSTEM/overlaid/hidden
        gobohide --hide /Users/SYSTEM/overlaid/hidden

        ls -l /Users/SYSTEM/workdir
        ls -l /Users/SYSTEM/workdir/work
        )

        printf "\n\n==========================================\n"

        printf "\n\n:: Listing of /.\n\n"
        (
        set -x
        ls -l /
        )

        printf "\n\n:: Listing overlayfs.\n\n"
        (
        set -x
        ls -l /Users/SYSTEM/upperdir
        ls -l /Users/SYSTEM/overlaid
        )

        printf "\n\n"

        printf "Testing base function:\n"
        if test -e /etc; then
          printf "  SUCCESS -> /etc does exist.\n"
          if ! ls / | grep /etc; then
            printf "  SUCCESS -> /etc was hidden from listing.\n"
          else
            printf "  FAIL -> /etc was not hidden from listing.\n"
            exit 1
          fi
        else
          printf "  FAIL -> /etc could not be accessed.\n"
          exit 1
        fi
      '')
    ];

    examples.wip-gobohide.output = {
      extraUtils = mkExtraUtils {
        name = "celun-wip-gobohide--extra-utils";
        inherit (cfg.extraUtils) packages;
      };
    };
  };
}
