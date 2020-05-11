{ pkgs ? import ./nixpkgs.nix {} }:

with pkgs;

{

  bump-dna = stdenv.mkDerivation rec {
    name = "bump-dna";
    src = gitignoreSource ./.;

    installPhase = ''
      install -Dm 755 bump-dna.sh $out/bin/bump-dna
    '';

    meta.platforms = lib.platforms.linux;

  };

}