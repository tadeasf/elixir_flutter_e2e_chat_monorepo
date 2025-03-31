#!/bin/bash

# Simple script to load environment variables from .env file

if [ -f .env ]
then
  export $(cat .env | sed 's/#.*//g' | xargs)
  echo "Environment variables loaded from .env file"
else
  echo "No .env file found"
fi 