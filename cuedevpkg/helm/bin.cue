package helm

import (
	"piper.octohelm.tech/http"
	"piper.octohelm.tech/file"
	"piper.octohelm.tech/wd"
	"piper.octohelm.tech/archive"
)

#Bin: {
	cwd: wd.#WorkDir

	_tmp: wd.#Temp & {
		id: "bin/helm"
	}

	_sys_info: wd.#SysInfo & {
		"cwd": _tmp.dir
	}

	version: string | *"v3.14.3"
	os:      string | *"\(_sys_info.platform.os)"
	arch:    string | *"\(_sys_info.platform.arch)"

	_fetch: http.#Fetch & {
		url:   "https://get.helm.sh/helm-\(version)-\(os)-\(arch).tar.gz"
		hitBy: "Content-Md5"
	}

	_untar: archive.#UnTar & {
		srcFile:         _fetch.file
		contentEncoding: "gzip"
		outDir:          _tmp.dir
	}

	_ensure: file.#Ensure & {
		"cwd":  _untar.dir
		"path": "helm"
	}

	_rel: file.#Rel & {
		baseDir:    cwd
		targetFile: _ensure.file
	}

	"file": _rel.file
}
