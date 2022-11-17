.PHONY: update version cards list clean build check release deploy local

SERVER_SSH ?= krcg_deploy@krcg.org:projects/lackey.krcg.org/dist
SSH_KEY_FILE ?= ~/.ssh/krcg_deploy
SERVER_HTTP ?= https://lackey.krcg.org
VERSION ?= $(shell date -u +"%F")

# update python requirements (for cardgen)
update:
	pip install -U pip
	pip install -r cardgen/requirements.txt

# set the version number
version:
	echo 'version = "${VERSION}"' > updatelist/version.py

# generate cards list plugin/sets/allsets.txt
cards:
	python -m cardgen

# generate plugin/updatelist.txt and modify version.txt if needed
list:
	LACKEY_SERVER_ROOT=${SERVER_HTTP} python -m updatelist

# remove build artifacts
clean:
	rm -rf build

# build plugin in the build folder, as it should appear on the local machine
build: clean
	LACKEY_SERVER_ROOT=${SERVER_HTTP} python -m builder

# check there is no standing change
# echo WTF
# echo `git branch --show-current`
# if [ `git branch --show-current` != "main"]; then echo A; else echo B; fi
# if [ `git branch --show-current` != "main"]; then $(error not on main branch) fi
check:
	if [ ! -z `git status --porcelain` ]; then $(error working directory is dirty) fi

# release (make sure there is no change, build the archive files, then tag and push)
release: version cards list check build
	git tag ${VERSION}
	git push origin ${VERSION}

# manual deploy from local (ssh access to server required)
deploy: check
	rsync -rlptq --delete-after -e ssh -i ${SSH_KEY_FILE} plugin/ ${SERVER_SSH}

# local deploy to the Lackey app (for testing purposes)
local: build
	rm -rf /Applications/LackeyCCG/plugins/vtes-test
	cp -r build/vtes /Applications/LackeyCCG/plugins/vtes-test
