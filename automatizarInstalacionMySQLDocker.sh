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
echo "Este script instalará MySQL en un contenedor de Docker"

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

echo "Iniciando la instalación de MySQL en Docker"

# Preguntar por la versión de MySQL
version="latest"
if validar_yn "¿Desea instalar una versión específica de MySQL?"; then
    echo "Ingrese la versión de MySQL que desea instalar (por ejemplo, 8.0):"
    read version
fi

# Descargar la imagen de MySQL
if ! $DOCKER_CMD pull mysql:$version; then
    error_exit "No se pudo descargar la imagen de MySQL. Verifique la conexión a Internet y la versión especificada."
fi
log "La imagen de MySQL se ha descargado correctamente"

# Obtener datos para crear el contenedor
while true; do
    echo "Ingrese el nombre del contenedor (por defecto: contenedor-mysql):"
    read nombre
    nombre=${nombre:-contenedor-mysql}
    
    # Verificar si el contenedor ya existe
    if $DOCKER_CMD ps -a --format "table {{.Names}}" | grep -q "^$nombre$" 2>/dev/null; then
        echo "Ya existe un contenedor con el nombre '$nombre'"
        if validar_yn "¿Desea eliminarlo y crear uno nuevo?"; then
            # Verificar si existe un volumen asociado
            volumen_existente="${nombre}_mysql_data"
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
    echo "Ingrese el nombre de la base de datos (por defecto: db):"
    read db
    db=${db:-db}
    importar="N"
fi

# Validación de puerto mejorada
while true; do
    echo "Ingrese el puerto de MySQL (por defecto: 3306):"
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

# Validación de contraseña mejorada
while true; do
    read -s -p "Ingrese la contraseña de MySQL (mínimo 8 caracteres): " contrasena
    echo
    if [ ${#contrasena} -ge 8 ]; then
        read -s -p "Confirme la contraseña: " contrasena_confirm
        echo
        if [ "$contrasena" = "$contrasena_confirm" ]; then
            break
        else
            echo "Las contraseñas no coinciden"
        fi
    else
        echo "La contraseña debe tener al menos 8 caracteres"
    fi
done

# Construir la sentencia Docker
# Crear un volumen único para cada contenedor
volumen_datos="${nombre}_mysql_data"

if [ "$importar" = "Y" ]; then
    sentencia="$DOCKER_CMD run -d \
        --name $nombre \
        -p $puerto:3306 \
        -e MYSQL_ROOT_PASSWORD=$contrasena \
        -v $volumen_datos:/var/lib/mysql \
        -v $ruta:/docker-entrypoint-initdb.d/import.sql \
        mysql:$version"
else
    sentencia="$DOCKER_CMD run -d \
        --name $nombre \
        -p $puerto:3306 \
        -e MYSQL_ROOT_PASSWORD=$contrasena \
        -e MYSQL_DATABASE=$db \
        -v $volumen_datos:/var/lib/mysql \
        mysql:$version"
fi

# Crear el contenedor
log "Creando contenedor MySQL..."
if eval "$sentencia"; then
    log "Contenedor creado exitosamente"
    
    # Esperar a que MySQL esté listo
    log "Esperando a que MySQL esté listo..."
    timeout=90
    while [ $timeout -gt 0 ]; do
        # Primero verificar si el proceso está escuchando en el puerto
        if $DOCKER_CMD exec "$nombre" ss -tlnp | grep -q ":3306 " 2>/dev/null; then
            # Luego intentar conectarse con mysql
            if $DOCKER_CMD exec "$nombre" mysql -u root -p"$contrasena_root" -e "SELECT 1;" >/dev/null 2>&1; then
                log "MySQL está listo y funcionando"
                break
            fi
        fi
        sleep 3
        timeout=$((timeout - 3))
    done
    
    if [ $timeout -le 0 ]; then
        error_exit "MySQL no respondió en el tiempo esperado"
    fi
    
    # Mostrar información de conexión
    echo "======================="
    echo "INFORMACIÓN DE CONEXIÓN"
    echo "======================="
    echo "Host: localhost"
    echo "Puerto: $puerto"
    echo "Usuario: root"
    echo "Contraseña: [la que configuraste]"
    if [ "$importar" != "Y" ]; then
        echo "Base de datos: $db"
    fi
    echo "Volumen de datos: $volumen_datos"
    echo "Comando de conexión: mysql -h localhost -P $puerto -u root -p"
    echo ""
    echo "GESTIÓN DE DATOS:"
    echo "- Para hacer backup: $DOCKER_CMD exec $nombre mysqldump -u root -p --all-databases > backup.sql"
    echo "- Para ver volúmenes: $DOCKER_CMD volume ls"
    echo "- Para eliminar volumen: $DOCKER_CMD volume rm $volumen_datos"
    echo "======================="
    
else
    error_exit "No se pudo crear el contenedor de MySQL"
fi