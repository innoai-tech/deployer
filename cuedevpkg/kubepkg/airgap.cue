package kubepkg

import (
	"piper.octohelm.tech/client"
	"piper.octohelm.tech/file"
	"piper.octohelm.tech/wd"
)

#Airgap: {
	kubepkgFile!: file.#File

	_env: client.#Env & {
		TARGET_PLATFORM!:                  string
		KUBEPKG_REMOTE_REGISTRY_ENDPOINT!: string
		KUBEPKG_REMOTE_REGISTRY_USERNAME!: string
		KUBEPKG_REMOTE_REGISTRY_PASSWORD!: client.#Secret
	}

	_bin: #Bin & {
		"cwd": kubepkgFile.wd
	}

	_tmp: wd.#Temp & {
		"id": "kubepkg-cache"
	}

	_rel: wd.#Rel & {
		baseDir:   kubepkgFile.wd
		targetDir: _tmp.dir
	}

	_exec: #Exec & {
		"cwd": kubepkgFile.wd
		"args": [
			"export",
			"--platform=\(_env.TARGET_PLATFORM)",
			"--storage-root=\(_rel.path)",
			"--output-oci=./\(kubepkgFile.filename).tar",
			"--output-manifests=./\(kubepkgFile.filename).yaml",
			"./\(kubepkgFile.filename)",
		]
	}

	$ok: _exec.$ok
}