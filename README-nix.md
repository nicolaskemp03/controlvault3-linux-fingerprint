# NixOS packaging

This project ships a Nix package for the libfprint TOD driver so you can
plug it straight into `services.fprintd.tod.driver` in your NixOS configuration.

There are two ways to import it — pick whichever fits your setup.

---

## Option A — Flakes (recommended)

### 1. Add the flake input

In your NixOS `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    controlvault3-fp = {
      url = "github:nicolaskemp03/controlvault3-linux-fingerprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, controlvault3-fp, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        {
          services.fprintd = {
            enable = true;
            tod = {
              enable = true;
              driver = controlvault3-fp.packages.x86_64-linux.default;
            };
          };
        }
      ];
    };
  };
}
```

### 2. Rebuild

```bash
sudo nixos-rebuild switch --flake .
fprintd-enroll   # touch ~12×
fprintd-verify   # tap once
```

---

## Option B — Import tarball (no flakes)

### 1. Fetch and call the package

In your `configuration.nix` (or wherever you define extra packages):

```nix
{ config, pkgs, ... }:

let
  controlvault3-fp-src = builtins.fetchTarball {
    url = "https://github.com/nicolaskemp03/controlvault3-linux-fingerprint/archive/main.tar.gz";
    # pin a sha256 for reproducibility (nix-prefetch-url --unpack <url>):
    # sha256 = "0000000000000000000000000000000000000000000000000000";
  };

  libfprint-2-tod1-cvfp = pkgs.callPackage "${controlvault3-fp-src}/default.nix" { };
in
{
  services.fprintd = {
    enable = true;
    tod = {
      enable = true;
      driver = libfprint-2-tod1-cvfp;
    };
  };
}
```

### 2. Rebuild

```bash
sudo nixos-rebuild switch
fprintd-enroll
fprintd-verify
```

> **Tip:** to pin the tarball hash and avoid re-downloading on every rebuild, run:
> ```bash
> nix-prefetch-url --unpack \
>   https://github.com/nicolaskemp03/controlvault3-linux-fingerprint/archive/main.tar.gz
> ```
> and paste the resulting hash into the `sha256` field above.

---

## Building standalone (for testing)

```bash
# without flakes
nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'
ls result/lib/libfprint-2/tod-1/

# with flakes
nix build .#
ls result/lib/libfprint-2/tod-1/
```

## How it works

The NixOS `services.fprintd.tod` module sets the environment variable
`FP_TOD_DRIVERS_DIR` to `"${cfg.tod.driver}${cfg.tod.driver.driverPath}"`.
This package provides:

- The compiled `libfprint-2-tod-1-cvfp.so` at `$out/lib/libfprint-2/tod-1/`
- The `passthru.driverPath = "/lib/libfprint-2/tod-1"` attribute the module expects

When `fprintd-tod` starts, it scans that directory and loads the driver — the
ControlVault 3 sensor (`0a5c:5843`) then shows up as a first-class fprintd device.
