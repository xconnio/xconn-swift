lint:
	swiftlint --strict

build:
	swift build

test:
	swift test

format:
	swiftformat . --swift-version 6
	swiftlint --fix

