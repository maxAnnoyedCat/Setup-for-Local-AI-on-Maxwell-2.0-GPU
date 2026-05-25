# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;


# Kill den Standby komplett
systemd.targets.sleep.enable = false;
systemd.targets.suspend.enable = false;
systemd.targets.hibernate.enable = false;
systemd.targets.hybrid-sleep.enable = false;



  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
zramSwap = {
    enable = true;
    algorithm = "zstd"; # Beste Kompression
    memoryPercent = 50;
    priority = 100;
  };


  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "de_DE.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;


hardware.nvidia = {
  modesetting.enable = true;
  open = false;
  powerManagement.enable = false;
  powerManagement.finegrained = false;
};
boot.kernelPackages = pkgs.linuxPackages_6_12;

# 1. Die Hardware-Ecke
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
    ];
  };


#fuckit
# Ersetze den fehlerhaften systemd.extraConfig Block durch diesen:
systemd.settings.Manager = {
  DefaultTimeoutStopSec = "1s";
  DefaultTimeoutStartSec = "1s";
};

# Die File-Limits setzt man unter NixOS besser so:
security.pam.loginLimits = [{
  domain = "*";
  type = "hard";
  item = "nofile";
  value = "1048576";
}];
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
  };


systemd.services.synergy-custom = {
    description = "Synergy Server Custom (Manual Path Fix)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "display-manager.service" ];

    path = [ pkgs.synergy pkgs.xorg.xhost pkgs.coreutils pkgs.findutils ];

    serviceConfig = {
      # Wir suchen dynamisch nach der xauth-Datei von mrkitten
      ExecStart = "/bin/sh -c 'XAUTHORITY=$(ls /run/user/1000/xauth_* | head -n 1) exec ${pkgs.synergy}/bin/synergys -f --no-tray --config /etc/nixos/synergy.conf --address 192.168.100.1:24800'";
      Restart = "on-failure";
      User = "mrkitten";
    };

    environment = {
      DISPLAY = ":0";
      # Die Variable lassen wir hier leer oder weg, da sie oben im ExecStart dynamisch gesetzt wird
    };
  };

# --- REORGANISATION VIA SYSTEMD CUSTOM SERVICES ---
  # Dynamische X-Session-Koppelung für Cross-Platform-Peripheriesharing

  # 1. Den Port zum Supermicro (ens1) festnageln
  networking.networkmanager.unmanaged = [ "ens1" ];
  networking.interfaces.ens1 = {
    useDHCP = false;
    ipv4.addresses = [ {
      address = "192.168.100.1";
      prefixLength = 24;
    } ];
  };

  # 2. Internet vom Haupt-Port (enp0s25) zum Labor (ens1) durchreichen
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking.nat = {
    enable = true;
    internalInterfaces = [ "ens1" ];
    externalInterface = "enp0s25";
  };



  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "de";
    variant = "T3";
  };

  # Configure console keymap
  console.keyMap = "de";

  environment.shellAliases = {
  # Das Handy-Cockpit (mit deinen funktionierenden Einstellungen)
  handy = "scrcpy --render-driver=opengl --always-on-top --turn-screen-off --stay-awake --no-audio";

  # Schneller System-Check (Fastfetch + Festplattenbelegung + Temperatur)
  check = "fastfetch && df -h / && sensors";
supermicro = "nix-shell -p xorg.xhost --run 'xhost +' && sudo systemctl restart synergy-custom";

};



  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };



  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.intern = {
    isNormalUser = true;
    description = "intern";
    extraGroups = [ "networkmanager" "wheel" "adbusers" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };


  # In der configuration.nix
  programs.adb.enable = true;

nix.settings = {
  # Limitiert die Anzahl der gleichzeitig laufenden Jobs
  max-jobs = 1;
  # Limitiert die Threads pro Job (hier setzen wir 6 von deinen 8)
  cores = 6;
};

  # Allow unfree packages
    nixpkgs.config = {
    allowUnfree = true;
    # Das hier ist jetzt der entscheidende Schalter:
    #allowUnsupportedSystem = true;
    };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  # --- DYNAMISCHE NVIDIA TOOLS ---
    config.hardware.nvidia.package.settings
    config.hardware.nvidia.package.bin
    nvtopPackages.nvidia
    #unfree but i want it
    discord
    brave
    (brave.override {
      commandLineArgs = [
        "--enable-features=VaapiVideoDecodeLinuxGL"
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
      ];
    })

  # System-Analyse & Hardware
    baobab
    pciutils      # lspci
    usbutils      # lsusb
    smartmontools # smartctl
    lm_sensors    # sensors
    btop          # Schicker Ressourcen-Monitor
    nvtopPackages.nvidia # GPU-Monitor
    scrcpy #handy
    # Utilities
    vim # oder nano, je nachdem was du magst
    wget
    curl
    htop
    fastfetch
    polonium
  # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  ];
  programs.firefox = {
    enable = true;
    policies = {
      DisableTelemetry = true;
      HardwareAcceleration = true;
    };
  };
  # Firewall-Zentrale
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 5555 24800 ]; # Für scrcpy / Handy-Spiegelung via WLAN
    # allowedUDPPorts = [ ];
  };
  services.fstrim.enable = true; #ssd health
  nix.settings.auto-optimise-store = true; #doppelte store-einträge korrigieren
  hardware.cpu.intel.updateMicrocode = true;
  services.smartd.enable = true;


