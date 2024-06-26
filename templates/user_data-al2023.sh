#!/bin/bash -e

exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

# AWS suggest to create a log for debug purpose based on https://aws.amazon.com/premiumsupport/knowledge-center/ec2-linux-log-user-data/
# As side effect all command, set +x disable debugging explicitly.
#
# An alternative for masking tokens could be: exec > >(sed 's/--token\ [^ ]* /--token\ *** /g' > /var/log/user-data.log) 2>&1

set +x

%{ if enable_debug_logging }
set -x
%{ endif }

${pre_install}

dnf upgrade-minimal -y
dnf install -y \
    jq \
    wget \
    git \
    unzip \
    zip \
    make \
    gcc \
    amazon-cloudwatch-agent \
    docker

dnf install -y --allowerasing curl
  

# Install 'yq'
YQ_VERSION=v4.34.1
yq_architecture=""
case $(uname -m) in
    x86_64)  yq_architecture="amd64" ;;
    arm)     yq_architecture="arm64" ;;
    aarch64) yq_architecture="arm64" ;;
esac
YQ_BINARY="yq_linux_$yq_architecture"
wget https://github.com/mikefarah/yq/releases/download/$YQ_VERSION/$YQ_BINARY.tar.gz -O - |\
  tar xz && mv $YQ_BINARY /usr/bin/yq

echo  'LANG="en_US.UTF-8"' >>  /etc/environment
echo  'LC_ALL="en_US.UTF-8"' >>  /etc/environment
echo  'LC_CTYPE="en_US.UTF-8"' >>  /etc/environment

USER_NAME=runners
useradd -m -s /bin/bash $USER_NAME
USER_ID=$(id -ru $USER_NAME)

# start docker 
service docker start
# add user $USER_NAME to docker group
usermod -aG docker $USER_NAME

# Auto-login to DockerHub if credentials are passed in the pre_install step
if [ "$DOCKERHUB_USERNAME" != "" ] && [ "$DOCKERHUB_PASSWORD" != "" ]; then
    echo "DockerHub username and password detected. Logging in automatically..."
    su $USER_NAME -c "docker login -u $DOCKERHUB_USERNAME -p $DOCKERHUB_PASSWORD"
fi

echo "INFO: installing github runner at $(date -u +%H:%M:%S)"

# assign to `user_name` because install_runner template uses it.
user_name="$USER_NAME"

# Install libicu on non-ubuntu
if [[ ! "$os_id" =~ ^ubuntu.* ]]; then
  dnf install -y libicu
fi

${install_runner}

${post_install}

${start_runner}
