# OntoPortal docker
OntoPortal Docker is a comprehensive collection of scripts designed to facilitate the running, testing, and deployment of ontoPortal using Docker.

With this project, you can quickly spin up a fully functional ontoPortal instance with minimal setup by leveraging docker's containerization technology. This allows you to test its features and deploy the instance using Kamal.

## Features
- Start ontoportal instance (with or without parsing ontology)
- Start specific services (API/UI)
- Build docker image for this project and push it to your repository 
- Deploy the instance to server

## Project architecture
- **bin**: directory contains essential scripts for deploying and running various components of the ontoPortal system
- **config**: contains deploy.yml file which contains settings and parameters required for deployment using kamal deployment tool
- **test**: testing-related files and scripts using bats testing framework
- **utils**: utility and additional scripts for various purposes
- **.env.sample**: sample file contains configuration of the ontoportal instance (will be copied to .env when running)
- **Dockerfile**: defines configurations to build the docker image for the project
- **ontoportal**: the main script to run the ontoportal, it includes the entry point and main execution logic for the ontoPortal services
- **run**: This file is used to set up environment for tests (it will be deleted).
## Prerequisites
- [git](https://git-scm.com/downloads)
- [Docker](https://docs.docker.com/engine/install/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [Kamal deploy tool](https://kamal-deploy.org/docs/installation/) (if you plan to use the deploy feature)

## Installation
```
~> git clone https://github.com/ontoportal-lirmm/ontoportal_docker.git
~> cd ontoportal-docker
```
## Usage
### General Command Structure
```
./ontoportal <command> [arguments]
```
### Commands
- **Start**
    - start ontoportal instance
    ```
    ./ontoportal start [--no-provision]
    ```
    - start specific services (API or UI)
    ```
    ./ontoportal start [api|ui] [--no-provision]
    ```
    - `--no-provision`: Start the appliance without any data (an empty appliance).

- **Deploy**
    - build and push image to repository (by default docker hub)
    ```
    ./ontoportal deploy push
    ```
    - Deploy ontoportal instance to server (or just specific services mentioned in the arguments)
    ```
    ./ontoportal deploy [api|ui]
    ```
- **Stop**: stop the OntoPortal API and UI services.
    ```
    ./ontoportal stop [api|ui]
    ```
- **Clean**: clean up the server. This removes all data, Docker Compose files, and containers
    ```
    ./ontoportal clean [-f]
    ```
    - `-f` : for force clean

- **Help**: display the help message.
    ```
    ./ontoportal help
    ```

### Additional Notes
- You can provide your own `.env` file to customize parameters. Place the .env file in the project directory.
- `.env` file contains 5 parts:
    - **General configuration**: where you can specify:
    ```yml
    ORGANIZATION_NAME: github organization from where script will fetch docker compose files
    COMPOSE_API_FILE_PATH: docker compose file of the UI 
    COMPOSE_UI_FILE_PATH: docker compose file of the UI 
    SERVICE: specify the service you want to run (script will handle this)
    ```
    - **API Configurations:** contains settings for api service
    - **UI Configurations:** contains settings for ui service
    - **Cron Configurations:** contains settings for cron service
    - **Kamal configurations**: for build and deployment of the ontoportal instance:
    ```yml
    IMAGE_NAME: the name of the image to build and push to docker hub
    SERVER_IP: the ip server where you want to deploy the instance 
    DOCKER_REGISTRY_NAME: the name of account in docker hub of another repository
    KAMAL_REGISTRY_PASSWORD: password of token to access the repository
    SSH_USER: the user that will be used when deploying into the server
    ```