{ pkgs, ... }: {

  programs.firefox = {
    enable = true;

    profiles = {
      default = {
        id = 0;
        name = "default";
        isDefault = true;

        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          onepassword-password-manager
        ];
      };
    };
  };
}
