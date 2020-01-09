here="`cd $(dirname ${BASH_SOURCE[0]}) && pwd`"
source "${here}/_env.sh"

if [ -z "${1+x}" ] || [ -z "${2+x}" ] || [ -z "${3+x}" ]; then
	echo "usage: <cmd> namespace prefix sub_dir" >&2
	exit 1
fi

namespace="${1}"
prefix="${2}"
sub_dir="${3}"

render_str="namespace=${namespace}"
render_str="${render_str}#prefix=${prefix}"
render_templ "${here}/chaos-template/network-delay-pd-tiflash-template.yaml" "${here}/${sub_dir}/network-delay-pd-tiflash.yaml" "${render_str}"
render_templ "${here}/chaos-template/network-delay-tikv-tiflash-template.yaml" "${here}/${sub_dir}/network-delay-tikv-tiflash.yaml" "${render_str}"
render_templ "${here}/chaos-template/network-partition-pd-tiflash-template.yaml" "${here}/${sub_dir}/network-partition-pd-tiflash.yaml" "${render_str}"
render_templ "${here}/chaos-template/network-partition-tikv-tiflash-template.yaml" "${here}/${sub_dir}/network-partition-tikv-tiflash.yaml" "${render_str}"
render_templ "${here}/chaos-template/pd-failure-template.yaml" "${here}/${sub_dir}/pd-failure.yaml" "${render_str}"
render_templ "${here}/chaos-template/tiflash-failure-template.yaml" "${here}/${sub_dir}/tiflash-failure.yaml" "${render_str}"
render_templ "${here}/chaos-template/tiflash-kill-template.yaml" "${here}/${sub_dir}/tiflash-kill.yaml" "${render_str}"
render_templ "${here}/chaos-template/tikv-failure-template.yaml" "${here}/${sub_dir}/tikv-failure.yaml" "${render_str}"
