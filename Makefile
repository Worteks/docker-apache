SKIP_SQUASH?=1

.PHONY: build
build:
	SKIP_SQUASH=$(SKIP_SQUASH) hack/build.sh

.PHONY: test
test:
	SKIP_SQUASH=$(SKIP_SQUASH) TAG_ON_SUCCESS=$(TAG_ON_SUCCESS) \
	    TEST_MODE=true hack/build.sh

.PHONY: run
run:
	docker run -e DEBUG=toto \
	    -e APACHE_DOMAIN=www.demo.local \
	    -e APACHE_HTTP_PORT=8080 \
	    -e PUBLIC_PROTO=http \
	    -p 8080:8080 wsweet/apache

.PHONY: ocbuild
ocbuild: occheck
	oc process -f openshift/imagestream.yaml -p FRONTNAME=wsweet | oc apply -f-
	BRANCH=`git rev-parse --abbrev-ref HEAD`; \
	if test "$$GIT_DEPLOYMENT_TOKEN"; then \
	    oc process -f openshift/build-with-secret.yaml \
		-p "APACHE_REPOSITORY_REF=$$BRANCH" \
		-p "FRONTNAME=wsweet" \
		-p "GIT_DEPLOYMENT_TOKEN=$$GIT_DEPLOYMENT_TOKEN" \
		| oc apply -f-; \
	else \
	    oc process -f openshift/build.yaml \
		-p "APACHE_REPOSITORY_REF=$$BRANCH" \
		-p "FRONTNAME=wsweet" \
		| oc apply -f-; \
	fi

.PHONY: occheck
occheck:
	oc whoami >/dev/null 2>&1 || exit 42

.PHONY: ocpurge
ocpurge:
	oc process -f openshift/build.yaml -p FRONTNAME=wsweet | oc delete -f- || true
	oc process -f openshift/imagestream.yaml -p FRONTNAME=wsweet | oc delete -f- || true
