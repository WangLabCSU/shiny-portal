#!/bin/bash
# crontab /home/data/shiny-server/crontab/crontab.txt

cd /home/data/shiny-server
cat /home/data/shiny-server/crontab/update-shiny-r-packages.R | docker compose exec -T shiny-server Rscript -
