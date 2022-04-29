# Pre-commit Docker image

[Pre-commit](http://pre-commit.com/) is a tool created by Yelp that allows you to run pre-commit sanity checks against your repo, to do things like ensuring private keys aren't being added etc. This image packages `pre-commit` in a docker-container, so you can ship it with a setup script you might be using to setup local development environment.

## Usage

- Create `.pre-commit-config.yaml` in the root of your repo. For example

```yaml

---
default_stages: ["commit", "push", "manual"]
repos:

- repo: <https://github.com/pre-commit/pre-commit-hooks>
    rev: v4.1.0
    hooks:
  - id: detect-aws-credentials
        args: ["--allow-missing-credentials"]
  - id: detect-private-key

- repo: <https://github.com/gruntwork-io/pre-commit>
    rev: v0.1.17
    hooks:
  - id: tflint
  - id: terraform-fmt
  - id: terraform-validate
    args:
      - "--module"

- repo: <https://github.com/antonbabenko/pre-commit-terraform>
    rev: v1.59.0
    hooks:
  - id: terraform_docs
        args:
    - "--hook-config=--path-to-file=README.md"
    - "--hook-config=--add-to-existing-file=true"
    - "--hook-config=--create-file-if-not-exist=true"
  - id: checkov
        verbose: true
        args:
    - "--soft-fail"
    - "--skip-check"
    - "CKV_AWS_145" # <https://docs.bridgecrew.io/docs/ensure-that-s3-buckets-are-encrypted-with-kms-by-default>
    - "--skip-check"
    - "CKV_AWS_19" # <https://docs.bridgecrew.io/docs/s3_14-data-encrypted-at-rest>
    - "--skip-check"
    - "CKV_AWS_18" # <https://docs.bridgecrew.io/docs/s3_13-enable-logging>
    - "--skip-check"
    - "CKV_AWS_144" # <https://docs.bridgecrew.io/docs/ensure-that-s3-bucket-has-cross-region-replication-enabled>
    - "--skip-check"
    - "CKV_AWS_21" # <https://docs.bridgecrew.io/docs/s3_16-enable-versioning>

```

- Add `pre-commit` script to `.git/hooks/pre-commit`

  ```shell
  cd $(git rev-parse --show-toplevel)

  NAME=$(basename `git rev-parse --show-toplevel`)_precommit
  docker ps -a | grep $NAME &> /dev/null
  CONTAINER_EXISTS=$?

  if [[ CONTAINER_EXISTS -eq 0 ]]; then
      docker restart $NAME && docker attach --no-stdin $NAME
  else
      docker run -t -v $(pwd):/pre-commit --name $NAME taghash/pre-commit
  fi

  ```

- Create an empty commit to test
  ```git commit --allow-empty -m "Test pre-commit"```

## Note

- If you are going to use a `pre-commit` plugin that needs dependencies not packaged in this image, you can extend this image and install the dependencies you need
- You might need to change the command, add volumes etc, based on your needs.
  For example, if you add `{ id: detect-aws-credentials }` to `.pre-commit-config.yaml`, you have to mount the directory holding your aws credentials.
  The docker command (as in the `pre-commit` script) would then become

  ```shell
  docker run -t -v $(pwd):/pre-commit -v $HOME/.aws:/root/.aws:ro --name $NAME taghash/pre-commit
  ```
