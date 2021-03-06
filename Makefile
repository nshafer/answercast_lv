# Simple commands

# Dev
static:
	npm run deploy --prefix ./assets

push_static:
	rsync -P -pthrvzc priv/static/ answercast@answercast.app:/web/answercast/priv/static/

# Server
release:
	git pull
	MIX_ENV=prod mix deps.get --only prod
	MIX_ENV=prod mix phx.digest
	MIX_ENV=prod mix release --overwrite

.PHONY: static push_static release