FROM debian:stable-slim

ENV PRE_COMMIT_VERSION 2.13.0

WORKDIR /pre-commit

RUN apt-get update && apt-get install -y \
      build-essential \
      git \
      python3-pip \
      python3 \
      && rm -rf /var/lib/apt/lists/*

RUN git init .

RUN pip3 install pre-commit==${PRE_COMMIT_VERSION} && \
      pre-commit install

CMD ["pre-commit", "run", "--all-files"]
