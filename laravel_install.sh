#!/bin/bash
DIR=$PWD

# Stop Services
$DIR/service_down.sh

# Verbose some output
clear
echo ""
echo "We are setting up your new Laravel instance. Please provide some parameters."
echo "Just hit <ENTER> to use default values for any question."
echo ""

# Set environment
cp -rf $DIR/.env.example $DIR/.env
ENVFILE=$DIR/.env

# Inject provided parameters into ENV file
read -p "What is the name of your App [Fresh Laravel App]? " appname
if [ -n "$appname" ]
then
  sed -i '' -e "s/Fresh Laravel App/$appname/g" $ENVFILE
fi
read -p  "Give a unique identifier for the docker service [laravel_test]: " servicename
if [ -n "$servicename" ]
then
  sed -i '' -e "s/laravel_test/$servicename/g" $ENVFILE
fi
read -p "At what URL will the app be accessible [localhost]: " appurl
if [ -n "$appurl" ]
then
  sed -i '' -e "s#test.local#$appurl#g" $ENVFILE
fi

echo ""
read -p "What's the Admin's Email address [info@domain.com]? " adminemail
if [ -n "$adminemail" ]
then
  sed -i '' -e "s/info@domain.com/$adminemail/g" $ENVFILE
fi
read -p  "Name the MySQL database [laraveldb]: " dbname
if [ -n "$dbname" ]
then
  sed -i '' -e "s/laraveldb/$dbname/g" $ENVFILE
fi
read -p  "Name the MySQL database user [laravelapp]: " dbuser
if [ -n "$dbuser" ]
then
  sed -i '' -e "s/laravelapp/$dbuser/g" $ENVFILE
fi
read -p  "Set a MySQL database password [You-will-never-guesS]: " dbpassword
if [ -n "$dbpassword" ]
then
  sed -i '' -e "s/You-will-never-guesS/$dbpassword/g" $ENVFILE
fi

# Check further installation options
echo ""
read -p "Do you wish to install the Breeze Authentication package (Blade Frontend) [n]?" BREEZEINSTALL
BREEZEINSTALL=${BREEZEINSTALL:-n}
if [ $BREEZEINSTALL != "y" ]
then
  # If Breeze Install was opted out, ask for Jetstream Installation
  read -p "Do you wish to install the Jetstream Authentication package (VueJS Frontend) [n]?" JETSTREAMINSTALL
  JETSTREAMINSTALL=${JETSTREAMINSTALL:-n}
  # If Jetstream was opted in, ask for Inertia option (if no, Livewire will be used)
  if [ $JETSTREAMINSTALL = "y" ]
    then
      read -p "Do you wish to install the Inertia flavor with VueJS [y]?" INERTIAINSTALL
      INERTIAINSTALL=${INERTIAINSTALL:-y}
  fi
fi
if [ $JETSTREAMINSTALL != "y" ]
  then
  # Ask for additional Vue Install if Jetstream was opted out
  read -p "Do you wish to set up VueJS 2 in your application [n]?" VUE2INSTALL
  VUE2INSTALL=${VUE2INSTALL:-n}
fi

#Start installation
clear

# USE ENV file for installation
source $DIR/.env

# Re-Create MySQL Database
rm -R $DIR/mysql
mkdir $DIR/mysql

# Re-Create Laravel Directory
rm -R $DIR/src
mkdir $DIR/src

# Install Laravel
docker-compose run --rm composer create-project laravel/laravel .

# Start Services
$DIR/service_up.sh

# Inject Project Vars into fresh Laravel ENV file
ENVFILE=$DIR/src/.env
sed -i '' -e "s/APP_NAME=Laravel/APP_NAME=\"$APP_NAME\"/g" $ENVFILE
sed -i '' -e "s/APP_URL=http:\/\/localhost/APP_URL=http:\/\/$URL/g" $ENVFILE
sed -i '' -e "s/DB_HOST=127.0.0.1/DB_HOST=mysql/g" $ENVFILE
sed -i '' -e "s/DB_DATABASE=laravel/DB_DATABASE=$MYSQL_DATABASE/g" $ENVFILE
sed -i '' -e "s/DB_USERNAME=root/DB_USERNAME=$MYSQL_USER/g" $ENVFILE
sed -i '' -e "s/DB_PASSWORD=/DB_PASSWORD=$MYSQL_PASSWORD/g" $ENVFILE

# Update permissions in Laravel dir
docker-compose exec -d -w /var/www/html php chown -R www-data:www-data .

#Perform Breeze/Auth installation
if [ $BREEZEINSTALL = "y" ]
then
  $DIR/laravel_module_auth_breeze.sh
  AUTHINSTALLED="y"
fi

#Perform Jetstream/Auth installation
if [ $JETSTREAMINSTALL = "y" ]
then
  $DIR/laravel_module_auth_jetstream.sh $INERTIAINSTALL
  AUTHINSTALLED="y"
fi

#Perform VueJS 2 installation
if [ $VUE2INSTALL = "y" ]
then
  $DIR/laravel_module_vuejs2.sh $AUTHINSTALLED
fi

# Initial Migrations
$DIR/laravel_module_initial_migration.sh
