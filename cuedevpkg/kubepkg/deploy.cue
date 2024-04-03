package kubepkg

import (
	"path"
	"strings"

	"piper.octohelm.tech/file"
	"piper.octohelm.tech/wd"
	"piper.octohelm.tech/exec"
)

#Deploy: {
	remote!:      wd.#WorkDir
	kubepkgFile!: file.#File

	_info: wd.#SysInfo & {
		cwd: remote
	}

	targetDir: string | *"/data/airgaps"

	_sync_oci_tar: file.#Sync & {
		srcFile: file.#File & {
			wd:       kubepkgFile.wd
			filename: strings.Replace(kubepkgFile.filename, ".kubepkg.json", ".\(_info.platform.arch).tar", 1)
		}

		outFile: {
			wd: remote
			filename: path.Join(["\(targetDir)", "\(path.Base(srcFile.filename))"])
		}
	}

	_sync_manifests_yaml: file.#Sync & {
		srcFile: file.#File & {
			wd:       kubepkgFile.wd
			filename: strings.Replace(kubepkgFile.filename, ".kubepkg.json", ".yaml", 1)
		}

		outFile: {
			wd: remote
			filename: path.Join(["\(targetDir)", "\(path.Base(srcFile.filename))"])
		}
	}

	_import_oci_tar: exec.#Run & {
		cwd: _sync_oci_tar.file.wd
		cmd: "ctr -n k8s.io i import \(_sync_oci_tar.file.filename)"
	}

	_kubectl_apply: exec.#Run & {
		$dep: _import_oci_tar.$ok

		cwd: _sync_manifests_yaml.file.wd
		cmd: "kubectl apply --force -f \(_sync_manifests_yaml.file.filename)"
	}

	$ok: _kubectl_apply.$ok
}
