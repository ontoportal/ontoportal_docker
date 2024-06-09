#!/usr/bin/env bash
setup() {
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
  curl -sSf http://localhost:9393 >/dev/null 2>&1
}

log() {
  docker exec -it api-service tail -f log/production.log
}

clean() {
  echo "[+] Cleaning the API containers"
  docker container rm -f api-service
  docker compose -f docker-compose_api.yml --profile 4store down --volumes
}

update() {
  docker compose -f docker-compose_api.yml --profile 4store pull
}

stop() {
  echo "[+] Stopping the API"
  docker stop api-service
  docker compose -f docker-compose_api.yml --profile 4store stop
}

start() {
  echo "[+] Running api script"

  local env_path='.env'

  source "$env_path"

  local api_url="$API_URL"

  if [ -z "$api_url" ]; then
    echo "[-] Error: Missing required configurations. Please provide the API_URL in your .env file"
    exit 1
  fi

  bash_cmd="rm -fr tmp/pids/unicorn.pid && (bundle check || bundle install) && bundle exec unicorn -c config/unicorn.rb -E production -l 9393"
  #bash_cmd="bash"

  docker_run_cmd="docker compose -f docker-compose_api.yml -p ontoportal_docker run --remove-orphans --name api-service --rm -d  --service-ports api bash -c \"$bash_cmd\""
  echo "[+] Starting the API"
  eval "$docker_run_cmd"

  # Wait for API to be ready (adjust the sleep time accordingly)
  if docker ps --format '{{.Names}}' | grep -q "^api-service$"; then
    echo "[+] API containers started"
  else
    eval "$docker_run_cmd > /dev/null 2>&1;"
  fi

  source utils/loading_animation.sh "[+] Waiting for the server http://localhost:9393 to be up..." "http://localhost:9393" 300

  if status_ok; then
    echo "[+] API is up and running!"
  else
    echo "[x] Timed out waiting for the server to be up."
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

setup

case $1 in
start)
  start "$2"
  ;;
stop)
  stop
  ;;
logs)
  log
  ;;
clean)
  clean
  ;;
update)
  update
  ;;
*)
  echo "Invalid option: $1"
  usage
  ;;
esac

exit 0
