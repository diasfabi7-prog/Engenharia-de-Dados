PYTHON ?= python3

.PHONY: help syntax lint test smoke check

help:
	@echo "make check  - executa todas as verificações sem baixar dados"
	@echo "make test   - executa testes unitários"
	@echo "make smoke  - valida a inicialização dos scripts"

syntax:
	@$(PYTHON) -c "import ast; from pathlib import Path; [ast.parse(path.read_text(encoding='utf-8')) for folder in ('scripts', 'notebooks') for path in Path(folder).glob('*.py')]; print('Sintaxe Python validada.')"

lint:
	@$(PYTHON) -m ruff check --select E9,F63,F7,F82 scripts tests

test:
	@$(PYTHON) -m pytest -q tests

smoke:
	@$(PYTHON) scripts/download_anp.py --list >/dev/null
	@$(PYTHON) scripts/inspect_raw.py --help >/dev/null
	@echo "Smoke test concluído."

check: syntax lint test smoke
