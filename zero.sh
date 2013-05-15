#!/bin/bash

CURRENT_APP_PATH="/home/www.example.com/current/"
CURRENT_CONFIG_PATH="/home/www.example.com/current/config"
SHARED_CONFIG_PATH="/home/www.example.com/shared/config"

response="0"
used_port1="0"
used_port2="0"

echo "Checking used ports..."
used_port1=$(curl --write-out %{http_code} --silent --output /dev/null http://localhost:3000)
used_port2=$(curl --write-out %{http_code} --silent --output /dev/null http://localhost:3003)

if [ $used_port1 == "200" ]
then
  echo "Port 3000 active"
  CURRENT_CONFIG_THIN="zero.thin.yml"
fi

if [ $used_port2 == "200" ]
then
  echo "Port 3003 active"
  CURRENT_CONFIG_THIN="zero2.thin.yml"
fi

echo "Starting zero down time deploy..."

if [ $CURRENT_CONFIG_THIN == "zero.thin.yml" ] 
then 
  echo "Zero detected... switching to Zero2"

  if [ -f "$CURRENT_CONFIG_PATH/thin.yml" ]
  then
    rm $CURRENT_CONFIG_PATH/thin.yml
  fi

  if [ -f "$CURRENT_CONFIG_PATH/thin.before.yml" ]
  then
    rm $CURRENT_CONFIG_PATH/thin.before.yml
  fi

  ln -s $SHARED_CONFIG_PATH/zero/zero.thin.yml $CURRENT_CONFIG_PATH/thin.before.yml
  ln -s $SHARED_CONFIG_PATH/zero/zero2.thin.yml $CURRENT_CONFIG_PATH/thin.yml
  cd $CURRENT_APP_PATH
  echo "Starting new servers..."
  thin start -C config/thin.yml -f
  echo "Waiting to finish start..."
  
  while [ $response != "200" ]
  do
    #echo "Checking port 3003"
    response=$(curl --write-out %{http_code} --silent --output /dev/null http://localhost:3003)
    sleep 1
  done

  rm $SHARED_CONFIG_PATH/example.com
  ln -s $SHARED_CONFIG_PATH/zero/zero2.example.com $SHARED_CONFIG_PATH/example.com
  echo "Reloading nginx..."
  sudo service nginx reload

  echo "Stoping current servers..."
  thin stop -C config/thin.before.yml -f
  rm $CURRENT_CONFIG_PATH/thin.before.yml
fi

if [ $CURRENT_CONFIG_THIN == "zero2.thin.yml" ]
then
  echo "Zero2 detected... switching to Zero"

  if [ -f "$CURRENT_CONFIG_PATH/thin.yml" ]
  then
    rm $CURRENT_CONFIG_PATH/thin.yml
  fi
  
  if [ -f "$CURRENT_CONFIG_PATH/thin.before.yml" ]
  then
    rm $CURRENT_CONFIG_PATH/thin.before.yml
  fi

  ln -s $SHARED_CONFIG_PATH/zero/zero2.thin.yml $CURRENT_CONFIG_PATH/thin.before.yml
  ln -s $SHARED_CONFIG_PATH/zero/zero.thin.yml $CURRENT_CONFIG_PATH/thin.yml
  cd $CURRENT_APP_PATH
  echo "Starting new servers..."
  thin start -C config/thin.yml -f
  echo "Waiting to finish start..."

  while [ $response != "200" ]
  do
    #echo "Checking port 3000"
    response=$(curl --write-out %{http_code} --silent --output /dev/null http://localhost:3000)
    sleep 1
  done

  rm $SHARED_CONFIG_PATH/example.com
  ln -s $SHARED_CONFIG_PATH/zero/zero.example.com $SHARED_CONFIG_PATH/example.com
  echo "Reloading nginx..."
  sudo service nginx reload

  echo "Stoping current servers..."
  thin stop -C config/thin.before.yml -f
  rm $CURRENT_CONFIG_PATH/thin.before.yml
fi

