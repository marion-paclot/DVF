#!/bin/bash
# Script de création de la base de donnees PostgreSQL
DIR=$(echo $(dirname $0))
cd $DIR

sudo -u postgres psql -c "DROP DATABASE IF EXISTS dvf_202106;"
sudo -u postgres psql -c "CREATE DATABASE dvf_202106;"
sudo -u postgres psql -c "ALTER DATABASE dvf_202106 SET datestyle TO ""ISO, DMY"";"
sudo -u postgres psql -d dvf_202106 -f "create_table.sql"

# Chargement des données sur le serveur
DATADIR="data"
mkdir -p $DATADIR

for YEAR in 2016 2017 2018 2019 2020
do
  [ ! -f $DATADIR/full_$YEAR.csv.gz ] && wget -r -np -nH -N --cut-dirs 5  https://files.data.gouv.fr/geo-dvf/2021-06/csv/$YEAR/full.csv.gz -O $DATADIR/full_$YEAR.csv.gz
done

find $DATADIR -name '*.gz' -exec gunzip -f '{}' \;

#Chargement des données dans postgres
DATAPATH=$( cd $DATADIR ; pwd -P )
for YEAR in 2016 2017 2018 2019 2020
do
  sudo -u postgres psql -d dvf_202106 -c "COPY dvf FROM '$DATAPATH/full_$YEAR.csv' delimiter ',' csv header encoding 'UTF8';"
done

# Ajout d'une colonne et d'index - Assez long
sudo -u postgres psql -d dvf_202106 -f "alter_table.sql"
