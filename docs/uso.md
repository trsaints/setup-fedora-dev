# Guia de Uso e Configuração

## Recursos Instalados

- Ferramentas base de desenvolvimento, terminal e diagnóstico: Git, GCC, Clang, CMake, Ninja, GDB, Valgrind, Neovim, ripgrep, fd, fzf, jq, tmux, Kitty, Zsh, `strace`, `lsof`, `perf`, `bpftrace`, `tcpdump`, TShark e mais.
- Runtimes e ferramentas globais pelo `mise`: .NET, Go, Node.js LTS, Python, lazygit, Kubernetes, IaC, qualidade e segurança.
- Ferramentas Python isoladas com `pipx`: `uv`, Poetry, Ruff, Black, mypy, HTTPie, Cookiecutter e pre-commit.
- Docker CE, cliente PostgreSQL, pgModeler, DBeaver CE e `k9s`.
- Obsidian via AppImage oficial em `~/Applications`, com o comando `obsidian` e atalho no menu de aplicações.
- Gradia via Flathub, para edição e captura de tela.
- ai-memory como serviço do usuário, integrado ao OpenCode em `http://127.0.0.1:25559`.
- Oh My Zsh, tema Dracula, Kitty, JetBrains Mono Nerd Font, tema Dracula GTK e ícones Candy.
- LazyVim com extras para Python, .NET/C#, Go, Docker, JSON, Markdown, SQL, Terraform, YAML, debug e testes.
- Laboratório local de observabilidade com OpenTelemetry Collector, Prometheus, Loki, Tempo e Grafana.

## Flags de Configuração

Todas ficam em [`../group_vars/all.yml`](../group_vars/all.yml).

| Flag | Efeito |
| --- | --- |
| `run_system_upgrade` | Atualiza os pacotes do sistema. |
| `install_docker_ce` | Instala e inicia Docker CE. |
| `replace_podman_with_docker` | Remove a stack Podman antes da instalação do Docker. |
| `configure_gnome` | Aplica tema, fonte e atalhos GNOME. |
| `configure_shell` | Instala e configura Oh My Zsh, plugins e Zsh padrão. |
| `configure_kitty` | Gerencia a configuração do Kitty. |
| `install_lazyvim` | Instala/configura LazyVim em `~/.config/nvim`. |
| `install_dbeaver` | Instala DBeaver CE via RPM oficial fixado. |
| `install_obsidian` | Instala Obsidian via AppImage em `~/Applications`. |
| `install_gradia` | Instala Gradia via Flathub para o usuário atual. |
| `install_ai_memory` | Instala ai-memory para o usuário atual. |
| `install_study_foundations` | Instala ferramentas para exercícios de C, Linux, rede e diagnóstico. |
| `install_database_tooling` | Instala o cliente PostgreSQL. |
| `install_platform_tooling` | Instala ferramentas de Kubernetes, IaC e carga. |
| `install_quality_tooling` | Instala linters para CI, OpenAPI e automação. |
| `install_security_tooling` | Instala Gitleaks e Trivy. |
| `install_observability_lab` | Provisiona o laboratório em `~/labs/observability`, sem iniciá-lo. |
| `configure_direnv` | Habilita o hook do `direnv` no Zsh. |

### ai-memory

O serviço usa `ai_memory_bind`, cujo padrão é `127.0.0.1:25559`; altere-o caso essa porta esteja ocupada. O playbook também atualiza a integração do OpenCode para usar a mesma URL.

Após a primeira instalação, a Web UI fica em `http://127.0.0.1:25559/web`. Use qualquer nome de usuário e, como senha, o token local em:

```bash
cat ~/.local/share/ai-memory/auth-tokens/default
```

Reinicie o OpenCode depois da instalação para que ele carregue o plugin atualizado.

## Aplicativos e Serviços

### DBeaver CE

O playbook fixa a versão oficial definida em `dbeaver_version`. Caso tenha outra instalação, como Flatpak, prefira manter apenas uma para evitar atalhos e diretórios de dados duplicados.

### Gradia

`<Super><Shift>S` abre uma captura de tela interativa com o Gradia.

### Laboratório de Observabilidade

Inicie somente quando for usá-lo:

```bash
cd ~/labs/observability
just up
```

- Grafana: `http://localhost:3000`
- Prometheus: `http://localhost:9090`
- OpenTelemetry OTLP gRPC: `localhost:4317`
- OpenTelemetry OTLP HTTP: `localhost:4318`

Todos os serviços são vinculados somente a `127.0.0.1`.

## Atalhos

### GNOME

- `<Super>Return`: abre Kitty.
- `<Super><Shift>S`: captura de tela interativa com Gradia.
- `<Super>E`: abre a pasta pessoal.
- `<Super>I`: abre as configurações do sistema.

### Kitty

- `Ctrl+Shift+Right`: split horizontal.
- `Ctrl+Shift+Down`: split vertical.
- `Ctrl+Shift+H/J/K/L`: navega entre splits.
- `Ctrl+Shift+Enter`: cria uma nova janela/split no diretório atual.
- `Ctrl+Shift+T`: cria uma nova aba no diretório atual.
- `Ctrl+Shift+W`: fecha o split.
- `Ctrl+Shift+Q`: fecha a aba.
- `Ctrl+Backspace`: apaga a palavra anterior.
- `Ctrl+Delete`: apaga a próxima palavra.

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

## Observações Sobre Arquivos Existentes

- Um `~/.zshrc` existente recebe backup antes de ser substituído.
- Um `~/.config/nvim` que não seja repositório Git interrompe o playbook para evitar sobrescrita.
- `~/labs/observability` recebe os arquivos gerenciados pelo playbook; não use esse diretório para alterações manuais sem backup.
- A disponibilidade de pacotes SRE é detectada por `dnf repoquery`; pacotes indisponíveis são informados sem interromper o restante da configuração.
