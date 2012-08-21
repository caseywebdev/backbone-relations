BIN=node_modules/.bin/
COFFEE=$(BIN)coffee
MOCHA=$(BIN)mocha

all:
	$(COFFEE) -cb -o ./ ./

test:
	$(MOCHA)

.PHONY: all test
