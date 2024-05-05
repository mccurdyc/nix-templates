package config

import (
	"strings"
	"encoding/yaml"
)

k8s: helmReleases: {}

for stage in stages for region in stage.regions {
	k8s: helmReleases: "\(stage.name)-\(region.name)": {
		apiVersion: "v1"
		kind: "ConfigMap"
		metadata: name: "xxx-\(stage.name)-\(region.name)"

		data: {
      xxx: 
    }
	}
}
