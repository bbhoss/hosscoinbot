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
        depsSha256 = "TuKrscgOtsjN7aBl65lGFTSPoM/5B9H/voSDdUTnBII=";

        elixir = erlPkgs.elixir;
        locales = pkgs.glibcLocales.override {
          allLocales = false; # Only en-US utf8
        };
        mixFodDeps = erlPkgs.fetchMixDeps {
          pname = "mix-deps-${pname}";
          version = builtins.hashString "sha256" depsSha256; # FIXME: use the real hash instead of a hash of the base64-encoded string
          inherit src;
          sha256 = depsSha256;
        };
        runtimeAppDeps = [
          locales
          pkgs.ffmpeg
          pkgs.youtube-dl
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
              "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
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