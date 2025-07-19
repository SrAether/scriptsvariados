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
                if [ -n "$volume_name" ] && validar_yn "¿Desea también eliminar el volumen de datos ($volume_name)?"; then
                    $DOCKER_CMD volume rm "$volume_name" 2>/dev/null || true
                    log "Volumen eliminado"
                fi
            fi
        fi
    fi
}

# Configurar trap para limpieza en caso de error
trap 'cleanup' ERR

echo "Creado por Aether"
echo "Este script instalará PostgreSQL en un contenedor de Docker"

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

echo "Iniciando la instalación de PostgreSQL en Docker"

# Preguntar por la versión de PostgreSQL
version="latest"
if validar_yn "¿Desea instalar una versión específica de PostgreSQL?"; then
    echo "Ingrese la versión de PostgreSQL que desea instalar (por ejemplo, 15, 14, 13):"
    read version
fi

# Descargar la imagen de PostgreSQL
if ! $DOCKER_CMD pull postgres:$version; then
    error_exit "No se pudo descargar la imagen de PostgreSQL. Verifique la conexión a Internet y la versión especificada."
fi
log "La imagen de PostgreSQL se ha descargado correctamente"

# Obtener datos para crear el contenedor
while true; do
    echo "Ingrese el nombre del contenedor (por defecto: contenedor-postgres):"
    read nombre
    nombre=${nombre:-contenedor-postgres}
    
    # Verificar si el contenedor ya existe
    if $DOCKER_CMD ps -a --format "table {{.Names}}" | grep -q "^$nombre$" 2>/dev/null; then
        echo "Ya existe un contenedor con el nombre '$nombre'"
        if validar_yn "¿Desea eliminarlo y crear uno nuevo?"; then
            # Verificar si existe un volumen asociado
            volumen_existente="${nombre}_postgres_data"
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

# Configuración de base de datos
echo "Ingrese el nombre de la base de datos (por defecto: postgres):"
read db
db=${db:-postgres}

echo "Ingrese el nombre de usuario (por defecto: postgres):"
read usuario
usuario=${usuario:-postgres}

# Validación de puerto mejorada
while true; do
    echo "Ingrese el puerto de PostgreSQL (por defecto: 5432):"
    read puerto
    puerto=${puerto:-5432}
    
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
    read -s -p "Ingrese la contraseña de PostgreSQL (mínimo 8 caracteres): " contrasena
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

# Configuración adicional de PostgreSQL
configuracion_adicional=""
if validar_yn "¿Desea configurar parámetros adicionales de PostgreSQL?"; then
    echo "Configuraciones disponibles:"
    echo "1. Configuración de memoria (shared_buffers, work_mem)"
    echo "2. Configuración de conexiones (max_connections)"
    echo "3. Configuración de logging"
    
    if validar_yn "¿Desea configurar la memoria compartida? (recomendado: 25% de RAM)"; then
        echo "Ingrese el tamaño de shared_buffers (ej: 256MB, 1GB):"
        read shared_buffers
        configuracion_adicional="$configuracion_adicional -c shared_buffers=$shared_buffers"
    fi
    
    if validar_yn "¿Desea configurar el número máximo de conexiones?"; then
        echo "Ingrese el número máximo de conexiones (por defecto: 100):"
        read max_connections
        max_connections=${max_connections:-100}
        configuracion_adicional="$configuracion_adicional -c max_connections=$max_connections"
    fi
    
    if validar_yn "¿Desea habilitar logging detallado?"; then
        configuracion_adicional="$configuracion_adicional -c log_statement=all -c log_min_duration_statement=0"
    fi
fi

# Configuración de archivos de inicialización
scripts_init=""
if validar_yn "¿Le gustaría importar scripts SQL de inicialización?"; then
    echo "Ingrese la ruta del directorio que contiene los scripts SQL:"
    echo "(Los archivos .sql se ejecutarán en orden alfabético)"
    read ruta_scripts
    if [ ! -d "$ruta_scripts" ]; then
        error_exit "El directorio especificado no existe."
    fi
    scripts_init="-v $ruta_scripts:/docker-entrypoint-initdb.d"
