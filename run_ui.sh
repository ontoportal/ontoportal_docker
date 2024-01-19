#!/usr/bin/env bash

update_env_file() {
  local api_url="$1"
  local api_key="$2"

  file_content=$(<.env_ui)
  while IFS= read -r line; do
        if [[ "$line" == "API_URL="* ]]; then
          echo "API_URL=$api_url"
        elif [[ "$line" == "API_KEY="* ]]; then
          echo "API_KEY=$api_key"
        else
          echo "$line"
        fi
  done <<< "$file_content" > .env_ui
}

dev() {
  echo "Starting Ontoportal Web UI development server..."

  local reset_cache=false
  local api_url=""
  local api_key=""

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
      --api-key)
        api_key="$2"
        shift 2
        ;;
      *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
  done

  if [ -n "$api_url" ] && [ -n "$api_key" ]; then
    update_env_file "$api_url" "$api_key"
  else
    source .env_ui
    api_url="$API_URL"
    api_key="$API_KEY"
  fi

  if [ -z "$api_url" ] || [ -z "$api_key" ]; then
    echo "Error: Missing required arguments. Please provide both --api-url and --api-key or update them in your .env"
    exit 1
  fi

  # Check if --reset-cache is present and execute docker compose down --volumes
  if [ "$reset_cache" = true ]; then
    echo "Resetting cache. Running: docker compose down --volumes"
    docker compose down --volumes
  fi

  echo "Run: bundle exec rails s -b 0.0.0.0 -p 3000"
  #docker compose run --rm -it --service-ports rails bash -c "(bundle check || bundle install) && bin/rails db:prepare && bundle exec rails s -b 0.0.0.0 -p 3000"
  docker compose -f docker-compose_ui_development.yml run --rm -d --name ui-service --service-ports rails bash -c "cp /app/config/bioportal_config_env.rb.sample /app/config/bioportal_config_development.rb && cp /app/config/database.yml.sample /app/config/database.yml && (bundle check || bundle install) && bin/rails db:prepare && bundle exec rails s -b 0.0.0.0 -p 4000"

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
