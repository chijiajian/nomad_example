job "redis" {
  datacenters = ["dc1"]
  type        = "service"
  update {
    max_parallel     = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    auto_revert      = false
    canary           = 0
  }
  group "cache" {
    count = 1
    network {
      mbits = 10
      port "db" {}
    }
    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }
    ephemeral_disk {
      size = 300
    }
    task "redis" {
      driver = "docker"
      config {
        image = "redis:3.2"
        port_map {
          db = 6379
        }
      }
      service {
        name = "global-redis-check"
        tags = ["global", "cache", "urlprefix-/redis"]
        port = "db"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}