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

        pname = "hosscoinbot";
        version = self.rev;
        src = ./.;

        elixir = erlPkgs.elixir;
        locales = pkgs.glibcLocales.override {
          allLocales = false; # Only en-US utf8
        };
        mixFodDeps = erlPkgs.fetchMixDeps {
          pname = "mix-deps-${pname}";
          inherit src version;
          sha256 = "2hrfG49grSJJStvSIRS/ZvIRyz2GfokObqsEz8Arg7Q=";
        };
        runtimeAppDeps = [
          locales
          pkgs.ffmpeg
        ];
        hosscoinbotRelease = erlPkgs.mixRelease {
          inherit src pname version mixFodDeps;

          nativeBuildInputs = [
            runtimeAppDeps
          ];
        };
      in
      {
        packages.hosscoinbot = hosscoinbotRelease;
        packages.hosscoinbotImage = pkgs.dockerTools.buildImage {
          name = pname;
          tag = version;

          contents = [
            runtimeAppDeps
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
            runtimeAppDeps
            elixir
            locales
          ];
        };
      });
}