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
    - [🎨 Herramientas de Procesamiento de Imágenes](#-herramientas-de-procesamiento-de-imágenes)
  - [🚀 Instalación y Uso](#-instalación-y-uso)
  - [📖 Guías Detalladas](#-guías-detalladas)
  - [⚙️ Requisitos](#️-requisitos)
  - [🤝 Contribuciones](#-contribuciones)
  - [📄 Licencia](#-licencia)
  - [👨‍💻 Autor](#-autor)

## 📜 Descripción

Este repositorio contiene una colección de scripts bash y Python diseñados para automatizar tareas comunes en sistemas Linux. Desde la configuración de entornos de desarrollo hasta la conversión de documentos, estos scripts te ayudarán a ahorrar tiempo y simplificar tu flujo de trabajo.

**🎯 Objetivo:** Proporcionar herramientas de automatización confiables y fáciles de usar para desarrolladores y administradores de sistemas que trabajan en entornos Linux.

**🌟 Ventajas:**
- 🚀 **Automatización completa**: Scripts que manejan desde la detección del sistema hasta la configuración final
- 🛡️ **Seguridad**: Configuraciones optimizadas y seguras por defecto
- 🔧 **Flexibilidad**: Compatible con múltiples distribuciones Linux
- 📖 **Documentación**: Cada script está completamente documentado
- 🎯 **Plug & Play**: Listo para usar sin configuración manual

## 🛠️ Scripts Disponibles

### 🐳 Automatización de Instalaciones Docker

#### 🌐 Nginx en Docker (`automatizarInstalacionNginxDocker.sh`)

Script completo para automatizar la instalación y configuración de Nginx en contenedores Docker con soporte para múltiples tipos de proyectos.

**Características principales:**
- 🎯 **Múltiples tipos de proyecto**:
  - Sitios web estáticos (HTML/CSS/JS)
  - Single Page Applications (React, Vue, Angular)
  - Proxy reverso para aplicaciones backend
  - Sitios PHP (WordPress, Laravel, etc.)
  - Configuración personalizada
  
- 🔒 **Seguridad**:
  - Soporte SSL/HTTPS con múltiples opciones
  - Certificados autofirmados para desarrollo
  - Integración con Let's Encrypt
  - Headers de seguridad configurados
  - Rate limiting configurable
  
- ⚡ **Optimización**:
  - Compresión gzip automática
  - Caché de archivos estáticos configurable
  - Logs personalizados (estándar, JSON, detallado)
  - Worker processes automáticos
  
- 🔌 **Proxy Reverso**:
  - Configuración automática de headers
  - Soporte para WebSockets
  - Timeouts configurables
  - Load balancing ready

**Uso:**
```bash
./automatizarInstalacionNginxDocker.sh
```

**Ejemplo de configuración:**
```bash
# Sitio estático
Tipo: Sitio estático
Directorio: /home/usuario/mi-sitio
Puerto HTTP: 80
Gzip: Habilitado
Caché: 30 días

# Proxy reverso para Node.js
Tipo: Proxy reverso
Backend: http://localhost:3000
WebSocket: Habilitado
Rate limiting: 10 req/s
```

**Volúmenes creados:**
- `{nombre}_nginx_config`: Configuración de Nginx
- `{nombre}_nginx_logs`: Logs de acceso y errores
- `{nombre}_nginx_cache`: Caché de archivos (opcional)

**Características avanzadas:**
- Configuración automática según tipo de proyecto
- Generación dinámica de `nginx.conf` y `default.conf`
- Soporte para múltiples dominios (preparado)
- Integración con PHP-FPM (instrucciones incluidas)
- Documentación completa de comandos útiles

```

| Script | Descripción | Características |
|--------|-------------|-----------------|
| `automatizarInstalacionMySQLDocker.sh` | Instala y configura MySQL en un contenedor Docker | ✅ Detección automática del SO<br>✅ Instalación de Docker si es necesario<br>✅ Configuración segura de MySQL |
| `automatizarInstalacionMariaDBDocker.sh` | Instala y configura MariaDB en un contenedor Docker | ✅ Detección automática del SO<br>✅ Instalación de Docker si es necesario<br>✅ Configuración optimizada de MariaDB<br>✅ Usuarios personalizados<br>✅ Configuraciones avanzadas |
| `automatizarInstalacionMongoDBDocker.sh` | Instala y configura MongoDB en un contenedor Docker | ✅ Detección automática del SO<br>✅ Instalación de Docker si es necesario<br>✅ Configuración con/sin autenticación<br>✅ Replica Sets<br>✅ Usuarios y roles<br>✅ Scripts de inicialización |
| `automatizarInstalacionNginxDocker.sh` | Instala y configura Nginx como servidor web o proxy reverso | ✅ Detección automática del SO<br>✅ Instalación de Docker si es necesario<br>✅ 5 tipos de proyecto (estático, SPA, proxy, PHP, custom)<br>✅ SSL/HTTPS configuración<br>✅ Gzip y caché<br>✅ Rate limiting<br>✅ Logs personalizados<br>✅ WebSocket support |
| `automatizarInstalacionPostgreSQLDocker.sh` | Instala y configura PostgreSQL en un contenedor Docker | ✅ Detección automática del SO<br>✅ Instalación de Docker si es necesario<br>✅ Configuración optimizada de PostgreSQL |
| `automatizarInstalacionPHP.sh` | Configura un entorno de desarrollo PHP con Nginx en Docker | ✅ Stack completo PHP + Nginx<br>✅ Configuración automática<br>✅ Entorno listo para desarrollo |

### ⚡ Configuración de Terminal

| Script | Descripción | Características |
|--------|-------------|-----------------|
| `ohmyzshauto.sh` | Instala y configura Oh My Zsh con plugins esenciales y herramientas adicionales | ✅ Detección automática de distro (Arch, Debian, RedHat)<br>✅ Instalación automática de dependencias (curl, zsh, git)<br>✅ Plugins: autosuggestions, syntax-highlighting, completions<br>✅ Opción de instalar fastfetch<br>✅ Cambio automático de shell por defecto |

### 📄 Herramientas de Conversión

| Script | Descripción | Características |
|--------|-------------|-----------------|
| `pdf_a_word.py` | Convierte archivos PDF a documentos Word (.docx) | ✅ Instalación automática de dependencias<br>✅ Interfaz simple<br>✅ Preserva el formato |

### 🎨 Herramientas de Procesamiento de Imágenes

| Script | Descripción | Características |
|--------|-------------|-----------------|
| `favicon.py` | Convierte imágenes a favicons en múltiples tamaños y formatos | ✅ Instalación automática de dependencias (Pillow)<br>✅ Genera .ico y .png en múltiples tamaños (16x16 a 256x256)<br>✅ Apple Touch Icon (180x180)<br>✅ Redimensionamiento de alta calidad (LANCZOS)<br>✅ Soporte para transparencia |
| `remove_background.py` | Elimina el fondo de imágenes usando IA | ✅ Instalación automática de dependencias (rembg, Pillow)<br>✅ Modelo BiRefNet de alta calidad<br>✅ 4 modelos disponibles (general, portrait, isnet, u2net)<br>✅ Alpha matting para bordes suaves<br>✅ Salida PNG con transparencia<br>✅ Procesamiento con IA avanzada |

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

### 🐬 MariaDB en Docker

El script `automatizarInstalacionMariaDBDocker.sh` automatiza completamente la instalación de MariaDB:

```bash
./automatizarInstalacionMariaDBDocker.sh
```

**Qué hace el script:**
- ✅ Verifica si Docker está instalado
- ✅ Instala Docker si es necesario
- ✅ Descarga la imagen oficial de MariaDB
- ✅ Configura el contenedor con variables de entorno seguras
- ✅ Expone el puerto 3306 para conexiones
- ✅ Permite configuración de usuarios personalizados
- ✅ Configuraciones avanzadas de rendimiento (InnoDB, Query Cache)
- ✅ Soporte para charset UTF8MB4 por defecto

### 🍃 MongoDB en Docker

El script `automatizarInstalacionMongoDBDocker.sh` automatiza completamente la instalación de MongoDB:

```bash
./automatizarInstalacionMongoDBDocker.sh
```

**Qué hace el script:**
- ✅ Verifica si Docker está instalado
- ✅ Instala Docker si es necesario
- ✅ Descarga la imagen oficial de MongoDB
- ✅ Configura autenticación opcional con usuarios y roles
- ✅ Expone el puerto 27017 para conexiones
- ✅ Configuración de Replica Sets para alta disponibilidad
- ✅ Configuraciones de rendimiento (WiredTiger Cache, conexiones)
- ✅ Soporte para scripts de inicialización JavaScript
- ✅ Usuarios administrador y de aplicación separados

### 🌐 Nginx en Docker

El script `automatizarInstalacionNginxDocker.sh` automatiza completamente la instalación y configuración de Nginx:

```bash
./automatizarInstalacionNginxDocker.sh
```

**Qué hace el script:**
- ✅ Verifica si Docker está instalado e instala si es necesario
- ✅ Descarga la imagen oficial de Nginx (varias versiones disponibles)
- ✅ **Configuración inteligente según tipo de proyecto**:
  - Sitio web estático (HTML/CSS/JS)
  - Single Page Application (React, Vue, Angular)
  - Proxy reverso para aplicaciones backend
  - Sitios PHP (con instrucciones PHP-FPM)
  - Configuración personalizada
- ✅ **Seguridad y SSL/HTTPS**:
  - Certificados autofirmados para desarrollo
  - Soporte para certificados existentes
  - Integración con Let's Encrypt
  - Headers de seguridad automáticos
- ✅ **Optimización de rendimiento**:
  - Compresión gzip configurable
  - Caché de archivos estáticos
  - Rate limiting para protección DDoS
  - Worker processes automáticos
- ✅ **Características avanzadas**:
  - Soporte WebSocket para proxy reverso
  - Logs personalizados (estándar, JSON, detallado)
  - Volúmenes separados para config, logs y caché
  - Configuración dinámica de nginx.conf
- ✅ Validación automática de configuración
- ✅ Documentación completa de comandos útiles

**Tipos de configuración soportados:**

**1. Sitio Estático:** Perfecto para sitios HTML/CSS/JS simples con caché y compresión automática.

**2. SPA (Single Page Application):** Configurado con fallback a index.html para routing del lado del cliente.

**3. Proxy Reverso:** Ideal para aplicaciones Node.js, Python, Go, etc. Con soporte para:
   - Headers de proxy configurados
   - WebSocket support opcional
   - Timeouts personalizables

**4. Sitio PHP:** Preparado para PHP-FPM con instrucciones para conectar contenedor PHP.

**5. Personalizada:** Configuración base que puedes modificar según necesites.

### 🐘 PostgreSQL en Docker

El script `automatizarInstalacionPostgreSQLDocker.sh` automatiza completamente la instalación de PostgreSQL:

```bash
./automatizarInstalacionPostgreSQLDocker.sh
```

**Qué hace el script:**
- ✅ Verifica si Docker está instalado
- ✅ Instala Docker si es necesario
- ✅ Descarga la imagen oficial de PostgreSQL
- ✅ Configura el contenedor con variables de entorno seguras
- ✅ Expone el puerto 5432 para conexiones
- ✅ Optimiza la configuración para desarrollo

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

### - 📄 Conversión PDF a Word

## 💡 Casos de Uso Comunes

### 🏗️ Configuración de Entorno de Desarrollo
```bash
# 1. Configurar terminal mejorado
./ohmyzshauto.sh

# 2. Instalar base de datos
./automatizarInstalacionMySQLDocker.sh
# o
./automatizarInstalacionMariaDBDocker.sh
# o
./automatizarInstalacionMongoDBDocker.sh
# o
./automatizarInstalacionPostgreSQLDocker.sh

# 3. Configurar entorno web
./automatizarInstalacionPHP.sh
```

### 📋 Mejores Prácticas
- ✅ **Siempre revisa** el contenido de un script antes de ejecutarlo
- ✅ **Ejecuta en un entorno de prueba** primero si es crítico
- ✅ **Mantén respaldos** de configuraciones importantes
- ✅ **Verifica los logs** después de la ejecución
- ✅ **Actualiza regularmente** clonando la última versión

### 🔍 Troubleshooting
| Problema | Solución |
|----------|----------|
| "Permission denied" | `chmod +x script.sh` |
| "Docker not found" | El script lo instalará automáticamente |
| "Command not found" | Verificar dependencias en la tabla de requisitos |

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
- 🐧 **Linux**: Ubuntu 18.04+, Debian 10+, CentOS 7+, Fedora 30+, Arch Linux
- 🍎 **macOS**: 10.15+ (compatibilidad parcial)

### Dependencias Mínimas
| Dependencia | Uso | Auto-instalación |
|-------------|-----|------------------|
| `bash` 4.0+ | Scripts shell | ✅ Preinstalado |
| `python3` 3.6+ | Scripts Python | ✅ Si es necesario |
| `curl` | Descargas | ✅ Si es necesario |
| `git` | Clonación | ✅ Si es necesario |
| `docker` | Contenedores | ✅ Si es necesario |

### Permisos
- 🔐 **Sudo**: Requerido para instalación de software del sistema
- 👤 **Usuario regular**: Los scripts funcionan sin root para operaciones básicas

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
<sub>Última actualización: 3 de diciembre de 2025</sub>
</div>
