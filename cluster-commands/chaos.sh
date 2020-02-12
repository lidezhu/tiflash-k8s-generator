source "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/_env.sh"

function chaos_command()
{
	if [ -z "${1+x}" ] || [ -z "${1}" ]; then
		echo "usage: <cmd> command" >&2
		exit 1
	fi

	local command="${1}"

	shift 1

	if [ ! -f "./namespace" ]; then
		echo "namespace file not found"
		exit 1
	else
		local chaos_namespace=`cat ./chaos_namespace`
	fi

	kubectl get ns "${chaos_namespace}" >/dev/null 2>&1
	if [ "${?}" -ne 0 ]; then
		kubectl create ns "${chaos_namespace}"
	fi

	"chaos_${command}" "${chaos_namespace}" "${@}"
}

chaos_command "${@}"
