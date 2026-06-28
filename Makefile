.PHONY: install build test test-unit test-integration test-acceptance run docker-build docker-up clean

install:
	pip3 install -r requirements.txt

build:
	python3 -m compileall app

test:
	pytest tests/ -v --cov=app --cov-report=term-missing

test-unit:
	pytest tests/unit/ -v

test-integration:
	pytest tests/integration/ -v

test-acceptance:
	pytest tests/acceptance/ -v

run:
	uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

docker-build:
	docker compose build

docker-up:
	docker compose up -d

clean:
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	rm -rf .pytest_cache .coverage htmlcov
