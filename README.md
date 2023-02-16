# OntoPortal docker development environment

This repo contains docker compose and [DIP](https://github.com/bibendi/dip) configuration for running and
developing OntoPortal stack in 3 different ways:

1. docker-compose.backend_only.yml contains just the backend services required for developing and running API on your local system.
2. Run API/ncbo_cron and depenencies in docker using DIP
3. Run API/ncbo_cron in docker with mounted source code volumes from your local system. This will allow editing files on your local machine while running code inside docker container. 


```sh
# clone this repo
git clone https://github.com/bioportal/ontoportal_docker.git

# clone ontologies_linked_data repo which is needed for creating solr configsets
git clone https://github.com/bioportal/ontologies_linked_data.git

# generate configsets:
cd ontologies_linked_data
./test/solr/generate_ncbo_configsets.sh

cd ../ontoportal_docker

# install DIP
bundle install

# export bioportal APIKEY which is needed for importing ontologies from bioportal when provisioning
cp .env.sample .env

# run provisioning via dip 
dip provision
```

`dip provision` will:
- clear existing volumes, i.e removing all data
- create 4store kb
- run ncbo_cron rake tasks for creating admin user acccount
- run bin/ncbo_ontology_import script on ncbo_cron container to import STY
    ontology from bioportal
- run ontology pull script
- process STY ontology

# DIP commands:

list available dip commands

`dip ls`

starts api which you would be able to access on http://localhost:9393

`dip api rackup` 

run ncbo_cron scripts:

`dip cron bundle exe bin/<script>`

For example, to import new ontology from BioPortal, pull and process it you would run:
```sh
dip cron bundle exec bin/ncbo_ontology_import --from-apikey ${BP_APIKEY} -o PO --from https://data.bioontology.org --admin-user admin
dip cron bundle exec bin/ncbo_ontology_pull -o PO
dip cron bundle exec bin/ncbo_ontology_process -o PO
```

# API Development

When developing API it is possible to mount the source code from your local directory inside the container so that it runs your latest changes. To do that you need to make changes to dip.yml file and uncomment the line containing `# - docker-compose.dev.yml`.  docker-compose.dev.yml contains overwrights to the docker-compose.yml which mounts your local directory.

to install gems inside the API container you would need to run `dip api bundle install` or `dip api bundle update` to get newer gems

to test your changes you would need to run `dip api test`

