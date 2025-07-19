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
                
                # Preguntar si también quiere eliminar el volumen
                if [ -n "$volumen_datos" ] && validar_yn "¿Desea también eliminar el volumen de datos ($volumen_datos)?"; then
                    $DOCKER_CMD volume rm "$volumen_datos" 2>/dev/null || true
                    log "Volumen eliminado"
                fi
            fi
        fi
    fi
}

# Configurar trap para limpieza en caso de error
trap 'cleanup' ERR

echo "Creado por Aether"
echo "Este script instalará MariaDB en un contenedor de Docker"

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

echo "Iniciando la instalación de MariaDB en Docker"

# Preguntar por la versión de MariaDB
version="latest"
if validar_yn "¿Desea instalar una versión específica de MariaDB?"; then
    echo "Versiones disponibles más comunes:"
    echo "- 11.5 (latest LTS)"
    echo "- 11.4"
    echo "- 10.11 (LTS)"
    echo "- 10.6 (LTS)"
    echo "Ingrese la versión de MariaDB que desea instalar:"
    read version
fi

# Descargar la imagen de MariaDB
if ! $DOCKER_CMD pull mariadb:$version; then
    error_exit "No se pudo descargar la imagen de MariaDB. Verifique la conexión a Internet y la versión especificada."
fi
log "La imagen de MariaDB se ha descargado correctamente"

# Obtener datos para crear el contenedor
while true; do
    echo "Ingrese el nombre del contenedor (por defecto: contenedor-mariadb):"
    read nombre
    nombre=${nombre:-contenedor-mariadb}
    
    # Verificar si el contenedor ya existe
    if $DOCKER_CMD ps -a --format "table {{.Names}}" | grep -q "^$nombre$" 2>/dev/null; then
        echo "Ya existe un contenedor con el nombre '$nombre'"
        if validar_yn "¿Desea eliminarlo y crear uno nuevo?"; then
            # Verificar si existe un volumen asociado
            volumen_existente="${nombre}_mariadb_data"
            if $DOCKER_CMD volume ls --format "table {{.Name}}" | grep -q "^$volumen_existente$" 2>/dev/null; then
                echo "Se encontró un volumen de datos existente: $volumen_existente"
                if validar_yn "¿Desea conservar los datos existentes?"; then
                    log "Se conservarán los datos del volumen existente"
                else
                    $DOCKER_CMD volume rm "$volumen_existente" 2>/dev/null || true
                    log "Volumen anterior eliminado"
                fi
            fi
            $DOCKER_CMD rm -f "$nombre"
            break
        fi
    else
        break
    fi
done

echo "Las importaciones son a través de un archivo SQL"
if validar_yn "¿Le gustaría importar una base de datos?"; then
    echo "Ingrese la ruta completa al archivo SQL:"
    read ruta
    if [ ! -f "$ruta" ]; then
        error_exit "El archivo SQL no existe en la ruta especificada."
    fi
    importar="Y"
else
    echo "No se importará ninguna base de datos. Se creará una base de datos vacía."
    echo "Ingrese el nombre de la base de datos (por defecto: mariadb):"
    read db
    db=${db:-mariadb}
    importar="N"
fi

