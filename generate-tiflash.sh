here="`cd $(dirname ${BASH_SOURCE[0]}) && pwd`"
source "${here}/_env.sh"

if [ -z "${1+x}" ]; then
	echo "usage: <cmd> namespace [tiflash_image] [tidb-cluster-name] [sub_dir] [chaos_namespace] [storage_class_name]" >&2
	exit 1
fi

namespace="${1}"

shift 1

if [ -z "${1+x}" ]; then
	image_tag="k8s72c54b"
else
	image_tag="${1}"
fi
if [ -z "${2+x}" ]; then
	tidb_cluster_name="${namespace}-cluster"
else
	tidb_cluster_name="${2}"
fi
if [ -z "${3+x}" ]; then
	sub_dir="${namespace}"
else
	sub_dir="${3}"
fi
if [ -z "${4+x}" ]; then
	chaos_namespace="${namespace}-chaos"
else
	chaos_namespace="${4}"
fi
if [ -z "${5+x}" ]; then
	storage_class_name="shared-nvme-disks"
else
	storage_class_name="${5}"
fi

schrodinger_tag="k8s20200307"
test_namespace="${namespace}-test"

here="`cd $(dirname ${BASH_SOURCE[0]}) && pwd`"
render_str="namespace=${namespace}"
render_str="${render_str}#tidb_cluster_name=${tidb_cluster_name}"
render_str="${render_str}#image_tag=${image_tag}"
render_str="${render_str}#storage_class_name=${storage_class_name}"
render_str="${render_str}#schrodinger_tag=${schrodinger_tag}"
render_str="${render_str}#test_namespace=${test_namespace}"
# generate cluster yaml
render_templ "${here}/cluster-template/tiflash-template.yaml" "${here}/${sub_dir}/tiflash.yaml" "${render_str}"
render_templ "${here}/cluster-template/tiflash-multi-disk-template.yaml" "${here}/${sub_dir}/tiflash-multi-disk.yaml" "${render_str}"
mkdir -p "${here}/${sub_dir}/tidb-cluster/"
cp -r ${here}/cluster-template/tidb-cluster/* "${here}/${sub_dir}/tidb-cluster/"
cp ${here}/cluster-template/tidb-cluster/.helmignore "${here}/${sub_dir}/tidb-cluster/"
#render_templ "${here}/cluster-template/tidb-cluster-template.yaml" "${here}/${sub_dir}/tidb-cluster.yaml" "${render_str}"

# generate schrodinger yaml
render_templ "${here}/schrodinger-template/bank-template.yaml" "${here}/${sub_dir}/bank.yaml" "${render_str}"
render_templ "${here}/schrodinger-template/bank2-template.yaml" "${here}/${sub_dir}/bank2.yaml" "${render_str}"
render_templ "${here}/schrodinger-template/crud-template.yaml" "${here}/${sub_dir}/crud.yaml" "${render_str}"
render_templ "${here}/schrodinger-template/ledger-template.yaml" "${here}/${sub_dir}/ledger.yaml" "${render_str}"
render_templ "${here}/schrodinger-template/ddl-template.yaml" "${here}/${sub_dir}/ddl.yaml" "${render_str}"
render_templ "${here}/schrodinger-template/sqllogic-template.yaml" "${here}/${sub_dir}/sqllogic.yaml" "${render_str}"

# copy cluster command
cp -r ${here}/cluster-commands/* "${here}/${sub_dir}/"
echo "${namespace}" > "${here}/${sub_dir}/namespace"
echo "${tidb_cluster_name}" > "${here}/${sub_dir}/name"
echo "${test_namespace}" > "${here}/${sub_dir}/test_namespace"
echo "${chaos_namespace}" > "${here}/${sub_dir}/chaos_namespace"

# generate chaos yaml
"${here}/generate-chaos.sh" "${namespace}" "${chaos_namespace}" "${sub_dir}"
