{
  description = "tools";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
    in {
      devShells.default = pkgs.mkShell {
        name = "tools";
        buildInputs = (with pkgs; [
          ansible
        ]) ++ (with pkgs.python310Packages; [
          python
          black
          ansible-lint
        ]);
      };
    }
  );
}
