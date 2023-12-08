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
  echo "Flags:" >&2
  echo "  -h : Show usage" >&2
}

no_support() {
  echo "No support yet!"
}

install_dependencies_linux() {
  sudo apt-get update
  sudo apt install -y net-tools
  sudo apt-get install -y curl tar wget
}

main() {
  if [ -f /etc/lsb-release ]; then
    # Check for Ubuntu
    . /etc/lsb-release
    echo "OS: Ubuntu | Version: $DISTRIB_RELEASE"
    install_dependencies_linux
    curl -sS https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/install_cli_ubuntu.sh  | bash -s -- $@
  elif [ -f /usr/bin/sw_vers ]; then
    # Check for macOS
    OS=$(sw_vers -productName)
    VERSION=$(sw_vers -productVersion)
    echo "OS: $OS | Version: $VERSION"
    no_support
  elif uname -a | grep -qi "freebsd"; then
    # Check for FreeBSD
    OS="FreeBSD"
    VERSION=$(uname -r)
    echo "OS: $OS | Version: $VERSION"
    install_dependencies_linux
    curl -sS https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/install_cli_fc_freebsd_pkg.sh  | bash -s -- $@
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
  fi
}

main "$@"
