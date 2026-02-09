# Container Engine and Base Image
ENGINE ?= docker
BASE_IMG_MINIO = quay.io/jooholee/model-minio
BASE_IMG = quay.io/jooholee/model-seaweedfs
TAG ?= latest

# Tag Mappings(Bucket)
TAGS_MAP_s3 = ods-ci-s3
TAGS_MAP_wisdom = ods-ci-wisdom
TAGS_MAP_latest = example-models

# Full image helper (indirect reference)
define FULL_IMAGE
$(BASE_IMG):$(TAGS_MAP_$(1))
endef

# Generalized build target
.PHONY: build-%  # e.g., build-s3 or build-wisdom
build-%:
	./hacks/build-image.sh $(ENGINE) "$(BASE_IMG):$(TAGS_MAP_$*)" "$(TAGS_MAP_$*)"

# Default build (uses TAG)
.PHONY: build
build:
	echo "$(TAGS_MAP_latest)"
	./hacks/build-image.sh $(ENGINE) "$(BASE_IMG):$(TAG)" "$(TAGS_MAP_latest)"

.PHONY: push-%
push-%:
	$(ENGINE) tag $(BASE_IMG):$(TAGS_MAP_$*) $(BASE_IMG):$(shell date +%Y%m%d)
	$(ENGINE) push $(BASE_IMG):$(shell date +%Y%m%d)
	$(ENGINE) push $(BASE_IMG):$(TAGS_MAP_$*)
# Default push (uses TAG)
.PHONY: push
push:
	$(ENGINE) tag $(BASE_IMG):$(TAG) $(BASE_IMG):$(shell date +%Y%m%d)
	$(ENGINE) push $(BASE_IMG):$(shell date +%Y%m%d)
	$(ENGINE) push $(BASE_IMG):$(TAG)

# Build and push all variants (s3, wisdom, latest)
.PHONY: build-all
build-all:
	$(MAKE) build-s3
	$(MAKE) build-wisdom
	$(MAKE) build

.PHONY: push-all
push-all:
	$(MAKE) push-s3
	$(MAKE) push-wisdom
	$(MAKE) push

.PHONY: all
all: build-all push-all
