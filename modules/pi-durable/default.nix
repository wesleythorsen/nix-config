{
  # Pi Durable is an SDK, not a CLI: `nix develop .#pi-durable` gives Node >= 22.19
  # and a starter project lives in ./_starter (copy it somewhere and `npm ci`).
  perSystem =
    { pkgs, ... }:
    {
      devShells.pi-durable = pkgs.mkShell {
        packages = with pkgs; [
          nodejs_24
          typescript
        ];
        shellHook = ''
          echo "pi-durable dev shell: node $(node --version)"
          echo "starter: ${toString ./_starter}  (cp -r it, then: npm ci && npm start)"
        '';
      };
    };
}
