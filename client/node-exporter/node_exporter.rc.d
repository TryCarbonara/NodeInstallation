#!/bin/sh

# PROVIDE: node_exporter
# REQUIRE: LOGIN
# KEYWORD: shutdown
#
# Add the following lines to /etc/rc.conf.local or /etc/rc.conf
# to enable this service:
#
# node_exporter_enable (bool):          Set to NO by default.
#               Set it to YES to enable node_exporter.
# node_exporter_user (string):          Set user that node_exporter will run under
#               Default is "nobody".
# node_exporter_group (string):         Set group that node_exporter will run under
#               Default is "nobody".
# node_exporter_args (string):          Set extra arguments to pass to node_exporter
#               Default is "".
# node_exporter_listen_address (string):Set ip:port that node_exporter will listen on
#               Default is ":9100".
# node_exporter_textfile_dir (string):  Set directory that node_exporter will watch
#               Default is "/var/tmp/node_exporter".

. /etc/rc.subr

name=node_exporter
rcvar=node_exporter_enable

load_rc_config $name

: ${node_exporter_enable:="NO"}
: ${node_exporter_user:="nobody"}
: ${node_exporter_group:="nobody"}
: ${node_exporter_args:=""}
: ${node_exporter_listen_address:=":9100"}
: ${node_exporter_textfile_dir:="/var/tmp/node_exporter"}


pidfile=/var/run/node_exporter.pid
command="/usr/sbin/daemon"
procname="/usr/local/bin/node_exporter"
command_args="-f -p ${pidfile} -T ${name} \
    /usr/bin/env ${procname} \
    --web.listen-address=${node_exporter_listen_address} \
    --collector.textfile.directory=${node_exporter_textfile_dir} \
    ${node_exporter_args}"

start_precmd=node_exporter_startprecmd

node_exporter_startprecmd()
{
    if [ ! -e ${pidfile} ]; then
        install \
            -o ${node_exporter_user} \
            -g ${node_exporter_group} \
            /dev/null ${pidfile};
    fi
    if [ ! -d ${node_exporter_textfile_dir} ]; then
        install \
            -d \
            -o ${node_exporter_user} \
            -g ${node_exporter_group} \
            -m 1755 \
            ${node_exporter_textfile_dir}
    fi
}

load_rc_config $name
run_rc_command "$1"
