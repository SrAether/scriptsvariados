#!/usr/bin/env python3
"""
Script para convertir una imagen en favicon con múltiples tamaños.
Genera archivos .ico y .png en los tamaños estándar para favicons.
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
        'PIL': 'Pillow'  # nombre del módulo: nombre del paquete pip
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
        response = input("¿Deseas instalarlas ahora? (s/n): ").strip().lower()
        
        if response in ['s', 'si', 'sí', 'y', 'yes']:
            print("\n📦 Instalando dependencias...")
            for _, package_name in missing_deps:
                try:
                    print(f"   Instalando {package_name}...")
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
            print("\n❌ No se pueden ejecutar el script sin las dependencias.")
            print("   Instala manualmente con: pip install Pillow")
            sys.exit(1)


# Verificar dependencias antes de importarlas
check_and_install_dependencies()

# Ahora importar las dependencias
from PIL import Image


def create_favicon(input_path, output_dir=None, sizes=None):
    """
    Convierte una imagen en favicon con múltiples tamaños.
    
    Args:
        input_path (str): Ruta de la imagen de entrada
        output_dir (str): Directorio de salida (opcional, usa el directorio de entrada por defecto)
        sizes (list): Lista de tamaños a generar (opcional)
    
    Returns:
        dict: Diccionario con las rutas de los archivos generados
    """
    # Tamaños estándar para favicons
    if sizes is None:
        sizes = [16, 32, 48, 64, 128, 256]
    
    input_path = Path(input_path)
    
    # Verificar que el archivo existe
    if not input_path.exists():
        raise FileNotFoundError(f"El archivo {input_path} no existe")
    
    # Determinar directorio de salida
    if output_dir is None:
        output_dir = input_path.parent
    else:
        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)
    
    # Cargar imagen original
    try:
        img = Image.open(input_path)
    except Exception as e:
        raise ValueError(f"Error al abrir la imagen: {e}")
    
    # Convertir a RGBA si no lo está (necesario para transparencia)
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    generated_files = {}
    
    # Generar PNGs individuales para cada tamaño
    png_images = []
    for size in sizes:
        # Redimensionar imagen manteniendo calidad
        resized = img.resize((size, size), Image.Resampling.LANCZOS)
        
        # Guardar PNG
        png_path = output_dir / f"favicon-{size}x{size}.png"
        resized.save(png_path, format='PNG', optimize=True)
        generated_files[f'png_{size}'] = str(png_path)
        png_images.append(resized)
        
        print(f"✓ Generado: {png_path.name}")
    
    # Generar archivo .ico con múltiples tamaños
    # El formato ICO puede contener múltiples resoluciones
    ico_path = output_dir / "favicon.ico"
    ico_sizes = [(size, size) for size in sizes if size <= 256]  # ICO soporta hasta 256x256
    
    # Crear las imágenes para el ICO
    ico_images = []
    for size in [s[0] for s in ico_sizes]:
        resized = img.resize((size, size), Image.Resampling.LANCZOS)
        ico_images.append(resized)
    
    # Guardar como ICO
    ico_images[0].save(
        ico_path,
        format='ICO',
        sizes=ico_sizes,
        append_images=ico_images[1:] if len(ico_images) > 1 else None
    )
    generated_files['ico'] = str(ico_path)
    print(f"✓ Generado: {ico_path.name} (con tamaños: {', '.join(f'{s}x{s}' for s in [sz[0] for sz in ico_sizes])})")
    
    # Generar favicon.png estándar (32x32 es el más común)
    standard_favicon = output_dir / "favicon.png"
    img.resize((32, 32), Image.Resampling.LANCZOS).save(
        standard_favicon, format='PNG', optimize=True
    )
    generated_files['standard'] = str(standard_favicon)
    print(f"✓ Generado: {standard_favicon.name} (32x32)")
    
    # Generar apple-touch-icon (180x180 para iOS)
    apple_icon = output_dir / "apple-touch-icon.png"
    img.resize((180, 180), Image.Resampling.LANCZOS).save(
        apple_icon, format='PNG', optimize=True
    )
    generated_files['apple'] = str(apple_icon)
    print(f"✓ Generado: {apple_icon.name} (180x180)")
    
    return generated_files


def main():
    """Función principal para ejecutar desde línea de comandos."""
    parser = argparse.ArgumentParser(
        description='Convierte una imagen en favicon con múltiples tamaños',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos de uso:
  %(prog)s logo.png
  %(prog)s logo.png -o ./favicons
  %(prog)s logo.png -s 16 32 64 128
  %(prog)s logo.png -o ./output -s 16 32 48
        """
    )
    
    parser.add_argument(
        'input',
        help='Ruta de la imagen de entrada (PNG, JPG, etc.)'
    )
    
    parser.add_argument(
        '-o', '--output',
        help='Directorio de salida (por defecto: mismo directorio que la imagen de entrada)',
        default=None
    )
    
    parser.add_argument(
        '-s', '--sizes',
        nargs='+',
        type=int,
        help='Tamaños a generar en píxeles (por defecto: 16 32 48 64 128 256)',
        default=None
    )
    
    args = parser.parse_args()
    
    try:
        print(f"\n🎨 Procesando imagen: {args.input}")
        print("=" * 60)
        
        generated = create_favicon(
            args.input,
            output_dir=args.output,
            sizes=args.sizes
        )
        
        print("=" * 60)
        print(f"✅ ¡Completado! Se generaron {len(generated)} archivos.")
        print(f"\n📁 Archivos generados en: {Path(args.output or Path(args.input).parent).absolute()}")
        
        print("\n💡 Uso en HTML:")
        print('  <link rel="icon" type="image/x-icon" href="/favicon.ico">')
        print('  <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png">')
        print('  <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png">')
        
    except Exception as e:
        print(f"\n❌ Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
