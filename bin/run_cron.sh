#!/usr/bin/env bash
setup() {
	./run_api.sh setup >/dev/null 2>&1
}

start() {
	local env_path='.env'
	local bash_cmd=$1

	echo "[+] Running cron script"

	if [ -z "$env_path" ]; then
		echo "[-] Error: Missing required configurations. Please provide the path to your .env file"
		exit 1
	fi

	source "$env_path"

	docker_run_cmd="docker compose -f docker-compose_api.yml -p ontoportal_docker run  --remove-orphans --rm --name cron-service  --service-ports ncbo_cron bash -c \"$bash_cmd\""

	echo "[+] Starting the CRON"
	eval "$docker_run_cmd"
	run_cron "$env_path" "$2"

	if [ $? -ne 0 ]; then
		echo "[-] Error in run_con function. Exiting..."
		exit 1
	fi

	echo "[+] The CRON is running successfully."
}

setup
start "$1"
