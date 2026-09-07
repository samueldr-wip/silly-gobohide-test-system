{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    mkMerge
  ;
in
{
  imports = [
    ./gobohide.nix
    ./initramfs.nix
    ./kernel.nix
  ];

  boot.cmdline = mkMerge [
    [
      "vt.global_cursor_default=0"
      "console=tty0"
      "console=ttyS0"
    ]
  ];

  device.config.qemu = {
    qemuOptions = lib.mkAfter [
      "-display" "none"
      # Using `-serial stdio` implies/conflicts with `-nographic`.
      #"-nographic"
    ];
    # Don't multiplex monitor on standard input/output.
    serialMode = "stdio";
  };

  wip.kernel = {
    structuredConfig = with lib.kernel; {
      # Basic features needed that may be removed by tinyconfig
      BLOCK = yes;
      USB_SUPPORT = yes;
      USB = yes;
      USB_ANNOUNCE_NEW_DEVICES = no;

      # To lazily report status on display...
      FRAMEBUFFER_CONSOLE = yes;
      VT_CONSOLE = yes;

      # Minimize the size, as convenient
      MODULES = no;
      CC_OPTIMIZE_FOR_PERFORMANCE = no;
      CC_OPTIMIZE_FOR_SIZE = yes;

      # -----

      # 1000 Hz is the preferred choice for desktop systems and other
      # systems requiring fast interactive responses to events.
      HZ = freeform "1000";
      HZ_1000 = yes;

      SMP = yes;

      # -----

      GOBOHIDE_FS = yes;

      # Testing with overlayfs (previously required patches)
      OVERLAY_FS = yes;
    };
    features = {
      #logo = true;
      printk = true;
      serial = true;
      vt = true;
      graphics = true;
    };
  };

  wip.stage-1.compression = lib.mkDefault "xz";
}
