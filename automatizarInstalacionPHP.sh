#!/bin/bash

echo "Creado por Aether"
echo "Este script creará un entorno de desarrollo PHP con Nginx en Docker"
echo "Coloque Y para continuar o N para cancelar"
read respuesta

if [ "$respuesta" != "Y" ]; then
    echo "Operación cancelada"
    exit 1
fi

# 1. VERIFICACIÓN E INSTALACIÓN DE DOCKER
#--------------------------------------------------

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "Docker no está instalado. Instalando Docker..."
    # Instalar Docker según el sistema operativo
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y docker.io
    elif command -v yum &> /dev/null; then
        sudo yum install -y docker
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y docker
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm docker
    else
        echo "No se pudo instalar Docker. Su sistema operativo no es compatible con este script."
        exit 1
    fi

    # Iniciar y habilitar el servicio de Docker
    sudo systemctl start docker
    echo "¿Desea que Docker se inicie con el sistema? (Y/N)"
    read respuesta_inicio
    if [ "$respuesta_inicio" = "Y" ]; then
        sudo systemctl enable docker
    fi

    if ! sudo systemctl is-active --quiet docker; then
        echo "Docker no se pudo iniciar. Por favor, verifique su instalación de Docker."
        exit 1
    fi
    echo "Docker se ha instalado y se está ejecutando correctamente."
else
    echo "Docker ya está instalado."
fi


# 2. CONFIGURACIÓN DEL ENTORNO PHP Y NGINX
#--------------------------------------------------

echo "Iniciando la configuración del entorno PHP con Nginx."

# Obtener la ruta del proyecto del usuario
echo "Por favor, ingrese la ruta absoluta a la carpeta de su proyecto PHP:"
read ruta_proyecto

if [ ! -d "$ruta_proyecto" ]; then
    echo "El directorio especificado no existe. Operación cancelada."
    exit 1
fi

# Obtener datos para los contenedores
echo "Ingrese el nombre para el contenedor de Nginx (por defecto: web-server):"
read nombre_nginx
nombre_nginx=${nombre_nginx:-web-server}

echo "Ingrese el nombre para el contenedor de PHP (por defecto: app-php):"
read nombre_php
nombre_php=${nombre_php:-app-php}

echo "Ingrese el puerto para acceder a su aplicación web (por defecto: 8080):"
read puerto
puerto=${puerto:-8080}

# 3. CREACIÓN DE LA RED Y CONTENEDORES DE DOCKER
#--------------------------------------------------

# Crear una red de Docker para la comunicación entre contenedores
nombre_red="red-php-nginx"
if ! sudo docker network ls | grep -q $nombre_red; then
    echo "Creando red de Docker con el nombre: $nombre_red"
    sudo docker network create $nombre_red
fi

# Crear y ejecutar el contenedor de PHP-FPM
echo "Creando el contenedor de PHP..."
if ! sudo docker run -d --name $nombre_php --network $nombre_red -v "$ruta_proyecto":/var/www/html php:fpm-alpine; then
    echo "No se pudo crear el contenedor de PHP. Verifique los datos ingresados."
    exit 1
fi
echo "Contenedor de PHP '$nombre_php' creado exitosamente."

# Crear un archivo de configuración de Nginx temporal
config_nginx_path="/tmp/nginx_config_for_${nombre_nginx}.conf"
echo "Creando configuración de Nginx..."
cat <<EOF > $config_nginx_path
server {
    listen 80;
    server_name localhost;
    root /var/www/html;

    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass   $nombre_php:9000;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include        fastcgi_params;
    }
}
EOF

# Crear y ejecutar el contenedor de Nginx
echo "Creando el contenedor de Nginx..."
if ! sudo docker run -d -p $puerto:80 --name $nombre_nginx --network $nombre_red -v "$ruta_proyecto":/var/www/html -v "$config_nginx_path":/etc/nginx/conf.d/default.conf nginx:stable-alpine; then
    echo "No se pudo crear el contenedor de Nginx. Verifique los datos y si el puerto $puerto está disponible."
    # Limpieza en caso de fallo
    sudo docker stop $nombre_php && sudo docker rm $nombre_php
    rm $config_nginx_path
    exit 1
fi

# Limpiar el archivo de configuración temporal
rm $config_nginx_path

echo "¡Entorno creado exitosamente!"
echo "Puede acceder a su aplicación en: http://localhost:$puerto"
echo "Sus contenedores en ejecución son: '$nombre_nginx' y '$nombre_php'."
