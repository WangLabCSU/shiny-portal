Init a renv in docker container

```sh
cd /home/data/shiny-server && docker exec -it shiny-server bash -c "cd /srv/shiny-server/hello && R -e 'renv::init(bare = TRUE); renv::install(\"ggplot2\"); renv::snapshot()'"
```