# Configuración de usuario personalizado
echo "Configuración de usuarios:"
echo "MariaDB creará automáticamente el usuario 'root'"
if validar_yn "¿Desea crear un usuario adicional (no root)?"; then
    echo "Ingrese el nombre del usuario adicional:"
    read usuario_custom
    while true; do
        read -s -p "Ingrese la contraseña para el usuario '$usuario_custom' (mínimo 8 caracteres): " pass_custom
        echo
        if [ ${#pass_custom} -ge 8 ]; then
            read -s -p "Confirme la contraseña: " pass_custom_confirm
            echo
            if [ "$pass_custom" = "$pass_custom_confirm" ]; then
                break
            else
                echo "Las contraseñas no coinciden"
            fi
        else
            echo "La contraseña debe tener al menos 8 caracteres"
        fi
    done
    crear_usuario="Y"
else
    crear_usuario="N"
fi

# Validación de puerto mejorada
while true; do
    echo "Ingrese el puerto de MariaDB (por defecto: 3306):"
    read puerto
    puerto=${puerto:-3306}
    
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

# Validación de contraseña root mejorada
while true; do
    read -s -p "Ingrese la contraseña de root para MariaDB (mínimo 8 caracteres): " contrasena_root
    echo
    if [ ${#contrasena_root} -ge 8 ]; then
        read -s -p "Confirme la contraseña de root: " contrasena_root_confirm
        echo
        if [ "$contrasena_root" = "$contrasena_root_confirm" ]; then
            break
        else
            echo "Las contraseñas no coinciden"
        fi
    else
        echo "La contraseña debe tener al menos 8 caracteres"
    fi
done

# Configuraciones adicionales de MariaDB
configuracion_adicional=""
if validar_yn "¿Desea configurar parámetros adicionales de MariaDB?"; then
    echo "Configuraciones disponibles:"
    echo "1. InnoDB Buffer Pool Size (recomendado: 70-80% de RAM disponible)"
    echo "2. Max Connections"
    echo "3. Query Cache"
    echo "4. Charset por defecto"
    
    if validar_yn "¿Desea configurar InnoDB Buffer Pool Size?"; then
        echo "Ingrese el tamaño del buffer pool (ej: 1G, 512M):"
        read innodb_buffer
        configuracion_adicional="$configuracion_adicional --innodb-buffer-pool-size=$innodb_buffer"
    fi
    
    if validar_yn "¿Desea configurar el número máximo de conexiones?"; then
        echo "Ingrese el número máximo de conexiones (por defecto: 151):"
        read max_connections
        max_connections=${max_connections:-151}
        configuracion_adicional="$configuracion_adicional --max-connections=$max_connections"
    fi
    
    if validar_yn "¿Desea habilitar el Query Cache?"; then
        echo "Ingrese el tamaño del query cache (ej: 64M, 128M):"
        read query_cache
        configuracion_adicional="$configuracion_adicional --query-cache-size=$query_cache --query-cache-type=1"
    fi
    
    if validar_yn "¿Desea configurar el charset por defecto como utf8mb4?"; then
        configuracion_adicional="$configuracion_adicional --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci"
    fi
fi

# Construir la sentencia Docker
# Crear un volumen único para cada contenedor
volumen_datos="${nombre}_mariadb_data"

# Variables de entorno base
env_vars="-e MARIADB_ROOT_PASSWORD=$contrasena_root"

# Agregar usuario personalizado si se especificó
if [ "$crear_usuario" = "Y" ]; then
    env_vars="$env_vars -e MARIADB_USER=$usuario_custom -e MARIADB_PASSWORD=$pass_custom"
fi

# Configurar base de datos
if [ "$importar" != "Y" ]; then
    env_vars="$env_vars -e MARIADB_DATABASE=$db"
fi

if [ "$importar" = "Y" ]; then
    sentencia="$DOCKER_CMD run -d \
        --name $nombre \
        -p $puerto:3306 \
        $env_vars \
        -v $volumen_datos:/var/lib/mysql \
        -v $ruta:/docker-entrypoint-initdb.d/import.sql \
        mariadb:$version"
else
    sentencia="$DOCKER_CMD run -d \
        --name $nombre \
        -p $puerto:3306 \
        $env_vars \
        -v $volumen_datos:/var/lib/mysql \
        mariadb:$version"
fi

# Agregar configuración adicional si existe
if [ -n "$configuracion_adicional" ]; then
    sentencia="$sentencia $configuracion_adicional"
fi

# Crear el contenedor
log "Creando contenedor MariaDB..."
if eval "$sentencia"; then
    log "Contenedor creado exitosamente"
    
    # Esperar a que MariaDB esté listo
    log "Esperando a que MariaDB esté listo..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if $DOCKER_CMD exec "$nombre" mysqladmin ping -h localhost --silent 2>/dev/null; then
            log "MariaDB está listo y funcionando"
            break
        fi
        sleep 2
        timeout=$((timeout - 2))
    done
    
    if [ $timeout -le 0 ]; then
        error_exit "MariaDB no respondió en el tiempo esperado"
    fi
    
    # Verificar la versión instalada
    version_instalada=$($DOCKER_CMD exec "$nombre" mysql -u root -p"$contrasena_root" -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
    if [ -n "$version_instalada" ]; then
        log "MariaDB versión instalada: $version_instalada"
    fi
    
    # Mostrar información de conexión
    echo "========================="
    echo "INFORMACIÓN DE CONEXIÓN"
    echo "========================="
    echo "Host: localhost"
    echo "Puerto: $puerto"
    echo "Usuario root: root"
    echo "Contraseña root: [la que configuraste]"
    if [ "$crear_usuario" = "Y" ]; then
        echo "Usuario adicional: $usuario_custom"
        echo "Contraseña usuario: [la que configuraste]"
    fi
    if [ "$importar" != "Y" ]; then
        echo "Base de datos: $db"
    fi
    echo "Volumen de datos: $volumen_datos"
    echo ""
    echo "Comandos de conexión:"
    echo "mysql -h localhost -P $puerto -u root -p"
    if [ "$crear_usuario" = "Y" ]; then
        echo "mysql -h localhost -P $puerto -u $usuario_custom -p"
    fi
    echo ""
    echo "Desde Docker:"
    echo "$DOCKER_CMD exec -it $nombre mysql -u root -p"
    if [ "$crear_usuario" = "Y" ]; then
        echo "$DOCKER_CMD exec -it $nombre mysql -u $usuario_custom -p"
    fi
    echo ""
    echo "GESTIÓN DE DATOS:"
    echo "- Para hacer backup: $DOCKER_CMD exec $nombre mysqldump -u root -p --all-databases > backup_mariadb.sql"
    echo "- Para ver volúmenes: $DOCKER_CMD volume ls"
    echo "- Para eliminar volumen: $DOCKER_CMD volume rm $volumen_datos"
    echo "- Ver logs: $DOCKER_CMD logs $nombre"
    echo "- Parar contenedor: $DOCKER_CMD stop $nombre"
    echo "- Iniciar contenedor: $DOCKER_CMD start $nombre"
    echo ""
    echo "CARACTERÍSTICAS DE MARIADB:"
    echo "- Compatible con MySQL"
    echo "- Motor de almacenamiento: InnoDB (por defecto)"
    echo "- Soporte nativo para JSON (desde 10.2+)"
    echo "- Columnas virtuales y computadas"
    echo "========================="
    
else
    error_exit "No se pudo crear el contenedor de MariaDB"
fi
