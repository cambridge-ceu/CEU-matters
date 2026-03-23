#!/usr/bin/bash

function setup()
{
  module load python/3.8
  source ~/rds/public_databases/software/py38/bin/activate
}

function ccal()
{
  module load ceuadmin/ccal
  ccal $1 -p > $1.eps
  convert -density 300 $1.eps $1.png
}

module load ceuadmin/libssh/0.10.6-icelake
module load ceuadmin/openssh/9.7p1-icelake
module load gettext/0.21/gcc/qnrcglqo
module load ceuadmin/krb5
module load libiconv/1.16/gcc/4miyzf3w

setup
mkdocs build
mkdocs gh-deploy

git remote set-url origin https://github.com/cambridge-CEU/CEU-matters.git
git add .gitignore
git commit -m ".gitignore"
git add docs
git commit -m "source"
git add mkdocs.yml
git commit -m "mkdocs.yml"
git push
