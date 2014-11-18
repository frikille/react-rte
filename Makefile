default: all

SRC = $(shell find src -name "*.ls" -type f | sort)
LIB = $(SRC:src/%.ls=lib/%.js)
LS = node_modules/LiveScript
LSC = node_modules/.bin/lsc

lib:
	mkdir -p lib/

lib/%.js: src/%.ls lib
	$(LSC) --output lib --bare --compile "$<"

all: build

build: $(LIB) package.json

clean:
	rm -f ./*.js
	rm -rf lib
	rm -rf browser
	rm -rf coverage
	rm -f package.json
