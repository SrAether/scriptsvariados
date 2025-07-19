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
    log "Realizando limpieza..."
    # Restaurar shell original si el cambio falló
    if [ -n "$original_shell" ] && [ "$shell_changed" = "true" ]; then
        if validar_yn "¿Desea restaurar el shell original ($original_shell)?"; then
            chsh -s "$original_shell"
            log "Shell restaurado a $original_shell"
        fi
    fi
}

# Configurar trap para limpieza en caso de error
trap 'cleanup' ERR

# Función mejorada para verificar si un paquete está instalado y, si no, instalarlo.
install_if_not_present() {
    local package=$1
    local installer_command=$2
    local package_display_name=${3:-$package}
    
    if ! command -v "$package" &> /dev/null; then
        log "$package_display_name no está instalado. Instalando..."
        if eval "$installer_command"; then
            log "$package_display_name instalado correctamente"
        else
            error_exit "No se pudo instalar $package_display_name"
        fi
    else
        log "$package_display_name ya está instalado"
    fi
}

# Función mejorada para verificar si Oh My Zsh está instalado y, si no, instalarlo.
install_oh_my_zsh() {
    if [ -d ~/.oh-my-zsh ]; then
        log "Oh My Zsh ya está instalado"
    else
        log "Instalando Oh My Zsh..."
        if RUNZSH=NO sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then
            log "Oh My Zsh instalado correctamente"
        else
            error_exit "No se pudo instalar Oh My Zsh"
        fi
    fi
}

echo "Creado por Aether"
echo "Este script automatizará la instalación de Zsh y Oh My Zsh"

# Verificar si el script se ejecuta como usuario con permisos
if [ "$EUID" -eq 0 ]; then
    error_exit "No ejecute este script como root. Use sudo cuando sea necesario."
fi

if ! validar_yn "¿Desea continuar con la instalación?"; then
    echo "Operación cancelada"
    exit 1
fi

# Guardar el shell actual para posible restauración
original_shell=$(getent passwd "$USER" | cut -d: -f7)
log "Shell actual: $original_shell"
shell_changed=false

# Preguntar por instalación de fastfetch
install_fastfetch=false
if validar_yn "¿Desea instalar fastfetch y agregarlo a .zshrc?"; then
    install_fastfetch=true
fi

# Detectar distribución de Linux con mejor precisión
log "Detectando distribución de Linux..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    distro_name="$NAME"
    log "Distribución detectada: $distro_name"
else
    error_exit "No se pudo detectar la distribución de Linux"
fi

# Verificación del tipo de distribución Linux y actualización de paquetes
if [ -f /etc/arch-release ] || [[ "$ID_LIKE" == *"arch"* ]] || [[ "$ID" == "arch" ]]; then
    log "Configurando para Arch Linux y derivados"
    
    # Actualizar lista de paquetes
    log "Actualizando lista de paquetes..."
    sudo pacman -Sy
    
    # Instalar dependencias básicas
    install_if_not_present "curl" "sudo pacman -S --noconfirm curl" "curl"
    install_if_not_present "zsh" "sudo pacman -S --noconfirm zsh" "Zsh"
    install_if_not_present "git" "sudo pacman -S --noconfirm git" "Git"
    
    # Instalar fastfetch si se selecciona
    if [ "$install_fastfetch" = true ]; then
        install_if_not_present "fastfetch" "sudo pacman -S --noconfirm fastfetch" "Fastfetch"
    fi

elif [ -f /etc/debian_version ] || [[ "$ID_LIKE" == *"debian"* ]] || [[ "$ID" == "debian" ]] || [[ "$ID" == "ubuntu" ]]; then
    log "Configurando para Debian/Ubuntu y derivados"
    
    # Actualizar lista de paquetes
    log "Actualizando lista de paquetes..."
    sudo apt-get update
    
    # Instalar dependencias básicas
    install_if_not_present "curl" "sudo apt-get install -y curl" "curl"
    install_if_not_present "zsh" "sudo apt-get install -y zsh" "Zsh"
    install_if_not_present "git" "sudo apt-get install -y git" "Git"
    
    # Instalar fastfetch si se selecciona
    if [ "$install_fastfetch" = true ]; then
        # Verificar si fastfetch está disponible en repositorios
        if apt-cache search fastfetch | grep -q fastfetch; then
            install_if_not_present "fastfetch" "sudo apt-get install -y fastfetch" "Fastfetch"
        else
            log "ADVERTENCIA: fastfetch no está disponible en los repositorios oficiales"
            if validar_yn "¿Desea instalarlo desde Snap?"; then
                sudo snap install fastfetch
            fi
        fi
    fi

