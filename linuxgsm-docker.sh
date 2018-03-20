#!/bin/bash

## can be simplified.

## name of the docker container
InstanceName='arkserver'
## arkserver for me (it's the script name in the server directory)
# for you need to be the server type name of the LinuxGSM script.
ServerType='arkserver'
## Image name to run (i have build with the lgsm-build.sh)
Img='lgsm-docker'
## current path; plz execute this script from it's folder
Path=$(pwd)
## Set the Network Used by docker
Network='host'
## Set the hostname for the docker container
Hostname='LGSM'
## Set it to False if you don't have a discord custom script like me
DiscordNotifier="false"

## check if the container already running; return (true or '')
status=$(sudo docker inspect --format="{{.State.Running}}" $InstanceName 2> /dev/null)

fn_discord_custom_sender(){
	if [ "${DiscordNotifier}" == "true" ]
	then
		sleep 2
		sudo docker exec ${InstanceName} alert_discord.sh "${cmd}"
	fi
}

## need to be test
fn_exec_cmd_sender(){
	if [ "${1}" == "exec" ]
	then
		if [ "${2}" == "install" ]
		then
			sudo docker "${1}" ${InstanceName} bash /home/lgsm/linuxgsm.sh "${3}"
		else
			sudo docker "${1}" ${InstanceName} ${ServerType} "${2}" "${3}"
		fi
	else
		sudo docker "${1}" ${InstanceName}
	fi
}

fn_command_support(){

	case ${cmd} in
		"install")
		    if [ "${3}" != "" ]
		    then
		    	fn_exec_cmd_sender exec install "${3}"
		    else
		    	# Get List of game server name for install
		    	sudo docker exec ${InstanceName} bash /home/lgsm/linuxgsm.sh install
			echo "enter the server name; ctrl+c to cancel"
			read -a type
			fn_exec_cmd_sender exec install "${type}"
		    fi
		    ;;

		"start")
		    fn_exec_cmd_sender exec start
		    fn_discord_custom_sender "${cmd}"
		    ;;

		"stop")
		    if [ "$status" == "true" ]
		    then
			fn_exec_cmd_sender exec stop
			fn_discord_custom_sender "${cmd}"
			sudo docker kill ${InstanceName}
		    fi
		    ;;

		"restart")
		    fn_exec_cmd_sender exec restart
		    fn_discord_custom_sender "${cmd}"
		    ;;

		"update") ## update stop the server if is already running(lgsm script).
		    fn_exec_cmd_sender exec update
		    fn_discord_custom_sender "${cmd}"
		    ;;

		"console")
		    fn_exec_cmd_sender exec console
		    ;;

		"monitor")
		    fn_exec_cmd_sender exec monitor
		    ;;

		"validate")
		    fn_exec_cmd_sender exec validate
		    ;;

		"backup")
		    fn_exec_cmd_sender exec backup
		    ;;

		"details")
		    fn_exec_cmd_sender exec details
		    ;;

		"alerts")
		    fn_exec_cmd_sender exec alerts
		    ;;

		"conjob")
		    crontab -l > CronTemp
		    echo "* */3 * * * bash ${Path}/linuxgsm-docker.sh command bash check_version.sh >/dev/null 2>&1" >> CronTemp
		    crontab CronTemp
		    rm CronTemp
		    ;;

		"attach")
		    echo "dettach with ctrl+p & ctrl+q"
		    fn_exec_cmd_sender attach
		    ;;

		"command")
		    ## Need to be test (take all parameter after the first one)
		    sudo docker exec -it ${InstanceName} "${@:2}"
		    ;;

		*)
		    echo "Parameter invalid, exit."
		    exit 1
	esac

}


## check if the the container already running; if not start it if command is not Stop;
if [ "${status}" != "true" ] && [ "$1" != "stop" ]
then
	echo "docker container was not running. start it for you."
	sudo docker rm ${InstanceName} 2> /dev/null
	sudo docker run --name ${InstanceName} --restart always --net=${Network} --hostname ${Hostname} -it -d -v "/home/lgsm/:/home/lgsm" ${Img} bash 2> /dev/null
elif [ "${status}" == "true" ]
then
	echo "docker container already running, append command."
else
	echo "docker container not running."
fi

## check if we have a parameter
if [ "${#}" -gt 0 ]
then
       	cmd=${1}
	fn_command_support "${cmd}" "${2}"
else
	echo $"Usage: $0 {start|stop|restart|console|monitor|update|backup|details|alerts|cronjob|attach|command|install}"
	read -a cmd
	fn_command_support "${cmd}" "${2}"
fi

#sudo docker run --name arkserver --rm -it -d -v "/home/lgsm/:/home/lgsm" lgsm-docker bash $@
