#!/usr/bin/env bash

if [ "${BASH_SOURCE-}" = "$0" ]; then
    echo "You must source this script: \$ source $0" >&2
    return
fi

if [[ ! -v WLR_ENV ]]; then
    echo "WLR build environment is not set"
    exit 1
fi

logStatus "Getting dependencies for ${WLR_ENV_NAME} ... "

export PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1
export PKG_CONFIG_ALLOW_SYSTEM_LIBS=1
export PKG_CONFIG_PATH=""
export PKG_CONFIG_SYSROOT_DIR=${WLR_DEPS_ROOT}/build-output
export PKG_CONFIG_LIBDIR=${PKG_CONFIG_SYSROOT_DIR}/lib/wasm32-wasi/pkgconfig

export WLR_DEPS_INCLUDE=${WLR_DEPS_ROOT}/build-output/include
export WLR_DEPS_LIBDIR=${WLR_DEPS_ROOT}/build-output/lib/wasm32-wasi

function wlr_dependencies_add {
    local _NAME=$1
    local _BUILD_COMMAND=$2
    local _TARGET=$3
    if [[ ! -z "$4" ]]; then
        local _DEP_URL=$4
    fi

    if [[ -e "${WLR_DEPS_ROOT}/build-output/${_TARGET}" ]]; then
        logStatus "${_NAME} is already available at ${WLR_DEPS_ROOT}/build-output/${_TARGET}!"
        return
    fi

    if [[ ! -d "${WLR_DEPS_ROOT}/build-output/" ]]; then
        mkdir -p "${WLR_DEPS_ROOT}/build-output/"
    fi

    if [[ -v _DEP_URL && "${WLR_DEPS_FORCE_LOCAL}" != *"${_NAME}"* ]]; then
        logStatus "Downloading ${_NAME} dependency from ${_DEP_URL}..."
        echo "curl -sL \"${_DEP_URL}\" | tar xzv -C \"${WLR_DEPS_ROOT}/build-output/\""
        curl -sL "${_DEP_URL}" | tar xzv -C "${WLR_DEPS_ROOT}/build-output/"
        if [[ ! -e "${WLR_DEPS_ROOT}/build-output/${_TARGET}" ]]; then
            logStatus "Failed to get '${WLR_DEPS_ROOT}/build-output/${_TARGET}' by downloading '${_DEP_URL}'!"
            exit 1
        fi
    else
        logStatus "Building ${_NAME} dependency locally..."
        WLR_DEPS_ROOT=${WLR_DEPS_ROOT} \
            WLR_BUILD_TYPE=dependency \
            $WLR_MAKE "${WLR_REPO_ROOT}/${_BUILD_COMMAND}" || exit 1
    fi
}
