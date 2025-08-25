lint:
	swiftlint --strict

build:
	swift build

test:
	swift test

format:
	swiftformat . --swift-version 6
	swiftlint --fix

run-xconn:
	git clone https://github.com/xconnio/xconn-aat-setup.git
	cd xconn-aat-setup/nxt && make run
