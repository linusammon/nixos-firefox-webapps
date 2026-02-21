![nixos-firefox-webapps](https://socialify.git.ci/linusammon/nixos-firefox-webapps/image?description=1&language=1&logo=https%3A%2F%2Fraw.githubusercontent.com%2FNixOS%2Fnixos-artwork%2F9d2cdedd73d64a068214482902adea3d02783ba8%2Flogo%2Fnix-snowflake-colours.svg&name=1&owner=1&pattern=Transparent&theme=Auto)


## Usage

### In your flake.nix

```nix
{
  inputs = {
    firefox-webapps.url = "github:linusammon/nixos-firefox-webapps";
  };
}
```

### In your home-manager configuration

```nix
{ inputs, ... }:
{
  imports = [ inputs.firefox-webapps.homeModules.default ];

  programs.firefox-webapps = {
    enable = true;
    webApps = [
      {
        name = "Notion";
        url = "https://notion.so";
        icon = ./icons/notion.png;
        comment = "Workspace for notes and projects";
        categories = [ "Office" ];
      }
    ];
  };
}
```
