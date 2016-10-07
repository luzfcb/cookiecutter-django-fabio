#!/bin/sh
# this is a very simple script that tests the docker configuration for cookiecutter-django
# it is meant to be run from the root directory of the repository, eg:
# sh tests/test_docker.sh

check_and_exit_if_error(){
  docker-compose -f dev.yml ps -q | xargs docker inspect -f '{{ .State.ExitCode }}' | while read -r code; do  
      if [ "$code" != 0 ]; then    
         exit -1
      fi
  done
}

# install test requirements
pip install -r requirements.txt

# create a cache directory
mkdir -p .cache/docker
cd .cache/docker

# create the project using the default settings in cookiecutter.json
cookiecutter ../../ --no-input --overwrite-if-exists
cd project_name

# run the project's tests
docker-compose -f dev.yml run django python manage.py test
check_and_exit_if_error

# return non-zero status code if there are migrations that have not been created
docker-compose -f dev.yml run django python manage.py makemigrations --dry-run --check
check_and_exit_if_error
