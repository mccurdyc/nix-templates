package config

import (
	"strings"
	"tool/file"
	"encoding/yaml"
)

fileHeader: "# DO NOT EDIT. Generated by CUE (build-helm-values). See Makefile\n---\n"

command: "build-helm-values": {
	// Because you can't use file.Read in a NON-_tool.cue file
	// https://github.com/cue-lang/cue/issues/2043#issuecomment-1291601109
	// file.Read NEEDS to be in a "command" block - https://github.com/cue-lang/cue/discussions/1832#discussioncomment-3316408
	read_files: {
		// CRITICAL You can NOT add `.contents` on the following line. They have to be separate calls.
		// EX: (file.Read & {...}).contents fails silently
		hello: (file.Read & {filename: "stages/raw/hello.txt", contents: string})
	}

	for stage in stages for region in stage.regions {
		"build-\(stage.name)-\(region.name)": file.Create & {
			// CRITICAL this MUST be the full path because we merge the two below.
			// There is no such thing as "injecting" a value and reading it in the k8s_data.cue
			// file. You have to merge them at this level.
			//
			// This is effectively setting one deeply-nested value.
			_merged: k8s.helmReleases["xxx-\(stage.name)-\(region.name)"] & {
				data: {
					"hello_rendered.txt": strings.TrimSpace(strings.Replace(read_files.hello.contents, "\t", "  ", -1))
          "toupper": toupper.#Transform({input: region.xxx.input}).output.value
        }
			}

			_serialized: yaml.Marshal(_merged)
			filename:    "../gen/\(stage.name)-\(region.name).yaml
			contents:    "\(fileHeader)\(_serialized)"
		}
	}
}
