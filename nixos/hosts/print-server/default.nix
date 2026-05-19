# Example host: import into your flake or copy pieces into /etc/nixos/configuration.nix
{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/print-server.nix
    ./hardware-configuration.nix
  ];

  # Replace with your disk layout from `nixos-generate-config --root /mnt`
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  services.lanPrintServer = {
    enable = true;
    hostName = "print-server";
    workgroup = "WORKGROUP";
    extraPrinterDrivers = with pkgs; [ hplip ];
    # cupsListenWildcard = false; # stricter: only local CUPS, no exposed 631
    # lanSubnets = [ "192.168.1.0/24" ]; # tighten CUPS Allow
  };

  networking.networkmanager.enable = lib.mkDefault false;
  networking.firewall.enable = lib.mkDefault true;

  # WPA via wpa_supplicant; PSK lives outside the Nix store (not in git).
  # On the target host: copy secrets/wlan.conf.example → /etc/nixos/secrets/wlan.conf
  networking.wireless.enable = true;
  networking.wireless.secretsFile = "/etc/nixos/secrets/wlan.conf";
  networking.wireless.networks."GFS IoT" = {
    pskRaw = "ext:psk_gfs_iot";
  };

  # Optional: sync clocks for TLS / logging sanity
  services.timesyncd.enable = lib.mkDefault true;

  system.stateVersion = lib.mkDefault "25.05";
}
