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
echo "Este script instalará MongoDB en un contenedor de Docker"

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

echo "Iniciando la instalación de MongoDB en Docker"

# Preguntar por la versión de MongoDB
version="latest"
if validar_yn "¿Desea instalar una versión específica de MongoDB?"; then
    echo "Versiones disponibles más comunes:"
    echo "- 7.0 (latest)"
    echo "- 6.0 (LTS)"
    echo "- 5.0 (LTS)"
    echo "- 4.4"
    echo "Ingrese la versión de MongoDB que desea instalar:"
    read version
fi

# Descargar la imagen de MongoDB
if ! $DOCKER_CMD pull mongo:$version; then
    error_exit "No se pudo descargar la imagen de MongoDB. Verifique la conexión a Internet y la versión especificada."
fi
log "La imagen de MongoDB se ha descargada correctamente"

# Obtener datos para crear el contenedor
while true; do
    echo "Ingrese el nombre del contenedor (por defecto: contenedor-mongodb):"
    read nombre
    nombre=${nombre:-contenedor-mongodb}
    
    # Verificar si el contenedor ya existe
    if $DOCKER_CMD ps -a --format "table {{.Names}}" | grep -q "^$nombre$" 2>/dev/null; then
        echo "Ya existe un contenedor con el nombre '$nombre'"
        if validar_yn "¿Desea eliminarlo y crear uno nuevo?"; then
            # Verificar si existe un volumen asociado
            volumen_existente="${nombre}_mongodb_data"
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

# Configuración de base de datos inicial
echo "Configuración de base de datos:"
echo "Ingrese el nombre de la base de datos inicial (por defecto: mongodb):"
read db_inicial
db_inicial=${db_inicial:-mongodb}

