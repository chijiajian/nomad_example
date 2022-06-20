variables {
  prometheus_download_url = "http://172.34.2.251:2015/prometheus-2.35.0.linux-amd64.tar.gz"
}
job "prometheus" {
  datacenters = ["dc1"]
  type        = "service"

  group "monitoring" {
    count = 1

    network {
      port "prometheus_ui" {
        static = 9090
      }
    }

    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    ephemeral_disk {
      size = 300
    }

    task "prometheus" {
      constraint {
        attribute = "${meta.tenant}"
        value     = "tenanta"
      }
      template {
        change_mode = "noop"
        destination = "${NOMAD_TASK_DIR}/prometheus-2.35.0.linux-amd64/prometheus.yml"

        data = <<EOH
---
global:
  scrape_interval:     5s
  evaluation_interval: 5s

scrape_configs:

  - job_name: 'nomad_metrics'

    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus_ui" }}:8500'
      services: ['nomad-client', 'nomad']

    relabel_configs:
    - source_labels: ['__meta_consul_tags']
      regex: '(.*)http(.*)'
      action: keep

    scrape_interval: 5s
    metrics_path: /v1/metrics
    params:
      format: ['prometheus']
EOH
      }

      driver = "raw_exec"

      config {
        command = "local/prometheus-2.35.0.linux-amd64/prometheus"
        args    = ["--config.file", "${NOMAD_TASK_DIR}/prometheus-2.35.0.linux-amd64/prometheus.yml"]

        ports = ["prometheus_ui"]
      }
      artifact {
        source      = var.prometheus_download_url
        destination = "/local"
      }

      service {
        name = "prometheus"
        tags = ["urlprefix-/"]
        port = "prometheus_ui"

        check {
          name     = "prometheus_ui port alive"
          type     = "http"
          path     = "/-/healthy"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
