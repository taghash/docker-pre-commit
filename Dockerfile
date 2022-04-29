FROM debian:stable-slim

# Set encodeing to UTF-8
ENV LANG C.UTF-8

# set DEBIAN_FRONTEND env var to noninteractive to prevent software-properties-common promting for geographic area
# https://www.codegrepper.com/code-examples/shell/apt+asks+for+geographic+location+while+installing+docker+image
ENV DEBIAN_FRONTEND=noninteractive

# apt updates
RUN apt-get update

# make sure apt is up to date
RUN apt-get update --fix-missing
RUN apt-get install -y apt-utils
RUN apt-get update

# apt installs
RUN apt-get install -y \
      curl \
      git \
      unzip \
      software-properties-common \
      python3-dev \
      python3-pip \
      python3-httplib2 \
      python3-setuptools \
      python3-pkg-resources \
      python3-yaml \
      gawk \
      coreutils

# pip installs
RUN pip3 install --upgrade pip
RUN pip3 install pre-commit

# configure pre-commit
RUN mkdir /pre-commit
RUN cd /pre-commit
RUN git init .
RUN pre-commit install

# instalk terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
RUN apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
RUN apt-get update && apt-get install -y terraform=1.1.9


# instalk terraform-docs for terraform pre-commit
RUN curl -sSLo ./terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/v0.16.0/terraform-docs-v0.16.0-linux-amd64.tar.gz
RUN tar -xzf terraform-docs.tar.gz
RUN chmod +x terraform-docs
RUN mv terraform-docs /usr/bin/terraform-docs

# instalk tflint for terraform pre-commit
RUN curl -sSLo ./tflint.sh https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh
RUN chmod +x ./tflint.sh
RUN ./tflint.sh

# instalk tfsec for terraform pre-commit
RUN curl -sSLo ./tfsec-linux-amd64 https://github.com/aquasecurity/tfsec/releases/download/v1.18.0/tfsec-linux-amd64
RUN chmod +x tfsec-linux-amd64
RUN mv tfsec-linux-amd64 /usr/bin/tfsec

# instalk checkov for terraform pre-commit
# https://stackoverflow.com/questions/49911550/how-to-upgrade-disutils-package-pyyaml
RUN pip3 install --ignore-installed PyYAML
RUN pip3 install -U checkov

WORKDIR /pre-commit

CMD ["pre-commit", "run", "--all-files"]
