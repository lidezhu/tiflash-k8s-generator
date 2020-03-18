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
	here="`cd $(dirname ${BASH_SOURCE[0]}) && pwd`"
	cd ./tidb-cluster
	helm install --values=values.yaml --name="${name}" --namespace="${namespace}" .
	cd "${here}"
	while true; do
		local pd_ready_num=`kubectl get pod -n "${namespace}" | grep pd | grep Running | wc -l`
		local tikv_ready_num=`kubectl get pod -n "${namespace}" | grep tikv | grep Running | wc -l`
		local tidb_ready_num=`kubectl get pod -n "${namespace}" | grep tidb | grep Running | wc -l`
		if [ "${pd_ready_num}" -eq 3 ] && [ "${tikv_ready_num}" -eq 3 ] && [ "${tidb_ready_num}" -eq 1 ]; then
			break
		fi
		echo "wait for tidb cluster ready, pd_ready_num: ${pd_ready_num}, tikv_ready_num: ${tikv_ready_num}, tidb_ready_num: ${tidb_ready_num}"
		sleep 10
	done

	kubectl apply -f tiflash.yaml -n "${namespace}"
	while true; do
		local tiflash_ready_num=`kubectl get pod -n "${namespace}" | \
			grep tiflash | grep -v pd  | grep -v tikv | grep -v tidb | grep -v discovery | \
			grep -v monitor | grep Running | wc -l`
		if [ "${tiflash_ready_num}" -eq 1 ]; then
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
	helm del --purge "${name}"
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

function logs()
{
	if [ -z "${1+x}" ] || [ -z "${2+x}" ] || [ -z "${3+x}" ] || [ -z "${4+x}" ]; then
		echo "usage: <cmd> mod pod-num" >&2
		exit 1
	fi

	local namespace="${1}"
	local name="${2}"
	local mod="${3}"
	local pod_num="${4}"
	if [ -z "${5+x}" ]; then
		local container=""
	else
		local container="${5}"
	fi

	local pod_name=`get_pod_name "${namespace}" "${name}" "${mod}" "${pod_num}"`

	if [ "${mod}" == "tidb" ]; then
		if [ "${container}" != "" ]; then
			kubectl logs "${pod_name}" -c "${container}" -n "${namespace}"
		else 
			kubectl logs "${pod_name}" -c tidb -n "${namespace}"
		fi
	elif [ "${mod}" == "tiflash" ]; then
		if [ "${container}" != "" ]; then
			kubectl logs "${pod_name}" -c "${container}" -n "${namespace}"
		else 
			kubectl logs "${pod_name}" -c tiflash-log -n "${namespace}"
		fi
	else
		kubectl logs "${pod_name}" -n "${namespace}"
	fi
}
export -f logs

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

	if [ "${mod}" == "tidb" ]; then
		kubectl  port-forward "svc/${name}-tidb" -n "${namespace}" ${port}:4000 >/dev/null 2>&1 &
	elif [ "${mod}" == "pd" ]; then
		kubectl  port-forward "svc/${name}-pd" -n "${namespace}" ${port}:2379 >/dev/null 2>&1 &
	elif [ "${mod}" == "tiflash" ]; then
		kubectl  port-forward "svc/tiflash" -n "${namespace}" ${port}:9000 >/dev/null 2>&1 &
	elif [ "${mod}" == "grafana" ]; then
		kubectl port-forward "svc/${name}-grafana" -n "${namespace}" --address 0.0.0.0 ${port}:3000 >/dev/null 2>&1 &
		echo "default username/passward: admin/admin"
	else
		echo "unsupported mod ${mod}" >&2
		exit 0
	fi
}
export -f port

function tidb_client()
{
	if [ -z "${1+x}" ] || [ -z "${2+x}" ] || [ -z "${3+x}" ]; then
		echo "usage: <cmd> port" >&2
		exit 1
	fi

	local namespace="${1}"
	local name="${2}"
	local port="${3}"
	if [ -z "${4+x}" ]; then
		local db="test"
	else
		local db="${4}"
	fi

	mysql -u root -D ${db} -h 127.0.0.1 -P ${port}
}
export -f tidb_client

