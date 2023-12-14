#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    script usage: install_cli_agent.sh [<flags>]
#%
#% DESCRIPTION
#%    This is a script template to install and configure required toolings for
#%    publishing energy consumption and usage data for calculating carbon emission
#%    Please refer: https://trycarbonara.github.io/docs/dist/html/linux-machine.html
#%    Support: Linux (Ubuntu >= 22.04), Kernel >= 5
#%
#% OPTIONS
#%    -h : Show usage
#%
#% EXAMPLES
#%    ./install_cli_agent.sh -g -u arg1 -p arg2 -r arg3 -o arg4
#%
#==========================================================================
#- IMPLEMENTATION
#-    version         install_cli_agent.sh (www.trycarbonara.com) 0.0.1
#-    author          Saurabh Sarkar
#-    copyright       Copyright (c) http://www.trycarbonara.com
#-    license         GNU General Public License
#-
#==========================================================================
#  HISTORY
#     12/08/2023 : saurabh-carbonara : Script creation
# 
#================================================================
#  DEBUG OPTION
#    set -n  # Uncomment to check your syntax, without execution.
#    set -x  # Uncomment to debug this shell script
#
#================================================================
# END_OF_HEADER
#================================================================

set +e

display_usage() { 
  echo "script usage: $(basename $0) [<flags>]" >&2
  echo "Suppored OS:" >&2
  echo "  * Ubuntu" >&2
  echo "  * FreeBSD" >&2
}

no_support() {
  echo "No support yet!"
}

install_dependencies_linux() {
  echo -n "Checking dependencies ..."
  # Check if wget is installed
  if command -v wget > /dev/null 2>&1; then
      echo -n "."
  else
      sudo apt-get install -y wget \
        || (sudo apt-get update && sudo apt-get install -y wget) \
        || true
  fi
  echo -e "\n"
}

install_dependencies_freebsd() {
  echo -n "Checking dependencies ..."
  # Check if curl is installed
  if command -v curl > /dev/null 2>&1; then
      echo -n "."
  else
      sudo pkg install -y curl \
        || (sudo pkg update -f  && sudo pkg install -y curl) \
        || true
  fi
  echo -e "\n"
}

main() {
  if [ -f /etc/lsb-release ]; then
    install_dependencies_linux
    # Check for Ubuntu
    . /etc/lsb-release
    echo "OS: Ubuntu | Version: $DISTRIB_RELEASE"
    wget -q -O - https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/install_cli_ubuntu.sh  | bash -s -- $@ 1>&2
  elif [ -f /usr/bin/sw_vers ]; then
    # Check for macOS
    OS=$(sw_vers -productName)
    VERSION=$(sw_vers -productVersion)
    echo "OS: $OS | Version: $VERSION"
    no_support
  elif uname -a | grep -qi "freebsd"; then
    install_dependencies_freebsd
    # Check for FreeBSD
    OS="FreeBSD"
    VERSION=$(uname -r)
    echo "OS: $OS | Version: $VERSION"
    curl -sS https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/install_cli_fc_freebsd_pkg.sh  | bash -s -- $@ 1>&2
  elif uname -a | grep -qi "microsoft"; then
    # Check for Windows Subsystem for Linux (WSL)
    OS="Windows (WSL)"
    VERSION=$(uname -r)
    echo "OS: $OS | Version: $VERSION"
    no_support
  elif [ -f /proc/version ]; then
    # General check for other Linux distributions (including WSL)
    if grep -qi "microsoft" /proc/version; then
      OS="Windows (WSL)"
      VERSION=$(uname -r)
      echo "OS: $OS | Version: $VERSION"
      no_support
    else
      OS="Linux"
      VERSION=$(uname -r)
      echo "OS: $OS | Version: $VERSION"
      no_support
    fi
  else
    echo "Unknown OS"
    display_usage
  fi
}

main "$@"
