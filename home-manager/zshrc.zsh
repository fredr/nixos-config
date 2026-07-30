# Interactive zsh setup. Kept as a real .zsh file rather than a Nix string so
# it gets syntax highlighting and shellcheck; anything needing a store path
# lives in home.sessionVariables / home.sessionPath in zsh.nix.

function encore-dev() {
  if [ -z "$1" ]; then
    nix develop ~/nixos-config#encore-dev -c zsh
    return
  fi

  local name="$1"
  local custom_path="$2"

  if [[ "$name" == */* ]]; then
    echo "Error: name must not contain '/'"
    return 1
  fi

  local encore_main=~/projects/encoredev/encore
  local worktree_base=~/projects/encoredev/encore.worktrees
  local worktree_dir="$worktree_base/$name"

  local new_worktree=0

  if [ -n "$custom_path" ]; then
    local resolved_path="$(realpath "$custom_path" 2>/dev/null)"
    if [ ! -d "$resolved_path" ]; then
      echo "Error: path '$custom_path' does not exist or is not a directory"
      return 1
    fi

    if [ -d "$worktree_dir" ] && [ ! -L "$worktree_dir" ]; then
      echo "Error: '$name' already exists as a worktree, not an external path"
      return 1
    fi

    mkdir -p "$worktree_base"
    ln -sfn "$resolved_path" "$worktree_dir"
  elif [ -L "$worktree_dir" ] && [ ! -d "$worktree_dir" ]; then
    echo "Error: '$name' links to a path that no longer exists: $(readlink "$worktree_dir")"
    return 1
  elif [ ! -d "$worktree_dir" ]; then
    local branch="fredr/$name"
    echo "Creating worktree '$name' (branch '$branch') from main..."
    mkdir -p "$worktree_base"
    git -C "$encore_main" worktree add -b "$branch" "$worktree_dir"
    new_worktree=1
  fi

  ENCORE_WORKTREE_NAME="$name" \
  ENCORE_WORKTREE_DIR="$(realpath "$worktree_dir")" \
  ENCORE_WORKTREE_NEW="$new_worktree" \
    nix develop ~/nixos-config#encore-dev -c zsh
}

function encore-dev-rm() {
  if [ -z "$1" ]; then
    echo "Usage: encore-dev-rm <name>"
    return 1
  fi

  local name="$1"
  local encore_main=~/projects/encoredev/encore
  local worktree_dir=~/projects/encoredev/encore.worktrees/$name

  if [ ! -e "$worktree_dir" ] && [ ! -L "$worktree_dir" ]; then
    echo "Entry '$name' does not exist"
    return 1
  fi

  if [ -L "$worktree_dir" ]; then
    rm "$worktree_dir"
    echo "Removed path link '$name'"
  else
    git -C "$encore_main" worktree remove --force "$worktree_dir"
    echo "Removed worktree '$name'"
  fi
}

function encore-cd() {
  if [ -z "${ENCORE_DEV_DIR:-}" ]; then
    echo "encore-cd: not inside an encore-dev shell" >&2
    return 1
  fi
  cd "$ENCORE_DEV_DIR"
}

# helper for converting encore protos to json, proto type is the argument
function encore-buf() {
  (cd ~/projects/encoredev/encore/proto ; buf convert --type $1 | jq)
}

# Restore SHELL to zsh — nix develop overrides it to bash via stdenv
export _ORIG_SHELL="${_ORIG_SHELL:-$SHELL}"
export SHELL="$_ORIG_SHELL"

export BASE_SHLVL=${BASE_SHLVL:-$SHLVL}

# Detect new subshells (nix develop, nix shell, etc.)
if [ "$SHLVL" -gt "$BASE_SHLVL" ] && [ "$SHLVL" != "${_HANDLED_SHLVL:-0}" ]; then
  if [ "${SHELL_NAME:-}" = "${_PARENT_SHELL_NAME:-}" ]; then
    _nix_pkg=""
    if [ -n "${_PARENT_PATH:-}" ]; then
      _nix_pkg=$(comm -23 \
        <(echo "$PATH" | tr ':' '\n' | grep '/nix/store/' | sort) \
        <(echo "${_PARENT_PATH}" | tr ':' '\n' | grep '/nix/store/' | sort) \
        | head -1 | sed -E 's|/nix/store/[a-z0-9]{32}-||;s|/bin$||;s|-[0-9].*||')
    fi
    export SHELL_NAME="${SHELL_NAME:+${SHELL_NAME}>}${_nix_pkg:-shell}"
    unset _nix_pkg
  fi
  export _HANDLED_SHLVL=$SHLVL
fi
export _PARENT_SHELL_NAME="${SHELL_NAME:-}"
export _PARENT_PATH="$PATH"

function nix_shell() {
  if [ -n "${SHELL_NAME:-}" ]; then
    echo " %{$fg[cyan]%}${SHELL_NAME}%{$reset_color%}"
  fi
}

ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg[green]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}!"
ZSH_THEME_GIT_PROMPT_CLEAN=""

PROMPT='%(?,,%{$fg[red]%}!%{$reset_color%} )%{$fg[blue]%}%~%{$reset_color%}$(git_prompt_info)$(nix_shell)
%{$fg[magenta]%}>%{$reset_color%} '

RPROMPT=""
