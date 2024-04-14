#!/usr/bin/bash

function setup()
{
  module load python/3.8
  source ~/rds/public_databases/software/py38/bin/activate
}

if [ "$(uname -n | sed 's/-[0-9]*$//')" == "login-q" ]; then
   module load ceuadmin/openssh/9.7p1-icelake
fi

setup
mkdocs build
mkdocs gh-deploy

git add .gitignore
git commit -m ".gitignore"
git add docs
git commit -m "source"
git add mkdocs.yml
git commit -m "mkdocs.yml"
git push
