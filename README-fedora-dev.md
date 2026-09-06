# Setup Fedora Dev com Ansible

Playbook local para configurar Fedora 44 para desenvolvimento fullstack com runtimes/SDKs gerenciados pelo `mise`, Docker CE, LazyVim, Kitty, GNOME, Dracula Theme, JetBrains Mono Nerd Font e ferramentas úteis para Ciência da Computação e SRE.

O script Bash original continua em `setup-fedora-dev.sh` como referência, mas o fluxo recomendado agora é o Ansible.

## O Que Ele Faz

- Atualiza o sistema com `dnf upgrade --refresh`.
- Instala ferramentas base: Git, GCC, Make, Neovim, ripgrep, fd, fzf, jq, tmux, btop, eza, bat, Zsh, Kitty e dependências de build para runtimes.
- Instala `mise`.
- Instala runtimes/SDKs globais pelo `mise`: `.NET`, `Python`, `Node.js LTS` e `Go`.
- Instala `pipx` e ferramentas Python usando o Python gerenciado pelo `mise`: `uv`, `poetry`, `ruff`, `black`, `mypy`, `ipython`, `httpie`, `cookiecutter` e `pre-commit`.
- Instala ferramentas SRE quando disponíveis: `ansible`, `kubectl`, `helm`, `terraform` e `k9s`.
- Instala `k9s` pelo release oficial do GitHub.
- Instala Docker CE oficial e adiciona seu usuário ao grupo `docker`, se `install_docker_ce` estiver ativo.
- Remove Podman, Buildah, Skopeo e `podman-docker` somente se `replace_podman_with_docker` estiver ativo. Essa flag vem ativa para preservar o comportamento do script original.
- Instala JetBrains Mono Nerd Font.
- Instala Dracula GTK Theme e aplica tema escuro no GNOME.
- Configura Kitty com Dracula, JetBrains Mono Nerd Font, splits, tabs e `Ctrl+Backspace` para apagar palavra.
- Configura Zsh com Oh My Zsh, Dracula, autocomplete, autosuggestions e syntax highlighting.
- Instala LazyVim em `~/.config/nvim`.
- Configura atalhos GNOME úteis.

## Arquivos Principais

- `playbook.yml`: tarefas principais.
- `group_vars/all.yml`: flags e listas de pacotes/ferramentas.
- `inventory.ini`: inventário local.
- `ansible.cfg`: configuração do Ansible para execução local.
- `bootstrap.sh`: instala `ansible-core` se necessário e executa o playbook.
- `templates/kitty.conf.j2`: configuração do Kitty.
- `templates/zshrc.j2`: configuração do Zsh.

## Executar

Primeiro revise `group_vars/all.yml`, principalmente estas flags:

- `run_system_upgrade`: atualiza todos os pacotes do sistema.
- `install_docker_ce`: instala Docker CE oficial.
- `replace_podman_with_docker`: remove Podman/Buildah/Skopeo antes de instalar Docker. Desative se quiser manter o stack padrão do Fedora.
- `configure_gnome`: aplica tema e atalhos GNOME.
- `configure_shell`: instala Oh My Zsh, plugins e altera shell padrão.
- `install_lazyvim`: instala LazyVim em `~/.config/nvim`.

Depois execute:

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

O bootstrap pede senha via `sudo` para instalar `ansible-core`, se necessário. O Ansible também pede senha de `become` para tarefas administrativas.

Se o Ansible já estiver instalado:

```bash
ansible-playbook playbook.yml --ask-become-pass
```

## Validar Sem Aplicar Mudanças

```bash
ansible-playbook playbook.yml --syntax-check
ansible-playbook playbook.yml --check --ask-become-pass
```

Algumas tarefas que baixam instaladores, executam `mise`, `pipx`, `gsettings` ou `nvim` podem ter limitações no modo `--check`.

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

- A remoção do Podman fica centralizada em `replace_podman_with_docker` e vem ativa para manter compatibilidade com o script original.
- Runtimes e SDKs não são instalados diretamente pelo `dnf`; ficam sob controle do `mise`.
- Se você já tiver um `~/.zshrc`, o Ansible cria backup antes de substituir.
- Se você já tiver uma configuração em `~/.config/nvim` que não seja Git, o playbook para antes de sobrescrever.
- Se algum pacote SRE não existir no repositório habilitado do Fedora, o playbook continua e informa o pacote indisponível.
