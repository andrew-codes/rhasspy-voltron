#!/usr/bin/env bash
set -e

if [[ -z "${PIP_INSTALL}" ]]; then
    export PIP_INSTALL='install'
fi

# Directory of *this* script
this_dir="$( cd "$( dirname "$0" )" && pwd )"
src_dir="$(realpath "${this_dir}/..")"

# -----------------------------------------------------------------------------

dist_dir="${src_dir}/dist"
mkdir -p "${dist_dir}"

# Clear old Rhasspy libraries
rm -f "${dist_dir}/"rhasspy*

# Make dependent libraries
cat "${src_dir}/RHASSPY_LIBRARIES" | \
    while read -r lib_name;
do
    echo "${lib_name}"
    cd "${src_dir}/${lib_name}" && python3 setup.py sdist --dist-dir "${dist_dir}"
    echo ''
done

# -----------------------------------------------------------------------------

# Create/update submodule virtual environments and build
# TODO: Add kaldi
cat "${src_dir}/RHASSPY_DIRS" | \
    while read -r package_name;
    do
        # rhasspy-asr-pocketsphinx-hermes -> rhasspyasr_pocketsphinx_hermes
        python_name="$(echo "${package_name}" | sed -e 's/-//' | sed -e 's/-/_/g')"

        echo '----------'
        echo "${package_name} (${python_name})"
        service_dir="${src_dir}/${package_name}"
        cd "${service_dir}"

        if [[ ! -f requirements.txt ]]; then
            echo 'Skipping (no requirements.txt)'
            echo ''
            continue
        fi

        if [[ ! -d .venv ]]; then
            # Create virtual environment
            rm -rf .venv
            python3 -m venv .venv
            .venv/bin/pip3 ${PIP_INSTALL} --upgrade wheel setuptools
        fi

        # Update dependencies
        .venv/bin/pip3 ${PIP_INSTALL} \
                       --upgrade \
                       -f "${dist_dir}" \
                       -r requirements.txt

        echo ''
    done