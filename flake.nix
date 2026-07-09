{
  description = "eVOLVER DPU — data processing and experiment control module";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            name = "evolver-dpu";
            packages = [
              pkgs.python3
              pkgs.poetry
            ];
            shellHook = ''
              echo "evolver-dpu dev shell"
              echo ""
              echo "First run:   poetry install"
              echo "Run DPU:     poetry run python experiment/template/eVOLVER.py"
              echo "Calibrate:   poetry run python calibration/calibrate.py --help"
            '';
          };
        }
      );

      # DPU uses ancient Python deps (Django 1.8.6, bokeh 0.10.0) unavailable in
      # modern nixpkgs; poetry manages the exact virtualenv.
      # ponytail: no package derivation — add when deps are updated or poetry2nix lands cleanly
      apps = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          run-dpu = pkgs.writeShellApplication {
            name = "run-dpu";
            runtimeInputs = [
              pkgs.poetry
              pkgs.python3
            ];
            text = ''
              set -euo pipefail
              if [ ! -f pyproject.toml ]; then
                echo "ERROR: run from the evolver-dpu repo root (has pyproject.toml)"
                exit 1
              fi
              poetry install --quiet
              exec poetry run python experiment/template/eVOLVER.py "$@"
            '';
          };
          run-calibration = pkgs.writeShellApplication {
            name = "run-calibration";
            runtimeInputs = [
              pkgs.poetry
              pkgs.python3
            ];
            text = ''
              set -euo pipefail
              if [ ! -f pyproject.toml ]; then
                echo "ERROR: run from the evolver-dpu repo root"
                exit 1
              fi
              poetry install --quiet
              exec poetry run python calibration/calibrate.py "$@"
            '';
          };
        in
        {
          "run-dpu" = {
            type = "app";
            program = "${run-dpu}/bin/run-dpu";
          };
          "run-calibration" = {
            type = "app";
            program = "${run-calibration}/bin/run-calibration";
          };
          default = {
            type = "app";
            program = "${run-dpu}/bin/run-dpu";
          };
        }
      );
    };
}
