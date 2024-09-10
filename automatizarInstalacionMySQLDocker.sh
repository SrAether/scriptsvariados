#!/bin/bash

echo "Creado por Aether"
echo "Este script instalará MySQL en un contenedor de Docker"
echo "Coloque Y para continuar o N para cancelar"
read respuesta

if [ "$respuesta" = "Y" ]; then
    echo "Iniciando la instalación de MySQL en Docker"
else
    echo "Operación cancelada"
    exit 1  # Salimos del script con código de error 1
fi

# Obtener información del sistema operativo
distro=$(uname -s)
echo "El sistema operativo es: $distro"

# Verificar si Docker está instalado
if command -v docker &> /dev/null; then
    echo "Docker está instalado"
else
    echo "Docker no está instalado"
    echo "Instalando Docker..."

    # Instalar Docker según el sistema operativo
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y docker.io
    elif command -v yum &> /dev/null; then
        sudo yum install -y docker
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y docker
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm docker
    else
        echo "No se pudo instalar Docker. Sistema operativo no soportado."
        exit 1
    fi

    # Iniciar y habilitar el servicio de Docker
    sudo systemctl start docker
    echo "¿Desea que Docker se inicie con el sistema? (Y/N)"
    read respuesta
    if [ "$respuesta" = "Y" ]; then
        sudo systemctl enable docker
    fi

    # Verificar que Docker esté en ejecución
    if ! sudo systemctl is-active --quiet docker; then
        echo "Docker no está en ejecución. Por favor, inicie Docker e intente nuevamente."
        exit 1
    fi

    echo "Docker se ha instalado correctamente y está en ejecución"
fi

echo "Iniciando la instalación de MySQL en Docker"

# Preguntar por la versión de MySQL
version="latest"
echo "¿Desea instalar una versión específica de MySQL? (Y/N)"
read respuesta
if [ "$respuesta" = "Y" ]; then
    echo "Ingrese la versión de MySQL que desea instalar (por ejemplo, 8.0):"
    read version
fi

# Descargar la imagen de MySQL
if ! sudo docker pull mysql:$version; then
    echo "No se pudo descargar la imagen de MySQL. Verifique la conexión a Internet y la versión especificada."
    exit 1
fi
echo "La imagen de MySQL se ha descargado correctamente"

# Obtener datos para crear el contenedor
echo "Ingrese el nombre del contenedor (por defecto: contenedor-mysql):"
read nombre
nombre=${nombre:-contenedor-mysql}  # Asignar valor predeterminado si está vacío

echo "Las importaciones son a través de un archivo SQL"
echo "¿Le gustaría importar una base de datos? (Y/N)"
read importar

if [ "$importar" = "Y" ]; then
    echo "Ingrese la ruta completa al archivo SQL:"
    read ruta
    if [ ! -f "$ruta" ]; then  # Verificar si el archivo existe
        echo "El archivo SQL no existe en la ruta especificada."
        exit 1
    fi
else
    echo "No se importará ninguna base de datos. Se creará una base de datos vacía."
    echo "Ingrese el nombre de la base de datos (por defecto: db):"
    read db
    db=${db:-db} 
fi

echo "Ingrese el puerto de MySQL (por defecto: 3306):"
read puerto
puerto=${puerto:-3306}

echo "Ingrese la contraseña de MySQL (por defecto: contraseña123):"
read contrasena
contrasena=${contrasena:-contraseña123}

# Construir la sentencia Docker
if [ "$importar" = "Y" ]; then
    sentencia="sudo docker run -d \
        --name $nombre \
        -p $puerto:3306 \
        -e MYSQL_ROOT_PASSWORD=$contrasena \
        -v db_data:/var/lib/mysql \
        -v $ruta:/docker-entrypoint-initdb.d/import.sql \
        mysql:$version"
else
    sentencia="sudo docker run -d \
        --name $nombre \
        -p $puerto:3306 \
        -e MYSQL_ROOT_PASSWORD=$contrasena \
        -e MYSQL_DATABASE=$db \
        -v db_data:/var/lib/mysql \
        mysql:$version"
fi

# Crear el contenedor
if ! eval "$sentencia"; then 
    echo "No se pudo crear el contenedor de MySQL. Verifique los datos ingresados y que el puerto esté disponible."
    exit 1
fi

echo "El contenedor de MySQL se ha creado correctamente"