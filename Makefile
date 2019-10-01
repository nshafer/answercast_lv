# Simple commands

include .env
export

static:
	npm run deploy --prefix ./assets

push:
	rsync -P -pthrvzc priv/static/ answercast.app:/web/answercast_lv/priv/static/

build:
	git pull
	mix deps.get --only prod
	mix compile
	mix phx.digest

serve:
	mix phx.server

deploy: build serve

.PHONY: static build serve deploy