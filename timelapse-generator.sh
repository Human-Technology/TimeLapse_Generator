#!/bin/bash

# Colores para mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

#Banner de Inicio
echo "-------------------------------------------------------------------------------------------------------"
echo "  _______ _                _                             _____                           _             "
echo " |__   __(_)              | |                           / ____|                         | |            "
echo "    | |   _ _ __ ___   ___| |     __ _ _ __  ___  ___  | |  __  ___ _ __   ___ _ __ __ _| |_ ___  _ __ "
echo "    | |  | | '_ \` _ \ / _ \ |    / _\` | '_ \/ __|/ _ \ | | |_ |/ _ \ '_ \ / _ \ '__/ _\` | __/ _ \| '__|"
echo "    | |  | | | | | | |  __/ |___| (_| | |_) \__ \  __/ | |__| |  __/ | | |  __/ | | (_| | || (_) | |   "
echo "    |_|  |_|_| |_| |_|\___|______\__,_| .__/|___/\___|  \_____|\___|_| |_|\___|_|  \__,_|\__\___/|_|   "
echo "                                      | |                                                              "
echo "                                      |_|                                                              "
echo 
echo "                     By José Sánchez - Human Technology                                                "
echo "-------------------------------------------------------------------------------------------------------"
echo "Este script te permite capturar imágenes con tu cámara y generar un video timelapse automáticamente."
echo "Instrucciones básicas:"
echo "1. Asegúrate de tener fswebcam, v4l-utils y ffmpeg instalados (el script los instalará si no están)."
echo "2. Ejecuta el script con: $0 <duración en minutos> <ruta del directorio>"
echo "   - Si no especificas la duración, el script se ejecutará indefinidamente hasta que lo detengas (Ctrl+C)."
echo "-------------------------------------------------------------------------------------------------------"
echo

