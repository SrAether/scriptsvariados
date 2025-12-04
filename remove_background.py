#!/usr/bin/env python3
"""
Script para quitar el fondo de imágenes.
Utiliza rembg para eliminar automáticamente el fondo y generar imágenes con transparencia.
"""

import argparse
import subprocess
import sys
from pathlib import Path


def check_and_install_dependencies():
    """
    Verifica si las dependencias están instaladas y ofrece instalarlas.
    """
    dependencies = {
        'rembg': 'rembg[gpu]',  # Versión con soporte GPU (fallback a CPU si no hay GPU)
        'PIL': 'Pillow'
    }
    
    missing_deps = []
    
    # Verificar cada dependencia
    for module_name, package_name in dependencies.items():
        try:
            __import__(module_name)
        except ImportError:
            missing_deps.append((module_name, package_name))
    
    # Si faltan dependencias, preguntar al usuario
    if missing_deps:
        print("⚠️  Dependencias faltantes detectadas:")
        for module_name, package_name in missing_deps:
            print(f"   - {package_name} (módulo: {module_name})")
        
        print("\nEste script requiere las dependencias anteriores para funcionar.")
        print("⚠️  Nota: La primera ejecución descargará modelos de IA (~176MB)")
        response = input("¿Deseas instalarlas ahora? (s/n): ").strip().lower()
        
        if response in ['s', 'si', 'sí', 'y', 'yes']:
            print("\n📦 Instalando dependencias...")
            for module_name, package_name in missing_deps:
                try:
                    print(f"   Instalando {package_name}...")
                    # Para rembg, instalar la versión básica si la GPU falla
                    if module_name == 'rembg':
                        try:
                            subprocess.check_call(
                                [sys.executable, "-m", "pip", "install", package_name],
                                stdout=subprocess.DEVNULL,
                                stderr=subprocess.PIPE
                            )
                        except subprocess.CalledProcessError:
                            print(f"   ⚠️  Instalación con GPU falló, instalando versión básica...")
                            package_name = 'rembg'
                            subprocess.check_call(
                                [sys.executable, "-m", "pip", "install", package_name],
                                stdout=subprocess.DEVNULL,
                                stderr=subprocess.PIPE
                            )
                    else:
                        subprocess.check_call(
                            [sys.executable, "-m", "pip", "install", package_name],
                            stdout=subprocess.DEVNULL,
                            stderr=subprocess.PIPE
                        )
                    print(f"   ✓ {package_name} instalado correctamente")
                except subprocess.CalledProcessError as e:
                    print(f"   ✗ Error al instalar {package_name}: {e}", file=sys.stderr)
                    sys.exit(1)
            
            print("\n✅ Todas las dependencias han sido instaladas.")
            print("   Ejecuta el script nuevamente para continuar.\n")
            sys.exit(0)
        else:
            print("\n❌ No se puede ejecutar el script sin las dependencias.")
            print("   Instala manualmente con: pip install rembg Pillow")
            sys.exit(1)


# Verificar dependencias antes de importarlas
check_and_install_dependencies()

# Ahora importar las dependencias
from rembg import remove, new_session
from PIL import Image
import io


