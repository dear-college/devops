{
  meta = {
    nixpkgs = import <nixpkgs> {};
  };
  
  server = { name, nodes, pkgs, modulesPath, ... }:
  let
    theApp = pkgs.callPackage ../server/default.nix { };
    theFrontend = pkgs.callPackage ../server/frontend/default.nix { };
    appService = port: {
      description = "app service on port ${toString port}";

      after = [ "network.target" ];
      wantedBy = [ "default.target" ];

      environment = {
        ROOT_URL="https://dear.college/";
        PORT="${toString port}";
        REDIS_SOCKET="/run/redis-localhost/redis.sock";

        GOOGLE_CLIENT_ID="661672318050-h4oghjn212j2uo4692e91immf24qb58b.apps.googleusercontent.com";
        GOOGLE_CLIENT_SECRET=builtins.readFile ./google.key;
        GOOGLE_REDIRECT_URI="https://dear.college/login/cb";

        SYMMETRIC_KEY=./key.bin;

        FRONTEND_PATH="${theFrontend}/lib/node_modules/@dear.college/frontend/src/dist/assets";
        MARKDOWN_PATH=theApp.src;
      };

      serviceConfig = {
        ExecStart = "${theApp}/bin/dear-college";
        User = "app";
        Restart = "always";
      };
    };
  in {
    imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];
    
    deployment.targetHost = "dear.college";

    networking.hostName = "dear-college";

    nixpkgs.config.allowUnfree = true;
    environment.systemPackages = with pkgs; [
      theApp
    ];

    services.redis.servers.localhost.enable = true;

    services.nginx = {
      enable = true;

      # Use recommended settings
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
    };

    services.nginx.upstreams = {
      backend = {
        servers = {
          "localhost:${nodes.server.config.systemd.services.app1.environment.PORT}" = {};
          "localhost:${nodes.server.config.systemd.services.app2.environment.PORT}" = {};
        };
      };
    };

    services.nginx.virtualHosts."dear.college" = {
      forceSSL = true;
      enableACME = true;
      default = true;
      root = "/var/www/dear.college";
      locations = {
        "/".proxyPass = "http://backend";
      };
    };

    security.acme.acceptTerms = true;

    security.acme.certs = {
      "dear.college".email = "kisonecat@gmail.com";
    };

    systemd.services.app1 = appService 4001;
    systemd.services.app2 = appService 4002;

    # for "security" do not run the app as root
    users.extraUsers = {
      app = {
        isNormalUser = true;
        extraGroups = [ "redis-localhost" ];
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    system.stateVersion = "24.05";
  };
}


