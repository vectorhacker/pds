# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.box = "bento/ubuntu-16.04"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: "192.168.33.10"
  
  # Expose the nomad api and ui to the host
  config.vm.network "forwarded_port", guest: 4646, host: 4646, auto_correct: true

  # Configure
  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2        # 2 CPUS
    vb.memory = "6144" # 6GB RAM
  end

  # set hostname
  config.vm.hostname = 'pds'
  
  # Provision
  config.vm.provision "docker" do |d|
    # local docker registry
    d.run "registry",
      image: "registry:2",
      args: "-p 5000:5000",
      restart: "always",
      daemonize: true
      
    # eventstore for eventsourcing
    d.run "eventstore",
      image: "eventstore/eventstore:release-4.1.0",
      args: "-p 2113:2113",
      restart: "always",
      daemonize: true

    # zookeper to keep kafka happy
    d.run "zookeeper",
      image: "confluentinc/cp-zookeeper:4.0.0",
      args: "--net=host -e ZOOKEEPER_CLIENT_PORT=32181",
      restart: "always",
      daemonize: true

    # kafka for stream processing goodness
    d.run "kafka",
      image: "confluentinc/cp-kafka:4.0.0",
      args: "--net=host -e KAFKA_ZOOKEEPER_CONNECT=localhost:32181 -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:29092 -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1",
      restart: "always",
      daemonize: true
  end

  config.vm.provision "shell", path: "vagrant/provision.sh", privileged: false
  config.vm.synced_folder ".", "/home/vagrant/golang/src/github.com/vectorhacker/pds"
end
