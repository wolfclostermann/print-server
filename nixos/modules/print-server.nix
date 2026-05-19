# Reusable module: CUPS + Avahi (Bonjour/mDNS) + Samba printer sharing.
{ config, lib, pkgs, ... }:

let
  cfg = config.services.lanPrintServer;
in
{
  options.services.lanPrintServer = {
    enable = lib.mkEnableOption "LAN print server (CUPS, Avahi/mDNS, Samba)";

    hostName = lib.mkOption {
      type = lib.types.str;
      default = "print-server";
      description = "Short DNS hostname for this machine.";
    };

    workgroup = lib.mkOption {
      type = lib.types.str;
      default = "WORKGROUP";
      description = "SMB workgroup advertised to Windows clients.";
    };

    lanSubnets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "127.0.0.0/8"
        "::1/128"
        "192.168.0.0/16"
        "10.0.0.0/8"
        "172.16.0.0/12"
      ];
      description = ''
        CUPS `Allow` subnets for IPP/HTTP admin. Narrow this to your site
        (e.g. `[ "192.168.1.0/24" ]`) instead of RFC1918 defaults.
      '';
    };

    cupsListenWildcard = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        If true, CUPS listens on all interfaces (`*:631`) so AirPrint/IPP
        clients on the LAN can reach queues. Set false to bind only to
        localhost and rely on another path (SSH tunnel, reverse proxy).
      '';
    };

    enableIppUsb = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Discover USB printers that speak IPP-over-USB (many recent devices).";
    };

    extraPrinterDrivers = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional CUPS driver packages (vendor PPDs, etc.).";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.hostName = cfg.hostName;

    # --- CUPS (IPP, AirPrint-style driverless, web UI) ---
    services.printing = {
      enable = true;
      webInterface = true;
      drivers = with pkgs;
        [
          cups-filters
          cups-browsed
          gutenprint
        ]
        ++ cfg.extraPrinterDrivers;
      browsing = true;
      defaultShared = true;
      listenAddresses = if cfg.cupsListenWildcard then [ "*:631" ] else [ "127.0.0.1:631" ];
      allowFrom = cfg.lanSubnets ++ [
        "127.0.0.1"
        "::1"
      ];
      openFirewall = cfg.cupsListenWildcard;
    };

    # --- Avahi (Bonjour / mDNS: discover printers & advertise SMB) ---
    services.avahi = {
      enable = true;
      openFirewall = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        userServices = true;
        addresses = true;
      };
    };

    # --- Samba: SMB access to CUPS queues (`Windows Printer` style sharing) ---
    # Full Samba build includes CUPS integration and can register mDNS where supported.
    services.samba = {
      enable = true;
      package = pkgs.samba4Full;
      openFirewall = true;
      settings = {
        global = {
          workgroup = cfg.workgroup;
          "server string" = "NixOS print server";
          "load printers" = "yes";
          printing = "cups";
          "printcap name" = "cups";
        };
        printers = {
          comment = "CUPS printers via Samba";
          path = "/var/spool/samba";
          public = "yes";
          browseable = "yes";
          "guest ok" = "yes";
          writable = "no";
          printable = "yes";
          "create mode" = "0700";
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/spool/samba 1777 root root -"
    ];

    # Windows 10+ network discovery without legacy WINS.
    services.samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

    services.ipp-usb.enable = cfg.enableIppUsb;

    # Helpful on a headless box for `lpadmin`, `hp-setup`, etc.
    environment.systemPackages = with pkgs; [
      cups
      system-config-printer
    ];
  };
}
