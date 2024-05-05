cue_mkfile := $(abspath $(lastword $(MAKEFILE_LIST)))
cue_dir := $(dir $(cue_mkfile))

# Generates Helm values YAMLs from their CUE definitions and writes to data/ directory.
.PHONY: write/yaml
write/yaml:
	@cd $(cue_dir) && \
	cue cmd --strict --verbose --all-errors --trace --simplify build-helm-values $(DIR)

write/all-yaml: write/prd-xxx-yaml write/local-yaml
write/prd-xxx-yaml:
	$(MAKE) write/yaml DIR=./stages/prd/regions/xxx/
write/local-yaml:
	$(MAKE) write/yaml DIR=./stages/local/regions/local/

# Vet all stage CUE definitions.
cue/vet:
	@cd $(cue_dir) && \
	cue vet --concrete --strict --verbose --all-errors --trace --simplify $(DIR)

cue/all-vet: cue/prd-xxx-vet cue/local-vet
cue/prd-xxx-vet:
	$(MAKE) cue/vet DIR=./stages/prd/regions/xxx/
cue/local-vet:
	$(MAKE) cue/vet DIR=./stages/local/regions/local/

.PHONY: cue/fmt
cue/fmt:
	@cd $(cue_dir) && \
	cue fmt ./...

write/local-files:
	@cd $(cue_dir) && \
	cue cmd -t dir="../local" write-local-files ./stages/local

# Generate a CUE schema from https://github.com/compose-spec/compose-spec/blob/master/schema/compose-spec.json
cue/import-compose-spec:
	@cd "$(cue_dir)compose" && \
	curl -sL https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json > compose-spec.json && \
	cue import \
		-f \
		--outfile - \
		-l '#ComposeSpec:' \
		--package 'compose' \
		compose-spec.json \
	| sed \
		'1s;^;// DO NOT EDIT\n// Generated from "make cue/import-compose-spec".\n// See Makefile\n;' \
		> compose.cue
