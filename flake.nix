{
  description = "eVOLVER DPU — Python 3.9 environment for experiment scripts and calibration tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, poetry2nix }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # nixpkgs 26.05: python311Packages.pip-25.3 has sphinx-9.1.0 in
      # nativeBuildInputs, but sphinx-9.1 requires Python >=3.12 — replace
      # sphinx with a no-op stub so pip's doc-build step doesn't block the
      # python3.11 environment from evaluating and building.
      mkPkgs =
        system:
        let
          base = nixpkgs.legacyPackages.${system};
          # pip's postBuild runs: sphinx-build ... man build/man
          # Then postInstall does: installManPage docs/build/man/*
          # The stub creates the output dir and a placeholder man page so
          # nixpkgs can produce the 'man' output without real sphinx-9.1.0.
          sphinxStub = base.writeShellScriptBin "sphinx-build" ''
            out_dir="''${@: -1}"
            mkdir -p "$out_dir"
            touch "$out_dir/pip.1"
          '';
        in
        import nixpkgs {
          inherit system;
          overlays = [
            (_self: super: {
              python311 = super.python311.override {
                packageOverrides = _pyself: pysuper: {
                  pip = pysuper.pip.overridePythonAttrs (old: {
                    nativeBuildInputs =
                      (builtins.filter
                        (p: (p.pname or p.name or "") != "sphinx" && (p.pname or p.name or "") != "sphinx-issues")
                        (old.nativeBuildInputs or [ ]))
                      ++ [ sphinxStub ];
                  });
                };
              };
            })
          ];
        };
    in
    {
      # Critical Python check — run with: nix flake check
      # The upstream DPU codebase is legacy Python with many historical style
      # violations. Keep the flake check focused on parse errors and serious
      # pyflakes failures so it stays useful on modern nixpkgs.
      checks = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
          lintPython =
            if pkgs ? python36 then pkgs.python36
            else if pkgs ? python39 then pkgs.python39
            else pkgs.python311;
        in
        {
          lint = pkgs.runCommand "flake8-lint" {
            nativeBuildInputs = [ (lintPython.withPackages (ps: [ ps.flake8 ])) ];
            src = ./.;
          } ''
            flake8 --select=E9,F63,F7,F82 --ignore=F824 --exclude=$src/evolver/socketIO_client \
              $src/calibration $src/experiment $src/graphing
            touch $out
          '';
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
          inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; })
            mkPoetryEnv
            defaultPoetryOverrides
            ;
        in
        {
          default = pkgs.mkShell {
            name = "dpu";

            packages = [
              # Target: Python 3.6. python36 removed from nixpkgs >= 23.05; python39 removed
              # from nixpkgs >= 25.05. Pin nixpkgs to 22.11 or use an overlay for the exact
              # interpreter. python39 is kept as an intermediate fallback where available.
              (mkPoetryEnv {
                projectDir = ./.;
                python =
                  if pkgs ? python36 then pkgs.python36
                  else if pkgs ? python39 then pkgs.python39
                  else pkgs.python311;
                preferWheels = true;

                overrides = defaultPoetryOverrides.extend (
                  _final: prev: {
                    # bokeh 0.10.0 pre-dates PEP 517 — needs setuptools.
                    # Its setup.py calls getsitepackages()[0] which throws
                    # IndexError in the Nix sandbox (empty list); patch it.
                    bokeh = prev.bokeh.overridePythonAttrs (old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ prev.setuptools ];
                      postPatch = ''
                        substituteInPlace setup.py \
                          --replace 'getsitepackages()[0]' "(getsitepackages() or ['/tmp'])[0]"
                      '';
                    });
                    django = prev.django.overridePythonAttrs (old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ prev.setuptools ];
                    });
                    django-crispy-forms = prev.django-crispy-forms.overridePythonAttrs (old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ prev.setuptools ];
                    });
                    # socketIO-client 0.7.2 is a legacy package needing setuptools
                    socketio-client = prev.socketio-client.overridePythonAttrs (old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ prev.setuptools ];
                    });
                    jinja2 = prev.jinja2.overridePythonAttrs (old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ prev.setuptools ];
                    });
                    # nixpkgs 26.05 + python3.11: build and pyproject-hooks
                    # no longer accept 'tomli' (moved into stdlib as tomllib);
                    # bypass the broken poetry2nix defaultPoetryOverrides entries.
                    build = pkgs.python311Packages.build;
                    pyproject-hooks = pkgs.python311Packages."pyproject-hooks";
                  }
                );
              })
            ];

            shellHook = ''
              echo "DPU dev shell — $(python --version)"
              echo ""
              echo "  Calibration:  python calibration/calibrate.py --help"
              echo "  Server test:  python experiment/server_test.py"
              echo "  Graphing app: cd graphing/src && python manage.py runserver"
              echo "  Check:        flake8 --select=E9,F63,F7,F82 --ignore=F824 calibration/ experiment/ graphing/"
            '';
          };
        }
      );
    };
}
