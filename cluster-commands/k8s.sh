# apply(run)
# delete [false / true]
# clear
# show
# desc [mod] [num]
# log [mod] [num] [container]
# copy
# exec [mod] [num] [container]
# help (print real command behind)
source "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/_env.sh"


function k8s_command()
{
	if [ -z "${1+x}" ] || [ -z "${1}" ]; then
		echo "usage: <cmd> command" >&2
		exit 1
	fi

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
		command="apply"
	fi

	"${command}" "${namespace}" "${name}" "${@}"
}

k8s_command "${@}"
