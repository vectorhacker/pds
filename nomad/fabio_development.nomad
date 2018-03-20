job "fabio" {
    datacenters = ["dc1"]

    type = "service"

    group "loadbalancer" {
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

        task "fabio" {
            driver = "exec"

            artifact {
                source = "https://github.com/fabiolb/fabio/releases/download/v1.5.8/fabio-1.5.8-go1.10-linux_amd64"
            }

            template {
                data = <<EOH
                    proxy.addr = 192.168.33.10:{{ env "NOMAD_PORT_lb" }}
                    ui.addr = 192.168.33.10:{{ env "NOMAD_PORT_ui" }}
                    log.level = DEBUG
                EOH

                destination = "local/fabio.properties"
            }

            config {
                command = "fabio-1.5.8-go1.10-linux_amd64"
                args = ["-cfg", "local/fabio.properties"]
            }

            resources {
                cpu = 100
                memory = 128
                
                network {
                    mbits = 1
                    port "lb" {
                        static = 9999
                    }
                    
                    port "ui" {
                        static = 9998
                    }
                }
            }
        }
    }
}