source "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/_helper.sh"

function help()
{
	if [ -z "${1+x}" ] || [ -z "${2+x}" ]; then
		echo "usage: <cmd>" >&2
		exit 1
	fi

	local namespace="${1}"
	local name="${2}"
	cat ./k8s_help
}

export -f help

function apply()
{
	if [ -z "${1+x}" ] || [ -z "${2+x}" ]; then
		echo "usage: <cmd>" >&2
		exit 1
	fi

	local namespace="${1}"
	local name="${2}"
	kubectl apply -f tidb-cluster.yaml -n "${namespace}"
	while true; do
		local pd_ready_num=`kubectl get pod -n "${namespace}" | grep pd | grep Running | wc -l`
		local tikv_ready_num=`kubectl get pod -n "${namespace}" | grep tikv | grep Running | wc -l`
		local tidb_ready_num=`kubectl get pod -n "${namespace}" | grep tidb | grep Running | wc -l`
		if [ "${pd_ready_num}" -eq 3 ] && [ "${tikv_ready_num}" -eq 3 ] && [ "${tidb_ready_num}" -eq 1 ]; then
			break
		fi
		echo "wait for tidb cluster ready"
		sleep 10
	done
	
	local temp_pd_port=12399
	local count=`ps -ef | grep port-forward | grep ${temp_pd_port} | wc -l`
	if [ ${count} != 0 ]; then
		ps -ef | grep port-forward | grep ${temp_pd_port} | awk '{print $2}' | xargs kill -9
	fi
	port "${namespace}" "${name}" "pd" ${temp_pd_port}
	if [ ! -f "./pd-ctl" ]; then
		wget http://139.219.11.38:8000/10zs84/pd-ctl.tar.gz
		tar -zxvf pd-ctl.tar.gz
	fi
	while true; do
		local count=`./pd-ctl -u http://127.0.0.1:${temp_pd_port} config set enable-placement-rules true | grep Failed | wc -l`
		if [ ${count} == "0" ]; then
			break
		fi
		sleep 10
	done

	kubectl apply -f tiflash.yaml -n "${namespace}"
	while true; do
		local tiflash_ready_num=`kubectl get pod -n "${namespace}" | \
			grep tiflash | grep -v pd  | grep -v tikv | grep -v tidb | grep -v discovery | \
			grep Running | wc -l`
		if [ "${tiflash_ready_num}" -eq 3 ]; then
			break
		fi
		echo "wait for tiflash pod ready"
		sleep 10
	done
}

export -f apply

function clear()
{
	if [ -z "${1+x}" ] || [ -z "${2+x}" ]; then
		echo "usage: <cmd>" >&2
		exit 1
	fi

	local namespace="${1}"
	local name="${2}"

	kubectl delete pvc --all -n "${namespace}"
	echo "delete pvc done"
}
export -f clear

function delete()
{
	if [ -z "${1+x}" ] || [ -z "${2+x}" ]; then
		echo "usage: <cmd>" >&2
		exit 1
	fi

	local namespace="${1}"
	local name="${2}"

	if [ -z "${3+x}" ]; then
		local clear_data='true'
	else
		local clear_data='${3}'
	fi

	kubectl delete -f tiflash.yaml -n "${namespace}"
	sleep 5
	kubectl delete -f tidb-cluster.yaml -n "${namespace}"
	while true; do
		local pod_count=`kubectl get pod -n "${namespace}" | wc -l`
		if [ "${pod_count}" == "0" ]; then
			break
		fi
		echo "wait for all pod terminate"
		sleep 10
	done
	if [ "${clear_data}" == 'true' ]; then
		clear "${namespace}" "${name}"
	fi
}
export -f delete

function show()
{
	if [ -z "${1+x}" ] || [ -z "${2+x}" ]; then
		echo "usage: <cmd>" >&2
		exit 1
	fi

	local namespace="${1}"
	local name="${2}"

	kubectl get pod -n "${namespace}"
}
export -f show

function desc()
{
	if [ -z "${1+x}" ] || [ -z "${2+x}" ] || [ -z "${3+x}" ] || [ -z "${4+x}" ]; then
		echo "usage: <cmd> mod pod-num" >&2
		exit 1
	fi

	local namespace="${1}"
	local name="${2}"
	local mod="${3}"
	local pod_num="${4}"

	local pod_name=`get_pod_name "${namespace}" "${name}" "${mod}" "${pod_num}"`

	kubectl describe pod "${pod_name}" -n "${namespace}"
}
export -f desc

