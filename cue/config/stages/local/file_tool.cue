package config

import (
	"strings"

	"tool/file"
	"tool/exec"
)

localFileHeader: "# DO NOT EDIT. Generated by CUE (dump-local-files). See config/stages/local/files.cue\n---\n"

// Reference - https://cuetorials.com/patterns/scripts-and-tasks/#scripts-with-args
args: {
	dir:  string | *"../local" @tag(dir)
	_dir: strings.TrimSuffix(dir, "/")
}

command: "write-local-files": {
	clean: exec.Run & {
		cmd: "rm -rf \(args._dir)/{gen}"
	}

	read_raw_files: {
		"hello_raw.txt":      (file.Read & {filename: "stages/raw/hello.txt", contents:      bytes}).contents
	}

	mkdir: {
		gen: file.MkdirAll & {
			// Reference - https://cuetorials.com/patterns/scripts-and-tasks/
			$dep: clean.$done //  explicit dependency 
			path: "\(args._dir)/gen/"
		}
	}

	headerFiles: {
		for f, body in files {
			"local-file-\(f)": file.Create & {
				$dep:     mkdir.gen.$done //  explicit dependency 
				filename: "\(args._dir)/\(f)"
				contents: "\(localFileHeader)\(body)"
			}
		}
	}

	withoutHeaderFiles: {
		for f, body in files_without_header & read_files {
			"local-file-\(f)": file.Create & {
				$dep:     mkdir.gen.$done //  explicit dependency 
				filename: "\(args._dir)/\(f)"
				contents: "\(body)"
			}
		}
	}
}