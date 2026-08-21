{
  flake.modules.darwin.macos-defaults = {
    system = {
      defaults = {
        NSGlobalDomain = {
          AppleShowAllExtensions = true; # Show file extensions
          AppleShowAllFiles = true; # Show hidden folders in finder
          InitialKeyRepeat = 15; # default 25
          KeyRepeat = 2;
        };

        dock = {
          autohide = true; # Auto-hide the Dock
          orientation = "right";
          mru-spaces = false; # Don’t “Automatically rearrange Spaces based on most recent use”
        };

        WindowManager = {
          GloballyEnabled = true; # Enable "Stage Manager"
        };
      };

      keyboard = {
        enableKeyMapping = true; # Turn on nix-darwin’s key-mapping support
      };
    };
  };
}