function log()
{
	if [ -z "${1+x}" ] || [ -z "${2+x}" ] || [ -z "${3+x}" ] || [ -z "${4+x}" ]; then
		echo "usage: <cmd> mod pod-num" >&2
		exit 1
	fi

	local namespace="${1}"
	local name="${2}"
	local mod="${3}"
	local pod_num="${4}"

	local pod_name=`get_pod_name "${namespace}" "${name}" "${mod}" "${pod_num}"`

	if [ "${mod}" == "tidb" ]; then
		kubectl logs "${pod_name}" -c tidb -n "${namespace}"
	elif [ "${mod}" == "tiflash" ]; then
		kubectl logs "${pod_name}" -c tiflash-log -n "${namespace}"
	else
		kubectl logs "${pod_name}" -n "${namespace}"
	fi
}
export -f log

function copy()
{
	if [ -z "${1+x}" ] || [ -z "${2+x}" ] || [ -z "${3+x}" ] || [ -z "${4+x}" ] || [ -z "${5+x}" ] || [ -z "${6+x}" ]; then
		echo "usage: <cmd> mod pod-num container-file-path host-file-path" >&2
		exit 1
	fi

	local namespace="${1}"
	local name="${2}"
	local mod="${3}"
	local pod_num="${4}"
	local container_file_path="${5}"
	local host_file_path="${6}"

	local pod_name=`get_pod_name "${namespace}" "${name}" "${mod}" "${pod_num}"`

	if [ "${mod}" == "tidb" ]; then
		kubectl cp "${namespace}/${pod_name}":"${container_file_path}" "${host_file_path}" -c tidb
	elif [ "${mod}" == "tiflash" ]; then
		kubectl cp "${namespace}/${pod_name}":"${container_file_path}" "${host_file_path}" -c tiflash
	else
		kubectl cp "${namespace}/${pod_name}":"${container_file_path}" "${host_file_path}"
	fi
}
export -f copy

function exec()
{
	if [ -z "${1+x}" ] || [ -z "${2+x}" ] || [ -z "${3+x}" ] || [ -z "${4+x}" ]; then
		echo "usage: <cmd>ß mod pod-num" >&2
		exit 1
	fi

	local namespace="${1}"
	local name="${2}"
	local mod="${3}"
	local pod_num="${4}"

	local pod_name=`get_pod_name "${namespace}" "${name}" "${mod}" "${pod_num}"`

	if [ "${mod}" == "tidb" ]; then
		kubectl exec -it "${pod_name}" -c tidb -n "${namespace}" /bin/sh
	elif [ "${mod}" == "tiflash" ]; then
		kubectl exec -it "${pod_name}" -c tiflash -n "${namespace}" /bin/bash
	else
		kubectl exec -it "${pod_name}" -n "${namespace}" /bin/sh
	fi
}
export -f exec

function port()
{
	if [ -z "${1+x}" ] || [ -z "${2+x}" ] || [ -z "${3+x}" ] || [ -z "${4+x}" ]; then
		echo "usage: <cmd> mod port" >&2
		exit 1
	fi

	local namespace="${1}"
	local name="${2}"
	local mod="${3}"
	local port="${4}"

	local pod_name=`get_pod_name "${namespace}" "${name}" "${mod}" "${pod_num}"`

	if [ "${mod}" == "tidb" ]; then
		kubectl  port-forward "svc/${name}-tidb" -n "${namespace}" ${port}:4000 >/dev/null 2>&1 &
	elif [ "${mod}" == "pd" ]; then
		kubectl  port-forward "svc/${name}-pd" -n "${namespace}" ${port}:2379 >/dev/null 2>&1 &
	else
		echo "unsupported mod ${mod}" >&2
		exit 0
	fi
}
export -f port

# chaos-related func
function chaos_help()
{
	if [ -z "${1+x}" ] || [ -z "${2+x}" ]; then
		echo "usage: <cmd>" >&2
		exit 1
	fi

	local namespace="${1}"
	local name="${2}"
	cat ./chaos_help
}

export -f chaos_help

