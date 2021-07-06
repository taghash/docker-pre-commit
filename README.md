# Pre-commit Docker image

[Pre-commit](http://pre-commit.com/) is a tool created by Yelp that
allows you to run pre-commit sanity checks against your repo, to do
things like ensuring private keys aren't being added etc. This image
packages `pre-commit` in a docker-container, so you can ship it with
a setup script you might be using to setup local development environment.

# Usage

- Create `.pre-commit-config.yaml` in the root of your repo. For example

  ```yaml
  - repo: git://github.com/pre-commit/pre-commit-hooks
    sha: master  # Use the ref you want to point at
    hooks:
      - { id: check-case-conflict }
      - { id: check-merge-conflict }
      - { id: check-symlinks }
      - { id: check-json }
      - { id: check-yaml }
      - { id: detect-private-key }
      - { id: end-of-file-fixer }
      - { id: trailing-whitespace }
  ```
- Add `pre-commit` script to `.git/hooks/pre-commit`
  ```shell
  #!/bin/sh
  toplevel="`git rev-parse --show-toplevel`"
  NAME="`basename "$toplevel"`_precommit"

  cd "$toplevel"

  # Find container executable; either podman or docker
  if command -v podman > /dev/null 2>&1; then
      container_exec=podman
  elif command -v docker > /dev/null 2>&1; then
      container_exec=docker
  else
      echo "No container executable found! Looked for \`podman' and \`docker'."
      exit 1
  fi

  # Is there already a container for this source directory?
  test -n "`"$container_exec" ps -a -q --no-trunc --filter 'name=^/?'"$NAME"'$'`"
  CONTAINER_EXISTS=$?

  if [ "$CONTAINER_EXISTS" -eq 0 ]; then
      "$container_exec" restart "$NAME" >/dev/null && "$container_exec" attach --no-stdin "$NAME"
  else
      "$container_exec" run -t -v $(pwd):/pre-commit --name "$NAME" alexs77/pre-commit
  fi
  ```
- Create an empty commit to test
  ```shell
  git commit --allow-empty -m "Test pre-commit"
  ```

# Note
- If you are going to use a `pre-commit` plugin that needs dependencies
  not packaged in this image, you can extend this image and install the
  dependencies you need
- You might need to change the command, add volumes etc, based on your
  needs.
  For example, if you add `{ id: detect-aws-credentials }` to `.pre-commit-config.yaml`,
  you have to mount the directory holding your aws credentials.
  The docker command (as in the `pre-commit` script) would then become
  ```shell
  "$container_exec" run -t -v $(pwd):/pre-commit -v $HOME/.aws:/root/.aws:ro --name $NAME alexs77/pre-commit
  ```
