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
    if [ -n "$nombre" ] && [ -n "$DOCKER_CMD" ]; then
        if $DOCKER_CMD ps -a --format "table {{.Names}}" | grep -q "^$nombre$" 2>/dev/null; then
            if validar_yn "¿Desea eliminar el contenedor creado debido al error?"; then
                $DOCKER_CMD rm -f "$nombre"
                log "Contenedor eliminado"
                
                # Preguntar si también quiere eliminar los volúmenes
                if [ -n "$volumen_config" ] && validar_yn "¿Desea también eliminar los volúmenes de datos?"; then
                    $DOCKER_CMD volume rm "$volumen_config" 2>/dev/null || true
                    $DOCKER_CMD volume rm "$volumen_logs" 2>/dev/null || true
                    $DOCKER_CMD volume rm "$volumen_cache" 2>/dev/null || true
                    log "Volúmenes eliminados"
                fi
            fi
        fi
    fi
}

# Configurar trap para limpieza en caso de error
trap 'cleanup' ERR

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║         Instalador de Nginx en Docker - by Aether        ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Este script instalará Nginx en un contenedor de Docker con"
echo "configuración optimizada para diferentes tipos de proyectos."
echo ""

# Verificar si el script se ejecuta como usuario con permisos
if [ "$EUID" -eq 0 ]; then
    error_exit "No ejecute este script como root. Use sudo cuando sea necesario."
fi

if ! validar_yn "¿Desea continuar con la instalación?"; then
    echo "Operación cancelada"
    exit 1
fi

# Obtener información del sistema operativo
distro=$(uname -s)
log "El sistema operativo es: $distro"

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

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "        Iniciando configuración de Nginx"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Preguntar por la versión de Nginx
version="latest"
if validar_yn "¿Desea instalar una versión específica de Nginx?"; then
    echo "Versiones disponibles más comunes:"
    echo "- latest (stable)"
    echo "- alpine (versión ligera)"
    echo "- mainline-alpine (última versión, ligera)"
    echo "- 1.25-alpine"
    echo "- 1.24-alpine"
    read -p "Ingrese la versión de Nginx que desea instalar: " version
fi

# Descargar la imagen de Nginx
if ! $DOCKER_CMD pull nginx:$version; then
    error_exit "No se pudo descargar la imagen de Nginx. Verifique la conexión a Internet y la versión especificada."
fi
log "La imagen de Nginx se ha descargado correctamente"

# Obtener nombre del contenedor
while true; do
    read -p "Ingrese el nombre del contenedor (por defecto: contenedor-nginx): " nombre
    nombre=${nombre:-contenedor-nginx}
    
    # Verificar si el contenedor ya existe
    if $DOCKER_CMD ps -a --format "table {{.Names}}" | grep -q "^$nombre$" 2>/dev/null; then
        echo "Ya existe un contenedor con el nombre '$nombre'"
        if validar_yn "¿Desea eliminarlo y crear uno nuevo?"; then
            # Verificar si existen volúmenes asociados
            volumen_existente_config="${nombre}_nginx_config"
            volumen_existente_logs="${nombre}_nginx_logs"
            volumen_existente_cache="${nombre}_nginx_cache"
            
            if $DOCKER_CMD volume ls --format "table {{.Name}}" | grep -q "^$volumen_existente_config$" 2>/dev/null; then
                if validar_yn "¿Desea conservar la configuración existente?"; then
                    log "Se conservará la configuración existente"
                    conservar_config="Y"
                else
                    $DOCKER_CMD volume rm "$volumen_existente_config" 2>/dev/null || true
                    $DOCKER_CMD volume rm "$volumen_existente_logs" 2>/dev/null || true
                    $DOCKER_CMD volume rm "$volumen_existente_cache" 2>/dev/null || true
                    log "Volúmenes anteriores eliminados"
                    conservar_config="N"
                fi
            fi
            $DOCKER_CMD rm -f "$nombre"
            break
        fi
    else
        conservar_config="N"
        break
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "        Tipo de Proyecto/Aplicación"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Seleccione el tipo de proyecto que desea servir:"
echo "1) Sitio web estático (HTML/CSS/JS)"
echo "2) Single Page Application (React, Vue, Angular)"
echo "3) Proxy reverso para aplicación backend"
echo "4) Sitio PHP (WordPress, Laravel, etc.)"
echo "5) Configuración personalizada/múltiple"
echo ""

