#!/bin/bash -x
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "INFO: pre-install phase starting at $(date -u +%H:%M:%S)"

${pre_install}

echo "INFO: installing additional packages at $(date -u +%H:%M:%S)"

# update docker apt sources
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


# install additional packages
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates \
    uidmap \
    jq \
    curl \
    git \
    unzip \
    zip \
    build-essential \
    docker-ce \
    docker-ce-cli \
    containerd.io

# Install 'yq'
YQ_VERSION=v4.34.1
yq_architecture=""
case $(uname -m) in
    x86_64) yq_architecture="amd64" ;;
    arm)    yq_architecture="arm64" ;;
esac
YQ_BINARY="yq_linux_${yq_architecture}"
wget https://github.com/mikefarah/yq/releases/download/$YQ_VERSION/$YQ_BINARY.tar.gz -O - |\
  tar xz && mv $YQ_BINARY /usr/bin/yq

# Install AWS CLI v2 (v1 is the default on AmazonLinux2). Using parenthesis () to do everything in subshell.
(
    cd /tmp
    CPU_ARCH=$(uname -m) # Get runner architecture "x86_64", "aarch64", ...
    curl "https://awscli.amazonaws.com/awscli-exe-linux-$CPU_ARCH.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install --bin-dir /usr/bin --install-dir /usr/local/aws-cli --update
)


echo  'LANG="en_US.UTF-8"' >>  /etc/environment
echo  'LC_ALL="en_US.UTF-8"' >>  /etc/environment
echo  'LC_CTYPE="en_US.UTF-8"' >>  /etc/environment

USER_NAME=runners
useradd -m -s /bin/bash $USER_NAME
USER_ID=$(id -ru $USER_NAME)

# install and configure cloudwatch logging agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/$(dpkg --print-architecture)/latest/amazon-cloudwatch-agent.deb

dpkg -i -E ./amazon-cloudwatch-agent.deb
amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:${ssm_key_cloudwatch_agent_config}

# start docker 
systemctl enable containerd.service
service docker start
# add user runners to docker group
usermod -aG docker $USER_NAME

# add user runners to sudo group
usermod -aG sudo $USER_NAME
echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10-extra-users

# Auto-login to DockerHub if credentials are passed in the pre_install step
if [ "$DOCKERHUB_USERNAME" != "" ] && [ "$DOCKERHUB_PASSWORD" != "" ]; then
    echo "DockerHub username and password detected. Logging in automatically..."
    su $USER_NAME -c "docker login -u $DOCKERHUB_USERNAME -p $DOCKERHUB_PASSWORD"
fi

echo "INFO: installing github runner at $(date -u +%H:%M:%S)"

# assign to `user_name` because install_runner template uses it.
user_name="$USER_NAME"

${install_runner}

# config runner for rootless docker
cd /opt/actions-runner/
# echo DOCKER_HOST=unix:///run/user/$USER_ID/docker.sock >>.env
# echo PATH=/home/$USER_NAME/bin:$PATH >>.env

${post_install}

cd /opt/actions-runner

echo "INFO: starting github runner at $(date -u +%H:%M:%S)"

${start_runner}
