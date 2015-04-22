#!/usr/bin/env bash

DEMO_APP_NAME="cookiecutter-django-demo"

echo -e "Starting to deploy to Heroku\n"
if [ "$TRAVIS" == "true" ]; then
    git config --global user.email "bnafta@gmail.com"
    git config --global user.name "Fabio C. Barrionuevo da Luz"
fi

echo "{
    \"project_name\": \"${DEMO_APP_NAME}\",
    \"repo_name\": \"{{ cookiecutter.project_name|replace(' ', '_') }}\",
    \"author_name\": \"Fabio C. Barrrionuevo da Luz\",
    \"email\": \"bnafta@gmail.com\",
    \"description\": \"A ${DEMO_APP_NAME} project\",
    \"domain_name\": \"${DEMO_APP_NAME}.herokuapp.com\",
    \"version\": \"0.1.0\",
    \"timezone\": \"UTC\",
    \"now\": \"2015/01/13\",
    \"year\": \"{{ cookiecutter.now[:4] }}\"
}" > cookiecutter.json || { 
    echo >&2 -e "\nError on change cookiecutter.json"
    exit 1;
}


cat ~/.ssh/config | grep -c heroku.com || echo "
Host heroku.com
   StrictHostKeyChecking no
   CheckHostIP no
   UserKnownHostsFile=/dev/null
" >> ~/.ssh/config || { 
    echo >&2 -e "\nError on change .ssh/config"
    exit 1;
}


cookiecutter . --no-input || { 
    echo >&2 -e "\nError on generate demo project"
    exit 1;
}


cd ${DEMO_APP_NAME}

echo "# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import models, migrations
from users.models import User

import environ
env = environ.Env()

def forwards(apps, schema_editor):

    user = User.objects.create_superuser(
        username=env('DJANGO_ADMIN_USERNAME'),
        email=env('DJANGO_ADMIN_EMAIL'),
        password=env('DJANGO_ADMIN_PASSWORD')
    )


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0001_initial'),
    ]

    operations = [
        migrations.RunPython(forwards),
    ]

" > ${DEMO_APP_NAME}/users/migrations/0002_auto_20150422_0158.py || { 
    echo >&2 -e "\nError on create default demo user"
    exit 1;
}

git init

git add .

git commit -m "first test" > /dev/null

# export HEROKU_API_KEY="YOU_HEROKU_API_KEY_HERE"

# heroku apps:destroy --app ${DEMO_APP_NAME} -a ${DEMO_APP_NAME} --confirm ${DEMO_APP_NAME}


# heroku keys:clear

yes | heroku keys:add


heroku apps:create --ssh-git --buildpack https://github.com/heroku/heroku-buildpack-python ${DEMO_APP_NAME}

# TODO: hide sensive informations
# configure database
heroku addons:add heroku-postgresql:dev --app ${DEMO_APP_NAME}
heroku pg:backups schedule DATABASE_URL --app ${DEMO_APP_NAME}
heroku pg:promote DATABASE_URL --app ${DEMO_APP_NAME}

heroku addons:add sendgrid:starter --app ${DEMO_APP_NAME}
heroku addons:add memcachier:dev --app ${DEMO_APP_NAME}

# configure environment variables on Heroku
heroku config:set DJANGO_SETTINGS_MODULE="config.production" --app ${DEMO_APP_NAME}
heroku config:set DJANGO_SECRET_KEY=${DJANGO_SECRET_KEY} --app ${DEMO_APP_NAME}
heroku config:set DJANGO_AWS_ACCESS_KEY_ID=${DJANGO_AWS_ACCESS_KEY_ID} --app ${DEMO_APP_NAME}
heroku config:set DJANGO_AWS_SECRET_ACCESS_KEY=${DJANGO_AWS_SECRET_ACCESS_KEY} --app ${DEMO_APP_NAME}
heroku config:set DJANGO_AWS_STORAGE_BUCKET_NAME=${DEMO_APP_NAME} --app ${DEMO_APP_NAME}

# used to create django superuser
heroku config:set DJANGO_ADMIN_USERNAME=${DJANGO_ADMIN_USERNAME} --app ${DEMO_APP_NAME}
heroku config:set DJANGO_ADMIN_EMAIL=${DJANGO_ADMIN_EMAIL} --app ${DEMO_APP_NAME}
heroku config:set DJANGO_ADMIN_PASSWORD=${DJANGO_ADMIN_PASSWORD} --app ${DEMO_APP_NAME}



git push heroku master

heroku run python ${DEMO_APP_NAME}/manage.py collectstatic --noinput
heroku run python ${DEMO_APP_NAME}/manage.py migrate --app ${DEMO_APP_NAME}

# heroku keys:clear