def remove_background(input_path, output_path=None, model='birefnet-general', alpha_matting=False):
    """
    Elimina el fondo de una imagen.
    
    Args:
        input_path (str): Ruta de la imagen de entrada
        output_path (str): Ruta de la imagen de salida (opcional)
        model (str): Modelo a usar ('birefnet-general', 'birefnet-portrait', 'isnet-general-use', 'u2net')
        alpha_matting (bool): Usar alpha matting para bordes más suaves
    
    Returns:
        str: Ruta del archivo generado
    """
    input_path = Path(input_path)
    
    # Verificar que el archivo existe
    if not input_path.exists():
        raise FileNotFoundError(f"El archivo {input_path} no existe")
    
    # Determinar ruta de salida
    if output_path is None:
        output_path = input_path.parent / f"{input_path.stem}_no_bg.png"
    else:
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Cargar imagen
    try:
        with open(input_path, 'rb') as f:
            input_data = f.read()
    except Exception as e:
        raise ValueError(f"Error al leer la imagen: {e}")
    
    print(f"🔄 Procesando imagen con modelo '{model}'...")
    if alpha_matting:
        print("   (usando alpha matting para bordes suaves)")
    
    # Eliminar fondo usando el modelo especificado
    try:
        # Crear sesión con el modelo específico
        session = new_session(model)
        
        # Usar la API con sesión personalizada
        if alpha_matting:
            output_data = remove(
                input_data,
                session=session,
                alpha_matting=True,
                alpha_matting_foreground_threshold=240,
                alpha_matting_background_threshold=10,
                alpha_matting_erode_size=10
            )
        else:
            output_data = remove(input_data, session=session)
    except Exception as e:
        raise ValueError(f"Error al procesar la imagen: {e}")
    
    # Guardar resultado
    try:
        output_image = Image.open(io.BytesIO(output_data))
        output_image.save(output_path, format='PNG', optimize=True)
    except Exception as e:
        raise ValueError(f"Error al guardar la imagen: {e}")
    
    return str(output_path)


def main():
    """Función principal para ejecutar desde línea de comandos."""
    parser = argparse.ArgumentParser(
        description='Elimina el fondo de imágenes usando IA',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Modelos disponibles:
  birefnet-general      - Modelo BiRefNet de alta calidad (por defecto, RECOMENDADO)
  birefnet-portrait     - BiRefNet optimizado para retratos/personas
  isnet-general-use     - Modelo IS-Net mejorado
  u2net                 - Modelo U2Net clásico (más rápido, menor calidad)

Ejemplos de uso:
  %(prog)s foto.jpg
  %(prog)s foto.jpg -o resultado.png
  %(prog)s foto.jpg -m birefnet-portrait  # mejor para personas
  %(prog)s foto.jpg -a  # con alpha matting para bordes suaves
  %(prog)s foto.jpg -m isnet-general-use -o output/sin_fondo.png
        """
    )
    
    parser.add_argument(
        'input',
        help='Ruta de la imagen de entrada'
    )
    
    parser.add_argument(
        '-o', '--output',
        help='Ruta de la imagen de salida (por defecto: [nombre]_no_bg.png)',
        default=None
    )
    
    parser.add_argument(
        '-m', '--model',
        help='Modelo a usar (por defecto: birefnet-general)',
        choices=['birefnet-general', 'birefnet-portrait', 'isnet-general-use', 'u2net'],
        default='birefnet-general'
    )
    
    parser.add_argument(
        '-a', '--alpha-matting',
        help='Usar alpha matting para bordes más suaves (más lento)',
        action='store_true'
    )
    
    args = parser.parse_args()
    
    try:
        print(f"\n🎨 Eliminando fondo de: {args.input}")
        print("=" * 60)
        
        # Primera ejecución puede tardar en descargar el modelo
        print("⚠️  Nota: La primera ejecución descargará el modelo de IA (~176MB)")
        print("   Esto puede tardar unos minutos dependiendo de tu conexión.\n")
        
        output_file = remove_background(
            args.input,
            output_path=args.output,
            model=args.model,
            alpha_matting=args.alpha_matting
        )
        
        print("=" * 60)
        print(f"✅ ¡Completado!")
        print(f"\n📁 Archivo generado: {Path(output_file).absolute()}")
        
        # Mostrar información del archivo
        file_size = Path(output_file).stat().st_size / 1024  # KB
        print(f"   Tamaño: {file_size:.1f} KB")
        
        img = Image.open(output_file)
        print(f"   Dimensiones: {img.width}x{img.height} píxeles")
        print(f"   Formato: PNG con transparencia")
        
    except Exception as e:
        print(f"\n❌ Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
