EXE := ./build/debug/main
SITE := inko-lang.org

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
	scripts/rclone.sh public "/var/lib/shost/${SITE}"

.PHONY: exe build watch clean deploy sponsors packages
