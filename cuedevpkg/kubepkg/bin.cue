package kubepkg

import (
	"piper.octohelm.tech/http"
	"piper.octohelm.tech/file"
	"piper.octohelm.tech/wd"
	"piper.octohelm.tech/archive"
)

#Bin: {
	cwd: wd.#WorkDir

	_tmp: wd.#Temp & {
		"id": "bin/kubepkg"
	}

	_sys_info: wd.#SysInfo & {
		"cwd": _tmp.dir
	}

	version: string | *"v0.5.4"
	os:      string | *"\(_sys_info.platform.os)"
	arch:    string | *"\(_sys_info.platform.arch)"

	_fetch: http.#Fetch & {
		url:   "https://github.com/octohelm/kubepkg/releases/download/\(version)/kubepkg_\(os)_\(arch).tar.gz"
		hitBy: "Content-Md5"
	}

	_untar: archive.#UnTar & {
		srcFile:         _fetch.file
		contentEncoding: "gzip"
		outDir:          _tmp.dir
	}

	_ensure: file.#Ensure & {
		"cwd":  _untar.dir
		"path": "kubepkg"
	}

	_rel: file.#Rel & {
		baseDir:    cwd
		targetFile: _ensure.file
	}

	"file": _rel.file
}
