package helm

import (
	"piper.octohelm.tech/exec"
	"piper.octohelm.tech/wd"
)

#Exec: {
	$dep?: _

	cwd: wd.#WorkDir
	args: [...string]

	_bin: #Bin & {
		"cwd": cwd
	}

	_exec: exec.#Run & {
		if $dep != _|_ {
			"$dep": $dep
		}

		"cwd": cwd
		"with": failfast: true
		"cmd": [
			"./\(_bin.file.filename)",
			for a in args {
				a
			},
		]
	}

	$ok: _exec.$ok
}
