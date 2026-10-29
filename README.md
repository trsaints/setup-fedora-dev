# Setup Fedora Dev com Ansible

Playbook local para configurar uma estação Fedora 44 para desenvolvimento fullstack, Ciência da Computação e SRE. Ele instala runtimes gerenciados pelo `mise`, Docker CE, ferramentas de banco de dados, ambiente GNOME/terminal e um laboratório local de observabilidade.

O script Bash original permanece em `setup-fedora-dev.sh` como referência; o fluxo suportado é o Ansible.

## Guias

- [Guia de instalação](docs/instalacao.md): pré-requisitos, personalização, execução, validação e impactos no sistema.
- [Guia de uso e configuração](docs/uso.md): recursos instalados, flags, aplicativos, atalhos e serviços configurados.

## Estrutura do Projeto

- `playbook.yml`: tarefas principais.
- `group_vars/all.yml`: flags, versões, URLs e listas de pacotes.
- `bootstrap.sh`: instala `ansible-core` se necessário e executa o playbook.
- `templates/`: configurações gerenciadas de Kitty e Zsh.
- `labs/observability/`: stack Docker Compose para experiências locais.
- `tests/`: testes de regressão da remoção do Podman.

## Início Rápido

Revise `group_vars/all.yml` e execute:

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

> Atenção: por padrão, o playbook troca a stack Podman pelo Docker CE. Leia a seção correspondente no [guia de instalação](docs/instalacao.md#substituição-do-podman) antes de executar.
