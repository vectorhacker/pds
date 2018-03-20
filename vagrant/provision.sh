export DEBIAN_FRONTEND=noninteractive
export VHOME=/home/vagrant
export GOPATH=$VHOME/golang
export PROJECT_ROOT=$GOPATH/src/github.com/vectorhacker/pds

sudo apt-get update -y -q
sudo apt-get install -y -q build-essential git curl ca-certificates bash-completion autoconf unison unzip vim apt-transport-https software-properties-common pkg-config zip g++ zlib1g-dev python

sudo mkdir -p $PROJECT_ROOT
sudo chown -R vagrant $GOPATH
sudo chgrp -R vagrant $GOPATH


# golang
PATH=$PATH:$GOPATH/bin:/usr/local/go/bin

if [ ! -d /usr/local/go ]; then
    sudo curl -O https://storage.googleapis.com/golang/go1.9.linux-amd64.tar.gz
    sudo tar -xvf go1.9.linux-amd64.tar.gz
    sudo mv go /usr/local
    sudo rm go1.9.linux-amd64.tar.gz
    echo "export GOPATH=$GOPATH" >> "$VHOME/.profile"
    echo "export PATH=\$PATH:\$GOPATH/bin:/usr/local/go/bin" >> "$VHOME/.profile"
fi

sudo -u vagrant -H bash -c "
id
source ~/.profile

if ! command -V golint ; then
    go get -u github.com/golang/lint/golint
    go get -u golang.org/x/tools/cmd/cover
    go get -u golang.org/x/tools/cmd/goimports
fi

if ! command -V protoc-gen-go ; then 
    go get -u github.com/golang/protobuf/...
    go get -u github.com/grpc-ecosystem/grpc-gateway/...
fi

if ! command -V glide ; then
    curl https://glide.sh/get | sh
fi

if ! command -V dep ; then
    curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
fi

if ! command -V migrate ; then 
    go get github.com/mattes/migrate
fi

if ! command -V buildifier ; then
    go get -d -u github.com/bazelbuild/buildifier/buildifier
    # generate step is why this isn't Glide-able
    go generate github.com/bazelbuild/buildifier/core
    go install github.com/bazelbuild/buildifier/buildifier
fi

if ! command -V go-bindata ; then
    go get -u github.com/jteeuwen/go-bindata/...
fi

go get -u github.com/gogo/protobuf/...

# used for local filesystem watching
if ! command -V modd ; then
    go get github.com/cortesi/modd/cmd/modd
fi
"

# bazel
curl -sSL https://github.com/bazelbuild/bazel/releases/download/0.11.1/bazel-0.11.1-installer-linux-x86_64.sh -o bazel-0.11.1-installer-linux-x86_64.sh

chmod +x bazel-0.11.1-installer-linux-x86_64.sh
sudo ./bazel-0.11.1-installer-linux-x86_64.sh


# Nomad
# Download Nomad
NOMAD_VERSION=0.7.1
CONSUL_VERSION=1.0.6

echo "Fetching Nomad..."
cd /tmp/
curl -sSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip -o nomad.zip

echo "Fetching Consul..."
curl -sSL https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip > consul.zip

echo "Installing Nomad..."
unzip nomad.zip
sudo install nomad /usr/bin/nomad

sudo mkdir -p /etc/nomad.d
sudo chmod a+w /etc/nomad.d

# Set hostname's IP to made advertisement Just Work
#sudo sed -i -e "s/.*nomad.*/$(ip route get 1 | awk '{print $NF;exit}') nomad/" /etc/hosts

echo "Installing Consul..."
unzip /tmp/consul.zip
sudo install consul /usr/bin/consul
(cat <<-EOF
	[Unit]
	Description=consul agent
	Requires=network-online.target
	After=network-online.target
	
	[Service]
	Restart=on-failure
	ExecStart=/usr/bin/consul agent -dev
	ExecReload=/bin/kill -HUP $MAINPID
	
	[Install]
	WantedBy=multi-user.target
EOF
) | sudo tee /etc/systemd/system/consul.service
sudo systemctl enable consul.service
sudo systemctl start consul

for bin in cfssl cfssl-certinfo cfssljson
do
	echo "Installing $bin..."
	curl -sSL https://pkg.cfssl.org/R1.2/${bin}_linux-amd64 > /tmp/${bin}
	sudo install /tmp/${bin} /usr/local/bin/${bin}
done

echo "Installing autocomplete..."
nomad -autocomplete-install

sudo mkdir -p /etc/nomad
sudo mkdir -p /var/lib/nomad

(cat <<-EOF
	# Increase log verbosity
    log_level = "DEBUG"

    bind_addr = "0.0.0.0" # the default
    data_dir  = "/var/lib/nomad"

    # Advertise agent
    advertise {
      http = "192.168.33.10"
      rpc  = "192.168.33.10"
      serf = "192.168.33.10"
    }

    # Enable the server
    server {
        enabled = true
        bootstrap_expect = 1
    }

    # Enable the client
    client {
        enabled = true
        network_interface = "eth1"
    }
EOF
) | sudo tee /etc/nomad/config.hcl

(cat <<-EOF
	[Unit]
	Description=nomad agent
	Requires=network-online.target
	After=network-online.target
	
	[Service]
	Restart=on-failure
	ExecStart=/usr/bin/nomad agent -config /etc/nomad/config.hcl
	ExecReload=/bin/kill -HUP $MAINPID
	
	[Install]
	WantedBy=multi-user.target
EOF
) | sudo tee /etc/systemd/system/nomad.service
sudo systemctl enable nomad.service
sudo systemctl start nomad


sudo apt-get autoremove -y -q
sudo echo "export PDS=/home/vagrant/golang/src/github.com/vectorhacker/pds/" >> "$VHOME/.profile"