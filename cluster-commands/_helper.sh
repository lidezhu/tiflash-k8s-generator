function get_pod_name()
{
	if [ -z "${1+x}" ] || [ -z "${2+x}" ] || [ -z "${3+x}" ] || [ -z "${4+x}" ]; then
		echo "usage: <func> namespace name mod pod-num" >&2
		exit 1
	fi

	local namespace="${1}"
	local name="${2}"
	local mod="${3}"
	local pod_num="${4}"

	if [ "${mod}" == "pd" ] || [ "${mod}" == "tikv" ] || [ "${mod}" == "tidb" ]; then
		echo "${name}-${mod}-${pod_num}"
	elif [ "${mod}" == "tiflash" ]; then
		echo "tiflash-${pod_num}"
	else
		echo "[func get_pod_name] unknown mod name ${mod}" >&2
		exit 1
	fi
}
export -f get_pod_name
