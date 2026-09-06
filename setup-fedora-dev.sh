#!/usr/bin/env bash
set -euo pipefail

DRACULA_THEME_DIR="$HOME/.themes/Dracula"
JETBRAINS_VERSION="3.4.0"
JETBRAINS_ZIP="JetBrainsMono-${JETBRAINS_VERSION}.zip"
JETBRAINS_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${JETBRAINS_VERSION}/JetBrainsMono.zip"
LAZYVIM_STARTER="$HOME/.config/nvim"

log() {
  printf '\n==> %s\n' "$1"
}

require_fedora() {
  if ! grep -qi '^ID=fedora' /etc/os-release; then
    printf 'Este script foi feito para Fedora. Abortando.\n' >&2
    exit 1
  fi
}

install_base_packages() {
  log "Atualizando sistema e instalando ferramentas base"
  sudo dnf upgrade --refresh -y
  sudo dnf install -y \
    @development-tools \
    ShellCheck \
    bat \
    bzip2-devel \
    btop \
    ca-certificates \
    curl \
    dconf-editor \
    dnf-plugins-core \
    eza \
    fastfetch \
    fd-find \
    fzf \
    gcc \
    gcc-c++ \
    git \
    gnome-extensions-app \
    gnome-tweaks \
    htop \
    jq \
    kitty \
    libffi-devel \
    make \
    neovim \
    openssl-devel \
    procps-ng \
    readline-devel \
    ripgrep \
    sqlite \
    sqlite-devel \
    tar \
    tmux \
    tk-devel \
    unzip \
    util-linux-user \
    wget \
    which \
    xz-devel \
    zlib-devel \
    zsh
}

install_mise() {
  log "Instalando mise e runtimes/SDKs globais"
  if ! command -v mise >/dev/null 2>&1; then
    curl https://mise.run | sh
  fi

  export PATH="$HOME/.local/bin:$PATH"
  eval "$(mise activate bash)"

  mise use -g \
    dotnet@latest \
    go@latest \
    node@lts \
    python@latest

  mise reshim
}

install_python_tools() {
  log "Instalando ferramentas Python para desenvolvimento e estudo"
  python -m pip install --user --upgrade pip pipx
  python -m pipx ensurepath

  local tools=(
    black
    cookiecutter
    httpie
    ipython
    mypy
    poetry
    pre-commit
    ruff
    uv
  )

  for tool in "${tools[@]}"; do
    python -m pipx install "$tool" || python -m pipx upgrade "$tool"
  done
}

install_sre_tools() {
  log "Instalando ferramentas para SRE, cloud native e observabilidade"
  local packages=(ansible kubernetes-client helm terraform)

  for package in "${packages[@]}"; do
    sudo dnf install -y "$package" || printf 'Pacote indisponivel no dnf atual: %s\n' "$package"
  done

  if ! command -v k9s >/dev/null 2>&1; then
    local tmp
    tmp="$(mktemp -d)"
    curl -fsSL "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz" -o "$tmp/k9s.tar.gz"
    tar -xzf "$tmp/k9s.tar.gz" -C "$tmp" k9s
    sudo install -m 0755 "$tmp/k9s" /usr/local/bin/k9s
    rm -rf "$tmp"
  fi
}

remove_podman_install_docker() {
  log "Removendo Podman e instalando Docker CE"
  sudo systemctl disable --now podman.socket 2>/dev/null || true
  sudo dnf remove -y podman podman-docker buildah skopeo containers-common || true
  sudo rm -f /etc/containers/nodocker

  sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
  sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl enable --now docker
  sudo usermod -aG docker "$USER"
}

install_jetbrains_mono_nf() {
  log "Instalando JetBrains Mono Nerd Font"
  mkdir -p "$HOME/.local/share/fonts/JetBrainsMonoNF"
  local tmp
  tmp="$(mktemp -d)"
  curl -fsSL "$JETBRAINS_URL" -o "$tmp/$JETBRAINS_ZIP"
  unzip -qo "$tmp/$JETBRAINS_ZIP" -d "$HOME/.local/share/fonts/JetBrainsMonoNF"
  fc-cache -fv "$HOME/.local/share/fonts" >/dev/null
  rm -rf "$tmp"
}

install_dracula_gnome() {
  log "Instalando Dracula Theme para GNOME"
  sudo dnf install -y gtk-murrine-engine sassc
  mkdir -p "$HOME/.themes"

  if [ ! -d "$DRACULA_THEME_DIR/.git" ]; then
    rm -rf "$DRACULA_THEME_DIR"
    git clone --depth 1 https://github.com/dracula/gtk.git "$DRACULA_THEME_DIR"
  else
    git -C "$DRACULA_THEME_DIR" pull --ff-only
  fi

  gsettings set org.gnome.desktop.interface gtk-theme Dracula || true
  gsettings set org.gnome.desktop.wm.preferences theme Dracula || true
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark || true
  gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11' || true
}

