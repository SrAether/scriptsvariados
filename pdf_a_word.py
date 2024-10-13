import sys
import os
# verificamos si existen las dependencias necesarias
try:
  import pdf2docx
except ImportError:
  # print("Instalando dependencias...") en morado
  print("\033[1;35mInstalando dependencias...\033[0m")
  os.system("pip install pdf2docx")
  
from pdf2docx import Converter

def convertir_pdf_a_word(ruta_pdf, ruta_docx=None):
  """
  Convierte un archivo PDF a un documento de Word (.docx).

  Args:
    ruta_pdf: La ruta al archivo PDF de entrada.
    ruta_docx: La ruta al archivo DOCX de salida. Si no se especifica, se 
               generará un nombre de archivo basado en el nombre del PDF.
  """

  try:
    # Si no se proporciona una ruta para el archivo DOCX, crea una
    # basada en el nombre del archivo PDF.
    if ruta_docx is None:
      nombre_archivo = os.path.splitext(os.path.basename(ruta_pdf))[0]
      ruta_docx = f"{nombre_archivo}.docx"

    # Crea un objeto Converter
    cv = Converter(ruta_pdf)
    # Convierte el PDF a DOCX
    cv.convert(ruta_docx)
    cv.close()

    print(f"Conversión exitosa! Archivo guardado como: {ruta_docx}")

  except Exception as e:
    print(f"Error al convertir el PDF: {e}")

if __name__ == "__main__":
  
  if len(sys.argv) < 2:
    # limpiar la pantalla
    os.system('cls' if os.name == 'nt' else 'clear')
    print("Uso: python convertir_pdf_a_word.py <ruta_pdf> [ruta_docx]")
    print("Entrando en modo interactivo...")
   
    while True:
      #print("Modo interactivo") en azul celeste
      print("\033[1;36mModo interactivo\033[0m")
      while True:
        
        #ruta_pdf = input("Ruta del archivo PDF: ") en verde
        ruta_pdf = input("\033[1;32mRuta del archivo PDF: \033[0m")
        # verifica si el archivo PDF existe
        if not os.path.exists(ruta_pdf):
          # limpiar la pantalla
          os.system('cls' if os.name == 'nt' else 'clear')
          # mensaje de modo interactivo
          print("\033[1;36mModo interactivo\033[0m")
          # mensaje de error en rojo
          print("\033[1;31mEl archivo PDF no existe.\033[0m")
          continue
        break
      ruta_pdf = input("Ruta del archivo PDF: ")
      # ruta documento de salida
      
      # ruta_docx = input("Ruta del archivo DOCX (opcional): ") en verde
      ruta_docx = input("\033[1;32mRuta del archivo DOCX (opcional): \033[0m")
      convertir_pdf_a_word(ruta_pdf, ruta_docx)
      break

  ruta_pdf = sys.argv[1]
  ruta_docx = sys.argv[2] if len(sys.argv) > 2 else None

  convertir_pdf_a_word(ruta_pdf, ruta_docx)
