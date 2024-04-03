package helm

import (
	"list"
	"path"
	"encoding/yaml"

	"piper.octohelm.tech/client"
	"piper.octohelm.tech/wd"
	"piper.octohelm.tech/http"
	"piper.octohelm.tech/file"

	kubepkgspec "github.com/octohelm/kubepkg/cuepkg/kubepkg"
)

#Step: {
	input?: string
	output: string
}

#ToKubePkg: {
	namespace!: string

	// helm chart
	chart!: {
		name!:   string
		version: string | *"1.0.0"
		dependencies: [Name=string]: {
			name:        Name
			repository!: string
			version!:    string
		}
	}

	// helm values
	values: {
		...
	}

	_bin: #Bin & {}

	_tmp: wd.#Temp & {
		id: "helm-charts/\(chart.name)@\(chart.version)"
	}

	_dep_charts: client.#Group & {
		for name, d in chart.dependencies {
			"\(name)": {
				_index: http.#Fetch & {
					url:   "\(d.repository)/index.yaml"
					hitBy: "Etag"
				}

				_read: file.#ReadFromYAML & {
					file: _index.file
				}
				// helm index struture
				// entries:
				//   <name>:
				//     version: <version>
				//     urls: [] 
				_matched: [
						for release in _read.data.entries[name] if release.version == d.version {
						release.urls[0]
					},
				][0]

				_tgz: http.#Fetch & {
					url:   _matched
					hitBy: "Etag"
				}

				_write: file.#Sync & {
					srcFile: _tgz.file
					outFile: {
						wd:       _tmp.dir
						filename: "charts/\(path.Base(_tgz.url))"
					}
				}
			}
		}
	}

	preConvert: [...#Step]

	exclude: [...string] | *[]

	manifests: {
		_write_chart_yaml: file.#WriteAsYAML & {
			$dep: _dep_charts.$ok

			outFile: {
				wd:       _tmp.dir
				filename: "Chart.yaml"
			}
			data: {
				apiVersion: "v2"
				name:       chart.name
				version:    chart.version
			}
		}

		_write_values_yaml: file.#WriteAsYAML & {
			$dep: _write_chart_yaml.$ok

			outFile: {
				wd:       _tmp.dir
				filename: "values.yaml"
			}

			data: values
		}

		_manifest_file: "manifests.yaml"

		_build: #Exec & {
			$dep:  _write_values_yaml.$ok
			"cwd": _tmp.dir
			"args": [
				"template --namespace=\(namespace) \(chart.name) . > \(_manifest_file)",
			]
		}

		_read: file.#ReadAsString & {
			$dep: _build.$ok

			file: {
				wd:       _tmp.dir
				filename: _manifest_file
			}
		}

		_preConvert: {
			"0": {
				output: _read.contents
			}

			for i, s in preConvert {
				"\(i+1)": s & {
					input: _preConvert["\(i)"].output
				}
			}
		}

		_manifests: client.#Wait & {
			_converted: _preConvert["\(len(_preConvert)-1)"].output

			data: yaml.UnmarshalStream(_converted)
		}

		output: _manifests.data
	}

	output: kubepkgspec.#KubePkg & {
		metadata: "namespace": namespace
		metadata: name:        chart.name
		spec: version:         chart.version

		for v in manifests.output {
			if v.kind != _|_ {
				let k = "\(v.metadata.name).\(v.kind)"

				if !list.Contains(exclude, k) {
					spec: manifests: "\(k)": v
				}
			}
		}
	}
}
