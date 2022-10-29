# https://www.gnu.org/software/make/manual/html_node/Makefile-Conventions.html

SHELL = /bin/bash

.ONESHELL:
.SUFFIXES:

LIB = pytest_aiomoto

.PHONY: clean
clean:
	@rm -rf build dist .eggs *.egg-info
	@rm -rf .benchmarks .coverage coverage.xml htmlcov prof report.xml .tox
	@find . -type d -name '.mypy_cache' -exec rm -rf {} +
	@find . -type d -name '__pycache__' -exec rm -rf {} +
	@find . -type d -name '*pytest_cache*' -exec rm -rf {} +
	@find . -type f -name "*.py[co]" -exec rm -rf {} +

.PHONY: docs
docs: clean
	@rm -rf site
	@poetry run mkdocs build
	@echo -e "\033[95m\n\nBuild successful! View docs with 'mkdocs serve'\n\033[0m"

.PHONY: flake8
flake8: clean
	@poetry run flake8 --ignore=E501 $(LIB)

.PHONY: format
format: clean
	@poetry run black $(LIB) tests docs *.py

.PHONY: init
init: poetry
	@poetry env info
	[[ -f pip.conf ]] && cp pip.conf $$(poetry env info -p)
	poetry run python -m pip install --upgrade pip
	poetry install -v --no-interaction --extras docs

.PHONY: lint
lint: clean
	@poetry run pylint --disable=missing-docstring tests
	@poetry run pylint $(LIB)

.PHONY: test
test: clean
	@poetry run coverage run --source=$(LIB) -m pytest && poetry run coverage report

.PHONY: typehint
typehint: clean
	@poetry run mypy --follow-imports=skip $(LIB)

.PHONY: package
package: clean
	@poetry check
	@poetry build

.PHONY: package-check
package-check: package
	@poetry run twine check dist/*

.PHONY: package-publish
package-publish: package-check
	@poetry publish

.PHONY: poetry
poetry:
	@if ! command -v poetry > /dev/null; then \
        curl -sSL https://install.python-poetry.org | python -
	fi
	if ! echo "$PATH" | grep -Eq "(^|:)${HOME}/.local/bin($|:)" ; then \
		export PATH="${HOME}/.local/bin:${PATH}"; \
	fi
	poetry --version

.PHONY: poetry-export
poetry-export:
	poetry export --without-hashes -f requirements.txt -o requirements.txt
	sed -i -e 's/^-e //g' requirements.txt
