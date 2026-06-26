FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG OPAM_SWITCH_NAME=artifact-switch
ARG OPAM_OCAML_COMPILER=5.2.1
ARG COQ_CORE_VERSION=9.1.1
ARG ROCQ_CORE_VERSION=9.1.1
ARG ROCQ_STDLIB_VERSION=9.0.0
ARG ALECTRYON_VERSION=2.0.0
ARG APT_INSECURE=false

SHELL ["/bin/bash", "-lc"]

RUN rm -rf /var/lib/apt/lists/* \
  && if [[ "${APT_INSECURE}" == "true" ]]; then \
       apt-get -o Acquire::AllowInsecureRepositories=true -o Acquire::AllowDowngradeToInsecureRepositories=true update; \
       apt-get install -y --allow-unauthenticated --no-install-recommends \
         ca-certificates \
         curl \
         unzip \
         git \
         build-essential \
         pkg-config \
         m4 \
         libgmp-dev \
         bubblewrap \
         opam \
         perl \
         openjdk-17-jdk \
         python3 \
         python3-pip \
         rsync; \
     else \
       apt-get update && apt-get install -y --no-install-recommends \
         ca-certificates \
         curl \
         unzip \
         git \
         build-essential \
         pkg-config \
         m4 \
         libgmp-dev \
         bubblewrap \
         opam \
         perl \
         openjdk-17-jdk \
         python3 \
         python3-pip \
         rsync; \
     fi \
  && rm -rf /var/lib/apt/lists/*

ENV CHECKERFRAMEWORK_HOME=/opt/checker-framework
ENV PATH=/root/.local/bin:${CHECKERFRAMEWORK_HOME}/checker/bin:${PATH}

RUN python3 -m pip install --no-cache-dir --break-system-packages "alectryon==${ALECTRYON_VERSION}" \
  && alectryon --version

COPY scripts/count_java_annotations.pl /root/.local/bin/count_java_annotations.pl
RUN chmod +x /root/.local/bin/count_java_annotations.pl

COPY scripts/install-rocq.sh /tmp/install-rocq.sh
COPY coq-record-update /tmp/coq-record-update-src
RUN chmod +x /tmp/install-rocq.sh \
  && OPAM_SWITCH_NAME=${OPAM_SWITCH_NAME} OPAM_OCAML_COMPILER=${OPAM_OCAML_COMPILER} COQ_CORE_VERSION=${COQ_CORE_VERSION} ROCQ_CORE_VERSION=${ROCQ_CORE_VERSION} ROCQ_STDLIB_VERSION=${ROCQ_STDLIB_VERSION} /tmp/install-rocq.sh \
  && rm -rf /tmp/install-rocq.sh /tmp/coq-record-update-src

WORKDIR /workspace
COPY . /workspace
RUN test -d /workspace/checker-framework \
  && test -d /workspace/jdk \
  && test -f /workspace/pico-rocq/Makefile \
  && test -f /workspace/pico-rocq/_RocqProject
RUN chmod +x /workspace/scripts/*.sh /workspace/checker-framework/gradlew /workspace/checker-framework/checker/bin/javac || true

ENTRYPOINT ["/workspace/scripts/run-artifact.sh"]
