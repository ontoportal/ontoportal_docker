# ontoportal docker

This repo contains docker compose and [DIP][] configuration for running and
developing OntoPortal stack.

```sh
# clone this repo
git clone https://github.com/bioportal/ontoportal_docker.git

# clone ontologies_linked_data repo which is needed for creating solr configsets
git clone https://github.com/bioportal/ontologies_linked_data.git

# generate configsets:
cd ontologies_linked_data
./test/solr/generate_ncbo_configsets.sh

cd ../ontoportal_docker

# run provisioning via dip
# export bioportal APIKEY 
export BP_APIKEY=<YOUR BIOPORTAL API KEY>
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

`dip ls` will list available dip commands

`dip api rackup` starts api which you would be able to access on
http://localhost:9393

