{ config, lib, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Etc/UTC";

  # Enable Docker service
  virtualisation.docker.enable = true;

  # Configure Docker containers
  virtualisation.oci-containers = {
    # Use Docker instead of Podmna
    backend = "docker";
    containers = {
      librewolf = {
        image = "lscr.io/linuxserver/librewolf:latest";
        ports = [ "8080:3000" "8443:3001" ];  # Map to different host ports
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "Etc/UTC";
        };
        volumes = [ "/mnt/docker/librewolf:/config" ];  # Update the path as necessary
      };

      chromium = {
        image = "lscr.io/linuxserver/chromium:latest";
        ports = [ "8081:3000" "8444:3001" ];  # Map to different host ports
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "Etc/UTC";
        };
        volumes = [ "/mnt/docker/chromium:/config" ];  # Update the path as necessary
      };
    };
  };

  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    neovim
    wget
    docker-compose
  ];

  # Networking setup (optional)
  networking.firewall.enable = false;  # Disable firewall for container access

  # System state version
  system.stateVersion = "24.05"; 
}
