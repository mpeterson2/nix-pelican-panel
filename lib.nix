{ stdenv, greeting }:

stdenv.mkDerivation rec {
  name = "pelican-panel";
  version = "1.0";

  src = ./.;

  nativeBuildInputs = [ ];
  buildInputs = [ ];

  buildPhase = ''
    cat > program.c <<EOF
    #include <stdio.h>

    int main() {
       printf("Hello, ${greeting}!\\n");
       return 0;
    }
    EOF

    gcc program.c -o ${name}
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp ${name} $out/bin
  '';

  meta = {
    description = "Host Pelican Panel";
    platform = stdenv.lib.platforms.unix;
  };
}
