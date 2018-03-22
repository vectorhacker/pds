job "service.hello" {
  datacenters = ["dc1"]

  type = "service"

  update {
    # The "max_parallel" parameter specifies the maximum number of updates to
    # perform in parallel. In this case, this specifies to update a single task
    # at a time.
    max_parallel = 1
    
    # The "min_healthy_time" parameter specifies the minimum time the allocation
    # must be in the healthy state before it is marked as healthy and unblocks
    # further allocations from being updated.
    min_healthy_time = "10s"
    
    # The "healthy_deadline" parameter specifies the deadline in which the
    # allocation must be marked as healthy after which the allocation is
    # automatically transitioned to unhealthy. Transitioning to unhealthy will
    # fail the deployment and potentially roll back the job if "auto_revert" is
    # set to true.
    healthy_deadline = "3m"
    
    # The "auto_revert" parameter specifies if the job should auto-revert to the
    # last stable job on deployment failure. A job is marked as stable if all the
    # allocations as part of its deployment were marked healthy.
    auto_revert = false
    
    # The "canary" parameter specifies that changes to the job that would result
    # in destructive updates should create the specified number of canaries
    # without stopping any previous allocations. Once the operator determines the
    # canaries are healthy, they can be promoted which unblocks a rolling update
    # of the remaining allocations at a rate of "max_parallel".
    #
    # Further, setting "canary" equal to the count of the task group allows
    # blue/green deployments. When the job is updated, a full set of the new
    # version is deployed and upon promotion the old version is stopped.
    canary = 0
  }

  # The "group" stanza defines a series of tasks that should be co-located on
  # the same Nomad client. Any task within a group will be placed on the same
  # client.
  #
  # For more information and examples on the "group" stanza, please see
  # the online documentation at:
  #
  #     https://www.nomadproject.io/docs/job-specification/group.html
  #
  group "api" {
    # The "count" parameter specifies the number of the task groups that should
    # be running under this group. This value must be non-negative and defaults
    # to 1.
    count = 5

    # The "restart" stanza configures a group's behavior on task failure. If
    # left unspecified, a default restart policy is used based on the job type.
    #
    # For more information and examples on the "restart" stanza, please see
    # the online documentation at:
    #
    #     https://www.nomadproject.io/docs/job-specification/restart.html
    #
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

    # The "task" stanza creates an individual unit of work, such as a Docker
    # container, web application, or batch processing.
    #
    # For more information and examples on the "task" stanza, please see
    # the online documentation at:
    #
    #     https://www.nomadproject.io/docs/job-specification/task.html
    #
    task "api" {
      # The "driver" parameter specifies the task driver that should be used to
      # run the task.
      driver = "docker"

      # The "config" stanza specifies the driver configuration, which is passed
      # directly to the driver to start the task. The details of configurations
      # are specific to each driver, so please see specific driver
      # documentation for more information.
      config {
        image = "localhost:5000/service.hello"
        force_pull = true
        
        port_map {
          grpc = 5000
        }
      }

      env {
        INSTANCE = "${NOMAD_ALLOC_INDEX}"
      }

      resources {
        cpu    = 100 # 500 MHz
        memory = 128 # 256MB
        
        network {
          mbits = 1
          port "grpc" {}
        }
      }

      # Register the grpc service by it's name in the protocol buffer
      service {
        name = "Hello"
        port = "grpc"
        
        tags = ["grpc"]

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