#!/usr/bin/env bash

UPDATE_RC="${UPDATE_RC:-"true"}"
GRAIN_DIR="${GRAIN_DIR:-"/usr/local/grain"}"
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"

set -e

rm -rf /var/lib/apt/lists/*

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")

    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done

    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

apt_get_update()
{
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

check_packages()
{
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

check_node()
{
    if ! type npm > /dev/null 2>&1; then
        echo "Installing node and npm..."
        check_packages curl
		curl -fsSL https://raw.githubusercontent.com/devcontainers/features/main/src/node/install.sh | $SHELL
		export NVM_DIR=/usr/local/share/nvm
		[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
		[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
    fi                                                                                                                                                              
}

updaterc()
{
    if [ "${UPDATE_RC}" = "true" ]; then
        echo "Updating /etc/bash.bashrc and /etc/zsh/zshrc..."

        if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
            echo -e "$1" >> /etc/bash.bashrc
        fi

        if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh.zshrc)" != *"$1"* ]]; then
            echo -e "$1" >> /etc/zsh/zshrc
        fi
    fi
}

export DEBIAN_FRONTEND=noninteractive

architecture="$(uname -m)"

if [ "${architecture}" != "amd64" ] && [ "${architecture}" != "x86_64" ] && [ "${architecture}" != "arm64" ] && [ "${architecture}" != "aarch64" ]; then
    echo "(!) Architecture $architecture unsupported"
    exit 1
fi

check_packages \
    curl \
    ca-certificates \
    zip \
    unzip \
    xz-utils \
    bzip2 \
    sed \
    git-core \
    libssl-dev \
    patch

if ! grain --version > /dev/null; then
    check_node
    
    echo "Creating ${GRAIN_DIR} directory..."
    mkdir -p "${GRAIN_DIR}"

    echo "Cloning the latest grain..."
    git clone "https://github.com/grain-lang/grain" ${GRAIN_DIR}

    echo "Building Grain..."
    cd ${GRAIN_DIR}

    npm ci

    npm run compiler build

    chown -R "${USERNAME}" ${GRAIN_DIR}
fi

rm -rf /var/lib/apt/lists/*

echo "Done!"