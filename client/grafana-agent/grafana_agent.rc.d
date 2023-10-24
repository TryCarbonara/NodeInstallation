#!/bin/sh

# PROVIDE: grafana_agent
# KEYWORD: shutdown
#
# Add the following lines to /etc/rc.conf.local or /etc/rc.conf
# to enable this service:
#
# grafana_agent_enable (bool):          Set to NO by default.
#               Set it to YES to enable grafana_agent.
# grafana_agent_config_file (string):   Set config file that grafana_agent will run with
#               Default is "".
# grafana_agent_args (string):          Set extra arguments to pass to grafana_agent
#               Default is "".

. /etc/rc.subr

name=grafana_agent
rcvar=grafana_agent_enable

load_rc_config $name

: ${grafana_agent_config_file:=""}
: ${grafana_agent_args:=""}

pidfile=/var/run/grafana_agent.pid
command="/usr/sbin/daemon"
procname="/usr/local/bin/grafana_agent"
command_args="-u root -f -p ${pidfile} -T ${name} \
    /usr/bin/env ${procname} \
    -config.expand-env -server.http.address=127.0.0.1:9090 -server.grpc.address=127.0.0.1:9091 \
    -config.file=${grafana_agent_config_file} \
    ${grafana_agent_args}"

load_rc_config $name
run_rc_command "$1"
