#!/bin/bash

# Función para verificar si un paquete está instalado y, si no, instalarlo.
install_if_not_present() {
    package=$1
    installer_command=$2
    if ! command -v "$package" &> /dev/null; then
        echo "$package no está instalado. Instalando $package..."
        $installer_command
    else
        echo "$package ya está instalado."
    fi
}

# Función para verificar si Oh My Zsh está instalado y, si no, instalarlo.
install_oh_my_zsh() {
    if [ -d ~/.oh-my-zsh ]; then
        echo "Oh My Zsh ya está instalado."
    else
        echo "Instalando Oh My Zsh..."
        RUNZSH=NO sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
}

# Verificación del tipo de distribución Linux
if [ -f /etc/arch-release ]; then
    echo "Estás usando Arch Linux."
    # Instalar curl, zsh y git si no están presentes
    install_if_not_present "curl" "sudo pacman -S --noconfirm curl"
    install_if_not_present "zsh" "sudo pacman -S --noconfirm zsh"
    install_if_not_present "git" "sudo pacman -S --noconfirm git"

elif [ -f /etc/debian_version ]; then
    echo "Estás usando Debian o un derivado de Debian."
    # Instalar curl, zsh y git si no están presentes
    install_if_not_present "curl" "sudo apt-get install -y curl"
    install_if_not_present "zsh" "sudo apt-get install -y zsh"
    install_if_not_present "git" "sudo apt-get install -y git"

elif [ -f /etc/redhat-release ]; then
    echo "Estás usando RedHat o un derivado de RedHat."
    # Instalar curl, zsh y git si no están presentes
    install_if_not_present "curl" "sudo yum install -y curl"
    install_if_not_present "zsh" "sudo yum install -y zsh"
    install_if_not_present "git" "sudo yum install -y git"

else
    echo "No se pudo determinar el tipo de Linux."
    exit 1 # Salir con error
fi

# Instalar Oh My Zsh
install_oh_my_zsh

# Cambiar el shell por defecto a zsh
echo "Cambiando el shell por defecto a zsh..."
chsh -s $(which zsh)

# Instalar plugins de Oh My Zsh (zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions)
echo "Instalando plugins de Oh My Zsh..."
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

# Clonar zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

# Clonar zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# Clonar zsh-completions
git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"

# Editar el archivo .zshrc para activar los plugins
echo "Configurando los plugins en .zshrc..."
sed -i 's/^plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)/' ~/.zshrc

# Recargar la configuración de Zsh
echo "Recargando configuración de Zsh..."
source ~/.zshrc

# Mensaje de finalización
echo "Oh My Zsh y los plugins se han instalado correctamente."
