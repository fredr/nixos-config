{
  config,
  host,
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.difftastic ];

  home.file.".ssh/allowed_signers".text = "* ${host.pubKey}";

  programs.git = {
    enable = true;

    settings = {
      init.defaultBranch = "main";
      core.editor = "nvim";
      user = {
        name = "Fredrik Enestad";
        email = "fredrik@enestad.com";

        signingKey = host.pubKey;
      };
      alias = {
        co = "checkout";
      };
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

  programs.jujutsu = {
    enable = true;

    settings = {
      user = {
        inherit (config.programs.git.settings.user) name email;
      };
      ui.editor = "nvim";
      # Without -X less uses the alternate screen, so the terminal turns
      # trackpad scrolling into arrow keys.
      ui.pager = [
        "less"
        "-FR"
      ];
      # Uses jj's built-in merge-tools.difft args, which pass --width=$width.
      ui.diff-formatter = "difft";
      # jj rewrites commits constantly, so sign on push instead of on every
      # snapshot.
      signing = {
        behavior = "drop";
        backend = "ssh";
        key = host.pubKey;
        backends.ssh.allowed-signers = "${config.home.homeDirectory}/.ssh/allowed_signers";
      };
      git.sign-on-push = true;
    };
  };
}
