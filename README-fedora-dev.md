# Setup Fedora Dev

Script para configurar Fedora para desenvolvimento fullstack com runtimes/SDKs gerenciados pelo `mise`, Docker CE, LazyVim, Kitty, GNOME, Dracula Theme, JetBrains Mono Nerd Font e ferramentas úteis para Ciência da Computação e SRE.

## O Que Ele Faz

- Atualiza o sistema com `dnf upgrade --refresh`.
- Instala ferramentas base: Git, GCC, Make, Neovim, ripgrep, fd, fzf, jq, tmux, btop, eza, bat, Zsh, Kitty e dependências de build para runtimes.
- Instala `mise`.
- Instala runtimes/SDKs globais pelo `mise`: `.NET`, `Python`, `Node.js LTS` e `Go`.
- Instala `pipx` e ferramentas Python usando o Python gerenciado pelo `mise`: `uv`, `poetry`, `ruff`, `black`, `mypy`, `ipython`, `httpie`, `cookiecutter` e `pre-commit`.
- Instala ferramentas SRE quando disponíveis: `ansible`, `kubectl`, `helm`, `terraform` e `k9s`.
- Remove Podman, Buildah, Skopeo e `podman-docker`.
- Instala Docker CE oficial e adiciona seu usuário ao grupo `docker`.
- Instala JetBrains Mono Nerd Font.
- Instala Dracula GTK Theme e aplica tema escuro no GNOME.
- Configura Kitty com Dracula, JetBrains Mono Nerd Font, splits, tabs e `Ctrl+Backspace` para apagar palavra.
- Configura Zsh com Oh My Zsh, Dracula, autocomplete, autosuggestions e syntax highlighting.
- Instala LazyVim em `~/.config/nvim`.
- Configura atalhos GNOME úteis.

## Executar

```bash
./scripts/setup-fedora-dev.sh
```

O script pede senha via `sudo` durante a execução.

## Depois De Executar

Reinicie a sessão ou reinicie o computador para aplicar:

- Shell padrão alterado para Zsh.
- Usuário adicionado ao grupo `docker`.
- Fonte e tema no GNOME.
- Atalho `<Super>Return` abrindo Kitty.

## Validação

```bash
docker run hello-world
dotnet --info
node --version
go version
python --version
mise current
uv --version
poetry --version
nvim
kitty
```

## Atalhos Kitty

- `Ctrl+Shift+Right`: split horizontal.
- `Ctrl+Shift+Down`: split vertical.
- `Ctrl+Shift+H/J/K/L`: navegar entre splits.
- `Ctrl+Shift+Enter`: nova janela/split no diretório atual.
- `Ctrl+Shift+T`: nova aba no diretório atual.
- `Ctrl+Shift+W`: fechar split.
- `Ctrl+Shift+Q`: fechar aba.
- `Ctrl+Backspace`: apagar palavra anterior no terminal.
- `Ctrl+Delete`: apagar próxima palavra no terminal.

## Observações

- A remoção do Podman é intencional e está no script em `remove_podman_install_docker`.
- Runtimes e SDKs não são instalados diretamente pelo `dnf`; ficam sob controle do `mise`.
- Se você já tiver um `~/.zshrc`, o script cria backup antes de substituir.
- Se você já tiver uma configuração em `~/.config/nvim` que não seja Git, o script cria backup antes de instalar LazyVim.
- Se algum pacote SRE não existir no repositório habilitado do Fedora, o script continua e instala o restante.
