{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
  };

  outputs = { self, nixpkgs, devenv, ... } @ inputs:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
        inherit system;
        config = {
            allowUnfree = true;
        };
    };
  in
  {

    devShell.${system} = devenv.lib.mkShell {
      inherit inputs pkgs;

      modules = [
        ({ pkgs, config, ...}:
        {
          languages.python = {
            enable = true;
            venv.enable = true;
            # venv.requirements = ''
            #     debugpy                
            #     pyright
            # '';
            uv = {
                enable = true;
                package = pkgs.uv;
                sync.enable = true;
            };
          };

          packages = with pkgs; [
            # pulumi
            # pulumiPackages.pulumi-language-go

            python312Packages.playwright
            playwright-driver
            chromium

            python312Packages.jupyterlab
            python312Packages.anthropic
            python312Packages.openai
            ollama

            isort
            black
            ruff
            reuse
          ];

          env.UV_PYTHON_PREFERENCE = "only-system";
          env.UV_PYTHON = "${pkgs.python312}";
          env.PYTHONPATH="$PYTHONPATH:/home/monk3yd/drive/upwork/app";


          env.PLAYWRIGHT_PYTHON_PATH = "${pkgs.python312}/bin/python3";
          env.PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = true;
          # env.PLAYWRIGHT_BROWSERS_PATH="${pkgs.chromium}/bin/chromium";
          env.PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}";

          # Add any missing library pkg to PATH
          env.LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            pkgs.zlib
            pkgs.glib
            pkgs.xorg.libX11
            pkgs.stdenv.cc.cc
            pkgs.libuv
          ];

          # Before git commit
          pre-commit.hooks = {
            isort.enable = true;
            # black.enable = true;
            # ruff = {
            #   enable = true;
            #   # entry = pkgs.lib.mkForce "${pkgs.ruff}/bin/ruff --fix --ignore=E501";
            # };
          };

          enterShell = ''
            # rm -rf .devenv && echo " * Deleted previous .venv"
            uv venv -p ${pkgs.python312} -v
            source .devenv/bin/activate
          '';
        })
      ];
    };
  };
}
