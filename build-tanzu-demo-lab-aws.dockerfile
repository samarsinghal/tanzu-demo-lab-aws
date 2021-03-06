FROM ubuntu:18.04
LABEL maintainer="Frank Carta <fcarta@vmware.com>"

ENV KUBECTL_VERSION=v1.18.0
ENV ARGOCD_CLI_VERSION=v1.7.7
ENV KPACK_VERSION=0.1.3
ENV ARGOCD_VERSION=v1.8.2
ENV ISTIO_VERSION=1.7.4
ENV VELERO_VERSION=v1.5.4
ENV BAT_VERSION=0.18.0

# Install System libraries
RUN echo "Installing System Libraries" \
  && apt-get update \
  && apt-get install -y build-essential python3.6 python3-pip python3-dev groff bash-completion git curl unzip wget findutils jq vim tree docker.io pv

# Install Bat CLI
COPY bin/bat-v${BAT_VERSION}-x86_64-unknown-linux-gnu.tar.gz .
RUN echo "Installing Bat" \
  && tar -zxvf bat-v${BAT_VERSION}-x86_64-unknown-linux-gnu.tar.gz \
  && mv bat-v${BAT_VERSION}-x86_64-unknown-linux-gnu/bat /usr/local/bin \
  && chmod +x /usr/local/bin/bat

# Install AWS CLI
RUN echo "Installing AWS CLI" \
  && pip3 install --upgrade awscli

# Install TMC CLI
COPY bin/tmc .
RUN echo "Installing TMC CLI" \
  && chmod +x tmc \
  && mv tmc /usr/local/bin/tmc \
  && which tmc \
  && tmc version

# Install Kubectl
RUN echo "Installing Kubectl" \
  && wget -q https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
  && chmod +x ./kubectl \
  && mv kubectl /usr/local/bin/kubectl \
  && which kubectl \
  && mkdir -p /etc/bash_completion.d \
  && kubectl completion bash > /etc/bash_completion.d/kubectl \
  && kubectl version --short --client

#Install Kustomize
RUN echo "Installing Kustomize" \
  && curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash \
  && mv kustomize /usr/local/bin/kustomize \
  && kustomize version

# Install Helm3
RUN echo "Installing Helm3" \
  && curl https://get.helm.sh/helm-v3.3.0-rc.2-linux-amd64.tar.gz --output helm.tar.gz \
  && tar -zxvf helm.tar.gz \
  && mv linux-amd64/helm /usr/local/bin/helm \
  && chmod +x /usr/local/bin/helm \
  && helm version

# Install KPACK CLI
COPY bin/kp-linux-${KPACK_VERSION} .
RUN echo "Installing kpack CLI" \
  && chmod +x kp-linux-${KPACK_VERSION} \
  && mv kp-linux-${KPACK_VERSION} /usr/local/bin/kp \
  && which kp \
  && kp version

# Get kpack install yaml install and log utility
RUN echo "Installing kpack log utility" \
  && mkdir /opt/kpack \
  && curl -sSL -o /opt/kpack/logs-v${KPACK_VERSION}-linux.tgz https://github.com/pivotal/kpack/releases/download/v${KPACK_VERSION}/logs-v${KPACK_VERSION}-linux.tgz \
  && tar -zxvf /opt/kpack/logs-v${KPACK_VERSION}-linux.tgz \
  && mv logs /usr/local/bin/logs \
  && chmod +x /usr/local/bin/logs

# Install Carvel tools
RUN echo "Installing K14s Carvel tools" \
  && wget -O- https://k14s.io/install.sh | bash 

# Install Istioctl
RUN echo "Installing Istioctl" \
  && curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} TARGET_ARCH=x86_64 sh - \
  && cd istio-${ISTIO_VERSION} \
  && cp $PWD/bin/istioctl /usr/local/bin/istioctl \
  && istioctl version

# Install ArgoCD
RUN echo "Installing ArgoCD" \
  && curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/$ARGOCD_VERSION/argocd-linux-amd64 \
  && chmod +x /usr/local/bin/argocd 
  #&& argocd version

# Install CF CLI 7
RUN echo "Installing CF CLI 7" \
  && wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | apt-key add - \
  && echo "deb https://packages.cloudfoundry.org/debian stable main" | tee /etc/apt/sources.list.d/cloudfoundry-cli.list \
  && apt-get update \
  && apt-get install cf7-cli 

# Install Bosh 
RUN echo "Installing Bosh" \
  && wget -q https://github.com/cloudfoundry/bosh-cli/releases/download/v6.4.1/bosh-cli-6.4.1-linux-amd64 \
  && mv bosh-cli-6.4.1-linux-amd64 bosh \
  && chmod +x bosh \
  && mv bosh /usr/local/bin

# Install Bitnami Sealed Secrets
RUN echo "Installing Bitnami Sealed Secrets" \
  && wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.15.0/kubeseal-linux-amd64 -O kubeseal \
  && install -m 755 kubeseal /usr/local/bin/kubeseal

# Install Jupyter - TODO[fcarta] make requirements.txt instead of using empty file
#RUN echo "Installing Jupyter" \
#  && pip3 install -r /deploy/jupyter/requirements.txt \
#  && pip3 install jupyter

# Install Velero CLI
COPY bin/velero-${VELERO_VERSION}-linux-amd64.tar.gz .
RUN echo "Installing Velero" \
  #  Download does a redirect and doesnt complete that actual cli download so commenting out for now - just including bin for now
  #  && curl https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-amd64.tar.gz --output velero.tar.gz \
  && tar -zxvf velero-${VELERO_VERSION}-linux-amd64.tar.gz \
  && mv velero-${VELERO_VERSION}-linux-amd64/velero /usr/local/bin/velero \
  && chmod +x /usr/local/bin/velero

# Create Aliases
RUN echo "alias k=kubectl" > /root/.profile

# Leave Container Running for SSH Access - SHOULD REMOVE
ENTRYPOINT ["tail", "-f", "/dev/null"]
# Use this if you want to enable/run jupyter notebooks
#CMD ["jupyter", "notebook", "--port=8888", "--no-browser", "--ip=0.0.0.0", "--allow-root"]

