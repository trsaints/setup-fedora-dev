# Guia de Instalação

## Pré-requisitos

- Fedora `44`.
- Conexão com a internet.
- Um usuário com acesso a `sudo`.
- Espaço livre para pacotes, runtimes do `mise`, fontes, imagens Docker e o laboratório local.

O playbook é local: ele configura o usuário que executa `bootstrap.sh`. Instalações via DNF, Docker CE e `k9s` em `/usr/local/bin` são compartilhadas por toda a máquina.

## Personalização

Antes de instalar, revise [`../group_vars/all.yml`](../group_vars/all.yml). As flags principais são descritas no [guia de uso](uso.md#flags-de-configuração).

Para uma instalação mais conservadora, considere desativar recursos que não utilizará:

```yaml
install_docker_ce: false
replace_podman_with_docker: false
configure_gnome: false
configure_shell: false
install_observability_lab: false
```

## Executar

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

Opcionalmente, injete o PAT do GitHub MCP para que o playbook o grave em `~/.config/opencode/github-mcp.env` (o token não vai para o `opencode.json`):

```bash
export GITHUB_MCP_PAT=ghp_seu_token
./bootstrap.sh
```

O script solicita e valida a senha `sudo`, instala `ansible-core` quando necessário, instala as collections definidas em `requirements.yml` e salva o stdout em `logs/ansible-YYYYMMDD-HHMMSS.log`. O Ansible também escreve em `logs/ansible.log`.

O playbook instala o OpenCode CLI (versão fixada em `opencode_cli_version`) antes de configurar o ai-memory, porque `ai-memory setup`, `install-hooks` e `install-mcp` consultam `opencode --version` para escolher o formato V1 ou V2 da integração. O binário fica em `~/.opencode/bin`, que é adicionado ao `PATH` pelo `~/.zshrc` gerenciado.

Se o Ansible já estiver disponível:

```bash
ansible-playbook playbook.yml --ask-become-pass
```

## Validar Sem Aplicar Mudanças

```bash
ansible-playbook playbook.yml --syntax-check
ansible-playbook playbook.yml --check --ask-become-pass
```

Tarefas que baixam instaladores, executam `mise`, `pipx`, `gsettings`, `nvim` ou autenticação OAuth podem ter limitações no modo `--check`.

## Substituição do Podman

Com `install_docker_ce: true` e `replace_podman_with_docker: true`, o playbook remove Podman, Buildah, Skopeo, `podman-docker`, `containers-common`, `containers-common-extra`, Toolbox e dependentes antes de instalar Docker CE. A remoção é uma transação DNF única; `allowerasing: true` permite remover dependentes, enquanto `autoremove: false` evita uma limpeza global de pacotes órfãos não relacionados.

Isso afeta todos os usuários da máquina. O playbook não executa `podman system reset`, `prune` nem remove volumes, imagens ou containers, mas esses dados deixam de ser utilizáveis enquanto o Podman estiver ausente. Faça backup e pare workloads, inclusive rootless, antes da troca.

Para revisar somente essa etapa:

```bash
./bootstrap.sh --tags podman_cleanup --check
```

Para executar apenas a remoção:

```bash
./bootstrap.sh --tags podman_cleanup
```

Os testes dessa etapa não alteram o sistema:

```bash
PYTHONDONTWRITEBYTECODE=1 /usr/bin/python3 -m unittest discover -s tests -v
```

## Após a Instalação

Encerre e inicie novamente a sessão para aplicar o shell padrão, o grupo `docker`, a fonte e o tema GNOME. Em seguida, consulte a [validação](uso.md#validação) e os recursos disponíveis no [guia de uso](uso.md).
