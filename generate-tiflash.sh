here="`cd $(dirname ${BASH_SOURCE[0]}) && pwd`"
source "${here}/_env.sh"

if [ -z "${1+x}" ] || [ -z "${2+x}" ] || [ -z "${3+x}" ]; then
	echo "usage: <cmd> namespace tidb-cluster-name tiflash_image sub_dir [storage_class_name]" >&2
	exit 1
fi

namespace="${1}"
tidb_cluster_name="${2}"
image_tag="${3}"
sub_dir="${4}"
if [ -z "${5+x}" ]; then
	storage_class_name="shared-nvme-disks"
else
	storage_class_name="${5}"
fi

here="`cd $(dirname ${BASH_SOURCE[0]}) && pwd`"
render_str="namespace=${namespace}"
render_str="${render_str}#tidb_cluster_name=${tidb_cluster_name}"
render_str="${render_str}#image_tag=${image_tag}"
render_str="${render_str}#storage_class_name=${storage_class_name}"
render_templ "${here}/tiflash-template.yaml" "${here}/${sub_dir}/tiflash.yaml" "${render_str}"
"${here}/generate-chaos.sh" "${namespace}" "${namespace}" "${sub_dir}"