function chaos_apply()
{
	if [ -z "${1+x}" ] || [ -z "${2+x}" ]; then
		echo "usage: <cmd> type" >&2
		exit 1
	fi

	local namespace="${1}"
	local type="${2}"

	if [ "${type}" == "kill" ]; then
		kubectl apply -f tiflash-kill.yaml -n "${namespace}"
	elif [ "${type}" == "failure" ]; then
		kubectl apply -f tiflash-failure.yaml -n "${namespace}"
	elif [ "${type}" == "delay_pd" ]; then
		kubectl apply -f network-delay-pd-tiflash.yaml -n "${namespace}"
	elif [ "${type}" == "delay_tikv" ]; then
		kubectl apply -f network-delay-tikv-tiflash.yaml -n "${namespace}"
	elif [ "${type}" == "partition_pd" ]; then
		kubectl apply -f network-partition-pd-tiflash.yaml -n "${namespace}"
	elif [ "${type}" == "partition_tikv" ]; then
		kubectl apply -f network-partition-tikv-tiflash.yaml -n "${namespace}"
	fi
}
export -f chaos_apply

function chaos_delete()
{
	if [ -z "${1+x}" ] || [ -z "${2+x}" ]; then
		echo "usage: <cmd> type" >&2
		exit 1
	fi

	local namespace="${1}"
	local type="${2}"

	if [ "${type}" == "kill" ]; then
		kubectl delete -f tiflash-kill.yaml -n "${namespace}"
	elif [ "${type}" == "failure" ]; then
		kubectl delete -f tiflash-failure.yaml -n "${namespace}"
	elif [ "${type}" == "delay_pd" ]; then
		kubectl delete -f network-delay-pd-tiflash.yaml -n "${namespace}"
	elif [ "${type}" == "delay_tikv" ]; then
		kubectl delete -f network-delay-tikv-tiflash.yaml -n "${namespace}"
	elif [ "${type}" == "partition_pd" ]; then
		kubectl delete -f network-partition-pd-tiflash.yaml -n "${namespace}"
	elif [ "${type}" == "partition_tikv" ]; then
		kubectl delete -f network-partition-tikv-tiflash.yaml -n "${namespace}"
	fi
}
export -f chaos_delete

function chaos_show()
{
	if [ -z "${1+x}" ]; then
		echo "usage: <cmd>" >&2
		exit 1
	fi

	local namespace="${1}"
	echo "PodChaos:"
	kubectl get podchaos -n "${namespace}"
	echo "NetworkChaos:"
	kubectl get networkchaos -n "${namespace}"
	echo "IOChaos:"
	kubectl get iochaos -n "${namespace}"
}
export -f chaos_show

function test_apply()
{
	if [ -z "${1+x}" ] || [ -z "${2+x}" ]; then
		echo "usage: <cmd> [bank/bank2/crud/ledger/sqllogic/ddl]" >&2
		exit 1
	fi

	local namespace="${1}"
	local test="${2}"

	if [ "${test}" == "bank" ]; then
		kubectl apply -f bank.yaml -n "${namespace}"
	elif [ "${test}" == "bank2" ]; then
		kubectl apply -f bank2.yaml -n "${namespace}"
	elif [ "${test}" == "crud" ]; then
		kubectl apply -f crud.yaml -n "${namespace}"
	elif [ "${test}" == "ledger" ]; then
		kubectl apply -f ledger.yaml -n "${namespace}"
	elif [ "${test}" == "sqllogic" ]; then
		kubectl apply -f sqllogic.yaml -n "${namespace}"
	elif [ "${test}" == "ddl" ]; then
		kubectl apply -f ddl.yaml -n "${namespace}"
	else
		echo "<apply> unknown test ${test}"
	fi
}
export -f test_apply

function test_delete()
{
	if [ -z "${1+x}" ] || [ -z "${2+x}" ]; then
		echo "usage: <cmd> [bank/bank2/crud/ledger/sqllogic/ddl]" >&2
		exit 1
	fi

	local namespace="${1}"
	local test="${2}"

	if [ "${test}" == "bank" ]; then
		kubectl delete -f bank.yaml -n "${namespace}"
	elif [ "${test}" == "bank2" ]; then
		kubectl delete -f bank2.yaml -n "${namespace}"
	elif [ "${test}" == "crud" ]; then
		kubectl delete -f crud.yaml -n "${namespace}"
	elif [ "${test}" == "ledger" ]; then
		kubectl delete -f ledger.yaml -n "${namespace}"
	elif [ "${test}" == "sqllogic" ]; then
		kubectl delete -f sqllogic.yaml -n "${namespace}"
	elif [ "${test}" == "ddl" ]; then
		kubectl delete -f ddl.yaml -n "${namespace}"
	else
		echo "<apply> unknown test ${test}"
	fi
}
export -f test_delete

function test_show()
{
	if [ -z "${1+x}" ]; then
		echo "usage: <cmd>" >&2
		exit 1
	fi

	local namespace="${1}"
	
	kubectl get pod -n "${namespace}"
}
export -f test_show