while true; do
    read -p "Seleccione una opción (1-5): " tipo_proyecto
    case $tipo_proyecto in
        1|2|3|4|5) break ;;
        *) echo "Opción inválida. Por favor seleccione 1-5" ;;
    esac
done

# Configuración según el tipo de proyecto
case $tipo_proyecto in
    1)
        tipo_nombre="Sitio Estático"
        config_type="static"
        ;;
    2)
        tipo_nombre="Single Page Application"
        config_type="spa"
        ;;
    3)
        tipo_nombre="Proxy Reverso"
        config_type="proxy"
        ;;
    4)
        tipo_nombre="Sitio PHP"
        config_type="php"
        ;;
    5)
        tipo_nombre="Configuración Personalizada"
        config_type="custom"
        ;;
esac

log "Tipo de proyecto seleccionado: $tipo_nombre"

# Configuración de directorios
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "        Configuración de Directorios"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Directorio del proyecto
if [ "$config_type" != "proxy" ]; then
    while true; do
        read -p "Ingrese la ruta del directorio de su proyecto (absoluta): " dir_proyecto
        
        if [ -z "$dir_proyecto" ]; then
            echo "Debe especificar un directorio"
            continue
        fi
        
        # Expandir ~ si está presente
        dir_proyecto="${dir_proyecto/#\~/$HOME}"
        
        if [ ! -d "$dir_proyecto" ]; then
            if validar_yn "El directorio no existe. ¿Desea crearlo?"; then
                mkdir -p "$dir_proyecto"
                log "Directorio creado: $dir_proyecto"
                break
            fi
        else
            log "Directorio encontrado: $dir_proyecto"
            break
        fi
    done
fi

# Configuración de proxy reverso
if [ "$config_type" = "proxy" ]; then
    echo ""
    echo "Configuración de Proxy Reverso:"
    read -p "Ingrese la URL del backend (ej: http://localhost:3000): " backend_url
    
    if validar_yn "¿Desea habilitar WebSocket support?"; then
        websocket_support="Y"
    else
        websocket_support="N"
    fi
fi

# Configuración de puertos
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "        Configuración de Puertos"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Puerto HTTP
while true; do
    read -p "Ingrese el puerto HTTP (por defecto: 80): " puerto_http
    puerto_http=${puerto_http:-80}
    
    if validar_puerto "$puerto_http"; then
        if ss -tuln 2>/dev/null | grep -q ":$puerto_http " || netstat -tuln 2>/dev/null | grep -q ":$puerto_http "; then
            echo "El puerto $puerto_http está en uso"
            continue
        else
            break
        fi
    else
        echo "Puerto inválido. Debe ser un número entre 1 y 65535"
    fi
done

# Puerto HTTPS
habilitar_https="N"
if validar_yn "¿Desea habilitar HTTPS?"; then
    habilitar_https="Y"
    
    while true; do
        read -p "Ingrese el puerto HTTPS (por defecto: 443): " puerto_https
        puerto_https=${puerto_https:-443}
        
        if validar_puerto "$puerto_https"; then
            if ss -tuln 2>/dev/null | grep -q ":$puerto_https " || netstat -tuln 2>/dev/null | grep -q ":$puerto_https "; then
                echo "El puerto $puerto_https está en uso"
                continue
            else
                break
            fi
        else
            echo "Puerto inválido"
        fi
    done
    
    # Configuración SSL
    echo ""
    echo "Configuración SSL:"
    echo "1) Usar certificados autofirmados (desarrollo)"
    echo "2) Proporcionar certificados existentes"
    echo "3) Configurar para Let's Encrypt (requiere dominio)"
    
    while true; do
        read -p "Seleccione una opción (1-3): " ssl_option
        case $ssl_option in
            1|2|3) break ;;
            *) echo "Opción inválida" ;;
        esac
    done
    
    if [ "$ssl_option" = "2" ]; then
        read -p "Ruta del certificado SSL (.crt): " ssl_cert_path
        read -p "Ruta de la clave privada (.key): " ssl_key_path
        
        if [ ! -f "$ssl_cert_path" ] || [ ! -f "$ssl_key_path" ]; then
            error_exit "Los archivos de certificado no existen"
        fi
    elif [ "$ssl_option" = "3" ]; then
        read -p "Ingrese su dominio (ej: ejemplo.com): " dominio
        echo "NOTA: Deberá configurar Let's Encrypt después de que el contenedor esté en ejecución"
    fi
fi

