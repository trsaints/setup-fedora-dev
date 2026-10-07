# Testes do bloco de substituição do Podman

Execute na raiz do repositório:

```sh
PYTHONDONTWRITEBYTECODE=1 /usr/bin/python3 -m unittest discover -s tests -v
```

Dependências: `unittest` (biblioteca padrão), PyYAML e Ansible Core com
`Templar.evaluate_conditional` e `trust_as_template` (2.19+; validado com 2.20.1).
O Jinja e o filtro `intersect` usados são os fornecidos pelo Ansible.

Os testes leem `playbook.yml` e `group_vars/all.yml`, carregam somente o bloco
`Replace Podman stack before Docker CE install` no parser do Ansible e avaliam
templates e condições efetivas, incluindo os guards herdados do bloco.
Os inventários de pacotes e o estado `LoadState` do socket são sintéticos.
Nenhum módulo Ansible,
comando externo, sudo, operação RPM/DNF ou alteração de serviço é executado.
O log do Ansible é direcionado a `/dev/null` para não escrever em `logs/`.

Cobertura: inventários parciais, todos ausentes/presentes, nomes exatos,
duplicatas, nova seleção após uma remoção simulada, flags desligadas, socket
com `LoadState` `loaded`/`masked`/`not-found`, tratamento de espaços e quebras de
linha em `stdout`, ausência do registro da consulta quando não há pacotes,
consulta read-only sem become disponível em check mode, propagação de falhas
por configuração, ordem das tarefas, tag, contrato da transação DNF, resultado
registrado e marcador `nodocker`.

Limitações: são testes de lógica e contrato, não integração com o solver DNF5.
Não validam resolução de dependências, transações RPM reais, comportamento do
systemd, falhas reais de módulos ou idempotência de alterações no host.
O cenário de repetição recebe explicitamente um inventário pós-remoção simulado.
