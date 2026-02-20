{
  outputs = { self }: {
    homeModules.default = import ./module.nix;
  };
}
