# PLACEHOLDER — replace with output of:
#   sudo nixos-generate-config --show-hardware-config
# or after install from the live ISO:
#   sudo nixos-generate-config --root /mnt
#
# Without real disk / bootloader / kernel modules, `nixos-rebuild` cannot
# produce a bootable system. This stub exists so the flake evaluates in CI
# only if you override fileSystems; for a real machine, overwrite this file.

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
