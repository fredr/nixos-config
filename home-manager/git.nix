{ config, host, ... }:
{
  home.file.".ssh/allowed_signers".text = "* ${host.pubKey}";

  programs.git = {
    enable = true;
    userName = "Fredrik Enestad";
    userEmail = "fredrik@enestad.com";

    aliases = {
      co = "checkout";
    };

    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "nvim";
      user.signingKey = host.pubKey;
      push = {
        default = "simple";
        autoSetupRemote = true;
      };
      pull.ff = "only";
      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = "${config.home.homeDirectory}/.ssh/allowed_signers";
      commit.gpgsign = true;
      tag.gpgsign = true;
    };
  };

}
