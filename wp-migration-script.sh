#!/bin/sh
#
# Written by Terraltech - 2013
#
# version: BETA
#

#------------------------------------------------------------------
# current info
#------------------------------------------------------------------
echo "######################################################"
echo "#			Starting backup			 #"
echo "#			Cureent Website			 #"
echo "#							 #"
echo "######################################################"

read -p "current URL: " CUR_URL

CUR_DB_HOST_DEFAULT="localhost"
read -p "Enter the current DB Host [$CUR_DB_HOST_DEFAULT]:" CUR_DB_HOST
[ -z "$CUR_DB_HOST" ] && CUR_DB_HOST=$CUR_DB_HOST_DEFAULT

echo $CUR_DB_HOST

read -p "current Database Name?: " CUR_DB_NAME

read -p "current Database User?: " CUR_DB_USER

read -p "current Database Password?: " CUR_DB_PASS

read -p "current website DocumentRoot Path?: " CUR_PATH
echo ""
echo "######################################################"
echo "#							 #"
echo "#			New Website			 #"
echo "#							 #"
echo "######################################################"

read -p "New URL?: " NEW_URL

read -p "New Database Host [$CUR_DB_HOST]: " NEW_DB_HOST
[ -z "$NEW_DB_HOST" ] && NEW_DB_HOST=$CUR_DB_HOST

read -p "New Database Name [$CUR_DB_NAME]: " NEW_DB_NAME
[ -z "$NEW_DB_NAME" ] && NEW_DB_NAME=$CUR_DB_NAME

read -p "New Database User? [$CUR_DB_USER]: " NEW_DB_USER
[ -z "$NEW_DB_USER" ] && NEW_DB_USER=$CUR_DB_USER

read -p "New Database Password [$CUR_DB_PASS]: " NEW_DB_PASS
[ -z "$NEW_DB_PASS" ] && NEW_DB_PASS=$CUR_DB_PASS

read -p "Remote DataBase ROOT password: " DB_ROOT_PASS

read -p "What is the User name of the remote server?: " NEW_USER
read -p "What is the IP address of the remote server?: " NEW_IP_HOST
read -p "What is the private key full path of the remote server? [/default/path/ServerKey]: " NEW_PK
[ -z "$NEW_PK" ] && NEW_PK=/default/path/ServerKey
echo ""
echo "##########################################################"
echo "Current URL: $CUR_URL				"
echo "Current DB Host: $CUR_DB_HOST			"
echo "Current Database Name: $CUR_DB_NAME		"
echo "Current Database User: $CUR_DB_USER		"
echo "Current Database Password: $CUR_DB_PASS		"
echo "Current website DocumentRoot Path: $CUR_PATH	"
echo "New URL: $NEW_URL					"
echo "New Database Host: $NEW_DB_HOST			"
echo "New DB Host: $NEW_DB_HOST				"
echo "New Database Name: $NEW_DB_NAME			"
echo "New Database User: $NEW_DB_USER			"
echo "New Database Password: $NEW_DB_PASS		"
echo "Remote DataBase ROOT password: $DB_ROOT_PASS	"
echo "Remote server system username: $NEW_USER		"
echo "Remote server IP address: $NEW_IP_HOST		"
echo "Private Key full path: $NEW_PK			"
echo "##########################################################"
echo ""
read -p "Continue (y/n)?" choice
case "$choice" in

	y|Y )
		#------------------------------------------------------------------
		# MySQL backup filename
		#------------------------------------------------------------------
		BACKUPMYSQLFILE=mysqlbackup.sql
		#------------------------------------------------------------------
		# Dump Database
		#------------------------------------------------------------------
		mysqldump -h localhost -u $CUR_DB_USER -p$CUR_DB_PASS $CUR_DB_NAME > $CUR_PATH$BACKUPMYSQLFILE
		echo "exporting DB done!"
		#------------------------------------------------------------------
		# Find and replace old URLs in SQL file
		#------------------------------------------------------------------
		sed -i "s/${CUR_URL}/${NEW_URL}/g" $CUR_PATH$BACKUPMYSQLFILE
		echo "replacing URL done!"
		#------------------------------------------------------------------
		# Find and replace old Database Info in wp-config.php.backup file
		#------------------------------------------------------------------
		sed -i.backup -e"s/define('DB_NAME', '${CUR_DB_NAME}');/define('DB_NAME', '${NEW_DB_NAME}');/g" -e"s/define('DB_USER', '${CUR_DB_USER}');/define('DB_USER', '${NEW_DB_USER}');/g" -e"s/define('DB_PASSWORD', '${CUR_DB_PASS}');/define('DB_PASSWORD', '${NEW_DB_PASS}');/g" -e"s/define('DB_HOST', '${CUR_DB_HOST}');/define('DB_HOST', '${NEW_DB_HOST}');/g"   ${CUR_PATH}wp-config.php
		echo "Editing wp-config.php done!"
		#------------------------------------------------------------------
		# Creating Document Root on remote server and synchronizing!
		#------------------------------------------------------------------
		ssh -i $NEW_PK $NEW_USER@$NEW_IP_HOST "sudo mkdir -p ${CUR_PATH}" && \
		rsync -avz -e "ssh -i $NEW_PK"  --rsync-path="sudo rsync" ${CUR_PATH} $NEW_USER@$NEW_IP_HOST:${CUR_PATH} && \
		rm $CUR_PATH$BACKUPMYSQLFILE && \
		rm ${CUR_PATH}wp-config.php.backup && \
		echo "Rsync done!"
		#------------------------------------------------------------------
		# Creating New DataBase on remote server
		#------------------------------------------------------------------
		ssh -i $NEW_PK $NEW_USER@$NEW_IP_HOST "mysqladmin -u root -p${DB_ROOT_PASS} CREATE $NEW_DB_NAME"
		#------------------------------------------------------------------
		# Adding new DB user on remote server
		#------------------------------------------------------------------
		ssh -i $NEW_PK $NEW_USER@$NEW_IP_HOST 'mysql -u root -p'${DB_ROOT_PASS}' -e "GRANT ALL PRIVILEGES ON '${NEW_DB_NAME}'.* TO '${NEW_DB_USER}'@'localhost' IDENTIFIED BY '\'''$NEW_DB_PASS''\''"'
		#------------------------------------------------------------------
		# Restoring database on remote server
		#------------------------------------------------------------------
		ssh -i $NEW_PK $NEW_USER@$NEW_IP_HOST "mysql -u root -p${DB_ROOT_PASS} ${NEW_DB_NAME} < ${CUR_PATH}mysqlbackup.sql"
		;;
	n|N )
		echo "exit"
		exit 1
		;;
	* ) echo "invalid input!";;
esac
