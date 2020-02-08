function apply()
{
	if [ -z "${1+x}" ] || [ -z "${2+x}" ]; then
		echo "usage: <func> namespace name" >&2
		exit 1
	fi

	local namespace="${1}"
	local name="${2}"
	kubectl apply -f tidb-cluster.yaml -n "${namespace}"
	# TODO
	while true; do
		# wait for tidb cluster ready
	done

	kubectl apply -f tiflash.yaml -n "${namespace}"
}

export -f apply

