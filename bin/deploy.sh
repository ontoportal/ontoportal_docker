#!/usr/bin/env bash
deploy() {
	local env_path='.env'

	if [ -f "$env_path" ]; then
		echo "[+] Env file exist"
	else
		echo "[+] Env file does not exist"
		cp .env.sample .env
	fi

	if [ -z "$1" ]; then
		SERVICE="ontoportal"
	else
		SERVICE="$1"
	fi

	# Update SERVICE variable in .env file without using sed
	awk -v SERVICE="$SERVICE" '/^SERVICE=/{sub(/=.*/, "=" SERVICE)} 1' .env >temp && mv temp .env

	echo "[+] Checking for env variables"
	source .env

	variables=("IMAGE_NAME" "SERVER_IP" "DOCKER_REGISTRY_NAME" "KAMAL_REGISTRY_PASSWORD" "SSH_USER")

	for variable in "${variables[@]}"; do
		if [ -z "${!variable}" ]; then
			echo "[-] Error: $variable is not set."
			exit
		fi
	done

	echo "[+] Changing kamal deploy.yml file"
	echo "" > config/deploy.yml
	echo "service: ontoportal_docker" > config/deploy.yml
	echo "image: ${IMAGE_NAME}" >> config/deploy.yml
	echo -e "servers:\n  - ${SERVER_IP}" >> config/deploy.yml
	echo "run_directory: /root/app" >> config/deploy.yml
	echo -e "registry:\n  username:\n    - ${DOCKER_REGISTRY_NAME}\n  password:\n    - ${KAMAL_REGISTRY_PASSWORD}" >>config/deploy.yml
	echo -e "ssh:\n  user: ${SSH_USER}" >> config/deploy.yml
	echo -e "volumes:\n  - /var/run/docker.sock:/var/run/docker.sock" >> config/deploy.yml
	echo -e "traefik:\n  host_port: 4000" >> config/deploy.yml
	echo -e "healthcheck:\n  cmd: /bin/true" >> config/deploy.yml
	if [ -z "$1" ]; then
	    echo "[+] Starting the deployment"
    	kamal setup -vv
	elif [ "$1" == "push" ]; then
    	echo "[+] Pushing image to Docker Hub without deploying to server"
    	kamal build push -vv
	fi

}

deploy "$1"
