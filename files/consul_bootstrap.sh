#!/usr/bin/env bash

consul_config_path=/etc/consul.d

help() {
  echo "
uso: consul_boostrap.sh [-h|--help] mode [bootstrap_expect] [rety_join]
Inicializa os arquivos de configuração do consul e habilita a unidade do consul no systemd.
argumentos:
  mode                   modo em que o consul vai rodar. Valores possíveis: server, client ou both.
argumentos opcionais:
  --help, -h, help       imprime essa mensagem de ajuda.
  bootstrap_expect       número de servidores no cluster.
  retry_join             lista de IPs ou configuração do cloud auto-join.
exemplos:
  Iniciar cluster no GCP com cloud auto-join:
    consul_boostrap.sh server 3 '\"provider=gce project_name=meu-projeto tag_value=consul\"'
    consul_boostrap.sh agent '\"provider=gce project_name=meu-projeto tag_value=consul\"'
"
}

main() {
  local mode="$1"

  case "${mode}" in
    server)
      render_server_config "${@:2}"
      ;;
    agent)
      render_agent_config "${@:2}"
      ;;
    help | --help | -h)
      help
      exit 0
      ;;
    *)
      echo "Parâmetro 'mode' invalido."
      help
      exit 1
      ;;
  esac

  echo "Habilitando e iniciando a unidade do Consul no systemd..."
  systemctl enable consul
  systemctl start consul

  echo "Finalizado."
  exit 0
}

render_server_config() {
  local bootstrap_expect="$1"
  local retry_join="${2:-\"127.0.0.1\"}"
  local datacenter="${3:-dc1}"

  echo "Renderizando arquivo de configuração do server..."

  if [[ -z "${bootstrap_expect}" ]]; then
    echo "Parâmetro 'bootstrap_expect' não informado."
    exit 1
  fi

  sed --expression "
    s/<BOOTSTRAP_EXPECT>/${bootstrap_expect}/
    s/<RETRY_JOIN>/${retry_join}/
    s/<DATACENTER>/${datacenter}/
  " "${consul_config_path}/server.hcl.tpl" > "${consul_config_path}/consul.hcl"
}

render_agent_config() {
  local retry_join="${1:-\"127.0.0.1\"}"
  local datacenter="${2:-dc1}"

  echo "Renderizando arquivo de configuração do agent..."

  sed --expression "
    s/<RETRY_JOIN>/${retry_join}/
    s/<DATACENTER>/${datacenter}/
  " "${consul_config_path}/consul.hcl.tpl" > "${consul_config_path}/consul.hcl"
}

main "$@"