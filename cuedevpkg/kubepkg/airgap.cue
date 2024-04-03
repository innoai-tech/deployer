package kubepkg

import (
	"strings"

	"piper.octohelm.tech/client"
	"piper.octohelm.tech/file"
	"piper.octohelm.tech/wd"
)

#Airgap: {
	kubepkgFile!: file.#File
	platform!:    string

	_arch: strings.Split(platform, "/")[1]

	_env: client.#Env & {
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

	_tar_filename: strings.Replace(kubepkgFile.filename, ".kubepkg.json", ".\(_arch).tar", 1)
	_yaml_filename: strings.Replace(kubepkgFile.filename, ".kubepkg.json", ".yaml", 1)

	_exec: #Exec & {
		"cwd": kubepkgFile.wd
		"args": [
			"export",
			"--platform=\(platform)",
			"--storage-root=\(_rel.path)",
			"--output-oci=./\(_tar_filename)",
			"--output-manifests=./\(_yaml_filename)",
			"./\(kubepkgFile.filename)",
		]
	}

	$ok: _exec.$ok
}
