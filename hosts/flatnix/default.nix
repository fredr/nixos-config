{ ... }: {
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];


  system.stateVersion = "24.05"; # Did you read the comment?

}

