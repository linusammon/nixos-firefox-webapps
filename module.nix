{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.firefox-webapps;

  mkSafeName = name: builtins.replaceStrings [ " " ] [ "_" ] (lib.toLower name);

  webAppType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Name of the web application";
      };
      url = lib.mkOption {
        type = lib.types.str;
        description = "URL to launch the application with";
      };
      icon = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to icon file";
      };
      comment = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Desktop entry description";
      };
      categories = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Desktop entry categories";
      };
      profilePrefs = lib.mkOption {
        type = lib.types.lines;
        default = ''
          user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
          user_pref("browser.cache.disk.enable", false);
          user_pref("browser.cache.memory.enable", true);
          user_pref("media.videocontrols.picture-in-picture.video-toggle.enabled", false);
          user_pref("browser.urlbar.autocomplete.enabled", false);
          user_pref("places.history.enabled", false);
          user_pref("geo.enabled", false);
          user_pref("browser.crashReports.enabled", false);
          user_pref("dom.push.enabled", false);
          user_pref("dom.webnotifications.enabled", false);
          user_pref("extensions.enabled", false);
          user_pref("extensions.pocket.enabled", false);
          user_pref("extensions.formautofill.enabled", false);
          user_pref("app.update.auto", false);
          user_pref("app.update.enabled", false);
          user_pref("app.update.silent", true);
          user_pref("signon.rememberSignons", false);
          user_pref("privacy.sanitize.sanitizeOnShutdown", true);
          user_pref("privacy.sanitize.timeSpan", 0);
          user_pref("privacy.clearOnShutdown.cookies", false);
          user_pref("privacy.clearOnShutdown.history", true);
          user_pref("privacy.clearOnShutdown.cache", true);
          user_pref("privacy.clearOnShutdown.sessions", true);
          user_pref("privacy.clearOnShutdown.offlineApps", true);
          user_pref("privacy.clearOnShutdown.formdata", true);
        '';
        description = "Additional Firefox preferences";
      };
      userChrome = lib.mkOption {
        type = lib.types.lines;
        default = ''
          #TabsToolbar, #identity-box, #tabbrowser-tabs, #TabsToolbar { display: none !important; }
          #nav-bar { visibility: collapse !important; }
          #titlebar { display: none !important; }
        '';
        description = "Custom userChrome.css content";
      };
    };
  };
in
{
  options.programs.firefox-webapps = {
    enable = lib.mkEnableOption "Firefox web applications as desktop apps";

    webApps = lib.mkOption {
      type = lib.types.listOf webAppType;
      default = [ ];
      description = "List of web applications to create desktop entries for";
      example = lib.literalExpression ''
        [
          {
            name = "GitHub";
            url = "https://github.com";
            icon = ./icons/github.png;
          }
        ]
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = map (
      app:
      let
        safeName = mkSafeName app.name;
      in
      pkgs.makeDesktopItem {
        name = safeName;
        inherit (app) comment;
        desktopName = app.name;
        exec = "${pkgs.firefox}/bin/firefox --profile .mozilla/firefox-webapps/${safeName} --name ${app.name} ${app.url}";
        terminal = false;
        type = "Application";
        icon = if app.icon != null then app.icon else "firefox";
        startupWMClass = "${safeName}-webapp";
      }
    ) cfg.webApps;

    home.file = builtins.listToAttrs (
      builtins.concatMap (
        app:
        let
          safeName = mkSafeName app.name;
        in
        [
          {
            name = ".mozilla/firefox-webapps/${safeName}/user.js";
            value = {
              text = app.profilePrefs;
            };
          }
          {
            name = ".mozilla/firefox-webapps/${safeName}/chrome/userChrome.css";
            value = {
              text = app.userChrome;
            };
          }
        ]
      ) cfg.webApps
    );

    home.activation.cleanupFirefoxWebappProfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      firefoxProfilesDir="$HOME/.mozilla/firefox-webapps"
      keepDirs="${lib.strings.concatStringsSep " " (map (app: app.name) cfg.webApps)}"

      if [ -d "$firefoxProfilesDir" ]; then
        for profile in "$firefoxProfilesDir"/*; do
          if [ -d "$profile" ]; then
            profileName=$(basename "$profile")
            if [[ ! " $keepDirs " =~ " $profileName " ]]; then
              rm -rf "$profile"
            fi
          fi
        done
      fi
    '';
  };
}