configure_kitty() {
  log "Configurando Kitty com Dracula, splits e atalhos produtivos"
  mkdir -p "$HOME/.config/kitty"

  if [ -f "$HOME/.config/kitty/kitty.conf" ] && ! grep -q 'Managed by setup-fedora-dev.sh' "$HOME/.config/kitty/kitty.conf"; then
    cp "$HOME/.config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf.backup.$(date +%Y%m%d%H%M%S)"
  fi

  cat > "$HOME/.config/kitty/kitty.conf" <<'EOF'
# Managed by setup-fedora-dev.sh
font_family JetBrainsMono Nerd Font
bold_font auto
italic_font auto
bold_italic_font auto
font_size 11.0

enable_audio_bell no
confirm_os_window_close 0
remember_window_size yes
initial_window_width 120c
initial_window_height 34c
window_padding_width 8
tab_bar_style powerline
tab_powerline_style slanted
active_tab_font_style bold
inactive_tab_font_style normal
enabled_layouts splits,tall,stack,fat,grid,horizontal,vertical

# Dracula Theme
foreground #f8f8f2
background #282a36
selection_foreground #ffffff
selection_background #44475a
url_color #8be9fd
cursor #f8f8f2
active_border_color #bd93f9
inactive_border_color #44475a
bell_border_color #ffb86c
active_tab_foreground #282a36
active_tab_background #bd93f9
inactive_tab_foreground #f8f8f2
inactive_tab_background #44475a
color0 #21222c
color1 #ff5555
color2 #50fa7b
color3 #f1fa8c
color4 #bd93f9
color5 #ff79c6
color6 #8be9fd
color7 #f8f8f2
color8 #6272a4
color9 #ff6e6e
color10 #69ff94
color11 #ffffa5
color12 #d6acff
color13 #ff92df
color14 #a4ffff
color15 #ffffff

# Splits, tabs and navigation
map ctrl+shift+enter launch --cwd=current
map ctrl+shift+right launch --location=hsplit --cwd=current
map ctrl+shift+down launch --location=vsplit --cwd=current
map ctrl+shift+h neighboring_window left
map ctrl+shift+j neighboring_window down
map ctrl+shift+k neighboring_window up
map ctrl+shift+l neighboring_window right
map ctrl+shift+w close_window
map ctrl+shift+t launch --type=tab --cwd=current
map ctrl+shift+q close_tab
map ctrl+shift+left previous_tab
map ctrl+shift+up next_tab

# Make Ctrl+Backspace delete the previous word in shells/readline apps.
map ctrl+backspace send_text all \x17
map ctrl+delete send_text all \x1bd
EOF
}

install_zsh_plugins() {
  log "Configurando Zsh produtivo com Dracula, autocomplete e sugestões"
  local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  mkdir -p "$zsh_custom/plugins" "$zsh_custom/themes"

  clone_or_update() {
    local repo="$1"
    local dir="$2"
    if [ ! -d "$dir/.git" ]; then
      git clone --depth 1 "$repo" "$dir"
    else
      git -C "$dir" pull --ff-only
    fi
  }

  clone_or_update https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom/plugins/zsh-autosuggestions"
  clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_custom/plugins/zsh-syntax-highlighting"
  clone_or_update https://github.com/zsh-users/zsh-completions "$zsh_custom/plugins/zsh-completions"
  clone_or_update https://github.com/marlonrichert/zsh-autocomplete.git "$zsh_custom/plugins/zsh-autocomplete"
  clone_or_update https://github.com/dracula/zsh.git "$zsh_custom/themes/dracula"
  ln -sf "$zsh_custom/themes/dracula/dracula.zsh-theme" "$zsh_custom/themes/dracula.zsh-theme"

  if [ -f "$HOME/.zshrc" ] && ! grep -q 'ZSH_THEME="dracula"' "$HOME/.zshrc"; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
  fi

  cat > "$HOME/.zshrc" <<'EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="dracula"

plugins=(
  git
  docker
  docker-compose
  dotnet
  python
  pip
  poetry
  fzf
  zsh-completions
  zsh-autocomplete
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export PATH="$HOME/.local/bin:$HOME/.dotnet/tools:$PATH"
eval "$(mise activate zsh)"

alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first --git'
alias la='eza -a --icons --group-directories-first'
alias cat='bat'
alias grep='rg'
alias top='btop'
alias py='python3'
alias venv='python3 -m venv .venv && source .venv/bin/activate'
alias dc='docker compose'
alias k='kubectl'
alias tf='terraform'

bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^H' backward-kill-word
bindkey '^?' backward-delete-char
bindkey '^[[3;5~' kill-word

autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select

if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

fastfetch 2>/dev/null || true
EOF

  if [ "${SHELL:-}" != "$(command -v zsh)" ]; then
    chsh -s "$(command -v zsh)"
  fi
}

install_lazyvim() {
  log "Instalando LazyVim"
  if [ -d "$LAZYVIM_STARTER" ] && [ ! -d "$LAZYVIM_STARTER/.git" ]; then
    mv "$LAZYVIM_STARTER" "$LAZYVIM_STARTER.backup.$(date +%Y%m%d%H%M%S)"
  fi

  if [ ! -d "$LAZYVIM_STARTER/.git" ]; then
    git clone https://github.com/LazyVim/starter "$LAZYVIM_STARTER"
    rm -rf "$LAZYVIM_STARTER/.git"
  fi

  nvim --headless '+Lazy! sync' +qa || true
}

configure_gnome_shortcuts() {
  log "Configurando atalhos úteis no GNOME"
  gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab']" || true
  gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']" || true
  gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q']" || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']" || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys control-center "['<Super>i']" || true

  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']" || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Terminal' || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'kitty' || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>Return' || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'Browser' || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'xdg-open https://www.google.com' || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Super>b' || true
}

print_next_steps() {
  log "Finalizado"
  printf 'Reinicie a sessão para aplicar grupo docker, shell padrão, fonte e tema.\n'
  printf 'Valide depois com:\n'
  printf '  docker run hello-world\n'
  printf '  dotnet --info\n'
  printf '  python3 --version && uv --version && poetry --version\n'
  printf '  nvim\n'
}

main() {
  require_fedora
  install_base_packages
  install_mise
  install_python_tools
  install_sre_tools
  remove_podman_install_docker
  install_jetbrains_mono_nf
  install_dracula_gnome
  configure_kitty
  install_zsh_plugins
  install_lazyvim
  configure_gnome_shortcuts
  print_next_steps
}

main "$@"
