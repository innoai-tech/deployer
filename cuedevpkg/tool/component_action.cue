package tool

import (
	"piper.octohelm.tech/wd"
	"piper.octohelm.tech/file"

	kubepkgspec "github.com/octohelm/kubepkg/cuepkg/kubepkg"
	"github.com/innoai-tech/deployer/cuedevpkg/kubepkg"
)

#ComponentAction: {
	cwd!: wd.#WorkDir
 	// 集群名称
	clusterName!: string
	// 目标架构
	platform!: string
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
					"filename": "target/\(clusterName)/\(group)/\(name).kubepkg.json"
				}
				"data": {
					c.output
				}
			}
		}
	}

	// 导出对应 airgap tar 包 和 yaml
	airgap: {
		for group, _components in component for name, _ in _components {
			"\(group)": "\(name)": kubepkg.#Airgap & {
				"platform":    platform
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
