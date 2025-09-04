#!/usr/bin/env bash
# shellcheck source=/dev/null
# Usage: ./bootstrap.sh
# This script will:
#   - install Mint and bootstrap its dependencies
#   - link git hooks
#   - install sonar-scanner if `INSTALL_SONAR` environment variable is provided
# If you get `zsh: permission denied: ./bootstrap.sh` error, please run `chmod +x bootstrap.sh` first

function puts {
  echo
  echo -e "👉 ${1}"
}

# Set bash to Strict Mode (http://redsymbol.net/articles/unofficial-bash-strict-mode/)
set -Eeuo pipefail

trap "echo ; echo ❌ The Bootstrap script failed to finish without error. See the log above to debug. ; echo" ERR

source ./Githubfile

if [ "${GITHUB_ACTIONS:-}" != "true" ]; then
  puts "Set up git hooks"
  bundle install
  bundle exec lefthook install
fi

if [ "${SKIP_MINT_BOOTSTRAP:-}" != true ]; then
  puts "Bootstrap Mint dependencies"
  git clone https://github.com/yonaskolb/Mint.git fastlane/mint
  root=$(pwd)
  cd fastlane/mint
  swift run mint install "yonaskolb/mint@${MINT_VERSION}"
  cd $root
  rm -rf fastlane/mint
  mint bootstrap --link
fi

if [[ ${INSTALL_SONAR-default} == true ]]; then
  puts "Install sonar scanner"
  DOWNLOAD_URL="https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_VERSION}-macosx-x64.zip"
  curl -sL "${DOWNLOAD_URL}" -o ./fastlane/sonar.zip
  cd fastlane
  unzip sonar.zip
  rm sonar.zip
  cd ..
  mv "fastlane/sonar-scanner-${SONAR_VERSION}-macosx-x64/" fastlane/sonar/
  chmod +x ./fastlane/sonar/bin/sonar-scanner
fi

if [[ ${INSTALL_YEETD-default} == true ]]; then
  PACKAGE="yeetd-normal.pkg"
  puts "Install yeetd v${YEETD_VERSION}"
  wget "https://github.com/biscuitehh/yeetd/releases/download/${YEETD_VERSION}/${PACKAGE}"
  sudo installer -pkg ${PACKAGE} -target /
  puts "Running yeetd daemon"
  yeetd &
fi

if [[ ${INSTALL_IPSW-default} == true ]]; then
  puts "Install ipsw v${IPSW_VERSION}"
  FILE="ipsw_${IPSW_VERSION}_macOS_universal.tar.gz"
  wget "https://github.com/blacktop/ipsw/releases/download/v${IPSW_VERSION}/${FILE}"
  tar -xzf "$FILE"
  chmod +x ipsw
  sudo mv ipsw /usr/local/bin/
fi
