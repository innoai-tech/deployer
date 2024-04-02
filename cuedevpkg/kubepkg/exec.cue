package kubepkg

import (
	"piper.octohelm.tech/exec"
	"piper.octohelm.tech/wd"
)

#Exec: {
	cwd: wd.#WorkDir
	args: [...string]

	_bin: #Bin & {
		"cwd": cwd
	}

	_exec: exec.#Run & {
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
