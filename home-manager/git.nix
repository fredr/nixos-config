{
  config,
  host,
  inputs,
  pkgs,
  ...
}:
let
  oyoDocs = "${inputs.oyo}/crates/oyo/docs";
in
{
  home.packages = [
    pkgs.difftastic
    inputs.oyo.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # `oy` reviews the current change, `oy <revset>` any other
  xdg.configFile."oyo/config.toml".source = (pkgs.formats.toml { }).generate "oyo-config.toml" {
    # Dark catppuccin is Mocha, matching alacritty. Syntax colours follow it.
    ui.theme.name = "catppuccin";
    # ( and ) step between comments as they did in hunk; { and } still work.
    keybindings.normal = {
      focus_next_comment = [
        "}"
        ")"
      ];
      focus_prev_comment = [
        "{"
        "("
      ];
    };
  };

  # The skills `oy skill path` points agents at, from the same revision as oy.
  home.file.".claude/skills/oyo-code-review/SKILL.md".source = "${oyoDocs}/SKILL.md";
  home.file.".claude/skills/oyo-tui-control/SKILL.md".source = "${oyoDocs}/CONTROL.md";
  home.file.".claude/skills/oyo-code-walkthrough/SKILL.md".source = "${oyoDocs}/WALKTHROUGH.md";

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
