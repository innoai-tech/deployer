package kubepkg

import (
	"piper.octohelm.tech/client"
	"piper.octohelm.tech/file"
)

#Apply: {
	$dep?: _

	kubepkgFile: file.#File

	_env: client.#Env & {
		KUBECONFIG!: string
	}

	_bin: #Bin & {
		"cwd": kubepkgFile.wd
	}

	_exec: #Exec & {
		if $dep != _|_ {
			"$dep": $dep
		}

		"cwd": kubepkgFile.wd
		"args": [
			"apply",
			"--kubeconfig=\(_env.KUBECONFIG)",
			"--force=true",
			"--create-namespace=true",
			"./\(kubepkgFile.filename)",
		]
	}

	$ok: _exec.$ok
}
