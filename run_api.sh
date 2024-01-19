#!/usr/bin/env bash

update_env_file() {
  local api_url="$1"
  local old_path="$2"
  local goo_path="$3"
  local sparql_client_path="$4"
  file_content=$(<.env_api)
  while IFS= read -r line; do
        if [[ "$line" == "API_URL="* && -n "$api_url" ]]; then
          echo "API_URL=$api_url"
        elif [[ "$line" == "ONTOLOGIES_LINKED_DATA_PATH="* ]]; then
          echo "ONTOLOGIES_LINKED_DATA_PATH=$old_path"
        elif [[ "$line" == "GOO_PATH="* ]]; then
          echo "GOO_PATH=$goo_path"
        elif [[ "$line" == "SPARQL_CLIENT_PATH="* ]]; then
          echo "SPARQL_CLIENT_PATH=$sparql_client_path"
        else
          echo "$line"
        fi
  done <<< "$file_content" > .env_api
}


build_docker_run_cmd() {
  local custom_command="$1"
  local old_path="$2"
  local goo_path="$3"
  local sparql_client_path="$4"
  local bash_cmd=""

  for path_var in "old_path:ontologies_linked_data" "goo_path:goo" "sparql_client_path:sparql-client"; do
    IFS=':' read -r path value <<< "$path_var"

    if [ -n "${!path}" ]; then
      host_path="$(realpath "$(dirname "${!path}")")/$value"
      echo "Run: bundle config local.$value ${!path}"
      container_path="/srv/ontoportal/$value"
      docker_run_cmd+=" -v $host_path:$container_path"
      bash_cmd+="(git config --global --add safe.directory $container_path && bundle config local.$value $container_path) &&"
    else
      bash_cmd+=" (bundle config unset local.$value) &&"
    fi
  done

  bash_cmd+=" (bundle check || bundle install || bundle update) && $custom_command"
  #docker_run_cmd+="docker compose run --rm -it --name api-service  --service-ports api bash -c \"$bash_cmd\""
  docker_run_cmd+="docker compose -f docker-compose_api_development.yml run --rm -d --name api-service  --service-ports api bash -c \"$bash_cmd\""
  
  echo "----------------------------------"
  ls
  echo "----------------------------------"
  echo
  echo '[+] RUN: ' $docker_run_cmd
  eval "$docker_run_cmd"
}



run_command() {
  local custom_command="$1"
  local reset_cache=false
  local api_url=""
  local old_path=""
  local goo_path=""
  local sparql_client_path=""

  shift
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      --reset-cache)
        reset_cache=true
        shift
        ;;
      --api-url)
        api_url="$2"
        shift 2
        ;;
      --old-path)
        old_path="$2"
        shift 2
        ;;
      --goo-path)
        goo_path="$2"
        shift 2
        ;;
      --sparql-client-path)
        sparql_client_path="$2"
        shift 2
        ;;
      *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
  done

  if [ "$reset_cache" = true ]; then
    echo "Resetting cache. Running: docker compose down --volumes"
    docker compose down --volumes
  fi

  update_env_file "$api_url" "$old_path" "$goo_path" "$sparql_client_path"


  source .env_api
  api_url="$API_URL"
  old_path="$ONTOLOGIES_LINKED_DATA_PATH"
  goo_path="$GOO_PATH"
  sparql_client_path="$SPARQL_CLIENT_PATH"


  if [ -z "$api_url" ] ; then
    echo "Error: Missing required arguments. Please provide both --api-url or update them in your .env_api"
    exit 1
  fi

  build_docker_run_cmd "$custom_command" "$old_path" "$goo_path" "$sparql_client_path"
}


clone_ongologies_linked_data(){
  repo_dir="ontologies_linked_data"

  if [ -d "$repo_dir" ]; then
      echo "[+] Directory $repo_dir already exists. Skipping cloning."
  else
    echo "[+] Cloning ontologies_linked_data repo..."
    git clone --depth=1 https://github.com/ontoportal-lirmm/ontologies_linked_data.git
  fi

  echo -n "[+] Generating Solr configsets: "
  if [ -d "$repo_dir" ]; then
    cd ontologies_linked_data || exit 1
    if ! ./test/solr/generate_ncbo_configsets.sh; then
      echo "Error: Failed to generate Solr configsets."
      exit 1
    else
      echo "Success: Generating Solr configsets."
    fi
    cd ..
  else
    echo "[-] Error: directory ontologies_linked_data does not exists"
  fi
}


# Function to handle the "dev" option
dev() {
  echo "Starting OntoPortal API development server..."
  clone_ongologies_linked_data

  local custom_command="bundle exec rackup --host 0.0.0.0  --env=development --port 9393"
  run_command "$custom_command" "$@"
}

case "$1" in
  "dev")
    dev "${@:2}"
    ;;
  "help")
    show_help
    ;;
  *)
    show_help
    exit 1
    ;;
esac
