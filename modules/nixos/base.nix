{
  flake.modules.nixos.base =
    { config, pkgs, ... }:
    {
      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [
          "root"
          config.primaryUser
        ];
      };

      networking.networkmanager.enable = true;
      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 22 ];
      };

      time.timeZone = "America/New_York";

      i18n.defaultLocale = "en_US.UTF-8";
      console = {
        font = "Lat2-Terminus16";
        keyMap = "us";
      };

      boot.loader.grub = {
        enable = true;
        device = "/dev/sda";
        useOSProber = true;
      };

      services.openssh = {
        enable = true;
        openFirewall = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PubkeyAuthentication = true;

          UseDns = false;
          UsePAM = true;
        };
      };

      services.avahi = {
        enable = true;
        nssmdns4 = true;
        publish.enable = true;
        publish.addresses = true;
        publish.domain = true;
      };

      # get rid of those noisy dbus/acpid errors
      services.resolved.enable = true;
      services.acpid.enable = true;

      programs.zsh.enable = true;
      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };

      system.stateVersion = "25.11";
    };
}
