#!/bin/bash

# Función para validar respuestas Y/N
validar_yn() {
    local respuesta
    while true; do
        read -p "$1 (Y/N): " respuesta
        case $respuesta in
            [Yy]|[Ss]|[Yy][Ee][Ss]|[Ss][Ii]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            *) echo "Por favor, responda Y/N" ;;
        esac
    done
}

# Función para validar puertos
validar_puerto() {
    local puerto=$1
    if [[ ! "$puerto" =~ ^[0-9]+$ ]] || [ "$puerto" -lt 1 ] || [ "$puerto" -gt 65535 ]; then
        return 1
    fi
    return 0
}

# Función de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

# Función de limpieza
cleanup() {
    log "Realizando limpieza de contenedores creados..."
    
    if [ -n "$nombre_nginx" ] && [ -n "$DOCKER_CMD" ]; then
        if $DOCKER_CMD ps -a --format "table {{.Names}}" | grep -q "^$nombre_nginx$" 2>/dev/null; then
            if validar_yn "¿Desea eliminar el contenedor de Nginx ($nombre_nginx)?"; then
                $DOCKER_CMD stop "$nombre_nginx" 2>/dev/null
                $DOCKER_CMD rm "$nombre_nginx" 2>/dev/null
                log "Contenedor de Nginx eliminado"
            fi
        fi
    fi
    
    if [ -n "$nombre_php" ] && [ -n "$DOCKER_CMD" ]; then
        if $DOCKER_CMD ps -a --format "table {{.Names}}" | grep -q "^$nombre_php$" 2>/dev/null; then
            if validar_yn "¿Desea eliminar el contenedor de PHP ($nombre_php)?"; then
                $DOCKER_CMD stop "$nombre_php" 2>/dev/null
                $DOCKER_CMD rm "$nombre_php" 2>/dev/null
                log "Contenedor de PHP eliminado"
            fi
        fi
    fi
    
    # Limpiar archivos temporales
    if [ -n "$config_nginx_path" ] && [ -f "$config_nginx_path" ]; then
        rm -f "$config_nginx_path"
        log "Archivo de configuración temporal eliminado"
    fi
}

# Configurar trap para limpieza en caso de error
trap 'cleanup' ERR

echo "Creado por Aether"
echo "Este script creará un entorno de desarrollo PHP con Nginx en Docker"

# Verificar si el script se ejecuta como usuario con permisos
if [ "$EUID" -eq 0 ]; then
    error_exit "No ejecute este script como root. Use sudo cuando sea necesario."
fi

if ! validar_yn "¿Desea continuar con la instalación?"; then
    echo "Operación cancelada"
    exit 1
fi

# 1. VERIFICACIÓN E INSTALACIÓN DE DOCKER
#--------------------------------------------------

log "Verificando instalación de Docker..."

# Verificar si Docker está instalado
if command -v docker &> /dev/null; then
    log "Docker está instalado"
    # Verificar si el usuario puede ejecutar docker sin sudo
    if docker ps &> /dev/null; then
        DOCKER_CMD="docker"
        log "Usando Docker sin sudo"
    else
        DOCKER_CMD="sudo docker"
        log "Se requiere sudo para ejecutar Docker"
    fi
else
    log "Docker no está instalado. Iniciando instalación..."
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
        error_exit "No se pudo instalar Docker. Sistema operativo no soportado."
    fi

    # Iniciar y habilitar el servicio de Docker
    sudo systemctl start docker
    if validar_yn "¿Desea que Docker se inicie con el sistema?"; then
        sudo systemctl enable docker
    fi

    # Verificar que Docker esté en ejecución
    if ! sudo systemctl is-active --quiet docker; then
        error_exit "Docker no está en ejecución. Por favor, inicie Docker e intente nuevamente."
    fi

    DOCKER_CMD="sudo docker"
    log "Docker se ha instalado correctamente y está en ejecución"
fi


# 2. CONFIGURACIÓN DEL ENTORNO PHP Y NGINX
#--------------------------------------------------

log "Iniciando la configuración del entorno PHP con Nginx"

# Obtener la ruta del proyecto del usuario con validación
while true; do
    echo "Por favor, ingrese la ruta absoluta a la carpeta de su proyecto PHP:"
    read ruta_proyecto
    
    if [ -z "$ruta_proyecto" ]; then
        echo "Debe especificar una ruta"
        continue
    fi
    
    if [ ! -d "$ruta_proyecto" ]; then
        echo "El directorio especificado no existe."
        if validar_yn "¿Desea crear el directorio?"; then
            if mkdir -p "$ruta_proyecto"; then
                log "Directorio creado: $ruta_proyecto"
                break
            else
                error_exit "No se pudo crear el directorio"
            fi
        fi
    else
        log "Usando directorio existente: $ruta_proyecto"
        break
    fi
