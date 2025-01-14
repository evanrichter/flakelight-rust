# flakelight-rust -- Rust module for flakelight
# Copyright (C) 2023 Archit Gupta <archit@accelbread.com>
# SPDX-License-Identifier: MIT

{ lib, src, ... }:
let
  inherit (builtins) readFile;
  inherit (lib) mkDefault;

  cargoToml = fromTOML (readFile (src + /Cargo.toml));
  tomlPackage = cargoToml.package or cargoToml.workspace.package;
in
{
  withOverlays = _: { inputs', ... }: rec {
    craneLib = inputs'.crane.lib;
    cargoArtifacts = craneLib.buildDepsOnly { inherit src; };
  };

  description = tomlPackage.description;

  # license will need to be set if Cargo license is a complex expression
  license = mkDefault tomlPackage.license;

  package = { craneLib, cargoArtifacts, defaultMeta }:
    craneLib.buildPackage {
      inherit src cargoArtifacts;
      doCheck = false;
      meta = defaultMeta;
    };

  devShell = {
    packages = pkgs: with pkgs; [ rust-analyzer cargo clippy rustc rustfmt ];

    env = { rustPlatform, ... }: {
      RUST_SRC_PATH = "${rustPlatform.rustLibSrc}";
    };
  };

  checks = { craneLib, cargoArtifacts, ... }: {
    test = craneLib.cargoTest { inherit src cargoArtifacts; };
    clippy = craneLib.cargoClippy {
      inherit src cargoArtifacts;
      cargoClippyExtraArgs = "--all-targets -- --deny warnings";
    };
  };

  formatters."*.rs" = "rustfmt";
}
