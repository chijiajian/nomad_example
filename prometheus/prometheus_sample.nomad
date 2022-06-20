variables {
  prometheus_download_url = "http://172.34.2.251:2015/prometheus-2.35.0.linux-amd64.tar.gz"
}
job "prometheus" {
  datacenters = ["dc1"]
  type        = "service"
  group "prometheus" {
    count = "1"
    network {
      port "http" { static = "9090" }
    }
    task "server" {
      driver = "raw_exec"
      constraint {
        attribute = "${meta.tenant}"
        value     = "tenanta"
      }
      config {
        command = "local/prometheus-2.35.0.linux-amd64/prometheus"
        args    = ["--config.file", "${NOMAD_TASK_DIR}/prometheus-2.35.0.linux-amd64/prometheus.yml"]
      }
      artifact {
        source      = var.prometheus_download_url
        destination = "/local"
      }
      service {
        name = "http-echo"
        port = "http"
        tags = [
          "anaconda",
          "urlprefix-/http-echo",
        ]
        check {
          type     = "http"
          path     = "/health"
          interval = "10s"
          timeout  = "5s"
        }
      }
    }
  }
}