# Configuraciones adicionales
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "        Configuraciones Adicionales"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Compresión gzip
habilitar_gzip="Y"
if validar_yn "¿Desea habilitar compresión gzip? (recomendado)"; then
    habilitar_gzip="Y"
else
    habilitar_gzip="N"
fi

# Caché
habilitar_cache="N"
if validar_yn "¿Desea habilitar caché de archivos estáticos?"; then
    habilitar_cache="Y"
    read -p "Tiempo de expiración del caché en días (por defecto: 30): " cache_dias
    cache_dias=${cache_dias:-30}
fi

# Rate limiting
habilitar_rate_limit="N"
if validar_yn "¿Desea habilitar rate limiting (límite de peticiones)?"; then
    habilitar_rate_limit="Y"
    read -p "Número de peticiones por segundo permitidas (por defecto: 10): " rate_limit
    rate_limit=${rate_limit:-10}
fi

# Logs personalizados
if validar_yn "¿Desea configurar formato de logs personalizado?"; then
    logs_personalizados="Y"
    echo "Formato de logs:"
    echo "1) Estándar"
    echo "2) JSON (para parsing)"
    echo "3) Detallado (incluye tiempos de respuesta)"
    
    read -p "Seleccione formato (1-3, por defecto: 1): " log_format
    log_format=${log_format:-1}
else
    logs_personalizados="N"
    log_format="1"
fi

# Crear volúmenes únicos para cada contenedor
volumen_config="${nombre}_nginx_config"
volumen_logs="${nombre}_nginx_logs"
volumen_cache="${nombre}_nginx_cache"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "        Generando Configuración de Nginx"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Crear directorio temporal para la configuración
temp_config_dir=$(mktemp -d)
nginx_conf="$temp_config_dir/nginx.conf"
default_conf="$temp_config_dir/default.conf"

# Generar nginx.conf principal
cat > "$nginx_conf" << 'NGINX_CONF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
NGINX_CONF

# Agregar formato de logs personalizado
case $log_format in
    2)
        cat >> "$nginx_conf" << 'NGINX_CONF'
    log_format json escape=json '{'
        '"time":"$time_iso8601",'
        '"remote_addr":"$remote_addr",'
        '"request":"$request",'
        '"status":$status,'
        '"body_bytes_sent":$body_bytes_sent,'
        '"request_time":$request_time,'
        '"http_referrer":"$http_referer",'
        '"http_user_agent":"$http_user_agent"'
    '}';
    access_log /var/log/nginx/access.log json;
NGINX_CONF
        ;;
    3)
        cat >> "$nginx_conf" << 'NGINX_CONF'
    log_format detailed '$remote_addr - $remote_user [$time_local] '
                       '"$request" $status $body_bytes_sent '
                       '"$http_referer" "$http_user_agent" '
                       'rt=$request_time uct="$upstream_connect_time" '
                       'uht="$upstream_header_time" urt="$upstream_response_time"';
    access_log /var/log/nginx/access.log detailed;
NGINX_CONF
        ;;
    *)
        cat >> "$nginx_conf" << 'NGINX_CONF'
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;
NGINX_CONF
        ;;
esac

# Continuar con nginx.conf
cat >> "$nginx_conf" << 'NGINX_CONF'
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 20M;
    
NGINX_CONF

# Agregar gzip si está habilitado
if [ "$habilitar_gzip" = "Y" ]; then
    cat >> "$nginx_conf" << 'NGINX_CONF'
    # Gzip Settings
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss 
               application/rss+xml font/truetype font/opentype 
               application/vnd.ms-fontobject image/svg+xml;
    gzip_disable "msie6";
    
NGINX_CONF
fi

# Agregar rate limiting si está habilitado
if [ "$habilitar_rate_limit" = "Y" ]; then
    cat >> "$nginx_conf" << NGINX_CONF
    # Rate Limiting
    limit_req_zone \$binary_remote_addr zone=general:10m rate=${rate_limit}r/s;
    limit_req_status 429;
    
NGINX_CONF
fi

