#!/usr/bin/env bash
setup() {
  echo "[+] Setup API"
  local env_path='.env'
  if [ -z "$env_path" ]; then
    echo "[-] Error: Missing required configurations. Please provide the path to your .env file"
    exit 1
  fi
  source "$env_path"

  if
    [ -z "$ORGANIZATION_NAME" ]
    [ -z "$COMPOSE_API_FILE_PATH" ]
  then
    echo "[-] Error: Missing required configurations. Please provide both ORGANIZATION_NAME and COMPOSE_API_FILE_PATH in  your .env file"
    exit 1
  fi

  echo "[+] Getting compose file for API"
  echo "[+] Getting compose file from: $ORGANIZATION_NAME$COMPOSE_API_FILE_PATH"
  eval "curl -sS -L https://raw.githubusercontent.com/$ORGANIZATION_NAME$COMPOSE_API_FILE_PATH -o docker-compose_api.yml"
}

status_ok() {
  curl -sSf http://$1:9393 >/dev/null 2>&1
}

logs() {
  docker exec -it api-service tail -f log/production.log
}

clean_containers() {
  echo "[+] Cleaning the API containers"
  docker container rm -f api-service >/dev/null 2>&1
  docker compose -f docker-compose_api.yml --profile 4store down --volumes >/dev/null 2>&1
}

clean() {
  clean_containers
  rm -f docker-compose_api.yml >/dev/null 2>&1
}

update() {
  echo "[+] Pulling latest images for api"
  docker compose -f docker-compose_api.yml --profile 4store pull
}

stop() {
  echo "[+] Stopping the API"
  docker stop api-service
  docker compose -f docker-compose_api.yml --profile 4store stop
}

provision() {
  if [ -z "$1" ]; then
    source .env
    clean_containers
    echo "[+] Running Cron provisioning"
    commands=(
        "bin/run_cron.sh 'bundle exec rake user:create[admin,admin@nodomain.org,password]' >/dev/null 2>&1"
        "bin/run_cron.sh 'bundle exec rake user:adminify[admin]' >/dev/null 2>&1"
        "bin/run_cron.sh 'bundle exec bin/ncbo_ontology_import --admin-user admin --ontologies $STARTER_ONTOLOGY --from-apikey $OP_APIKEY --from $OP_API_URL' >/dev/null 2>&1"
        "bin/run_cron.sh 'bundle exec bin/ncbo_ontology_process -o ${STARTER_ONTOLOGY}' >/dev/null 2>&1"
    )
    for cmd in "${commands[@]}"; do
        echo "[+] Run: $cmd"
        if ! eval "$cmd"; then
            echo "Error: Failed to run provisioning .  $cmd"
            exit 1
        fi
    done
    echo "CRON Setup completed successfully!"
  elif [ "$1" == "--no-provision" ]; then
    echo "[+] Skipping Cron provisioning"
  fi
}

run() {
  local env_path='.env'

  source "$env_path"

  if [ -z "$API_URL" ]; then
    echo "[-] Error: Missing required configurations. Please provide the API_URL in your .env file"
    exit 1
  fi

  bash_cmd="rm -fr tmp/pids/unicorn.pid && (bundle check || bundle install) && bundle exec unicorn -c config/unicorn.rb -E production -l 9393"
  docker_run_cmd="docker compose -f docker-compose_api.yml -p ontoportal_docker run --remove-orphans --name api-service --rm -d  --service-ports api bash -c \"$bash_cmd\""
  echo "[+] Starting the API"
  eval "$docker_run_cmd"

  # Wait for API to be ready (adjust the sleep time accordingly)
  if docker ps --format '{{.Names}}' | grep -q "^api-service$"; then
    echo "[+] API containers started"
  else
    eval "$docker_run_cmd > /dev/null 2>&1;"
  fi

  local HOST_IP='localhost'
  if [ -f "/.dockerenv" ]; then
    # we are inside the container of ontoportal_docker so we have to test the IP of the machine
    docker_host_IP=$(dig +short A host.docker.internal)
    if [ -n "$docker_host_IP" ]; then
      echo "IP of the local machine: $docker_host_IP"
      HOST_IP=$docker_host_IP
    else
      echo "Cannot get the IP address of the host machine, localhost will be used"
    fi
  fi
  source utils/loading_animation.sh "[+] Waiting for the server http://$HOST_IP:9393 to be up..." "http://$HOST_IP:9393" 300

  if status_ok $HOST_IP; then
    echo "[+] API is up and running!"
  else
    echo "[x] Timed out waiting for the server to be up."
    exit 1
  fi
}

start() {
  echo "[+] Running api script"
  setup
  update
  provision "$1"
  run
  if [ $? -ne 0 ]; then
    echo "[-] Error Running API. Exiting..."
    exit 1
  fi
}

usage() {
  echo "Usage: $0 <option>"
  echo "Options:"
  echo "  start      Start the API"
  echo "  stop       Stop the API"
  echo "  logs       View the logs of the API"
  echo "  clean      Clean the API containers"
  echo "  update     Update the API containers to the latest version"
  exit 1
}

# Option parser
if [[ $# -eq 0 ]]; then
  usage
fi


case $1 in
  "start")
    start "$2"
    ;;
  "stop")
    stop
    ;;
  "logs")
    logs
    ;;
  "clean")
    clean
    ;;
  "update")
    update
    ;;
  "setup")
    setup
    ;;
  *)
    echo "Invalid option: $1"
    usage
    ;;
esac

exit 0