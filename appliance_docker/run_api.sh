#!/usr/bin/env bash

# Function to display script usage information
show_help() {
  cat << EOL
Usage: $0 {dev|test|run|help} [--reset-cache] [--api-url API_URL] [--api-key API_KEY] [--old-path OLD_PATH] [--goo-path GOO_PATH] [--sparql-client-path SPARQL_CLIENT_PATH]
  dev            : Start the Ontoportal API development server.
                  Example: $0 dev --api-url http://localhost:9393
                  Use --reset-cache to remove volumes: $0 dev --reset-cache
  test           : Run tests. Specify either a test file or use 'all'.
                  Example: $0 test test/controllers/test_users_controller.rb -v --name=name_of_the_test
                  Example (run all tests): $0 test all -v
  run            : Run a command in the Ontoportal API Docker container.
  help           : Show this help message.

Description:
  This script provides convenient commands for managing an Ontoportal API
  application using Docker Compose. It includes options for starting the development server,
  running tests, and executing commands within the Ontoportal API Docker container.

Options:
  --reset-cache             : Remove Docker volumes (used with 'dev').
  --api-url API_URL         : Specify the API URL.
  --api-key API_KEY         : Specify the API key.
  --old-path OLD_PATH       : Specify the path for ontologies_linked_data.
  --goo-path GOO_PATH       : Specify the path for goo.
  --sparql-client-path      : Specify the path for sparql-client.
  test_file | all            : Specify either a test file or  all the tests will be run.
  -v                        : Enable verbosity.
  --name=name_of_the_test   : Specify the name of the test.

Goals:
  - Simplify common tasks related to Ontoportal API development using Docker.
  - Provide a consistent and easy-to-use interface for common actions.
EOL
}


# Function to update or create the .env file with API_URL and API_KEY
update_env_file() {
  # Update the .env file with the provided values
  local api_url="$1"
  local old_path="$2"
  local goo_path="$3"
  local sparql_client_path="$4"

  # Update  the .env file with the provided values
  file_content=$(<.env_ui)

  # Make changes to the variable
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
  done <<< "$file_content" > .env_ui
}

# Function to create configuration files if they don't exist
create_config_files() {
  [ -f ".env" ] || cp .env.sample .env
  [ -f "config/environments/development.rb" ] || cp config/environments/config.rb.sample config/environments/development.rb
}

# Function to build Docker run command with conditionally added bind mounts
build_docker_run_cmd() {
  local custom_command="$1"
  local old_path="$2"
  local goo_path="$3"
  local sparql_client_path="$4"

  local docker_run_cmd="docker compose run --rm -it"
  local bash_cmd=""

  # Conditionally add bind mounts only if the paths are not empty
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
  docker_run_cmd+=" --name api-service  --service-ports api bash -c \"$bash_cmd\""

  eval "$docker_run_cmd"
}

# Function to handle the "dev" and "test" options
run_command() {
  local custom_command="$1"

  local reset_cache=false
  local api_url=""
  local old_path=""
  local goo_path=""
  local sparql_client_path=""

  shift
  # Check for command line arguments
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

  # Check if --reset-cache is present and execute docker compose down --volumes
  if [ "$reset_cache" = true ]; then
    echo "Resetting cache. Running: docker compose down --volumes"
    docker compose down --volumes
  fi

  # Check if arguments are provided
  update_env_file "$api_url" "$old_path" "$goo_path" "$sparql_client_path"


  # If no arguments, fetch values from the .env file
  source .env_ui
  api_url="$API_URL"
  old_path="$ONTOLOGIES_LINKED_DATA_PATH"
  goo_path="$GOO_PATH"
  sparql_client_path="$SPARQL_CLIENT_PATH"


  if [ -z "$api_url" ] ; then
    echo "Error: Missing required arguments. Please provide both --api-url or update them in your .env_ui"
    exit 1
  fi



  # Build the Docker run command
  echo "Run: $custom_command"
  build_docker_run_cmd "$custom_command" "$old_path" "$goo_path" "$sparql_client_path"
}

clone_ongologies_linked_data(){
	# Step 1: Clone ontologies_linked_data repo
	echo "Cloning ontologies_linked_data repo..."
	git clone --depth=1 https://github.com/ontoportal-lirmm/ontologies_linked_data.git

	# Step 2: Generate configsets
	echo "Generating Solr configsets..."
	cd ontologies_linked_data || exit 1
	if ! ./test/solr/generate_ncbo_configsets.sh; then
	  echo "Error: Failed to generate Solr configsets."
	  exit 1
	fi
	cd ..
}

# Function to handle the "dev" option
dev() {
  echo "Starting OntoPortal API development server..."

  clone_ongologies_linked_data
  #local custom_command="bundle exec shotgun --host 0.0.0.0  --env=development"
  local custom_command="bundle exec rackup --host 0.0.0.0  --env=development --port 9393"
  
  echo "$custom_command"
  run_command "$custom_command" "$@"
}

# Function to handle the "test" option
test() {
  echo "Running tests..."
  local test_path=""
  local test_options=""
  local all_arguments=()
  # Check for command line arguments
  while [ "$#" -gt 0 ]; do
     case "$1" in
         --api-url | --reset-cache | --old-path | --goo-path | --sparql-client-path)
          all_arguments+=("$1" "$2")
          shift 2
          ;;
       *)
         if [ -z "$test_path" ]; then
           test_path="$1"
         else
           test_options="$test_options $1"
         fi
         ;;
     esac
     shift
  done

  local custom_command="bundle exec rake test TEST='$test_path' TESTOPTS='$test_options'"
  echo "run :  $custom_command"
  run_command "$custom_command" "${all_arguments[@]}"
}

# Function to handle the "run" option
run() {
  echo "Run: $*"
  docker compose run --rm -it api bash -c "$*"
}

#create_config_files

# Main script logic
case "$1" in
  "run")
    run "${@:2}"
    ;;
  "dev")
    dev "${@:2}"
    ;;
  "test")
    test "${@:2}"
    ;;
  "help")
    show_help
    ;;
  *)
    show_help
    exit 1
    ;;
esac
