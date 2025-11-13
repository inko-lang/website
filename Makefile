# The Cloudflare Pages project to deploy to.
PROJECT := inko-lang-org
EXE := ./build/debug/main

exe:
	@inko build

build: exe
	@${EXE} build

sponsors: exe
	@${EXE} sponsors

packages: exe
	@${EXE} packages

watch:
	@bash scripts/watch.sh

clean:
	@rm -rf public build

deploy: build
	@npx wrangler pages deploy --project-name ${PROJECT} public

.PHONY: exe build watch clean deploy sponsors packages
