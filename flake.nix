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
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; })
            mkPoetryEnv
            defaultPoetryOverrides
            ;
        in
        {
          default = pkgs.mkShell {
            name = "dpu";

            packages = [
              (mkPoetryEnv {
                projectDir = ./.;
                python = pkgs.python39;
                preferWheels = true;

                overrides = defaultPoetryOverrides.extend (
                  _final: prev: {
                    # bokeh 0.10.0 and Django 1.8.x pre-date PEP 517 — they
                    # need setuptools on the build path.
                    bokeh = prev.bokeh.overridePythonAttrs (old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ prev.setuptools ];
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
            '';
          };
        }
      );
    };
}
