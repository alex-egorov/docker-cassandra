default: docker_build

DOCKER_IMAGE ?= alex202/cassandra
TEST_COMMAND ?=

GIT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)

ifeq ($(GIT_BRANCH), master)
	DOCKER_TAG = latest
else
	DOCKER_TAG = $(GIT_BRANCH)
endif

# For debug. Usage: make print-VARIABLE
print-%  : ; @echo $* = $($*)

all: docker_build docker_test docker_push

clean:
	docker rmi -f $(DOCKER_IMAGE):$(DOCKER_TAG) || :

docker_build:
	docker build \
	  --build-arg VCS_REF=$$(git rev-parse --short HEAD) \
	  --build-arg BUILD_DATE=$$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
	  -t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	docker images | grep $(DOCKER_IMAGE)

docker_push:
	# Push to DockerHub
	docker push $(DOCKER_IMAGE):$(DOCKER_TAG)

docker_test:
	docker run --name cassandra --hostname cassandra.vnet -e MAX_HEAP_SIZE=2048M -e HEAP_NEWSIZE=800M -d  smizy/cassandra:${TAG}
	#docker run $(DOCKER_IMAGE):$(DOCKER_TAG) bash -c 'for i in $$(seq 200); do nc -z cassandra.vnet 9042 && echo "test starting" && break; echo -n .; sleep 1; [ $$i -ge 300 ] && echo timeout && exit 124; done'
