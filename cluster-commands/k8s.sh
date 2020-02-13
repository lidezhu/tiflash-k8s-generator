source "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/_env.sh"

function k8s_command()
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
		local namespace=`cat ./namespace`
	fi

	if [ ! -f "./name" ]; then
		echo "name file not found"
		exit 1
	else
		local name=`cat ./name`
	fi

	if [ "${command}" == 'run' ]; then
		local command="apply"
	fi

	kubectl get ns "${namespace}" >/dev/null 2>&1
	if [ "${?}" -ne 0 ]; then
		echo "[cmd k8s] namespace ${namespace} not found. creating"
		kubectl create ns "${namespace}"
	fi

	"${command}" "${namespace}" "${name}" "${@}"
}

k8s_command "${@}"
