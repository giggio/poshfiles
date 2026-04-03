{
  description = "Powershell configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
      devShells = {
        ${system}.default = pkgs.mkShell {
          name = "PowerShell environment";
          buildInputs = with pkgs; [
            powershell-editor-services # Common platform for PowerShell development support in any editor or application https://github.com/PowerShell/PowerShellEditorServices
          ];
          shellHook = ''
            echo "Welcome to PowerShell!"
          '';
        };
      };
    };
}