# Cerrar nginx.conf
cat >> "$nginx_conf" << 'NGINX_CONF'
    include /etc/nginx/conf.d/*.conf;
}
NGINX_CONF

log "Configuración principal de Nginx generada"

# Generar default.conf según el tipo de proyecto
case $config_type in
    static|spa)
        cat > "$default_conf" << NGINX_CONF
server {
    listen 80;
    server_name localhost;
    
    root /usr/share/nginx/html;
    index index.html index.htm;
    
NGINX_CONF
        
        if [ "$habilitar_rate_limit" = "Y" ]; then
            echo "    limit_req zone=general burst=20 nodelay;" >> "$default_conf"
        fi
        
        if [ "$config_type" = "spa" ]; then
            cat >> "$default_conf" << 'NGINX_CONF'
    
    # SPA Configuration - try files first, fallback to index.html
    location / {
        try_files $uri $uri/ /index.html;
    }
    
NGINX_CONF
        else
            cat >> "$default_conf" << 'NGINX_CONF'
    
    location / {
        try_files $uri $uri/ =404;
    }
    
NGINX_CONF
        fi
        
        if [ "$habilitar_cache" = "Y" ]; then
            cat >> "$default_conf" << NGINX_CONF
    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires ${cache_dias}d;
        add_header Cache-Control "public, immutable";
    }
    
NGINX_CONF
        fi
        
        cat >> "$default_conf" << 'NGINX_CONF'
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
NGINX_CONF
        ;;
        
    proxy)
        cat > "$default_conf" << NGINX_CONF
server {
    listen 80;
    server_name localhost;
    
NGINX_CONF
        
        if [ "$habilitar_rate_limit" = "Y" ]; then
            echo "    limit_req zone=general burst=20 nodelay;" >> "$default_conf"
        fi
        
        cat >> "$default_conf" << NGINX_CONF
    
    location / {
        proxy_pass ${backend_url};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
NGINX_CONF
        
        if [ "$websocket_support" = "Y" ]; then
            cat >> "$default_conf" << 'NGINX_CONF'
    
    # WebSocket support
    location /ws {
        proxy_pass ${backend_url};
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400;
    }
NGINX_CONF
        fi
        
        cat >> "$default_conf" << 'NGINX_CONF'
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
NGINX_CONF
        ;;
        
    php)
        cat > "$default_conf" << 'NGINX_CONF'
server {
    listen 80;
    server_name localhost;
    
    root /usr/share/nginx/html;
    index index.php index.html index.htm;
    
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    location ~ \.php$ {
        fastcgi_pass php-fpm:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~ /\.ht {
        deny all;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
NGINX_CONF
        echo "NOTA: Para PHP, necesitará crear un contenedor PHP-FPM adicional"
        ;;
        
    custom)
        cat > "$default_conf" << 'NGINX_CONF'
server {
    listen 80;
    server_name localhost;
    
    root /usr/share/nginx/html;
    index index.html index.htm;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # Agregue aquí su configuración personalizada
}
NGINX_CONF
        ;;
esac

log "Configuración del servidor generada"

# Construir comando Docker
docker_command="$DOCKER_CMD run -d --name $nombre"

# Agregar puertos
docker_command="$docker_command -p $puerto_http:80"
if [ "$habilitar_https" = "Y" ]; then
    docker_command="$docker_command -p $puerto_https:443"
fi

# Agregar volúmenes
docker_command="$docker_command -v $volumen_config:/etc/nginx:ro"
docker_command="$docker_command -v $volumen_logs:/var/log/nginx"

if [ "$config_type" != "proxy" ]; then
    docker_command="$docker_command -v $dir_proyecto:/usr/share/nginx/html:ro"
fi

if [ "$habilitar_cache" = "Y" ]; then
    docker_command="$docker_command -v $volumen_cache:/var/cache/nginx"
fi

# Agregar imagen
docker_command="$docker_command nginx:$version"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "        Creando Contenedor de Nginx"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Crear volúmenes si no existen
if [ "$conservar_config" != "Y" ]; then
    $DOCKER_CMD volume create "$volumen_config" >/dev/null
    log "Volumen de configuración creado: $volumen_config"
fi

$DOCKER_CMD volume create "$volumen_logs" >/dev/null
log "Volumen de logs creado: $volumen_logs"

if [ "$habilitar_cache" = "Y" ]; then
    $DOCKER_CMD volume create "$volumen_cache" >/dev/null
    log "Volumen de caché creado: $volumen_cache"
fi

# Copiar archivos de configuración al volumen
log "Copiando archivos de configuración..."

# Crear contenedor temporal para copiar configuración
temp_container="${nombre}_temp"
$DOCKER_CMD run -d --name "$temp_container" -v "$volumen_config:/target" nginx:$version sleep 3600 >/dev/null

# Copiar configuración
$DOCKER_CMD cp "$nginx_conf" "$temp_container:/target/nginx.conf"
$DOCKER_CMD exec "$temp_container" mkdir -p /target/conf.d
$DOCKER_CMD cp "$default_conf" "$temp_container:/target/conf.d/default.conf"

# Limpiar contenedor temporal
$DOCKER_CMD rm -f "$temp_container" >/dev/null
rm -rf "$temp_config_dir"

log "Configuración copiada exitosamente"

# Crear el contenedor
log "Creando contenedor Nginx..."
if eval "$docker_command"; then
    log "Contenedor creado exitosamente"
    
    # Esperar a que Nginx esté listo
    log "Esperando a que Nginx esté listo..."
    sleep 3
    
    # Verificar que Nginx está funcionando
    if $DOCKER_CMD exec "$nombre" nginx -t >/dev/null 2>&1; then
        log "Nginx está funcionando correctamente"
    else
        log "ADVERTENCIA: La configuración de Nginx puede tener problemas"
        $DOCKER_CMD logs "$nombre"
    fi
    
    # Mostrar información de conexión
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║              INSTALACIÓN COMPLETADA                      ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    echo "INFORMACIÓN DEL SERVIDOR:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Contenedor: $nombre"
    echo "Tipo: $tipo_nombre"
    echo "Puerto HTTP: $puerto_http"
    
    if [ "$habilitar_https" = "Y" ]; then
        echo "Puerto HTTPS: $puerto_https"
    fi
    
    if [ "$config_type" != "proxy" ]; then
        echo "Directorio proyecto: $dir_proyecto"
    else
        echo "Backend URL: $backend_url"
    fi
    
    echo ""
    echo "ACCESO:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "URL: http://localhost:$puerto_http"
    
    if [ "$habilitar_https" = "Y" ]; then
        echo "URL HTTPS: https://localhost:$puerto_https"
    fi
    
    echo ""
    echo "VOLÚMENES:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Configuración: $volumen_config"
    echo "Logs: $volumen_logs"
    
    if [ "$habilitar_cache" = "Y" ]; then
        echo "Caché: $volumen_cache"
    fi
    
    echo ""
    echo "COMANDOS ÚTILES:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Ver logs en tiempo real:"
    echo "  $DOCKER_CMD logs -f $nombre"
    echo ""
    echo "Recargar configuración:"
    echo "  $DOCKER_CMD exec $nombre nginx -s reload"
    echo ""
    echo "Verificar configuración:"
    echo "  $DOCKER_CMD exec $nombre nginx -t"
    echo ""
    echo "Parar contenedor:"
    echo "  $DOCKER_CMD stop $nombre"
    echo ""
    echo "Iniciar contenedor:"
    echo "  $DOCKER_CMD start $nombre"
    echo ""
    echo "Ver archivos de log:"
    echo "  $DOCKER_CMD exec $nombre tail -f /var/log/nginx/access.log"
    echo "  $DOCKER_CMD exec $nombre tail -f /var/log/nginx/error.log"
    echo ""
    echo "Acceder al shell del contenedor:"
    echo "  $DOCKER_CMD exec -it $nombre sh"
    echo ""
    echo "Editar configuración:"
    echo "  $DOCKER_CMD exec -it $nombre vi /etc/nginx/conf.d/default.conf"
    echo ""
    
    if [ "$config_type" = "php" ]; then
        echo "NOTA PHP-FPM:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Necesita crear un contenedor PHP-FPM y conectarlo a este Nginx"
        echo "Ejemplo:"
        echo "  docker run -d --name php-fpm -v $dir_proyecto:/usr/share/nginx/html php:fpm"
        echo "  docker network create nginx-php"
        echo "  docker network connect nginx-php $nombre"
        echo "  docker network connect nginx-php php-fpm"
        echo ""
    fi
    
    if [ "$ssl_option" = "3" ]; then
        echo "CONFIGURACIÓN DE LET'S ENCRYPT:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Para configurar Let's Encrypt, use certbot:"
        echo "  docker run -it --rm --name certbot \\"
        echo "    -v \"$volumen_config:/etc/nginx\" \\"
        echo "    -v \"certbot-etc:/etc/letsencrypt\" \\"
        echo "    -v \"$dir_proyecto:/usr/share/nginx/html\" \\"
        echo "    certbot/certbot certonly --webroot \\"
        echo "    -w /usr/share/nginx/html -d $dominio"
        echo ""
    fi
    
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║         Nginx instalado y configurado exitosamente       ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    
else
    error_exit "No se pudo crear el contenedor de Nginx"
fi
