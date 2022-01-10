{
  description = "Hosscoinbot. The ultimate centralized shitcoin.";

  inputs = {
    nixpkgs = { url = "github:NixOS/nixpkgs/nixpkgs-unstable"; };
    flake-utils = { url = "github:numtide/flake-utils"; };
    flake-compat = {
      url = github:edolstra/flake-compat;
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, flake-compat }:
   flake-utils.lib.eachDefaultSystem (system:
      let
        inherit (nixpkgs.lib) optional;
        pkgs = import nixpkgs { inherit system; };
        erlPkgs = pkgs.beam.packagesWith pkgs.beam.interpreters.erlang;
        src = builtins.fetchGit {
          url = "ssh://git@github.com/bbhoss/hosscoinbot";
          rev = "0ac87ae9c9c5fe676b92d77164f1167b89047f48";
        };
        pname = "hosscoinbot";
        version = "0.0.1";

        elixir = erlPkgs.elixir;
        locales = pkgs.glibcLocales.override {
          allLocales = false; # Only en-US utf8
        };
        mixFodDeps = erlPkgs.fetchMixDeps {
          pname = "mix-deps-${pname}";
          inherit src version;
          sha256 = "2hrfG49grSJJStvSIRS/ZvIRyz2GfokObqsEz8Arg7Q=";
        };
        hosscoinbotRelease = erlPkgs.mixRelease {
          inherit src pname version mixFodDeps;

          depsBuildTarget = [
            locales
          ];
        };
      in
      {
        packages.hosscoinbot = hosscoinbotRelease;
        packages.hosscoinbotImage = pkgs.dockerTools.buildImage {
          name = pname;
          tag = version;

          contents = [
            hosscoinbotRelease
            pkgs.busybox # for debugging
          ];

          config = {
            Cmd = [
              "${hosscoinbotRelease}/bin/hosscoinbot"
              "start"
            ];
            Env = [
              "LC_ALL=en_US.UTF-8"
              "LOCALE_ARCHIVE=${locales}/lib/locale/locale-archive"
            ];
          };
        };

        defaultPackage = self.packages.${system}.hosscoinbot;

        devShell = pkgs.mkShell {
          buildInputs = [
            elixir
            locales
          ];
        };
      });
}