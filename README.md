<div align="center">

# 🚀 Scripts Variados

<p>
  <strong>Colección de scripts útiles para automatizar tareas cotidianas en Linux</strong>
</p>

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/SrAether/scriptsvariados/blob/main/LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/SrAether/scriptsvariados)](https://github.com/SrAether/scriptsvariados/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/SrAether/scriptsvariados)](https://github.com/SrAether/scriptsvariados/network)
[![GitHub issues](https://img.shields.io/github/issues/SrAether/scriptsvariados)](https://github.com/SrAether/scriptsvariados/issues)

</div>

---

## 📋 Tabla de Contenidos

- [🚀 Scripts Variados](#-scripts-variados)
  - [📋 Tabla de Contenidos](#-tabla-de-contenidos)
  - [📜 Descripción](#-descripción)
  - [🛠️ Scripts Disponibles](#️-scripts-disponibles)
    - [🐳 Automatización de Instalaciones Docker](#-automatización-de-instalaciones-docker)
    - [⚡ Configuración de Terminal](#-configuración-de-terminal)
    - [📄 Herramientas de Conversión](#-herramientas-de-conversión)
  - [🚀 Instalación y Uso](#-instalación-y-uso)
  - [📖 Guías Detalladas](#-guías-detalladas)
  - [⚙️ Requisitos](#️-requisitos)
  - [🤝 Contribuciones](#-contribuciones)
  - [📄 Licencia](#-licencia)
  - [👨‍💻 Autor](#-autor)

## 📜 Descripción

Este repositorio contiene una colección de scripts bash y Python diseñados para automatizar tareas comunes en sistemas Linux. Desde la configuración de entornos de desarrollo hasta la conversión de documentos, estos scripts te ayudarán a ahorrar tiempo y simplificar tu flujo de trabajo.

## 🛠️ Scripts Disponibles

### 🐳 Automatización de Instalaciones Docker

| Script | Descripción | Características |
|--------|-------------|-----------------|
| `automatizarInstalacionMySQLDocker.sh` | Instala y configura MySQL en un contenedor Docker | ✅ Detección automática del SO<br>✅ Instalación de Docker si es necesario<br>✅ Configuración segura de MySQL |
| `automatizarInstalacionPHP.sh` | Configura un entorno de desarrollo PHP con Nginx en Docker | ✅ Stack completo PHP + Nginx<br>✅ Configuración automática<br>✅ Entorno listo para desarrollo |

### ⚡ Configuración de Terminal

| Script | Descripción | Características |
|--------|-------------|-----------------|
| `ohmyzshauto.sh` | Instala y configura Oh My Zsh con plugins esenciales y herramientas adicionales | ✅ Detección automática de distro (Arch, Debian, RedHat)<br>✅ Instalación automática de dependencias (curl, zsh, git)<br>✅ Plugins: autosuggestions, syntax-highlighting, completions<br>✅ Opción de instalar fastfetch<br>✅ Cambio automático de shell por defecto |

### 📄 Herramientas de Conversión

| Script | Descripción | Características |
|--------|-------------|-----------------|
| `pdf_a_word.py` | Convierte archivos PDF a documentos Word (.docx) | ✅ Instalación automática de dependencias<br>✅ Interfaz simple<br>✅ Preserva el formato |

## 🚀 Instalación y Uso

### � Clonación del Repositorio

```bash
git clone https://github.com/SrAether/scriptsvariados.git
cd scriptsvariados
```

### 🐚 Para Scripts Bash (.sh)

1. **Dar permisos de ejecución:**
   ```bash
   chmod +x nombre_del_script.sh
   ```

2. **Ejecutar el script:**
   ```bash
   ./nombre_del_script.sh
   ```

### 🐍 Para Scripts Python (.py)

1. **Ejecutar directamente:**
   ```bash
   python3 nombre_del_script.py
   ```

## 📖 Guías Detalladas

### 🐳 MySQL en Docker

El script `automatizarInstalacionMySQLDocker.sh` automatiza completamente la instalación de MySQL:

```bash
./automatizarInstalacionMySQLDocker.sh
```

**Qué hace el script:**
- ✅ Verifica si Docker está instalado
- ✅ Instala Docker si es necesario
- ✅ Descarga la imagen oficial de MySQL
- ✅ Configura el contenedor con variables de entorno seguras
- ✅ Expone el puerto 3306 para conexiones

### ⚡ Configuración de Oh My Zsh

El script `ohmyzshauto.sh` configura tu terminal con las mejores herramientas:

```bash
./ohmyzshauto.sh
```

**Qué hace el script:**
- ✅ **Detección automática** de distribución Linux (Arch, Debian/Ubuntu, RedHat/CentOS/Fedora)
- ✅ **Instalación inteligente** de dependencias (curl, zsh, git) si no están presentes
- ✅ **Instalación de Oh My Zsh** con configuración automática
- ✅ **Cambio de shell por defecto** a Zsh automáticamente
- ✅ **Opción de fastfetch** para mostrar información del sistema al abrir terminal
- ✅ **Configuración automática** del archivo .zshrc con los plugins activados

**Plugins incluidos:**
- 🔍 **zsh-autosuggestions**: Sugerencias automáticas basadas en el historial
- 🌈 **zsh-syntax-highlighting**: Resaltado de sintaxis en tiempo real
- 📝 **zsh-completions**: Autocompletado mejorado

**Distribuciones soportadas:**
- 🏹 **Arch Linux** (pacman)
- 🐧 **Debian/Ubuntu** (apt)
- 🎩 **RedHat/CentOS/Fedora** (yum)

### 🐘 Entorno PHP con Nginx

El script `automatizarInstalacionPHP.sh` crea un stack completo de desarrollo:

```bash
./automatizarInstalacionPHP.sh
```

**Stack incluido:**
- 🐘 PHP (última versión estable)
- 🌐 Nginx como servidor web
- 🐳 Todo containerizado con Docker

### 📄 Conversión PDF a Word

El script `pdf_a_word.py` convierte tus documentos de manera sencilla:

```bash
python3 pdf_a_word.py
```

**Características:**
- 📦 Instala automáticamente las dependencias necesarias
- 🎯 Preserva el formato original tanto como sea posible
- 💻 Interfaz de línea de comandos intuitiva

## ⚙️ Requisitos

### Sistema Operativo
- 🐧 Linux (Ubuntu, Debian, CentOS, Fedora, Arch Linux)
- 🍎 macOS (parcialmente compatible)

### Dependencias Generales
- `bash` (para scripts .sh)
- `python3` (para scripts .py)
- `curl` y `wget` (instalados automáticamente)
- `git` (para clonación)

### Dependencias Específicas
Los scripts instalan automáticamente sus dependencias específicas cuando es necesario.

## 🤝 Contribuciones

¡Las contribuciones son más que bienvenidas! Si tienes ideas para mejorar los scripts existentes o quieres agregar nuevos scripts útiles, aquí te explico cómo hacerlo:

### 🛠️ Cómo Contribuir

1. **Fork el repositorio**
2. **Crea una nueva rama** para tu característica:
   ```bash
   git checkout -b feature/nueva-caracteristica
   ```
3. **Realiza tus cambios** y haz commit:
   ```bash
   git commit -m "Agrega nueva característica: descripción"
   ```
4. **Push a tu rama**:
   ```bash
   git push origin feature/nueva-caracteristica
   ```
5. **Abre un Pull Request**

### 📝 Estándares de Contribución

- ✅ Documenta tu código claramente
- ✅ Incluye comentarios explicativos
- ✅ Prueba tu script en diferentes distribuciones si es posible
- ✅ Sigue las convenciones de nomenclatura existentes
- ✅ Agrega tu script a la documentación del README

### 💡 Ideas para Nuevos Scripts

- 🔧 Automatización de configuraciones de desarrollo
- 📦 Instaladores de software específico
- 🔄 Scripts de backup y sincronización
- 🎨 Personalizaciones de entorno
- 🔍 Herramientas de monitoreo del sistema

## 📄 Licencia

Este proyecto está bajo la **Licencia MIT**. Esto significa que puedes:

- ✅ Usar comercialmente
- ✅ Modificar
- ✅ Distribuir
- ✅ Usar privadamente

Ver el archivo [LICENSE](LICENSE) para más detalles.

## 👨‍💻 Autor

**Aether** - *Creador y Mantenedor*

- 🐙 GitHub: [@SrAether](https://github.com/SrAether)
- 📧 Email: [Contacto disponible en el perfil de GitHub]

---

<div align="center">

### 🌟 ¿Te resultó útil este proyecto?

Si estos scripts te ahorraron tiempo o te fueron útiles, ¡considera darle una ⭐ al repositorio!

**¡Comparte con otros desarrolladores que puedan beneficiarse!**

</div>

---

<div align="center">
<sub>Última actualización: Julio 2025</sub>
</div>
