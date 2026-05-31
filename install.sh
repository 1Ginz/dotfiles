#!/usr/bin/env zsh
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo "${GREEN}==>${NC} $1"; }
warn() { echo "${YELLOW}WARN:${NC} $1"; }

# ── 1. Homebrew ────────────────────────────────────────────────────────────────
info "Checking Homebrew..."
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  info "Homebrew found, updating..."
  brew update --quiet
fi

# ── 2. CLI packages ────────────────────────────────────────────────────────────
info "Installing/upgrading brew packages..."
BREW_PACKAGES=(
  git
  fzf
  zoxide
  eza
  tmux
  kubectl
  kubectx
  go
  starship
  rust
)

for pkg in "${BREW_PACKAGES[@]}"; do
  if brew list "$pkg" &>/dev/null; then
    brew upgrade "$pkg" 2>/dev/null || true
  else
    brew install "$pkg"
  fi
done

# ── 3. Casks ──────────────────────────────────────────────────────────────────
info "Installing casks..."
BREW_CASKS=(
  font-jetbrains-mono-nerd-font
  ghostty
)

for cask in "${BREW_CASKS[@]}"; do
  if brew list --cask "$cask" &>/dev/null; then
    brew upgrade --cask "$cask" 2>/dev/null || true
  elif [[ "$cask" == "ghostty" && -d "/Applications/Ghostty.app" ]]; then
    info "Ghostty already installed, skipping"
  else
    brew install --cask "$cask"
  fi
done

# ── 4. zinit ──────────────────────────────────────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
  info "Installing zinit..."
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
else
  info "Updating zinit..."
  git -C "$ZINIT_HOME" pull --quiet
fi

# ── 5. nvm ────────────────────────────────────────────────────────────────────
NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
  info "Installing nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
else
  info "nvm found, updating..."
  NVM_LATEST=$(git -C "$NVM_DIR" describe --abbrev=0 --tags --match "v[0-9]*" "$(git -C "$NVM_DIR" rev-list --tags --max-count=1)" 2>/dev/null || true)
  [ -n "$NVM_LATEST" ] && git -C "$NVM_DIR" checkout "$NVM_LATEST" --quiet 2>/dev/null || true
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# ── 6. Node LTS + Claude Code ─────────────────────────────────────────────────
info "Installing Node.js LTS..."
nvm install --lts --no-progress
nvm use --lts

info "Installing/upgrading Claude Code..."
npm install -g @anthropic-ai/claude-code

# ── 7. TPM (tmux plugin manager) ──────────────────────────────────────────────
export TMUX_PLUGIN_MANAGER_PATH="$HOME/.config/tmux/plugins/"
mkdir -p "$TMUX_PLUGIN_MANAGER_PATH"

TPM_DIR="$TMUX_PLUGIN_MANAGER_PATH/tpm"
if [ ! -d "$TPM_DIR" ]; then
  info "Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
  info "Updating TPM..."
  git -C "$TPM_DIR" pull --quiet
fi


# ── 8. Symlinks ───────────────────────────────────────────────────────────────
info "Creating symlinks..."

symlink() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"

  if [ -L "$dst" ]; then
    if [ "$(readlink "$dst")" = "$src" ]; then
      return
    fi
    warn "Replacing symlink: $dst"
    rm "$dst"
  elif [ -e "$dst" ]; then
    warn "Backing up existing file: $dst -> ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi

  ln -sf "$src" "$dst"
  info "Linked: $(basename "$dst")"
}

symlink "$DOTFILES/.zshrc"                       "$HOME/.zshrc"
symlink "$DOTFILES/.gitconfig"                   "$HOME/.gitconfig"
symlink "$DOTFILES/.gitignore_global"            "$HOME/.gitignore_global"
symlink "$DOTFILES/.config/tmux/tmux.conf"       "$HOME/.config/tmux/tmux.conf"
symlink "$DOTFILES/.config/tmux/tmux.reset.conf" "$HOME/.config/tmux/tmux.reset.conf"
symlink "$DOTFILES/.ssh/config"                  "$HOME/.ssh/config"
symlink "$DOTFILES/.config/ghostty/config"          "$HOME/.config/ghostty/config"
symlink "$DOTFILES/.config/ghostty/shaders"        "$HOME/.config/ghostty/shaders"
symlink "$DOTFILES/.config/starship.toml"          "$HOME/.config/starship.toml"

# ── 9. macOS keyboard shortcuts ───────────────────────────────────────────────
info "Restoring macOS keyboard shortcuts..."
cp "$DOTFILES/macos/com.apple.symbolichotkeys.plist" \
   "$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
info "Keyboard shortcuts applied (log out and back in if shortcuts don't take effect)"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
info "Done! Next steps:"
echo "  1. Open a new terminal to apply .zshrc"
echo "  2. Create ~/.zshrc.secrets with your API tokens:"
echo "     export ATLASSIAN_AUTH=..."
echo "     export JIRA_API_TOKEN=..."
echo "  3. Start tmux and press prefix + I (Ctrl+A then I) to install plugins"
echo "  4. After plugins install, build tmux-thumbs binary:"
echo "     cargo build --release --manifest-path ~/.config/tmux/plugins/tmux-thumbs/Cargo.toml"
echo "  4. Log out and back in to fully apply keyboard shortcuts"
