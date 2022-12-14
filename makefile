VERSION := $(shell grep -Eo '(\d\.\d\.\d)(-dev)?' main.go)

.PHONY: build check test mkrel upload

linux: linux_amd64
linux_amd64:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o bin/vault-backend-migrator-linux-amd64 github.com/gorshtein/vault-backend-migrator

osx: osx_amd64
osx_amd64:
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -o bin/vault-backend-migrator-osx-amd64 github.com/gorshtein/vault-backend-migrator

win: win_64
win_64:
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -o bin/vault-backend-migrator-amd64.exe github.com/gorshtein/vault-backend-migrator

dist: build linux osx win

check:
	go vet ./...
	go fmt ./...

test: check dist
	go test -v ./...

ci: check dist test

build: check
	go build -o vault-backend-migrator github.com/gorshtein/vault-backend-migrator
	@chmod +x vault-backend-migrator

docker: dist
	docker build -t gorshtein/vault-backend-migrator:$(VERSION) .

dockerpush: docker
	docker push gorshtein/vault-backend-migrator:$(VERSION)

release: ci docker dockerpush mkrel upload

tag:
	git tag $(VERSION)
	git push --tags origin $(VERSION)

mkrel: tag
ifeq ($(DEV), )
  $(shell gothub release -u gorshtein -r vault-backend-migrator -t $(VERSION) --name $(VERSION) --pre-release)
else
  $(shell gothub release -u gorshtein -r vault-backend-migrator -t $(VERSION) --name $(VERSION))
endif

upload:
	gothub upload -u gorshtein -r vault-backend-migrator -t $(VERSION) --name "vault-backend-migrator-linux" --file bin/vault-backend-migrator-linux-amd64
	gothub upload -u gorshtein -r vault-backend-migrator -t $(VERSION) --name "vault-backend-migrator-osx" --file bin/vault-backend-migrator-osx-amd64
	gothub upload -u gorshtein -r vault-backend-migrator -t $(VERSION) --name "vault-backend-migrator.exe" --file bin/vault-backend-migrator-amd64.exe
