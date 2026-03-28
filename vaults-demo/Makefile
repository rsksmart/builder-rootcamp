SHELL := /bin/bash

.PHONY: build test test-fork test_fork fmt clean

build:
	forge build

test:
	forge test -vvv

# Make target names can't include ":" like npm scripts.
# Equivalent to `npm run test:fork`.
test-fork:
	set -euo pipefail; \
	if [ -f .env ]; then source .env; fi; \
	forge test -vvv --match-path "test/fork/*" --fork-url "$$RPC_URL"

# Alias
test_fork: test-fork

fmt:
	forge fmt

clean:
	rm -rf out cache


