job "linkerd" {
    datacenters = ["dc1"]
    type = "service"

    group "router" {
        count = 1

        restart {
          # The number of attempts to run the job within the specified interval.
          attempts = 10
          interval = "5m"

          # The "delay" parameter specifies the duration to wait before restarting
          # a task after it has failed.
          delay = "25s"

         # The "mode" parameter controls what happens when a task has restarted
         # "attempts" times within the interval. "delay" mode delays the next
         # restart until the next interval. "fail" mode does not restart the task
         # if "attempts" has been hit within the interval.
          mode = "delay"
        }

        task "linkerd" {
            driver = "docker"

            config {
                image = "buoyantio/linkerd:1.3.6"

                network_mode = "host"

                args = [
                   "/config.yaml"
                ]

                volumes = [
                    "local/config.yaml:/config.yaml"
                ]
            }

            template {
                data = <<EOH
admin:
  port: {{ env "NOMAD_PORT_admin" }}
  ip: 0.0.0.0
routers:
- protocol: h2
  label: outgoing
  dtab: |
    /srv        => /#/io.l5d.consul/dc1/grpc;
    /grpc       => /srv;
    /svc        => /$/io.buoyant.http.domainToPathPfx/grpc;
  identifier:
    kind: io.l5d.header.path
    segments: 1
  servers:
  - port: {{ env "NOMAD_PORT_outgoing" }}
    ip: 0.0.0.0

- protocol: h2
  label: incoming
  dtab: |
    /srv        => /#/io.l5d.consul/dc1/grpc;
    /grpc       => /srv;
    /svc        => /$/io.buoyant.http.domainToPathPfx/grpc;
  identifier:
    kind: io.l5d.header.path
    segments: 1
  servers:
  - port: {{ env "NOMAD_PORT_incomming" }}
    ip: 0.0.0.0
namers:
- kind: io.l5d.consul
  host: 127.0.0.1
  port: 8500
  includeTag: true
  useHealthCheck: false
  healthStatuses:
    - "passing"
    - "warning"
  setHost: true
  consistencyMode: stale
              EOH

                destination = "local/config.yaml"
            }

            resources {
                cpu = 100
                memory = 256
                
                network {
                    mbits = 1
                    port "admin" {
                        static = 9990
                    }

                    port "incomming" {
                        static = 4141
                    }
                    
                    port "outgoing" {
                        static = 4140
                    }
                }
            }
        }
    }
}