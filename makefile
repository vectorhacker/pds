test:
	bash ci/test.sh

build:
	bash ci/build.sh

clean:
	rm -rf vendor
	bash ci/clean.sh

dev-build: build
	bash ci/dev-build.sh
	
dev:
	bash vagrant/dev-watch.sh