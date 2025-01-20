# TimeLapse_Generator

TimeLapse Generator es un script en Bash que permite capturar imágenes con una cámara conectada al sistema y genera automáticamente un video timelapse a partir de esas imágenes.


## Características

- Verifica e instala automáticamente los paquetes necesarios: `fswebcam`, `v4l-utils`, y `ffmpeg`.
- Permite especificar una duracion en minutos o ejecutarse indefinidamente hasta que el usuario lodetenga.
- Genera un video timelapse con una cantidad de cuadros por segundos configurables.
- Opcionamente elimina las imagenes capturadas después de generar el video.
- Incluye validaciones y manejo de errores.


## Requisitos

- Sistema operativo basado en Linux - (Base Debian).
- Cámara compatible conectada al sistema.
- Paquetes `fswebcam`, `v4l-utils` y `ffmpeg` (se instalan automáticamente si no están presentes).


## Instalación

1. Clona el repositorio:
  ```bash
  git clone https://github.com/Human-Technology/TimeLapse_Generator.git
  cd TimeLapse_Generator
  ```

2. Da Permisos de ejecución:
  ```bash
  chmod +x timelapse-generator.sh
  ```

3. Ejecuta el Script:
  ```bash
  ./timelapse-generator.sh <duración en minutos> <ruta del directorio>
  ```
- Si no especificas una duración, el script se ejecutará indefinidamente hasta que lo detengas manualmente (Ctrl+C)

## Ejemplo de uso:

  ```bash
  ./timelapse-generator.sh 30 /home/user/timelapse
  ```
- Esto ejecutará el script durante 30 minutos y guardará las imágenes y el video en la carpeta `/home/user/timelapse`.


## Licencia
Este proyecto está licenciado bajo la licencia MIT.
