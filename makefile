# Static ———————————————————————————————————————————————————————————————————————————————————————————————————————————————
LC_LANG				= it_IT
DEFAULT_GOAL 		:= help
SHELL 				= /bin/bash

RED					= \033[0;31m
GREEN				= \033[0;32m
ORANGE				= \033[0;33m
NC					= \033[0m

# Setup ————————————————————————————————————————————————————————————————————————————————————————————————————————————————
env					:= dev
docker-os			:= mac
java_container		:= java_nome_app_app
node_container		:= nodejs
docker_compose_exec := docker-compose
project_name		:= $(shell basename $(CURDIR))
compose				:= $(docker_compose_exec) --file docker/docker-compose.yml --file docker/docker-compose.override.yml
maven_version		:= maven:3-openjdk-17-slim


.PHONY: start
start: ## avvia tutti i servizi
		$(compose) -p $(project_name) start

.PHONY: stop
stop: ## ferma l'ambiente di sviluppo
		$(compose) -p $(project_name) stop $(s)

.PHONY: up
up: ## tira su l'ambiente di sviluppo
		$(compose) -p $(project_name) up -d --remove-orphans

.PHONY: rebuild
rebuild: ## esegue un rebuild del sistema
		$(compose) -p $(project_name) up -d --build

.PHONY: log
log: ## mostra i log del container su stdout
		$(compose) -p $(project_name) logs -f -t $(java_container)

.PHONY: erase
erase: ## ferma ed elimina i containers ed i loro volume
		$(compose) -p $(project_name) stop
		$(compose) -p $(project_name) down -v --remove-orphans

.PHONY: prepare
prepare: hooks ## esegue la preparazione dell'ambiente
		test -s docker/java/properties || mkdir -p docker/java/properties
		cp -R properties/local docker/java/properties
		test -s docker/java/target || mkdir -p docker/java/target
		test -s docker/docker-compose.override.yml || cp docker/docker-compose.override.dist.yml docker/docker-compose.override.yml
		rm -rf docker/java/target/*
		docker run --rm -v "$(CURDIR):/opt/maven" -v maven-repo:/root/.m2 -w /opt/maven $(maven_version) mvn clean install -DskipTests
		cp target/*.jar docker/java/target

.PHONY: hooks
hooks: ## aggiunge gli hooks di Git
		test -s .git || rm -rf .git/hooks && ln -s ../scripts/git-hooks .git/hooks

.PHONY: build
build: prepare ## esegue un build del sistema
		$(compose) -p $(project_name) build

.PHONY: coverage
coverage: ## esegue phpunit
		docker run --rm -v "$(CURDIR):/opt/maven" -v maven-repo:/root/.m2 -w /opt/maven $(maven_version) mvn clean install -Pbadge


.PHONY: junit
junit: ## esegue phpunit
		docker run --rm -v "$(CURDIR):/opt/maven" -v maven-repo:/root/.m2 -w /opt/maven $(maven_version) mvn clean verify

.PHONY: junit-debug
junit-debug: ## esegue phpunit
		docker run --rm -p 5009:5005 -v "$(CURDIR):/opt/maven" -v maven-repo:/root/.m2 -w /opt/maven $(maven_version) mvn clean verify -Dmaven.surefire.debug="-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=*:5005"

.PHONY: test
test: junit ## esegue phpunit


.PHONY: qa
# test: wiremock_start redis_start phpunit redis_stop wiremock_stop ## esegue i test unitari e di integrazione
qa: sonarqube_start sonarqube_qa sonarqube_stop## esegue i test unitari e di integrazione

.PHONY: enter
enter: ## entra in ambiente bash
		$(compose) -p $(project_name) exec -u utente $(php_container) //bin//bash

.PHONY: root
root: ## entra in ambiente bash come root
		$(compose) -p $(project_name) exec -u root $(php_container) //bin//bash

.PHONY: wiremock_start
wiremock_start: ## avvia il mock server
		$(compose) -p $(project_name) up -d wiremock

.PHONY: wiremock_stop
wiremock_stop: ## termina il mock server
		$(compose) -p $(project_name) stop wiremock
		
.PHONY: sonarqube_start
sonarqube_start: ## avvia sonarqube
		$(compose) --file docker/docker-compose.qa.yml -p $(project_name) up -d sonarqube

.PHONY: sonarqube_stop
sonarqube_stop: ## termina sonarqube
		$(compose) --file docker/docker-compose.qa.yml -p $(project_name) stop sonarqube

.PHONY: sonarqube_qa
sonarqube_qa: ## esegue localmente il quality gateway
		./docker/sonarqube/waitforsonar.sh
		./docker/sonarqube/changepassword.sh
		docker run --rm -v "$(CURDIR):/opt/maven" -v maven-repo:/root/.m2 -w /opt/maven $(maven_version) mvn clean verify sonar:sonar -Dsonar.host.url=http://host.docker.internal:9000 -Dsonar.login=admin -Dsonar.password=admin

.PHONY: redis_start
redis_start: ## avvia Redis
		$(compose) -p $(project_name) up -d serviceredis

.PHONY: redis_stop
redis_stop: ## termina Redis
		$(compose) -p $(project_name) stop serviceredis

.PHONY: commitlint
commitlint:
	$(compose) -p $(project_name) run --rm $(node_container) sh -lc 'commitlint -e --from=HEAD'

.PHONY: help
help: ## Mostra questo messaggio
	@cat $(MAKEFILE_LIST) | grep -e "^[a-zA-Z_\-]*: *.*## *" | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
