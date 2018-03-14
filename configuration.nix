# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
let
  secrets = import ./secrets.nix;
  mozillapkgs = import ./overlays/nixpkgs-mozilla/.nix { inherit pkgs; };
in {
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
    #overlays = [
    #  (import ./overlays/nixpkgs-mozilla/firefox-overlay.nix)
    #];
  };

  imports =
    [
      ./hardware-configuration.nix
      ./packages
      ./packages/services.nix
    ];

  boot = {
    # Busted sometime
    # initrd.preDeviceCommands = "cat ${pkgs.motd-massive}";
    kernelParams = [ "acpi_rev_override=5" ];
    kernel.sysctl = {
      "net.ipv6.conf.all.use_tempaddr" = 2;
    };
    # kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking.hostName = "Morbo"; # Define your hostname.
  networking.networkmanager.enable = true;
  networking.extraHosts = ''
    # 127.0.0.1 www.facebook.com facebook.com
  '';

  hardware = {
    pulseaudio.enable = true;
    mcelog.enable = true;
    bumblebee.enable = true;
    bluetooth.enable = true;
  };

  i18n = {
    consoleFont = "latarcyrheb-sun32";
    consoleKeyMap = "dvorak";
  };

  time.timeZone = "America/New_York";
  security.pam.services.lightdm.enableKwallet = true;
  security.pam.services.sddm.enableKwallet = true;

  environment = {
    systemPackages = with pkgs; [
      git
      terminator
      file
      gnupg
      gitAndTools.hub
      spotify
      firefox
      google-chrome
      xclip
      enpass
      custom-emacs
      ripgrep
      nixpkgs-maintainer-tools
      #latest.firefox-nightly-bin

     ];

    etc."i3/config".source = pkgs.i3config;
    variables = {
      GDK_SCALE = "2.5";
    };
  };


  powerManagement.cpuFreqGovernor = "powersave";

  services = {
    openssh = {
      enable = true;
    };

    redshift = {
      enable = true;
      latitude = secrets.latitude;
      longitude = secrets.longitude;
      temperature.night = 3400;
    };

    xserver = {
      enable = true;
      autorun = true;
      layout = "dvorak";
      libinput = {
        enable = true;
        naturalScrolling = true;
        disableWhileTyping = true;
      };

      displayManager.sddm.enable = true;
      #displayManager.lightdm.enable = true;
      desktopManager.plasma5.enable = true;
      windowManager.i3 = {
        enable = true;
        configFile = "/etc/i3/config";
      };

      inputClassSections = [
        ''
          Identifier "libinput touchscreen catchall"
          MatchIsTouchscreen "on"
          MatchDevicePath "/dev/input/event*"
          Driver "libinput"
          Option "DisableWhileTyping" "true"
        ''
      ];

      monitorSection = ''
        DisplaySize 406 228
      '';
    };
  };

  fonts = {
    enableFontDir = true;
    fonts = with pkgs; [
      unifont
      ttf_bitstream_vera
      noto-fonts
      noto-fonts-emoji
      fira
      fira-mono
      fira-code
    ];
  };

  programs = {
    zsh.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  virtualisation.virtualbox.host.enable = true;

  users.extraUsers.grahamc = rec {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "pcscd" "networkmanager" ];
    createHome = true;
    home = "/home/grahamc";
    shell = "/run/current-system/sw/bin/zsh";
    hashedPassword = secrets.hashedPassword;
    symlinks = {
      ".mbsyncrc" = pkgs.email.mbsyncrc;
      ".msmtprc" = pkgs.email.msmtprc;
      ".notmuch-config" = pkgs.email.notmuch-config;
      ".gitconfig" = pkgs.gitconfig;
      ".gnupg/gpg.conf" = pkgs.gnupgconfig.gpgconf;
      ".gnupg/scdaemon.conf" = pkgs.gnupgconfig.scdaemonconf;
      ".mail/grahamc/.notmuch/hooks/pre-new" = pkgs.email.pre-new;
      ".mail/grahamc/.notmuch/hooks/post-new" = pkgs.email.post-new;
      ".mozilla/native-messaging-hosts/passff.json" = "${pkgs.passff-host}/share/passff-host/passff.json";
    } // (if (builtins.pathExists "${home}/projects/nixpkgs") then {
      "projects/nixpkgs/.git/hooks/pre-push" = pkgs.nixpkgs-pre-push;
    } else {});
  };

  nix = {
    useSandbox = true;
    distributedBuilds = true;
    buildMachines = secrets.buildMachines;
  };

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "16.09";


    systemd.user.services.keybase = {
      description = "Keybase service";
      serviceConfig = {
        ExecStart = ''
          ${pkgs.keybase}/bin/keybase -d service --auto-forked
        '';
        Restart = "on-failure";
        PrivateTmp = true;
      };
      wantedBy = [ "default.target" ];
};
}
