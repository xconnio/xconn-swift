lint:
	swiftlint --strict

build:
	swift build

test:
	swift test

format:
	swiftformat . --swift-version 6
	swiftlint --fix

setup-and-run-xconn:
	git clone https://github.com/xconnio/xconn-aat-setup.git .xconn-aat-setup
	cd .xconn-aat-setup/nxt && make run

run-xconn:
	cd .xconn-aat-setup/nxt && make run