fi

# Crear volumen nombrado para persistencia
volume_name="${nombre}_postgres_data"
if ! $DOCKER_CMD volume ls | grep -q "$volume_name" 2>/dev/null; then
    log "Creando volumen para datos: $volume_name"
    $DOCKER_CMD volume create "$volume_name"
fi

# Construir la sentencia Docker
sentencia="$DOCKER_CMD run -d \
    --name $nombre \
    -p $puerto:5432 \
    -e POSTGRES_DB=$db \
    -e POSTGRES_USER=$usuario \
    -e POSTGRES_PASSWORD=$contrasena \
    -v $volume_name:/var/lib/postgresql/data \
    $scripts_init \
    postgres:$version"

# Agregar configuración adicional si existe
if [ -n "$configuracion_adicional" ]; then
    sentencia="$sentencia $configuracion_adicional"
fi

# Crear el contenedor
log "Creando contenedor PostgreSQL..."
if eval "$sentencia"; then
    log "Contenedor creado exitosamente"
    
    # Esperar a que PostgreSQL esté listo
    log "Esperando a que PostgreSQL esté listo..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if $DOCKER_CMD exec "$nombre" pg_isready -h localhost -U "$usuario" -d "$db" 2>/dev/null; then
            log "PostgreSQL está listo y funcionando"
            break
        fi
        sleep 2
        timeout=$((timeout - 2))
    done
    
    if [ $timeout -le 0 ]; then
        error_exit "PostgreSQL no respondió en el tiempo esperado"
    fi
    
    # Verificar la conexión y mostrar información
    log "Verificando la conexión a la base de datos..."
    if $DOCKER_CMD exec "$nombre" psql -h localhost -U "$usuario" -d "$db" -c "SELECT version();" &>/dev/null; then
        log "Conexión a PostgreSQL verificada exitosamente"
    else
        log "ADVERTENCIA: No se pudo verificar la conexión"
    fi
    
    # Mostrar información de conexión
    echo "=============================="
    echo "INFORMACIÓN DE CONEXIÓN"
    echo "=============================="
    echo "Host: localhost"
    echo "Puerto: $puerto"
    echo "Base de datos: $db"
    echo "Usuario: $usuario"
    echo "Contraseña: [la que configuraste]"
    echo "Volumen de datos: $volume_name"
    echo ""
    echo "Comandos de conexión:"
    echo "psql -h localhost -p $puerto -U $usuario -d $db"
    echo "o desde Docker:"
    echo "$DOCKER_CMD exec -it $nombre psql -U $usuario -d $db"
    echo ""
    echo "URL de conexión:"
    echo "postgresql://$usuario:[password]@localhost:$puerto/$db"
    echo ""
    echo "GESTIÓN DE DATOS:"
    echo "- Para hacer backup: $DOCKER_CMD exec $nombre pg_dump -U $usuario -d $db > backup.sql"
    echo "- Para ver volúmenes: $DOCKER_CMD volume ls"
    echo "- Para eliminar volumen: $DOCKER_CMD volume rm $volume_name"
    echo "=============================="
    
    # Información adicional útil
    echo ""
    log "Comandos útiles:"
    echo "- Ver logs: $DOCKER_CMD logs $nombre"
    echo "- Entrar al contenedor: $DOCKER_CMD exec -it $nombre bash"
    echo "- Conectar a psql: $DOCKER_CMD exec -it $nombre psql -U $usuario -d $db"
    echo "- Parar contenedor: $DOCKER_CMD stop $nombre"
    echo "- Iniciar contenedor: $DOCKER_CMD start $nombre"
    
else
    error_exit "No se pudo crear el contenedor de PostgreSQL"
fi
