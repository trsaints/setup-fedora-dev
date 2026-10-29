# Guia de Uso e Configuração

## Recursos Instalados

- Ferramentas base de desenvolvimento, terminal e diagnóstico: Git, GCC, Clang, CMake, Ninja, GDB, Valgrind, Neovim, ripgrep, fd, fzf, jq, tmux, Kitty, Zsh, `strace`, `lsof`, `perf`, `bpftrace`, `tcpdump`, TShark e mais.
- Runtimes e ferramentas globais pelo `mise`: .NET, Go, Node.js LTS, Python, lazygit, Kubernetes, IaC, qualidade e segurança.
- Ferramentas Python isoladas com `pipx`: `uv`, Poetry, Ruff, Black, mypy, HTTPie, Cookiecutter e pre-commit.
- Docker CE, cliente PostgreSQL, pgModeler, DBeaver CE e `k9s`.
- Obsidian via AppImage oficial em `~/Applications`, com o comando `obsidian` e atalho no menu de aplicações.
- Gradia via Flathub, para edição e captura de tela.
- Visual Studio Code pelo repositório oficial da Microsoft e GitHub CLI (`gh`) pelo Fedora.
- Firefox Developer Edition pelo arquivo oficial da Mozilla em `~/Applications`, com o comando `firefox-developer-edition`.
- Bruno via Flathub para chamadas e coleções de APIs locais e versionáveis com Git.
- ai-memory como serviço do usuário, integrado ao OpenCode em `http://127.0.0.1:25559`.
- Servidor MCP do GitHub registrado no OpenCode, autenticado por `GITHUB_MCP_PAT` sem gravar o token na configuração.
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
| `install_vscode` | Instala Visual Studio Code pelo repositório oficial da Microsoft. |
| `install_firefox_developer_edition` | Instala Firefox Developer Edition em `~/Applications`. |
| `install_bruno` | Instala Bruno via Flathub para o usuário atual. |
| `install_github_cli` | Instala GitHub CLI (`gh`) pelos repositórios do Fedora. |
| `install_ai_memory` | Instala ai-memory para o usuário atual. |
| `configure_github_mcp` | Registra o servidor MCP do GitHub no OpenCode usando `GITHUB_MCP_PAT`. |
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

### GitHub MCP no OpenCode

O playbook grava `~/.config/opencode/opencode.json` com o servidor `github` em `mcp.servers` (formato do OpenCode V2), usando `oauth: false` e o cabeçalho `Authorization: Bearer {env:GITHUB_MCP_PAT}`. O token nunca é escrito nesse arquivo; ele é resolvido pelo OpenCode a partir do ambiente. O arquivo gerenciado é JSON estrito, sem comentários; use `~/.config/opencode/opencode.jsonc` para preferências locais, como o shell padrão.

Para injetar o PAT, exporte `GITHUB_MCP_PAT` antes de executar o playbook:

```bash
export GITHUB_MCP_PAT=ghp_seu_token
./bootstrap.sh
```

Com a variável definida, o playbook grava `~/.config/opencode/github-mcp.env` com modo `0600`, e o `~/.zshrc` gerado passa a carregar esse arquivo em cada shell novo. Se preferir configurar manualmente (ou depois da instalação):

```bash
cat > ~/.config/opencode/github-mcp.env <<'EOF'
export GITHUB_MCP_PAT=ghp_seu_token
EOF
chmod 600 ~/.config/opencode/github-mcp.env
```

Abra um shell novo e valide:

```bash
opencode mcp list
```

O servidor `github` deve aparecer conectado. Se o serviço do OpenCode já estiver em execução, rode `opencode service restart` para que ele herde a variável; sem o PAT o servidor permanece configurado, mas sem autenticar.

Para reaplicar apenas esta configuração depois de mudar o token:

```bash
./bootstrap.sh --tags github_mcp
```

Se você já exportava o token com outro nome (por exemplo, `GITHUB_OPENCODE_PAT`), basta criar o arquivo com o novo nome:

```bash
printf 'export GITHUB_MCP_PAT=%q\n' "$GITHUB_OPENCODE_PAT" > ~/.config/opencode/github-mcp.env
chmod 600 ~/.config/opencode/github-mcp.env
```

> Não versione `github-mcp.env` nem exporte o token em arquivos do repositório. Use um token de granularidade fina (ou clássico) apenas com os escopos necessários para os repositórios que o agente deve acessar.

## Aplicativos e Serviços

### DBeaver CE

O playbook fixa a versão oficial definida em `dbeaver_version`. Caso tenha outra instalação, como Flatpak, prefira manter apenas uma para evitar atalhos e diretórios de dados duplicados.

### Gradia

`<Super><Shift>S` abre uma captura de tela interativa com o Gradia.

### VS Code, GitHub CLI, Firefox Developer Edition e Bruno

- Use `code` para abrir o VS Code e `gh auth login` para autenticar o GitHub CLI.
- O Firefox Developer Edition é iniciado pelo menu de aplicações ou com `firefox-developer-edition`. O arquivo oficial atualmente fixado pelo playbook é para `x86_64`.
- Bruno é iniciado pelo menu de aplicações ou com `flatpak run com.usebruno.Bruno`. Salve coleções em um repositório Git para compartilhar e versionar as chamadas de API.

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
