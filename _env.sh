function render_templ()
{
	if [ -z "${3+x}" ]; then
		echo "[func render_templ] usage: <func> templ_file dest_file render_str(k=v#k=v#..)" >&2
		return 1
	fi

	local src="${1}"
	local dest="${2}"
	local kvs="${3}"

	local dest_dir=`dirname "${dest}"`
	mkdir -p "${dest_dir}"

	local here="`cd $(dirname ${BASH_SOURCE[0]}) && pwd`"
	python "${here}/render_templ.py" "${kvs}" < "${src}" > "${dest}"
}
export -f render_templ
