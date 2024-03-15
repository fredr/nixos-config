{ ... }: {
  programs.git = {
    enable = true;
    userName = "fredr";
    userEmail = "fredrik@enestad.com";

    extraConfig = {
      init.defaultBranch = "main";
    };
  };

}
