{ ... }: {
  environment.etc."machine-id".source = "/persist/etc/machine-id";
  #environment.etc."ssh/".source = "/persist/etc/ssh";
}
