.PHONY: lint

lint:
	docker run --rm \
		--platform linux/amd64 \
		-e RUN_LOCAL=true \
		-e DEFAULT_BRANCH=main \
		-e VALIDATE_ALL_CODEBASE=false \
		-e VALIDATE_CHECKOV=false \
		-e VALIDATE_JSCPD=false \
		-e VALIDATE_DOCKERFILE_HADOLINT=false \
		-e FILTER_REGEX_INCLUDE='(^|/)(Dockerfile|\\.github/workflows/.*\\.ya?ml|.*\\.md)$$' \
		-v "$$(pwd):/tmp/lint" \
		-w /tmp/lint \
		ghcr.io/super-linter/super-linter:slim-v7.4.0
