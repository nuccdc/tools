#!/bin/sh

# Sets up local dev environment

set -x

DEV_DIR=$(dirname "$0")
export PIPENV_PIPFILE="${DEV_DIR}/Pipfile"

# install pipenv
pip install --no-cache-dir pipenv

# Install dev dependencies and allow prereleasees
pipenv install --dev --pre

# Install pre-commit hooks
pipenv run pre-commit install --install-hooks --overwrite
