#!/usr/bin/env python3
"""
Script para convertir archivos PDF a documentos Word (.docx).
Utiliza pdf2docx para realizar la conversión preservando el formato.
"""

import argparse
import subprocess
import sys
import os
from pathlib import Path


def check_and_install_dependencies():
    """
    Verifica si las dependencias están instaladas y ofrece instalarlas.
    """
    dependencies = {
        'pdf2docx': 'pdf2docx'
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
            print("\n❌ No se puede ejecutar el script sin las dependencias.")
            print("   Instala manualmente con: pip install pdf2docx")
            sys.exit(1)


# Verificar dependencias antes de importarlas
check_and_install_dependencies()

# Ahora importar las dependencias
from pdf2docx import Converter


def convertir_pdf_a_word(ruta_pdf, ruta_docx=None):
    """
    Convierte un archivo PDF a un documento de Word (.docx).

    Args:
        ruta_pdf (str): La ruta al archivo PDF de entrada.
        ruta_docx (str): La ruta al archivo DOCX de salida (opcional).
    
    Returns:
        str: Ruta del archivo generado.
    """
    ruta_pdf = Path(ruta_pdf)
    
    # Verificar que el archivo existe
    if not ruta_pdf.exists():
        raise FileNotFoundError(f"El archivo {ruta_pdf} no existe")
    
    # Si no se proporciona una ruta para el archivo DOCX, crear una
    if ruta_docx is None:
        ruta_docx = ruta_pdf.parent / f"{ruta_pdf.stem}.docx"
    else:
        ruta_docx = Path(ruta_docx)
        ruta_docx.parent.mkdir(parents=True, exist_ok=True)
    
    print(f"🔄 Convirtiendo: {ruta_pdf.name}")
    
    try:
        # Crear objeto Converter y realizar conversión
        cv = Converter(str(ruta_pdf))
        cv.convert(str(ruta_docx))
        cv.close()
        
        return str(ruta_docx)
        
    except Exception as e:
        raise ValueError(f"Error al convertir el PDF: {e}")


def modo_interactivo():
    """Ejecuta el script en modo interactivo."""
    os.system('cls' if os.name == 'nt' else 'clear')
    print("\033[1;36m" + "=" * 50 + "\033[0m")
    print("\033[1;36m       Convertidor PDF a Word - Modo Interactivo\033[0m")
    print("\033[1;36m" + "=" * 50 + "\033[0m\n")
    
    # Solicitar ruta del PDF
    while True:
        ruta_pdf = input("\033[1;32mRuta del archivo PDF: \033[0m").strip()
        
        # Remover comillas si las hay
        ruta_pdf = ruta_pdf.strip('"').strip("'")
        
        if not ruta_pdf:
            print("\033[1;31mError: Debe especificar una ruta\033[0m\n")
            continue
            
        if not os.path.exists(ruta_pdf):
            print("\033[1;31mError: El archivo PDF no existe\033[0m\n")
            continue
            
        if not ruta_pdf.lower().endswith('.pdf'):
            print("\033[1;33mAdvertencia: El archivo no tiene extensión .pdf\033[0m")
            respuesta = input("¿Desea continuar de todos modos? (s/n): ").strip().lower()
            if respuesta not in ['s', 'si', 'sí', 'y', 'yes']:
                continue
        
        break
    
    # Solicitar ruta de salida (opcional)
    ruta_docx = input("\033[1;32mRuta del archivo DOCX (Enter para usar el mismo nombre): \033[0m").strip()
    ruta_docx = ruta_docx.strip('"').strip("'") if ruta_docx else None
    
    return ruta_pdf, ruta_docx


def main():
    """Función principal para ejecutar desde línea de comandos."""
    parser = argparse.ArgumentParser(
        description='Convierte archivos PDF a documentos Word (.docx)',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos de uso:
  %(prog)s documento.pdf
  %(prog)s documento.pdf -o resultado.docx
  %(prog)s documento.pdf --output carpeta/resultado.docx
  %(prog)s   # Modo interactivo
        """
    )
    
    parser.add_argument(
        'input',
        nargs='?',
        help='Ruta del archivo PDF de entrada'
    )
    
    parser.add_argument(
        '-o', '--output',
        help='Ruta del archivo DOCX de salida (por defecto: mismo nombre que el PDF)',
        default=None
    )
    
    args = parser.parse_args()
    
    try:
        # Si no se proporciona archivo, usar modo interactivo
        if args.input is None:
            ruta_pdf, ruta_docx = modo_interactivo()
        else:
            ruta_pdf = args.input
            ruta_docx = args.output
        
        print(f"\n🎨 Procesando archivo: {ruta_pdf}")
        print("=" * 50)
        
        output_file = convertir_pdf_a_word(ruta_pdf, ruta_docx)
        
        print("=" * 50)
        print(f"✅ ¡Conversión exitosa!")
        print(f"\n📁 Archivo generado: {Path(output_file).absolute()}")
        
        # Mostrar información del archivo
        file_size = Path(output_file).stat().st_size / 1024  # KB
        print(f"   Tamaño: {file_size:.1f} KB")
        
    except FileNotFoundError as e:
        print(f"\n❌ Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
