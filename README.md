# Setup Fedora Dev com Ansible

Playbook local para configurar Fedora 44 para desenvolvimento fullstack com runtimes/SDKs gerenciados pelo `mise`, Docker CE, LazyVim, Kitty, GNOME, Dracula Theme, JetBrains Mono Nerd Font e ferramentas úteis para Ciência da Computação e SRE.

O script Bash original continua em `setup-fedora-dev.sh` como referência, mas o fluxo recomendado agora é o Ansible.

## O Que Ele Faz

- Atualiza o sistema com `dnf upgrade --refresh`.
- Instala ferramentas base: Git, GCC, Make, Neovim, ripgrep, fd, fzf, jq, tmux, btop, eza, bat, Zsh, Kitty e dependências de build para runtimes.
- Instala pgModeler em versão fixada disponível no Fedora 44.
- Instala DBeaver CE via RPM oficial versionado, se `install_dbeaver` estiver ativo.
- Instala `mise`.
- Instala runtimes/SDKs e ferramentas globais pelo `mise` com versões fixadas: `.NET`, `Python`, `Node.js LTS`, `Go` e `lazygit`.
- Instala `pipx` e ferramentas Python usando o Python gerenciado pelo `mise`: `uv`, `poetry`, `ruff`, `black`, `mypy`, `ipython`, `httpie`, `cookiecutter` e `pre-commit`.
- Instala ferramentas SRE quando disponíveis: `ansible`, `kubectl`, `helm`, `terraform` e `k9s`.
- Instala `k9s` pelo release oficial do GitHub.
- Instala Docker CE oficial e adiciona seu usuário ao grupo `docker`, se `install_docker_ce` estiver ativo.
- Remove Podman, Buildah, Skopeo, `podman-docker`, `containers-common`, `containers-common-extra`, Toolbox e dependentes antes do Docker, se `install_docker_ce` e `replace_podman_with_docker` estiverem ativos. Pacotes ausentes são pulados. A substituição vem ativa por padrão.
- Instala JetBrains Mono Nerd Font.
- Instala Dracula GTK Theme e aplica tema escuro no GNOME.
- Configura Kitty com Dracula, JetBrains Mono Nerd Font, splits, tabs e `Ctrl+Backspace` para apagar palavra.
- Configura Zsh com Oh My Zsh, Dracula, autocomplete, autosuggestions e syntax highlighting.
- Instala LazyVim em `~/.config/nvim` com extras para Python, .NET/C#, debug/testes e `lazygit` disponível para integrações Git.
- Configura atalhos GNOME úteis.

## Arquivos Principais

- `playbook.yml`: tarefas principais.
- `group_vars/all.yml`: flags e listas de pacotes/ferramentas.
- `inventory.ini`: inventário local.
- `ansible.cfg`: configuração do Ansible para execução local.
- `bootstrap.sh`: instala `ansible-core` se necessário e executa o playbook.
- `templates/kitty.conf.j2`: configuração do Kitty.
- `templates/lazyvim-extras.lua.j2`: extras de linguagem habilitados no LazyVim.
- `templates/zshrc.j2`: configuração do Zsh.
- `logs/`: diretório local para logs de execução, não versionados.

## Executar

Primeiro revise `group_vars/all.yml`, principalmente estas flags:

- `run_system_upgrade`: atualiza todos os pacotes do sistema.
- `install_docker_ce`: instala Docker CE oficial.
- `replace_podman_with_docker`: remove a stack Podman e ferramentas que dependem dela (incluindo Toolbox) antes de instalar Docker. Desative se quiser manter a stack padrão do Fedora.
- `configure_gnome`: aplica tema e atalhos GNOME.
- `configure_shell`: instala Oh My Zsh, plugins e altera shell padrão.
- `install_lazyvim`: instala LazyVim em `~/.config/nvim`.
- `install_dbeaver`: instala DBeaver CE via RPM oficial versionado.

Depois execute:

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

O bootstrap pede e valida a senha via `sudo`, permitindo nova tentativa se ela for digitada errado, e repassa a senha validada ao Ansible para tarefas administrativas.

A execução via `bootstrap.sh` grava o stdout em `logs/ansible-YYYYMMDD-HHMMSS.log`. O próprio Ansible também grava em `logs/ansible.log`.

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

### Substituição do Podman

A remoção consulta os RPMs instalados e envia somente os pacotes presentes ao DNF, em uma única transação. `allowerasing: true` permite remover dependentes que impediriam a operação, como Toolbox e outros consumidores de `containers-common`. `autoremove: false` evita uma limpeza global de pacotes órfãos; isso **não** impede a remoção dos dependentes necessários. A transação é exibida no log e falhas reais não são ignoradas. Se nenhum pacote da lista estiver instalado, a remoção é pulada e o playbook continua para o Docker.

Para inspecionar somente essa etapa sem remover pacotes:

```bash
./bootstrap.sh --tags podman_cleanup --check
```

Revise a lista de remoção apresentada, pois outros aplicativos dependentes também podem ser removidos. Depois execute `./bootstrap.sh` normalmente; não é necessário desfazer as etapas que já concluíram. Para executar somente a remoção, use `./bootstrap.sh --tags podman_cleanup` (isso não instala Docker).

O “wipe” é de **pacotes**, não de dados: não executa `podman system reset`, `prune` nem apaga diretórios de volumes, imagens ou containers. Esses dados não são migrados para Docker. Pare workloads Podman, inclusive os rootless, e faça backup antes da troca; parar o socket de sistema não encerra todos os containers. Se a instalação do Docker falhar depois da remoção, a máquina poderá ficar sem runtime até a correção. Reinstalar os pacotes removidos não equivale a um rollback completo dos workloads.

Os testes de regressão dessa etapa não alteram o sistema. Veja as dependências e limitações em [`tests/README.md`](tests/README.md):

```bash
PYTHONDONTWRITEBYTECODE=1 /usr/bin/python3 -m unittest discover -s tests -v
```

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
- Se algum pacote SRE não existir no repositório habilitado do Fedora, o playbook continua e informa o pacote indisponível. A disponibilidade é detectada pelo `stdout` do `dnf repoquery`, não apenas pelo código de saída.
