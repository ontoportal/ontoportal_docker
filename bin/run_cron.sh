#!/usr/bin/env bash
run_cron(){
  local env_path=$1
	local bash_cmd=$2

	if [ -z "$env_path" ]; then
  		echo "[-] Error: Missing required configurations. Please provide the path to your .env file"
  		exit 1
  fi

  source "$env_path"

	docker_run_cmd="docker compose -f docker-compose_api.yml -p ontoportal_docker run  --remove-orphans --rm --name cron-service  --service-ports ncbo_cron bash -c \"$bash_cmd\""
	echo "[+] Starting the CRON"
	eval "$docker_run_cmd"
}

start_cron(){
    local  file_path="docker-compose_api.yml"
    local  env_path="$1"

    source "$env_path"

    if [ -z "$ORGANIZATION_NAME" ]; [ -z "$COMPOSE_API_FILE_PATH" ]; then
      		echo "[-] Error: Missing required configurations. Please provide both ORGANIZATION_NAME and COMPOSE_API_FILE_PATH in  your .env file"
      		exit 1
    fi

		echo "[+] Getting compose file for CRON"
		echo "[+] Getting compose file from: $ORGANIZATION_NAME$COMPOSE_API_FILE_PATH"
		eval "curl -sS -L https://raw.githubusercontent.com/$ORGANIZATION_NAME$COMPOSE_API_FILE_PATH -o docker-compose_api.yml"

		echo "[+] Running cron script"
		run_cron "$env_path" "$2"

		if [ $? -ne 0 ]; then
			echo "[-] Error in run_con function. Exiting..."
			exit 1
		fi
		echo "[+] The CRON is running successfully."
}


start_cron "$1" "$2"