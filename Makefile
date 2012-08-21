BIN=node_modules/.bin/
COFFEE=$(BIN)coffee
MOCHA=$(BIN)mocha

all:
	$(COFFEE) -c -o ./dist ./lib

test:
	$(MOCHA)

.PHONY: all test
