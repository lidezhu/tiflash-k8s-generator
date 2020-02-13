source "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/_env.sh"

function prepare_io_chaos()
{
	if [ ! -f "./namespace" ]; then
		echo "namespace file not found"
		exit 1
	else
		local namespace=`cat ./namespace`
	fi

	kubectl get ns "${namespace}" >/dev/null 2>&1
	if [ "${?}" -ne 0 ]; then
		echo "[cmd k8s] namespace ${namespace} not found. creating"
		kubectl create ns "${namespace}"
	fi

	kubectl label ns "${namespace}" admission-webhook=enabled

	kubectl annotate ns "${namespace}" admission-webhook.pingcap.com/init-request=chaosfs-tiflash
}

prepare_io_chaos "${@}"