done

# Verificar si hay archivos PHP en el directorio
php_files=$(find "$ruta_proyecto" -name "*.php" 2>/dev/null | wc -l)
if [ "$php_files" -eq 0 ]; then
    log "No se encontraron archivos PHP en el directorio"
    if validar_yn "¿Desea crear un archivo index.php de prueba?"; then
        cat > "$ruta_proyecto/index.php" << 'EOF'
<?php
phpinfo();
echo "<h2>¡Entorno PHP funcionando correctamente!</h2>";
echo "<p>Fecha y hora: " . date('Y-m-d H:i:s') . "</p>";
?>
EOF
        log "Archivo index.php de prueba creado"
    fi
fi

# Obtener datos para los contenedores con validación
while true; do
    echo "Ingrese el nombre para el contenedor de Nginx (por defecto: web-server):"
    read nombre_nginx
    nombre_nginx=${nombre_nginx:-web-server}
    
    # Verificar si el contenedor ya existe
    if $DOCKER_CMD ps -a --format "table {{.Names}}" | grep -q "^$nombre_nginx$" 2>/dev/null; then
        echo "Ya existe un contenedor con el nombre '$nombre_nginx'"
        if validar_yn "¿Desea eliminarlo y crear uno nuevo?"; then
            $DOCKER_CMD stop "$nombre_nginx" 2>/dev/null
            $DOCKER_CMD rm "$nombre_nginx" 2>/dev/null
            break
        fi
    else
        break
    fi
done

while true; do
    echo "Ingrese el nombre para el contenedor de PHP (por defecto: app-php):"
    read nombre_php
    nombre_php=${nombre_php:-app-php}
    
    # Verificar si el contenedor ya existe
    if $DOCKER_CMD ps -a --format "table {{.Names}}" | grep -q "^$nombre_php$" 2>/dev/null; then
        echo "Ya existe un contenedor con el nombre '$nombre_php'"
        if validar_yn "¿Desea eliminarlo y crear uno nuevo?"; then
            $DOCKER_CMD stop "$nombre_php" 2>/dev/null
            $DOCKER_CMD rm "$nombre_php" 2>/dev/null
            break
        fi
    else
        break
    fi
done

# Validación de puerto mejorada
while true; do
    echo "Ingrese el puerto para acceder a su aplicación web (por defecto: 8080):"
    read puerto
    puerto=${puerto:-8080}
    
    if validar_puerto "$puerto"; then
        # Verificar si el puerto está en uso
        if ss -tuln 2>/dev/null | grep -q ":$puerto " || netstat -tuln 2>/dev/null | grep -q ":$puerto "; then
            echo "El puerto $puerto está en uso"
            continue
        else
            break
        fi
    else
        echo "Puerto inválido. Debe ser un número entre 1 y 65535"
    fi
done

# Selección de versión de PHP
echo "Seleccione la versión de PHP:"
echo "1. PHP 8.3 (más reciente)"
echo "2. PHP 8.2"
echo "3. PHP 8.1"
echo "4. PHP 7.4"
echo "5. Otra versión (especificar)"

read -p "Seleccione una opción (1-5): " php_version_option

case $php_version_option in
    1) php_version="8.3-fpm-alpine" ;;
    2) php_version="8.2-fpm-alpine" ;;
    3) php_version="8.1-fpm-alpine" ;;
    4) php_version="7.4-fpm-alpine" ;;
    5) 
        read -p "Ingrese la versión de PHP (ej: 8.0-fpm-alpine): " php_version
        ;;
    *) php_version="8.3-fpm-alpine" ;;
esac

log "Versión de PHP seleccionada: $php_version"

# 3. CREACIÓN DE LA RED Y CONTENEDORES DE DOCKER
#--------------------------------------------------

# Crear una red de Docker para la comunicación entre contenedores
nombre_red="red-php-nginx-$(date +%s)"
log "Creando red de Docker: $nombre_red"
if ! $DOCKER_CMD network create "$nombre_red"; then
    error_exit "No se pudo crear la red de Docker"
fi

# Descargar imágenes de Docker
log "Descargando imagen de PHP: php:$php_version"
if ! $DOCKER_CMD pull "php:$php_version"; then
    error_exit "No se pudo descargar la imagen de PHP"
fi

