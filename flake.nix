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
        overlays = [
        (final: prev: {
          python312Packages = prev.python312Packages // {

            gradio = prev.python312Packages.gradio.overridePythonAttrs (old: {
              version = "5.9.1";
              pythonImportsCheck = [];
              dontUsePythonImportsCheck = true;
              doInstallCheck = false;
              PYTHONDONTWRITEBYTECODE = 1;

              # Pre-fetch the frpc binary
              frpcSrc = pkgs.fetchurl {
                url = "https://cdn-media.huggingface.co/frpc-gradio-0.3/frpc_linux_amd64";
                sha256 = "sha256-x5HR8Ee0H/WIV3L8S/ILeXxgWbvYKrueMd4V5V1qV8Q=";  # Replace with actual hash if this one doesn't work
              };

              postInstall = ''
                cp ${pkgs.fetchurl {
                  url = "https://cdn-media.huggingface.co/frpc-gradio-0.3/frpc_linux_amd64";
                  sha256 = "sha256-x5HR8Ee0H/WIV3L8S/ILeXxgWbvYKrueMd4V5V1qV8Q=";  # Same hash as above
                }} $out/lib/python3.12/site-packages/gradio/frpc_linux_amd64_v0.3
                chmod +x $out/lib/python3.12/site-packages/gradio/frpc_linux_amd64_v0.3
              '';

              # Skip problematic Python files during bytecode compilation
              prePatch = ''
                rm -f _frontend_code/lite/examples/transformers_basic/run.py
              '';
            });

          };
        })
        ];
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

            # Automation & Data Extraction
            python312Packages.playwright
            playwright-driver
            chromium

            # LLMs & AI Agents
            python312Packages.jupyterlab
            python312Packages.anthropic
            python312Packages.openai
            python312Packages.gradio
            python312Packages.ipywidgets
            python312Packages.ollama
            ollama
            python312Packages.transformers
            python312Packages.torch

            isort
            black
            ruff
            reuse
          ];

          env.UV_PYTHON_PREFERENCE = "only-system";
          env.UV_PYTHON = "${pkgs.python312}";
          env.PYTHONPATH="$PYTHONPATH:/home/monk3yd/drive/upwork/app";

          # TODO Add soap.nix

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
