{
  description = "Native-feeling web applications for NixOS using Firefox under the hood.";

  outputs = { self }: {
    homeModules.default = import ./module.nix;
  };
}
