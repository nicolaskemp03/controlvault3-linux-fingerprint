# Standalone Nix expression — use with callPackage or import from tarball.
# See README-nix.md for usage instructions.
{
  lib,
  stdenv,
  pkg-config,
  libfprint-tod,
  openssl,
  glib,
  gusb,
}:

stdenv.mkDerivation {
  pname = "libfprint-2-tod1-cvfp";
  version = "0-unstable-2026-09-20";

  src = lib.cleanSource ./driver;

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    libfprint-tod
    openssl
    glib
    gusb
  ];

  buildPhase = ''
    runHook preBuild
    gcc -shared -fPIC cvfp-tod.c -o libfprint-2-tod-1-cvfp.so \
      $(pkg-config --cflags --libs libfprint-2-tod-1 libfprint-2) \
      $(pkg-config --cflags --libs glib-2.0 gobject-2.0 gusb) \
      -lcrypto
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 libfprint-2-tod-1-cvfp.so -t "$out/lib/libfprint-2/tod-1/"
    runHook postInstall
  '';

  # Required by the NixOS fprintd module (services.fprintd.tod.driver):
  #   FP_TOD_DRIVERS_DIR = "${cfg.tod.driver}${cfg.tod.driver.driverPath}";
  passthru.driverPath = "/lib/libfprint-2/tod-1";

  meta = with lib; {
    description = "ControlVault 3 (BCM58200, 0a5c:5843) TOD driver for libfprint — open-source, keyless";
    homepage = "https://github.com/nicolaskemp03/controlvault3-linux-fingerprint";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}
