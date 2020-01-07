#!/bin/bash

pipenv install --dev --skip-lock \
       "jedi>=0.9.0" \
       "json-rpc>=1.8.1" \
       "service_factory>=0.1.5" \
       "python-language-server~=0.22.0" \
       pyls-isort \
       flake8 \
       black \
       autoflake \
       importmagic \
       epc \
       ipdb