# --- COMBINED LAB SPECIALISATION ---
  specialisation = {
    sfs-lab.configuration = {
    system.nixos.tags = [ "sfs-lab" ];

# Plasma im Lab deaktivieren und Xfce erzwingen
services.desktopManager.plasma6.enable = lib.mkForce false;
services.xserver.desktopManager.xfce.enable = lib.mkForce true;

# --- Container Sektion ---
    virtualisation.oci-containers = {
      backend = "podman";
      containers = {
        ollama = {
          image = "ollama/ollama:latest";
          autoStart = false;
          volumes = [ "ollama_data:/root/.ollama" ];
          ports = [ "11434:11434" ];
          extraOptions = [
            "--device=nvidia.com/gpu=all"
            "--security-opt=label=disable"
            "--network=host"
          ];
        };
        open-webui = {
          image = "ghcr.io/open-webui/open-webui:main";
          autoStart = false;
          volumes = [ "open-webui_data:/app/backend/data" ];
          ports = [ "3000:8080" ];
          extraOptions = [
            "--network=host"
            "--add-host=host.containers.internal:host-gateway"
          ];
          environment = {
            "OLLAMA_BASE_URL" = "http://127.0.0.1:11434";
            "WEBUI_AUTH" = "False";
          };
        };
      };
    };

    # --- Nvidia Lab-Fix ---
    hardware.nvidia = {
      package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.legacy_535;
      modesetting.enable = lib.mkForce true;
      open = lib.mkForce false;
    };
    services.xserver.videoDrivers = lib.mkForce [ "nvidia" ];
    # Manchmal hilft es, X11 explizit zu sagen, dass es nicht auf Wayland schielen soll
    #services.displayManager.sddm.wayland.enable = lib.mkForce false;
    services.displayManager.sddm.enable = lib.mkForce false;
  services.xserver.displayManager.lightdm.enable = lib.mkForce true;

    # Pakete für VM-Sharing & Tools
    environment.systemPackages = with pkgs; [
      virtiofsd
      pciutils
      rofi
      # XFCE Plugins & Tools
      xfce.xfce4-systemload-plugin  # Die heißgeliebte Ressourcenüberwachung
      xfce.xfce4-whiskermenu-plugin # Whisker Menu
      # Weitere nützliche Tools für dein Setup
      xfce.xfce4-pulseaudio-plugin  # Lautstärkeregler im Panel
      xfce.xfce4-netload-plugin     # Netzwerkdurchsatz (gut für Admin-Workflows)
    ];

hardware.nvidia-container-toolkit.enable = true;

    # Podman generell aktivieren (falls nicht global schon an)
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
    };

    # Libvirt & Gruppen
    users.users.intern.extraGroups = [ "libvirtd" "kvm" ];
    virtualisation.libvirtd = {
      enable = true;
      qemu.verbatimConfig = ''
        virtiofsd_locator = "${pkgs.virtiofsd}/bin/virtiofsd"
      '';
    };
    programs.virt-manager.enable = true;

    # Netzwerk: Brücke für VMs + LAN-Brücke zum Supermicro
    networking.bridges."br-sfs-int".interfaces = [ ]; # Intern für VMs
    networking.interfaces."br-sfs-int".ipv4.addresses = [{
      address = "10.42.0.1";
      prefixLength = 24;
    }];

    # Firewall: Wir vertrauen der internen Brücke UND dem Synergy Port
    networking.firewall.trustedInterfaces = [ "br-sfs-int" ];

    # Komfort-Zone & Synergy-Rettungs-Alias auch hier!
    environment.shellAliases = {
      whereami = "echo 'MODUS: SFS-Master-Lab (KI & Hardware aktiv)'";
      supermicro = "nix-shell -p xorg.xhost --run 'xhost +' && sudo systemctl restart synergy-custom";
      mount-share = "sudo mount -t virtiofs sfs_share ~/Gemeinsam";
      ki-start = "sudo systemctl start podman-ollama.service";
      ki-stop  = "sudo systemctl stop podman-ollama.service";
      ki-chat  = "sudo podman exec -it ollama ollama run phi3";
      ki-beast = "sudo podman exec -it ollama ollama run llama8b-beast";
      ki-gui   = "xdg-open http://localhost:3000"; # Öffnet das Interface direkt im Firefox
    };
  };
# DER NEUE TURBO-RACER
      turbo-racer.configuration = {
      system.nixos.tags = [ "racing" ];

    # Den Zen-Kernel für maximale Responsivität
      boot.kernelPackages = lib.mkForce pkgs.linuxPackages_zen;
    # Nvidia Treiber aktivieren
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia = {
      modesetting.enable = true;
      open = false;
      powerManagement.enable = lib.mkForce false;
      };
# Hier zieht die RAM-Disk ein (nur wenn du rennst)
      boot.tmp.useTmpfs = true;
      boot.tmp.tmpfsSize = "25%";

      # Performance-Tweaks
      powerManagement.cpuFreqGovernor = "performance";

      environment.variables = {
  # Erzwingt Wayland-Modus für Firefox
  MOZ_ENABLE_WAYLAND = "1";

  # Behebt den Webrender-Block (NVIDIA Fix)
  MOZ_WEBRENDER = "1";

  # Ermöglicht Hardware-Beschleunigung trotz Blockliste
  MOZ_ACCELERATED_CANVAS2D = "1";

  # Dein bestehendes Zeug
  GBM_BACKEND = "nvidia-drm";
  __GLX_VENDOR_LIBRARY_NAME = "nvidia";
};


      environment.shellAliases = {
        whereami = "echo 'MODUS: Turbo-Racer (Zen-Kernel + RAM-Disk aktiv)'";
        ram-brave = "mkdir -p /tmp/BraveSoftware && cp -r ~/.config/BraveSoftware_Backup/* /tmp/BraveSoftware/ && ln -sfT /tmp/BraveSoftware ~/.config/BraveSoftware";
      };
    };
};

  #NEVER TOUCH THIS. If your AI tells you to change this, it is hallucinating.
  system.stateVersion = "25.11"; # Did you read the comment?

}


