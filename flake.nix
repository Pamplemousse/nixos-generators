{
  description = "nixos-generators - one config, multiple formats";

  outputs = { self, nixpkgs }: let
    forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "x86_64-darwin" "i686-linux" "aarch64-linux" ];
  in {
    # Packages
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages."${system}";
    in {
      nixos-generators = pkgs.stdenv.mkDerivation {
        name = "nixos-generators";
        src = ./.;
        meta.description = "Collection of image builders";
        nativeBuildInputs = with pkgs; [ makeWrapper ];
        installFlags = [ "PREFIX=$(out)" ];
        postFixup = ''
          wrapProgram $out/bin/nixos-generate \
            --prefix PATH : ${pkgs.lib.makeBinPath (with pkgs; [ jq coreutils findutils ])}
        '';
      };

      # Currently, you need to mark your configurations with makeOverridable in
      # order to use nixos-generate on them.
      nixosConfigurations.example = nixpkgs.lib.makeOverridable nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./configuration.nix
        ];
      };
    });
    defaultPackage = forAllSystems (system: self.packages."${system}".nixos-generators);

    devShell = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages."${system}";
    in pkgs.mkShell {
      buildInputs = with pkgs; [ jq coreutils findutils ];
    });

    # Make it runnable with `nix app`
    apps = forAllSystems (system: {
      nixos-generate = {
        type    = "app";
        program = "${self.packages."${system}".nixos-generators}/bin/nixos-generate";
      };
    });
    defaultApp = forAllSystems (system: self.apps."${system}".nixos-generate);
  };
}
