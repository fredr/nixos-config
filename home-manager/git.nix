{
  config,
  host,
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.hunk.homeManagerModules.default ];

  home.packages = [ pkgs.difftastic ];

  # `hunk diff [revset]` / `hunk show [revset]` for reviewing changes
  programs.hunk = {
    enable = true;
    enableClaudeIntegration = true;
    enableJujutsuIntegration = true;
    # Note stepping ships unbound. ( and ) are free in both review and
    # history, and sit next to { and } (previous/next annotated hunk).
    settings.keybindings = {
      "hunk.review.nextNote" = ")";
      "hunk.review.previousNote" = "(";
    };
  };

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
