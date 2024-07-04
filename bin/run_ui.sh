#!/usr/bin/env bash
setup() {
  echo "[+] Setup UI"
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
  echo "[+] Getting compose file from: $ORGANIZATION_NAME$COMPOSE_UI_FILE_PATH"
  eval "curl -sS -L https://raw.githubusercontent.com/$ORGANIZATION_NAME$COMPOSE_UI_FILE_PATH -o docker-compose_ui.yml"
}

status_ok() {
  curl -sSf http://$1:3000 >/dev/null 2>&1
}

logs() {
  docker logs ui-service -f
}

update() {
  docker compose -f docker-compose_ui.yml pull
}

clean_containers() {
  echo "[+] Cleaning the UI containers"
  docker container rm -f ui-service >/dev/null 2>&1
  docker compose -f docker-compose_ui.yml down --volumes >/dev/null 2>&1
}

clean() {
  clean_containers
  rm -f docker-compose_ui.yml >/dev/null 2>&1
}

stop() {
  echo "[+] Stopping the UI"
  docker stop ui-service
  docker compose -f docker-compose_ui.yml stop
}

run() {
  local env_path='.env'

  if [ -z "$env_path" ]; then
    echo "[-] Error: Missing required configurations. Please provide the path to your .env file"
    exit 1
  fi

  source "$env_path"

  local api_url="$API_URL"
  local api_key="$API_KEY"

  if [ -z "$api_url" ] || [ -z "$api_key" ]; then
    echo "[-] Error: Missing required arguments. Please provide both --api-url and --api-key or update them in your .env"
    exit 1
  fi
  echo "[+] Starting the UI"

  create_secrets_cmd="bin/rails secret"
  create_credentials_cmd="EDITOR='nano' bin/rails credentials:edit"
  create_db_cmd="bin/rails db:prepare"
  run_server_cmd="bundle exec puma -C config/puma.rb"
  #run_server_cmd="bash"

  bash_cmd="(bundle check || bundle install) && $create_secrets_cmd && $create_credentials_cmd  && $create_db_cmd && $run_server_cmd"

  docker_run_cmd="docker compose -f docker-compose_ui.yml -p ontoportal_docker run  --remove-orphans  --rm  --name ui-service --service-ports -d production bash -c \"$bash_cmd\""

  eval "$docker_run_cmd"

  # Wait for UI to be ready (adjust the sleep time accordingly)
  sleep 1
  if docker ps --format '{{.Names}}' | grep -q "^ui-service$"; then
    echo "[+] UI containers started"
  else
    echo "[x] UI containers failed to start"
    exit 1
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
  source utils/loading_animation.sh "[+] Waiting for the server http://$HOST_IP:3000 to be up..." "http://$HOST_IP:3000" 300

  if status_ok $HOST_IP; then
    echo "[+] UI is up and running!"
  else
    echo "[x] Timed out waiting for the UI to be up."
    exit 1
  fi
}

start() {
  echo "[+] Running ui script"
  setup
  update
  run
  if [ $? -ne 0 ]; then
    echo "[-] Error Running UI. Exiting..."
    exit 1
  fi
}

usage() {
  echo "Usage: $0 <option>"
  echo "Options:"
  echo "  start      Start the UI"
  echo "  stop       Stop the UI"
  echo "  logs       View the logs of the UI"
  echo "  clean      Clean the UI containers"
  echo "  update     Update the UI containers to the latest version"
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
