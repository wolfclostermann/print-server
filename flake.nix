{
  description = "NixOS configuration for a LAN print server (CUPS, Avahi, Samba)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      nixosModules.print-server = import ./nixos/modules/print-server.nix;

      nixosConfigurations.print-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./nixos/hosts/print-server
        ];
      };

      # Convenience: `nix flake check` / dev shells per arch
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            nixos-rebuild
          ];
        };
      });
    };
}
