package tool

import (
	"piper.octohelm.tech/wd"
	"piper.octohelm.tech/file"

	kubepkgspec "github.com/octohelm/kubepkg/cuepkg/kubepkg"
	"github.com/innoai-tech/deployer/cuedevpkg/kubepkg"
)

#ComponentAction: {
	cwd!: wd.#WorkDir
	// 使用 deploy 时需要指定
	remote: wd.#WorkDir

	component: [Group=string]: [Name=string]: {
		output: kubepkgspec.#KubePkg & {
			metadata: namespace: _ | *"\(Group)"
		}
		...
	}

	// 导出 kubepkg json
	export: {
		for group, _components in component for name, c in _components {
			"\(group)": "\(name)": file.#WriteAsJSON & {
				"outFile": {
					"wd":       cwd
					"filename": "target/\(group)/\(name).kubepkg.json"
				}
				"data": {
					c.output
				}
			}
		}
	}

	_env: client.#Env & {
		TARGET_PLATFORM!: string
	}

	// 导出对应 airgap tar 包 和 yaml
	airgap: {
		for group, _components in component for name, _ in _components {
			"\(group)": "\(name)": kubepkg.#Airgap & {
				"platform":    _env.TARGET_PLATFORM
				"kubepkgFile": export["\(group)"]["\(name)"].file
			}
		}
	}

	// 直接部署给 k8s
	apply: {
		for group, _components in component for name, _ in _components {
			"\(group)": "\(name)": kubepkg.#Apply & {
				"kubepkgFile": export["\(group)"]["\(name)"].file
			}
		}
	}

	// 通过离线安装包部署
	deploy: {
		for group, _components in component for name, _ in _components {
			"\(group)": "\(name)": kubepkg.#Deploy & {
				"remote":      remote
				"kubepkgFile": export["\(group)"]["\(name)"].file
			}
		}
	}
}
