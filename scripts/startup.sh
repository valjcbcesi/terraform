#!/bin/bash

# Mise à jour du système
apt-get update -y
apt-get upgrade -y

# Installation d'Apache, PHP et des extensions requises par WordPress
apt-get install -y apache2 php libapache2-mod-php php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip wget unzip default-mysql-client

# Démarrage et activation du serveur web Apache
systemctl start apache2
systemctl enable apache2

# Téléchargement et extraction de la dernière version de WordPress
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz

# Déplacement des fichiers de WordPress dans le dossier web public d'Apache
rm -rf /var/www/html/*
cp -r wordpress/* /var/www/html/

# Création du fichier de configuration WordPress
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

# Configuration de la connexion à la base de données (basé sur ton database.tf)
sed -i "s/database_name_here/wordpress/g" /var/www/html/wp-config.php
sed -i "s/username_here/wp_user/g" /var/www/html/wp-config.php
sed -i "s/password_here/un_bien_joli_mot_de_passe/g" /var/www/html/wp-config.php

# Terraform remplacera ${db_ip} par la vraie IP
sed -i "s/localhost/${db_ip}/g" /var/www/html/wp-config.php

# Attribution des bons droits au serveur web (l'utilisateur www-data)
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/

# Redémarrage d'Apache pour appliquer les configurations
systemctl restart apache2