log "Descargando imagen de Nginx"
if ! $DOCKER_CMD pull nginx:stable-alpine; then
    error_exit "No se pudo descargar la imagen de Nginx"
fi

# Crear y ejecutar el contenedor de PHP-FPM
log "Creando el contenedor de PHP..."
php_command="$DOCKER_CMD run -d \
    --name $nombre_php \
    --network $nombre_red \
    -v \"$ruta_proyecto\":/var/www/html \
    php:$php_version"

if ! eval "$php_command"; then
    error_exit "No se pudo crear el contenedor de PHP"
fi
log "Contenedor de PHP '$nombre_php' creado exitosamente"

# Esperar a que PHP esté listo
log "Esperando a que PHP esté listo..."
sleep 3

# Verificar que PHP esté funcionando
if ! $DOCKER_CMD exec "$nombre_php" php -v &>/dev/null; then
    error_exit "PHP no está funcionando correctamente en el contenedor"
fi
log "PHP está funcionando correctamente"

# Crear un archivo de configuración de Nginx mejorado
config_nginx_path="/tmp/nginx_config_for_${nombre_nginx}_$(date +%s).conf"
log "Creando configuración de Nginx en: $config_nginx_path"

cat <<EOF > "$config_nginx_path"
server {
    listen 80;
    server_name localhost;
    root /var/www/html;
    index index.php index.html index.htm;

    # Configuración de logs
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Configuración de archivos estáticos
    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files \$uri =404;
    }

    # Configuración principal
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    # Configuración de PHP
    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass $nombre_php:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        include fastcgi_params;
        
        # Configuraciones adicionales de PHP
        fastcgi_read_timeout 300;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
    }

    # Negar acceso a archivos sensibles
    location ~ /\. {
        deny all;
    }
    
    location ~ /\.htaccess {
        deny all;
    }
}
EOF

# Crear y ejecutar el contenedor de Nginx
log "Creando el contenedor de Nginx..."
nginx_command="$DOCKER_CMD run -d \
    -p $puerto:80 \
    --name $nombre_nginx \
    --network $nombre_red \
    -v \"$ruta_proyecto\":/var/www/html \
    -v \"$config_nginx_path\":/etc/nginx/conf.d/default.conf \
    nginx:stable-alpine"

if ! eval "$nginx_command"; then
    error_exit "No se pudo crear el contenedor de Nginx"
fi
log "Contenedor de Nginx '$nombre_nginx' creado exitosamente"

# Esperar a que Nginx esté listo
log "Esperando a que Nginx esté listo..."
timeout=30
while [ $timeout -gt 0 ]; do
    if curl -s "http://localhost:$puerto" &>/dev/null; then
        log "Nginx está respondiendo correctamente"
        break
    fi
    sleep 2
    timeout=$((timeout - 2))
done

if [ $timeout -le 0 ]; then
    log "ADVERTENCIA: Nginx no respondió en el tiempo esperado, pero los contenedores están ejecutándose"
fi

# Limpiar el archivo de configuración temporal (se mantiene para referencia)
# rm "$config_nginx_path"

# Mostrar información de conexión
echo "=============================="
echo "ENTORNO PHP CREADO EXITOSAMENTE"
echo "=============================="
echo "✓ Red Docker: $nombre_red"
echo "✓ Contenedor PHP: $nombre_php (php:$php_version)"
echo "✓ Contenedor Nginx: $nombre_nginx"
echo "✓ Puerto: $puerto"
echo "✓ Directorio: $ruta_proyecto"
echo ""
echo "Acceso a la aplicación:"
echo "🌐 URL: http://localhost:$puerto"
echo ""
echo "Comandos útiles:"
echo "• Ver logs de Nginx: $DOCKER_CMD logs $nombre_nginx"
echo "• Ver logs de PHP: $DOCKER_CMD logs $nombre_php"
echo "• Entrar a PHP: $DOCKER_CMD exec -it $nombre_php sh"
echo "• Entrar a Nginx: $DOCKER_CMD exec -it $nombre_nginx sh"
echo "• Parar entorno: $DOCKER_CMD stop $nombre_nginx $nombre_php"
echo "• Iniciar entorno: $DOCKER_CMD start $nombre_php $nombre_nginx"
echo "• Eliminar entorno: $DOCKER_CMD rm $nombre_nginx $nombre_php && $DOCKER_CMD network rm $nombre_red"
echo ""
echo "Archivo de configuración Nginx: $config_nginx_path"
echo "=============================="

log "Entorno PHP con Nginx creado exitosamente"