elif [ -f /etc/redhat-release ] || [[ "$ID_LIKE" == *"rhel"* ]] || [[ "$ID_LIKE" == *"fedora"* ]]; then
    log "Configurando para RedHat/Fedora y derivados"
    
    # Determinar gestor de paquetes
    if command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
    else
        PKG_MANAGER="yum"
    fi
    
    log "Usando gestor de paquetes: $PKG_MANAGER"
    
    # Actualizar lista de paquetes
    log "Actualizando lista de paquetes..."
    sudo $PKG_MANAGER update -y
    
    # Instalar dependencias básicas
    install_if_not_present "curl" "sudo $PKG_MANAGER install -y curl" "curl"
    install_if_not_present "zsh" "sudo $PKG_MANAGER install -y zsh" "Zsh"
    install_if_not_present "git" "sudo $PKG_MANAGER install -y git" "Git"
    
    # Instalar fastfetch si se selecciona
    if [ "$install_fastfetch" = true ]; then
        install_if_not_present "fastfetch" "sudo $PKG_MANAGER install -y fastfetch" "Fastfetch"
    fi

else
    error_exit "Distribución de Linux no soportada: $distro_name"
fi

# Instalar Oh My Zsh
install_oh_my_zsh

# Verificar que se instaló correctamente
if [ ! -d ~/.oh-my-zsh ]; then
    error_exit "Oh My Zsh no se instaló correctamente"
fi

# Cambiar el shell por defecto a zsh
if validar_yn "¿Desea cambiar el shell por defecto a zsh?"; then
    log "Cambiando el shell por defecto a zsh..."
    if chsh -s "$(which zsh)"; then
        log "Shell cambiado exitosamente a zsh"
        shell_changed=true
    else
        error_exit "No se pudo cambiar el shell a zsh"
    fi
else
    log "Shell mantenido como: $original_shell"
fi

# Crear respaldo del .zshrc actual si existe
if [ -f ~/.zshrc ]; then
    backup_file="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    log "Creando respaldo de .zshrc en: $backup_file"
    cp ~/.zshrc "$backup_file"
fi

