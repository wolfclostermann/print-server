# NixOS print server

Temporary personal mirror for installing on Intel hardware. CUPS, Avahi (mDNS), Samba printer sharing, `hplip`, and WPA for **GFS IoT**.

## Install

1. Boot from the [NixOS minimal x86_64 ISO](https://nixos.org/download).
2. Partition and mount; run `nixos-generate-config --root /mnt`.
3. Replace `nixos/hosts/print-server/hardware-configuration.nix` with the generated file.
4. Create WLAN secrets on the target (not in git):

   ```bash
   sudo mkdir -p /mnt/etc/nixos/secrets
   sudo cp secrets/wlan.conf.example /mnt/etc/nixos/secrets/wlan.conf
   sudo chmod 600 /mnt/etc/nixos/secrets/wlan.conf
   # edit psk_gfs_iot=... on the installed system path
   ```

5. Install (pick one):

   **A — Local flake on USB (no `api.github.com`; use when GitHub API is blocked):**

   On a machine that has this repo:

   ```bash
   tar -czf print-server.tar.gz -C "$(dirname "$PWD")" "$(basename "$PWD")"
   # copy print-server.tar.gz to the installer USB, then on the installer:
   tar -xzf /mnt/usb/print-server.tar.gz -C /mnt
   sudo nixos-install --flake /mnt/print-server#print-server
   ```

   **B — Git clone (often works if only the API is blocked):**

   ```bash
   git clone https://github.com/wolfclostermann/print-server.git
   cd print-server
   sudo nixos-install --flake .#print-server
   ```

   **C — Remote flake (needs HTTPS to `api.github.com`):**

   ```bash
   sudo nixos-install --flake github:wolfclostermann/print-server#print-server
   ```

## Build x86_64 ISO from Apple Silicon

```bash
nix-build -E '
  let src = builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  in (import "${src}/nixos/release-combined.nix" { nixpkgs = src; }).nixos.iso_minimal.x86_64-linux
'
# ISO: ./result/iso/*.iso → dd to USB
```

## Delete when done

Remove this public repo after the box is installed and the config is copied to GFS-internal storage if needed.
