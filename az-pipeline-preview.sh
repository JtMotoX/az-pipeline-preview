#!/bin/sh

set -e
cd "$(dirname "$0")"

SCRIPT_NAME="$(basename "$0")"
BASE_NAME="${SCRIPT_NAME%.sh}"

show_help() {
	printf 'Usage: %s [OPTIONS]\n' "${SCRIPT_NAME}"
	printf '\n'
	printf 'Generate Azure Pipeline YAML from a preview run.\n'
	printf '\n'
	printf 'Options:\n'
	printf '  --project-name NAME    Azure DevOps project name (required)\n'
	printf '  --definition-id ID     Pipeline definition ID (required)\n'
	printf '  --branch BRANCH        Branch name (required)\n'
	printf '  --format FORMAT        Output format: yaml or json (default: yaml)\n'
	printf '  --output FILE          Output file path (default: /tmp/%s.yml|json)\n' "${BASE_NAME}"
	printf '  --help                 Show this help message\n'
	printf '\n'
	printf 'Example:\n'
	printf '  %s --project-name platform-services --definition-id 1823 --branch feature/add-logging\n' "${SCRIPT_NAME}"
}

PROJECT=""
PIPELINE_ID=""
BRANCH=""
FORMAT="yaml"
OUTPUT=""

while [ $# -gt 0 ]; do
	case "${1}" in
		--project-name)
			PROJECT="${2}"
			shift 2
			;;
		--definition-id)
			PIPELINE_ID="${2}"
			shift 2
			;;
		--branch)
			BRANCH="${2}"
			shift 2
			;;
		--format)
			FORMAT="${2}"
			if [ "${FORMAT}" != "yaml" ] && [ "${FORMAT}" != "json" ]; then
				printf 'Error: Invalid format. Must be yaml or json\n' >&2
				exit 1
			fi
			shift 2
			;;
		--output)
			OUTPUT="${2}"
			shift 2
			;;
		--help)
			show_help
			exit 0
			;;
		*)
			printf 'Error: Unknown option: %s\n' "${1}" >&2
			show_help >&2
			exit 1
			;;
	esac
done

if [ "${PROJECT}" = "" ] || [ "${PIPELINE_ID}" = "" ] || [ "${BRANCH}" = "" ]; then
	printf 'Error: Missing required arguments\n' >&2
	show_help >&2
	exit 1
fi

set +e
response=$(
	az rest \
		--method POST \
		--uri "https://dev.azure.com/netapp-ngdc/${PROJECT}/_apis/pipelines/${PIPELINE_ID}/preview?api-version=6.1-preview.1" \
		--body "{\"previewRun\":true,\"resources\":{\"repositories\":{\"self\":{\"refName\":\"refs/heads/${BRANCH}\"}}}}" \
		--resource 499b84ac-1321-427f-aa17-267ca6975798 \
		2>&1
)
set -e

if ! printf '%s' "${response}" | jq -e '.finalYaml' > /dev/null 2>&1; then
	printf 'Error: Failed to generate pipeline YAML\n' >&2
	printf '%s\n' "${response}" >&2
	exit 1
fi

if [ "${FORMAT}" = "json" ]; then
	output_file="${OUTPUT:-/tmp/${BASE_NAME}.json}"
	printf '%s' "${response}" | jq -r '.finalYaml' | yq eval -o=json - > "${output_file}"
	printf 'Pipeline JSON saved to %s\n' "${output_file}"
else
	output_file="${OUTPUT:-/tmp/${BASE_NAME}.yml}"
	printf '%s' "${response}" | jq -r '.finalYaml' > "${output_file}"
	printf 'Pipeline YAML saved to %s\n' "${output_file}"
fi