# Instalar plugins de Oh My Zsh
if validar_yn "¿Desea instalar plugins adicionales de Oh My Zsh?"; then
    log "Instalando plugins de Oh My Zsh..."
    ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
    
    plugins_to_install=()
    
    # Seleccionar plugins
    if validar_yn "¿Instalar zsh-autosuggestions (sugerencias automáticas)?"; then
        plugins_to_install+=("zsh-autosuggestions")
    fi
    
    if validar_yn "¿Instalar zsh-syntax-highlighting (resaltado de sintaxis)?"; then
        plugins_to_install+=("zsh-syntax-highlighting")
    fi
    
    if validar_yn "¿Instalar zsh-completions (autocompletado mejorado)?"; then
        plugins_to_install+=("zsh-completions")
    fi
    
    # Instalar plugins seleccionados
    for plugin in "${plugins_to_install[@]}"; do
        plugin_dir="$ZSH_CUSTOM/plugins/$plugin"
        if [ ! -d "$plugin_dir" ]; then
            log "Instalando plugin: $plugin"
            case $plugin in
                "zsh-autosuggestions")
                    git clone https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir"
                    ;;
                "zsh-syntax-highlighting")
                    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugin_dir"
                    ;;
                "zsh-completions")
                    git clone https://github.com/zsh-users/zsh-completions "$plugin_dir"
                    ;;
            esac
            
            if [ $? -eq 0 ]; then
                log "Plugin $plugin instalado correctamente"
            else
                log "ERROR: No se pudo instalar el plugin $plugin"
            fi
        else
            log "Plugin $plugin ya está instalado"
        fi
    done
    
    # Configurar plugins en .zshrc si se instalaron algunos
    if [ ${#plugins_to_install[@]} -gt 0 ]; then
        log "Configurando plugins en .zshrc..."
        plugins_string="git ${plugins_to_install[*]}"
        
        # Actualizar línea de plugins en .zshrc
        if grep -q "^plugins=" ~/.zshrc; then
            sed -i "s/^plugins=.*/plugins=($plugins_string)/" ~/.zshrc
        else
            echo "plugins=($plugins_string)" >> ~/.zshrc
        fi
        log "Plugins configurados: $plugins_string"
    fi
fi

# Configurar fastfetch si se instaló
if [ "$install_fastfetch" = true ] && command -v fastfetch &> /dev/null; then
    log "Configurando fastfetch en .zshrc..."
    
    # Verificar si fastfetch ya está en .zshrc
    if ! grep -q "fastfetch" ~/.zshrc; then
        echo "" >> ~/.zshrc
        echo "# Mostrar información del sistema al iniciar terminal" >> ~/.zshrc
        echo "if command -v fastfetch &> /dev/null; then" >> ~/.zshrc
        echo "    fastfetch" >> ~/.zshrc
        echo "fi" >> ~/.zshrc
        log "Fastfetch agregado a .zshrc"
    else
        log "Fastfetch ya está configurado en .zshrc"
    fi
fi

# Configurar tema personalizado si se desea
if validar_yn "¿Desea configurar un tema personalizado para Oh My Zsh?"; then
    echo "Temas populares disponibles:"
    echo "1. robbyrussell (por defecto)"
    echo "2. agnoster"
    echo "3. powerlevel10k"
    echo "4. spaceship"
    echo "5. otro (especificar)"
    
    read -p "Seleccione una opción (1-5): " tema_opcion
    
    case $tema_opcion in
        1) tema="robbyrussell" ;;
        2) tema="agnoster" ;;
        3) 
            tema="powerlevel10k/powerlevel10k"
            log "Instalando tema Powerlevel10k..."
            git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
            ;;
        4)
            tema="spaceship"
            log "Instalando tema Spaceship..."
            git clone https://github.com/spaceship-prompt/spaceship-prompt.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/spaceship-prompt --depth=1
            ln -s ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/spaceship-prompt/spaceship.zsh-theme ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/spaceship.zsh-theme
            ;;
        5)
            read -p "Ingrese el nombre del tema: " tema
            ;;
        *) tema="robbyrussell" ;;
    esac
    
    log "Configurando tema: $tema"
    sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"$tema\"/" ~/.zshrc
fi

# Verificar configuración final
log "Verificando configuración final..."
if [ -f ~/.zshrc ] && grep -q "ZSH=" ~/.zshrc; then
    log "Archivo .zshrc configurado correctamente"
else
    log "ADVERTENCIA: Puede haber problemas con la configuración de .zshrc"
fi

# Mostrar información final
echo "=============================="
echo "INSTALACIÓN COMPLETADA"
echo "=============================="
echo "✓ Zsh instalado"
echo "✓ Oh My Zsh instalado"

if [ "$shell_changed" = true ]; then
    echo "✓ Shell cambiado a zsh"
else
    echo "- Shell mantenido como: $original_shell"
fi

if [ "$install_fastfetch" = true ]; then
    echo "✓ Fastfetch instalado y configurado"
fi

if [ ${#plugins_to_install[@]} -gt 0 ] 2>/dev/null; then
    echo "✓ Plugins instalados: ${plugins_to_install[*]}"
fi

echo ""
echo "Para aplicar todos los cambios:"
echo "1. Cierre y reabra su terminal, o"
echo "2. Ejecute: source ~/.zshrc"
echo ""

if [ -f "$backup_file" ]; then
    echo "Respaldo de .zshrc anterior: $backup_file"
fi

echo "¡Disfrute de su nueva configuración de Zsh!"
echo "=============================="

log "Script completado exitosamente"


