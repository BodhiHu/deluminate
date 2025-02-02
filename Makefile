.PHONY: clean package test

SHELL := /bin/bash

MANIFEST := \
	animated_gif_checker.js \
	background.js \
	common.js \
	deluminate-*.png \
	deluminate.css \
	deluminate.js \
	manifest.json \
	options.html \
	options.js \
	popup.html \
	popup.js

BUILD_DIR := build

LAST_VERSION_COMMIT := $(shell git blame manifest.json | grep \\bversion \
	| cut -d' ' -f1)
BUILD_NUM := $(shell git log $(LAST_VERSION_COMMIT)..HEAD --oneline \
	| wc -l | tr -d ' ')
PKG_SUFFIX := $(shell git symbolic-ref --short HEAD \
	| sed '/^master$$/d;s/^/-/')

package: deluminate$(PKG_SUFFIX).zip

deluminate.zip: $(MANIFEST)
	zip "$@" $(MANIFEST)

deluminate%.zip: $(MANIFEST) | $(BUILD_DIR)
	rm -f $(BUILD_DIR)/*
	cp $(MANIFEST) $(BUILD_DIR)/
	cp $(BUILD_DIR)/manifest.json $(BUILD_DIR)/manifest.json.orig
	sed -e '/"version"/s/"[^"]*$$/.$(BUILD_NUM)&/' \
		-e 's/"Deluminate"/"Deluminate$(PKG_SUFFIX)"/' \
		"$(BUILD_DIR)/manifest.json.orig" > "$(BUILD_DIR)/manifest.json"
	cd $(BUILD_DIR) && zip "../$@" $(MANIFEST)

$(BUILD_DIR):
	mkdir $@

clean:
	rm -f deluminate*.zip
	find spec -name 'junit*.xml' -exec rm -f {} +

test: node_modules
	npm test

node_modules: package.json
	npm install

deploy: deluminate.zip node_modules
	npm run deploy -- "$<"

deploy-dev: deluminate$(PKG_SUFFIX).zip node_modules
	npm run deploy-dev -- "$<"
