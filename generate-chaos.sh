here="`cd $(dirname ${BASH_SOURCE[0]}) && pwd`"
source "${here}/_env.sh"

if [ -z "${1+x}" ] || [ -z "${2+x}" ] || [ -z "${3+x}" ]; then
	echo "usage: <cmd> namespace prefix sub_dir" >&2
	exit 1
fi

namespace="${1}"
chaos_namespace="${2}"
sub_dir="${3}"

render_str="namespace=${namespace}"
render_str="${render_str}#chaos_namespace=${chaos_namespace}"
render_templ "${here}/chaos-template/network-delay-pd-template.yaml" "${here}/${sub_dir}/network-delay-pd.yaml" "${render_str}"
render_templ "${here}/chaos-template/network-delay-tikv-template.yaml" "${here}/${sub_dir}/network-delay-tikv.yaml" "${render_str}"
render_templ "${here}/chaos-template/network-partition-pd-tiflash-template.yaml" "${here}/${sub_dir}/network-partition-pd-tiflash.yaml" "${render_str}"
render_templ "${here}/chaos-template/network-partition-tikv-tiflash-template.yaml" "${here}/${sub_dir}/network-partition-tikv-tiflash.yaml" "${render_str}"
render_templ "${here}/chaos-template/network-corrupt-pd-template.yaml" "${here}/${sub_dir}/network-corrupt-pd.yaml" "${render_str}"
render_templ "${here}/chaos-template/network-corrupt-tikv-template.yaml" "${here}/${sub_dir}/network-corrupt-tikv.yaml" "${render_str}"
render_templ "${here}/chaos-template/network-duplicate-pd-template.yaml" "${here}/${sub_dir}/network-duplicate-pd.yaml" "${render_str}"
render_templ "${here}/chaos-template/network-duplicate-tikv-template.yaml" "${here}/${sub_dir}/network-duplicate-tikv.yaml" "${render_str}"
render_templ "${here}/chaos-template/network-loss-pd-template.yaml" "${here}/${sub_dir}/network-loss-pd.yaml" "${render_str}"
render_templ "${here}/chaos-template/network-loss-tikv-template.yaml" "${here}/${sub_dir}/network-loss-tikv.yaml" "${render_str}"
render_templ "${here}/chaos-template/pd-failure-template.yaml" "${here}/${sub_dir}/pd-failure.yaml" "${render_str}"
render_templ "${here}/chaos-template/tidb-failure-template.yaml" "${here}/${sub_dir}/tidb-failure.yaml" "${render_str}"
render_templ "${here}/chaos-template/tiflash-failure-template.yaml" "${here}/${sub_dir}/tiflash-failure.yaml" "${render_str}"
render_templ "${here}/chaos-template/tiflash-kill-template.yaml" "${here}/${sub_dir}/tiflash-kill.yaml" "${render_str}"
render_templ "${here}/chaos-template/tikv-failure-template.yaml" "${here}/${sub_dir}/tikv-failure.yaml" "${render_str}"
render_templ "${here}/chaos-template/io-delay-template.yaml" "${here}/${sub_dir}/io-delay.yaml" "${render_str}"
render_templ "${here}/chaos-template/io-errno-template.yaml" "${here}/${sub_dir}/io-errno.yaml" "${render_str}"
render_templ "${here}/chaos-template/io-mixed-template.yaml" "${here}/${sub_dir}/io-mixed.yaml" "${render_str}"
render_templ "${here}/chaos-template/time-chaos-pd-template.yaml" "${here}/${sub_dir}/time-chaos-pd.yaml" "${render_str}"

mkdir -p "${here}/${sub_dir}/chaosfs-configmap"
cp "${here}/chaos-template/chaosfs-configmap/tiflash-configmap.yaml" "${here}/${sub_dir}/chaosfs-configmap/tiflash-configmap.yaml"
