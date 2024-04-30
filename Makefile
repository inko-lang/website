# The Cloudflare Pages project to deploy to.
PROJECT := inko-lang-org

build:
	@inko build
	@./build/main build

sponsors:
	@inko build
	@./build/main sponsors

packages:
	@inko build
	@./build/main packages

setup:
	@inko pkg sync

watch:
	@bash scripts/watch.sh

clean:
	@rm -rf public

deploy:
	@npx wrangler pages deploy --project-name ${PROJECT} public

.PHONY: setup build watch clean deploy sponsors packages
