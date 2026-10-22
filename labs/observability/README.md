# Observability Lab

Local OpenTelemetry, Prometheus, Loki, Tempo and Grafana stack for safe experiments. It is provisioned by the playbook but never started automatically.

## Start

```bash
cd ~/labs/observability
just up
```

Grafana is available at <http://localhost:3000>, Prometheus at <http://localhost:9090>, and the OpenTelemetry Collector accepts OTLP/gRPC on `localhost:4317` and OTLP/HTTP on `localhost:4318`.

The Grafana instance deliberately enables anonymous administrator access because this lab is bound only to the local machine. Do not reuse this configuration outside a local development environment.

## Stop And Reset

```bash
just down
just reset
```

`reset` removes all collected data. Use it before a fresh experiment when you need controlled measurements.
