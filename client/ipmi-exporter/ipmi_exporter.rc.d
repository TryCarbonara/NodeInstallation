#!/bin/sh

# PROVIDE: ipmi_exporter
# KEYWORD: shutdown
#
# Add the following lines to /etc/rc.conf.local or /etc/rc.conf
# to enable this service:
#
# ipmi_exporter_enable (bool):          Set to NO by default.
#               Set it to YES to enable ipmi_exporter.
# ipmi_exporter_config_file (string):   Set config file that ipmi_exporter will run with
#               Default is "".
# ipmi_exporter_args (string):          Set extra arguments to pass to ipmi_exporter
#               Default is "".
# ipmi_exporter_listen_address (string):Set ip:port that ipmi_exporter will listen on
#               Default is ":9290".

. /etc/rc.subr

name=ipmi_exporter
rcvar=ipmi_exporter_enable

load_rc_config $name

: ${ipmi_exporter_config_file:=""}
: ${ipmi_exporter_args:=""}
: ${ipmi_exporter_listen_address:=":9290"}

pidfile=/var/run/ipmi_exporter.pid
command="/usr/sbin/daemon"
procname="/usr/local/bin/ipmi_exporter"
command_args="-u root -f -p ${pidfile} -T ${name} \
    /usr/bin/env ${procname} \
    --web.listen-address=${ipmi_exporter_listen_address} \
    --config.file=${ipmi_exporter_config_file} \
    ${ipmi_exporter_args}"

load_rc_config $name
run_rc_command "$1"
