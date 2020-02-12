source "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/_env.sh"


function test_command()
{
	if [ -z "${1+x}" ] || [ -z "${1}" ]; then
		echo "usage: <cmd> command" >&2
		exit 1
	fi

	local command="${1}"

	shift 1

	if [ ! -f "./test_namespace" ]; then
		echo "test namespace file not found"
		exit 1
	else
		local namespace=`cat ./test_namespace`
	fi

	kubectl get ns "${namespace}" >/dev/null 2>&1
	if [ "${?}" -ne 0 ]; then
		echo "[cmd k8s] namespace ${namespace} not found. creating"
		kubectl create ns "${namespace}"
	fi

	"test_${command}" "${namespace}" "${@}"
}

test_command "${@}"
