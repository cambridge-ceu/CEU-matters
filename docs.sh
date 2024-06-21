#!/usr/bin/bash

function setup()
{
  module load python/3.8
  source ~/rds/public_databases/software/py38/bin/activate
}

setup
mkdocs build
mkdocs gh-deploy

if [ "$(uname -n | sed 's/-[0-9]*$//')" == "login-q" ]; then
   module load ceuadmin/openssh/9.7p1-icelake
   module load ceuadmin/libssh/0.10.6-icelake
fi

git add .gitignore
git commit -m ".gitignore"
git add docs
git commit -m "source"
git add mkdocs.yml
git commit -m "mkdocs.yml"
git push
