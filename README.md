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