#Verificar si se proporcionaron los argumentos correctos
if [ $# -lt 1 ]; then
  echo -e "${RED}Uso: $0 <duracion en minutos> <ruta del directorio>${NC}"
  echo "Ejemplo: $0 30 /home/user/timelapse"
  echo "Nota: Si no especificas la duración, el script se ejecutará indefinidamente hasta que lo detengas (Ctrl+C)."
  exit 1
fi

#Funcion para Verifica si los paquetes necesarios estan instalados
check_and_install() {
  REQUIRED_PACKAGES=("fswebcam" "v4l-utils" "ffmpeg")
  MISSING_PACKAGES=()

  # Verificar si algún paquete está ausente
  for PACKAGE in "${REQUIRED_PACKAGES[@]}"; do
    if ! dpkg -l | grep -q "^ii.*${PACKAGE}"; then
      MISSING_PACKAGES+=("$PACKAGE")
    fi
  done

  # Si hay paquetes faltantes, actualizar el sistema y luego instalarlos
  if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo -e "${BLUE}Faltan los siguientes paquetes: ${MISSING_PACKAGES[@]}.${NC}"
    echo -e "${BLUE}Actualizando el sistema antes de instalar los paquetes necesarios...${NC}"
    sudo apt update && sudo apt upgrade -y
    if [ $? -ne 0 ]; then
      echo -e "${RED}Error al actualizar el sistema. Verifica tu conexión a Internet.${NC}"
      exit 1
    fi

    echo -e "${BLUE}Instalando paquetes necesarios: ${MISSING_PACKAGES[@]}...${NC}"
    sudo apt install -y "${MISSING_PACKAGES[@]}"
    if [ $? -ne 0 ]; then
      echo -e "${RED}Error al instalar los paquetes. Verifica tu conexión a Internet.${NC}"
      exit 1
    fi
  else
    echo -e "${GREEN}Todos los paquetes necesarios están instalados.${NC}"
  fi
}


#Verificar los paquetes necesarios 
check_and_install


# Verificar si el primer argumento es numérico (duración en minutos)
if [[ $1 =~ ^[0-9]+$ ]]; then
  DURATION_MIN=$1 # Duración en minutos pasada como argumento
  BASE_DIR=$2 # Ruta del directorio pasada como argumento
else
  DURATION_MIN=0 # Indicador para ejecución indefinida
  BASE_DIR=$1 # Si no se especifica duración, el primer argumento será la ruta
fi

#Validar la ruta del directorio
if [ ! -d "$BASE_DIR" ]; then
  echo -e "${RED}Error: EL directorio especificado '$BASE_DIR' no existe.${NC}"
  exit 1
fi

OUTPUT_DIR="${BASE_DIR}/output"
SAVE_DIR="${BASE_DIR}/save"
VIDEO_DIR="$BASE_DIR/video_timelapse"
mkdir -p "$OUTPUT_DIR"
mkdir -p "$SAVE_DIR"
mkdir -p "$VIDEO_DIR"


# Ajustar parámetros de la cámara 
v4l2-ctl --set-ctrl=brightness=50 --set-ctrl=contrast=50 --set-ctrl=saturation=50

CAMERA_DEVICE=/dev/video0
RESOLUTION=1280x720
DELAY=10
END_TIME=$(( $(date +%s) + DURATION_MIN * 60 ))
RUN=true

# Manejar señales para detener el Script 
trap "RUN=false" SIGINT SIGTERM

count=0
while $RUN; do
  if [[ $DURATION_MIN -gt 0 && $(date +%s) -ge $END_TIME ]]; then
    RUN=false
    break
  fi

  sudo fswebcam -d v4l2:${CAMERA_DEVICE} -i 0 -r ${RESOLUTION} -S 10 -F 1 --no-banner ${OUTPUT_DIR}/out.jpg
  cp -v ${OUTPUT_DIR}/out.jpg ${SAVE_DIR}/$(date '+%Y%m%d%H%M%S').jpg
  ((count++))
  echo -e "${BLUE}Imagen capturada: $count | Tiempo restante: $(( ($END_TIME - $(date +%s)) / 60 )) minutos...${NC}"
  sleep ${DELAY}
done

#Mostrar uso de disco
IMAGE_SIZE=$(du -sh "$SAVE_DIR" | awk '{print $1}')
echo -e "${GREEN}Captura de imágenes finalizada. Tamaño total: $IMAGE_SIZE${NC}"
echo -e "${BLUE}Generando video en la carpeta ${VIDEO_DIR}...${NC}"

# Solicitar FPS al usuario
read -p "¿Cuántas imágenes por segundo desea para el video? (Presione Enter para usar el valor predeterminado de 10): " FPS
FPS=${FPS:-10}

# Validar FPS
if ! [[ $FPS =~ ^[0-9]+$ ]] || [[ $FPS -le 0 ]] || [[ $FPS -gt 60 ]]; then
  echo -e "${RED}FPS no válido. Usando el valor predeterminado de 10.${NC}"
  FPS=10
fi

# Generar el video a partir de las imágenes
VIDEO_FILE="${VIDEO_DIR}/timelapse_$(date '+%Y%m%d%H%M%S').mp4"
sudo ffmpeg -framerate $FPS -pattern_type glob -i "${SAVE_DIR}/*.jpg" -c:v libx264 -pix_fmt yuv420p "$VIDEO_FILE" -y


if [ $? -eq 0 ]; then
  echo -e "${GREEN}Vídeo generado exitosamente: $(realpath "$VIDEO_FILE")${NC}"
  echo "Puedes reproducirlo con: ffplay $(realpath "$VIDEO_FILE")"
else
  echo -e "${RED}Ocurrió un error al generar el video.${NC}"
fi

# Preguntar al usuario si desea eliminar las imágenes capturadas
read -p "¿Deseas eliminar las imágenes capturadas después de generar el video? (y/n): " DELETE_IMAGES
if [[ "$DELETE_IMAGES" =~ ^[Yy]$ ]]; then
  rm -rf "$SAVE_DIR"
  echo -e "${BLUE}Imágenes eliminadas.${NC}"
else
  echo -e "${BLUE}Las imágenes se han conservado en: $SAVE_DIR${NC}"
fi

echo -e "${GREEN}TimeLapse Generator terminado. ¡Gracias por usar este script!${NC}"