# Configuración de autenticación
autenticacion="N"
if validar_yn "¿Desea habilitar autenticación en MongoDB?"; then
    autenticacion="Y"
    echo "Configurando autenticación..."
    
    echo "Ingrese el nombre del usuario administrador (por defecto: admin):"
    read usuario_admin
    usuario_admin=${usuario_admin:-admin}
    
    while true; do
        read -s -p "Ingrese la contraseña del administrador (mínimo 8 caracteres): " pass_admin
        echo
        if [ ${#pass_admin} -ge 8 ]; then
            read -s -p "Confirme la contraseña: " pass_admin_confirm
            echo
            if [ "$pass_admin" = "$pass_admin_confirm" ]; then
                break
            else
                echo "Las contraseñas no coinciden"
            fi
        else
            echo "La contraseña debe tener al menos 8 caracteres"
        fi
    done
    
    # Preguntar por usuario adicional
    if validar_yn "¿Desea crear un usuario adicional para la aplicación?"; then
        echo "Ingrese el nombre del usuario de aplicación:"
        read usuario_app
        
        while true; do
            read -s -p "Ingrese la contraseña del usuario de aplicación (mínimo 8 caracteres): " pass_app
            echo
            if [ ${#pass_app} -ge 8 ]; then
                read -s -p "Confirme la contraseña: " pass_app_confirm
                echo
                if [ "$pass_app" = "$pass_app_confirm" ]; then
                    break
                else
                    echo "Las contraseñas no coinciden"
                fi
            else
                echo "La contraseña debe tener al menos 8 caracteres"
            fi
        done
        crear_usuario_app="Y"
    else
        crear_usuario_app="N"
    fi
fi

# Validación de puerto mejorada
while true; do
    echo "Ingrese el puerto de MongoDB (por defecto: 27017):"
    read puerto
    puerto=${puerto:-27017}
    
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

# Configuraciones adicionales de MongoDB
configuracion_adicional=""
if validar_yn "¿Desea configurar parámetros adicionales de MongoDB?"; then
    echo "Configuraciones disponibles:"
    echo "1. WiredTiger Cache Size"
    echo "2. Max Connections"
    echo "3. Configuración de Replica Set"
    echo "4. Configuración de logging"
    
    if validar_yn "¿Desea configurar WiredTiger Cache Size?"; then
        echo "Ingrese el tamaño del cache WiredTiger en GB (recomendado: 50% de RAM):"
        read cache_size
        configuracion_adicional="$configuracion_adicional --wiredTigerCacheSizeGB $cache_size"
    fi
    
    if validar_yn "¿Desea configurar el número máximo de conexiones?"; then
        echo "Ingrese el número máximo de conexiones (por defecto: 65536):"
        read max_connections
        max_connections=${max_connections:-65536}
        configuracion_adicional="$configuracion_adicional --maxConns $max_connections"
    fi
    
    if validar_yn "¿Desea configurar este MongoDB como Replica Set?"; then
        echo "Ingrese el nombre del Replica Set:"
        read replica_set_name
        configuracion_adicional="$configuracion_adicional --replSet $replica_set_name"
        echo "NOTA: Será necesario inicializar el replica set después de la instalación"
        configurar_replica="Y"
    else
        configurar_replica="N"
    fi
    
    if validar_yn "¿Desea habilitar logging detallado?"; then
        configuracion_adicional="$configuracion_adicional --verbose"
    fi
fi

# Configuración de scripts de inicialización
scripts_init=""
if validar_yn "¿Le gustaría importar scripts de inicialización JavaScript?"; then
    echo "Ingrese la ruta del directorio que contiene los scripts .js:"
    echo "(Los archivos .js se ejecutarán en orden alfabético)"
    read ruta_scripts
    if [ ! -d "$ruta_scripts" ]; then
        error_exit "El directorio especificado no existe."
    fi
    scripts_init="-v $ruta_scripts:/docker-entrypoint-initdb.d"
fi

# Construir la sentencia Docker
# Crear un volumen único para cada contenedor
volumen_datos="${nombre}_mongodb_data"

# Variables de entorno base
env_vars=""

# Configurar autenticación si está habilitada
if [ "$autenticacion" = "Y" ]; then
    env_vars="$env_vars -e MONGO_INITDB_ROOT_USERNAME=$usuario_admin"
    env_vars="$env_vars -e MONGO_INITDB_ROOT_PASSWORD=$pass_admin"
    env_vars="$env_vars -e MONGO_INITDB_DATABASE=$db_inicial"
fi

# Construir comando Docker
if [ -n "$configuracion_adicional" ]; then
    comando_mongo="mongod $configuracion_adicional"
else
    comando_mongo="mongod"
fi

sentencia="$DOCKER_CMD run -d \
    --name $nombre \
    -p $puerto:27017 \
    $env_vars \
    -v $volumen_datos:/data/db \
    $scripts_init \
    mongo:$version $comando_mongo"

# Crear el contenedor
log "Creando contenedor MongoDB..."
if eval "$sentencia"; then
    log "Contenedor creado exitosamente"
    
    # Esperar a que MongoDB esté listo
    log "Esperando a que MongoDB esté listo..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if [ "$autenticacion" = "Y" ]; then
            # Con autenticación
            if $DOCKER_CMD exec "$nombre" mongosh --eval "db.adminCommand('ping')" --quiet &>/dev/null; then
                log "MongoDB está listo y funcionando"
                break
            fi
        else
            # Sin autenticación
            if $DOCKER_CMD exec "$nombre" mongosh --eval "db.adminCommand('ping')" --quiet &>/dev/null; then
                log "MongoDB está listo y funcionando"
                break
            fi
        fi
        sleep 2
        timeout=$((timeout - 2))
    done
    
    if [ $timeout -le 0 ]; then
        error_exit "MongoDB no respondió en el tiempo esperado"
    fi
    
    # Crear usuario de aplicación si se especificó
    if [ "$autenticacion" = "Y" ] && [ "$crear_usuario_app" = "Y" ]; then
        log "Creando usuario de aplicación..."
        create_user_script="db.getSiblingDB('$db_inicial').createUser({
            user: '$usuario_app',
            pwd: '$pass_app',
            roles: [
                { role: 'readWrite', db: '$db_inicial' }
            ]
        })"
        
        if $DOCKER_CMD exec "$nombre" mongosh -u "$usuario_admin" -p "$pass_admin" --authenticationDatabase admin --eval "$create_user_script" &>/dev/null; then
            log "Usuario de aplicación creado exitosamente"
        else
            log "ADVERTENCIA: No se pudo crear el usuario de aplicación"
        fi
    fi
    
    # Inicializar replica set si se configuró
    if [ "$configurar_replica" = "Y" ]; then
        log "Inicializando Replica Set..."
        init_replica_script="rs.initiate({
            _id: '$replica_set_name',
            members: [
                { _id: 0, host: 'localhost:27017' }
            ]
        })"
        
        sleep 5  # Esperar un poco más para replica set
        if $DOCKER_CMD exec "$nombre" mongosh --eval "$init_replica_script" &>/dev/null; then
            log "Replica Set inicializado exitosamente"
        else
            log "ADVERTENCIA: No se pudo inicializar el Replica Set automáticamente"
        fi
    fi
    
    # Verificar la versión instalada
    version_instalada=$($DOCKER_CMD exec "$nombre" mongosh --eval "db.version()" --quiet 2>/dev/null | tail -n 1)
    if [ -n "$version_instalada" ]; then
        log "MongoDB versión instalada: $version_instalada"
    fi
    
    # Mostrar información de conexión
    echo "============================"
    echo "INFORMACIÓN DE CONEXIÓN"
    echo "============================"
    echo "Host: localhost"
    echo "Puerto: $puerto"
    echo "Base de datos inicial: $db_inicial"
    
    if [ "$autenticacion" = "Y" ]; then
        echo "Autenticación: HABILITADA"
        echo "Usuario administrador: $usuario_admin"
        echo "Contraseña admin: [la que configuraste]"
        if [ "$crear_usuario_app" = "Y" ]; then
            echo "Usuario aplicación: $usuario_app"
            echo "Contraseña app: [la que configuraste]"
        fi
    else
        echo "Autenticación: DESHABILITADA"
    fi
    
    echo "Volumen de datos: $volumen_datos"
    
    if [ "$configurar_replica" = "Y" ]; then
        echo "Replica Set: $replica_set_name"
    fi
    
    echo ""
    echo "COMANDOS DE CONEXIÓN:"
    if [ "$autenticacion" = "Y" ]; then
        echo "Admin: mongosh mongodb://$usuario_admin:[password]@localhost:$puerto/$db_inicial?authSource=admin"
        if [ "$crear_usuario_app" = "Y" ]; then
            echo "App: mongosh mongodb://$usuario_app:[password]@localhost:$puerto/$db_inicial"
        fi
        echo ""
        echo "Desde Docker (admin):"
        echo "$DOCKER_CMD exec -it $nombre mongosh -u $usuario_admin -p --authenticationDatabase admin"
        if [ "$crear_usuario_app" = "Y" ]; then
            echo "Desde Docker (app):"
            echo "$DOCKER_CMD exec -it $nombre mongosh -u $usuario_app -p $db_inicial"
        fi
    else
        echo "mongosh mongodb://localhost:$puerto/$db_inicial"
        echo ""
        echo "Desde Docker:"
        echo "$DOCKER_CMD exec -it $nombre mongosh"
    fi
    
    echo ""
    echo "GESTIÓN DE DATOS:"
    echo "- Para hacer backup: $DOCKER_CMD exec $nombre mongodump --out /tmp/backup"
    echo "- Para restaurar: $DOCKER_CMD exec $nombre mongorestore /tmp/backup"
    echo "- Para ver volúmenes: $DOCKER_CMD volume ls"
    echo "- Para eliminar volumen: $DOCKER_CMD volume rm $volumen_datos"
    echo "- Ver logs: $DOCKER_CMD logs $nombre"
    echo "- Parar contenedor: $DOCKER_CMD stop $nombre"
    echo "- Iniciar contenedor: $DOCKER_CMD start $nombre"
    echo ""
    echo "CARACTERÍSTICAS DE MONGODB:"
    echo "- Base de datos NoSQL orientada a documentos"
    echo "- Formato BSON (Binary JSON)"
    echo "- Escalabilidad horizontal con sharding"
    echo "- Replica Sets para alta disponibilidad"
    echo "- Índices flexibles y consultas ad-hoc"
    echo "- Motor de almacenamiento: WiredTiger (por defecto)"
    
    if [ "$configurar_replica" = "Y" ]; then
        echo ""
        echo "COMANDOS ADICIONALES PARA REPLICA SET:"
        echo "- Ver estado: rs.status()"
        echo "- Ver configuración: rs.conf()"
        echo "- Agregar miembro: rs.add('host:port')"
    fi
    
    echo "============================"
    
else
    error_exit "No se pudo crear el contenedor de MongoDB"
fi