# chaos-related func
function chaos_help()
{
	if [ -z "${1+x}" ]; then
		echo "usage: <cmd>" >&2
		exit 1
	fi

	local namespace="${1}"
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
	elif [ "${type}" == "delay-pd" ]; then
		kubectl apply -f network-delay-pd.yaml -n "${namespace}"
	elif [ "${type}" == "delay-tikv" ]; then
		kubectl apply -f network-delay-tikv.yaml -n "${namespace}"
	elif [ "${type}" == "delay-tiflash" ]; then
		kubectl apply -f network-delay-tiflash.yaml -n "${namespace}"
	elif [ "${type}" == "corrupt-pd" ]; then
		kubectl apply -f network-corrupt-pd.yaml -n "${namespace}"
	elif [ "${type}" == "corrupt-tikv" ]; then
		kubectl apply -f network-corrupt-tikv.yaml -n "${namespace}"
	elif [ "${type}" == "corrupt-tiflash" ]; then
		kubectl apply -f network-corrupt-tiflash.yaml -n "${namespace}"
	elif [ "${type}" == "duplicate-pd" ]; then
		kubectl apply -f network-duplicate-pd.yaml -n "${namespace}"
	elif [ "${type}" == "duplicate-tikv" ]; then
		kubectl apply -f network-duplicate-tikv.yaml -n "${namespace}"
	elif [ "${type}" == "duplicate-tiflash" ]; then
		kubectl apply -f network-duplicate-tiflash.yaml -n "${namespace}"
	elif [ "${type}" == "loss-pd" ]; then
		kubectl apply -f network-loss-pd.yaml -n "${namespace}"
	elif [ "${type}" == "loss-tikv" ]; then
		kubectl apply -f network-loss-tikv.yaml -n "${namespace}"
	elif [ "${type}" == "loss-tiflash" ]; then
		kubectl apply -f network-loss-tiflash.yaml -n "${namespace}"
	elif [ "${type}" == "partition-pd" ]; then
		kubectl apply -f network-partition-pd-tiflash.yaml -n "${namespace}"
	elif [ "${type}" == "partition-tikv" ]; then
		kubectl apply -f network-partition-tikv-tiflash.yaml -n "${namespace}"
	elif [ "${type}" == "delay" ]; then
		kubectl apply -f io-delay.yaml -n "${namespace}"
	elif [ "${type}" == "errno" ]; then
		kubectl apply -f io-errno.yaml -n "${namespace}"
	elif [ "${type}" == "mixed" ]; then
		kubectl apply -f io-mixed.yaml -n "${namespace}"
	elif [ "${type}" == "time-pd" ]; then
		kubectl apply -f time-chaos-pd.yaml -n "${namespace}"
	elif [ "${type}" == "pd-failure" ]; then
		kubectl apply -f pd-failure.yaml -n "${namespace}"
	elif [ "${type}" == "tikv-failure" ]; then
		kubectl apply -f tikv-failure.yaml -n "${namespace}"
	elif [ "${type}" == "tidb-failure" ]; then
		kubectl apply -f tidb-failure.yaml -n "${namespace}"
	else
		echo "<apply> unknown chaos test: ${type}" >&2
		exit 1
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
	elif [ "${type}" == "delay-pd" ]; then
		kubectl delete -f network-delay-pd.yaml -n "${namespace}"
	elif [ "${type}" == "delay-tikv" ]; then
		kubectl delete -f network-delay-tikv.yaml -n "${namespace}"
	elif [ "${type}" == "corrupt-pd" ]; then
		kubectl delete -f network-corrupt-pd.yaml -n "${namespace}"
	elif [ "${type}" == "corrupt-tikv" ]; then
		kubectl delete -f network-corrupt-tikv.yaml -n "${namespace}"
	elif [ "${type}" == "duplicate-pd" ]; then
		kubectl delete -f network-duplicate-pd.yaml -n "${namespace}"
	elif [ "${type}" == "duplicate-tikv" ]; then
		kubectl delete -f network-duplicate-tikv.yaml -n "${namespace}"
	elif [ "${type}" == "loss-pd" ]; then
		kubectl delete -f network-loss-pd.yaml -n "${namespace}"
	elif [ "${type}" == "loss-tikv" ]; then
		kubectl delete -f network-loss-tikv.yaml -n "${namespace}"
	elif [ "${type}" == "partition-pd" ]; then
		kubectl delete -f network-partition-pd-tiflash.yaml -n "${namespace}"
	elif [ "${type}" == "partition-tikv" ]; then
		kubectl delete -f network-partition-tikv-tiflash.yaml -n "${namespace}"
	elif [ "${type}" == "delay" ]; then
		kubectl delete -f io-delay.yaml -n "${namespace}"
	elif [ "${type}" == "errno" ]; then
		kubectl delete -f io-errno.yaml -n "${namespace}"
	elif [ "${type}" == "mixed" ]; then
		kubectl delete -f io-mixed.yaml -n "${namespace}"
	elif [ "${type}" == "time-pd" ]; then
		kubectl delete -f time-chaos-pd.yaml -n "${namespace}"
	elif [ "${type}" == "pd-failure" ]; then
		kubectl delete -f pd-failure.yaml -n "${namespace}"
	elif [ "${type}" == "tikv-failure" ]; then
		kubectl delete -f tikv-failure.yaml -n "${namespace}"
	elif [ "${type}" == "tidb-failure" ]; then
		kubectl delete -f tidb-failure.yaml -n "${namespace}"
	else
		echo "<apply> unknown chaos test: ${type}" >&2
		exit 1
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
	echo "TimeChaos:"
	kubectl get timechaos -n "${namespace}"
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

function test_logs()
{
	if [ -z "${1+x}" ] || [ -z "${2+x}" ]; then
		echo "usage: <cmd> [bank/bank2/crud/ledger/sqllogic/ddl]" >&2
		exit 1
	fi

	local namespace="${1}"
	local test="${2}"

	if [ "${test}" == "bank" ]; then
		kubectl logs bank -n "${namespace}"
	elif [ "${test}" == "bank2" ]; then
		kubectl logs bank2 -n "${namespace}"
	elif [ "${test}" == "crud" ]; then
		kubectl logs crud -n "${namespace}"
	elif [ "${test}" == "ledger" ]; then
		kubectl logs ledger -n "${namespace}"
	elif [ "${test}" == "sqllogic" ]; then
		kubectl logs sqllogic -n "${namespace}"
	elif [ "${test}" == "ddl" ]; then
		kubectl logs ddl -n "${namespace}"
	else
		echo "<apply> unknown test ${test}"
	fi
}
export -f test_logs

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
