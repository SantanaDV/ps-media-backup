# PS Media Backup (Fotos y Vídeos desde C:)

Script en PowerShell para **localizar y copiar fotos y vídeos** desde `C:\` a una unidad de destino (por ejemplo, un disco externo), **manteniendo la estructura de carpetas**, mostrando **progreso con ETA** y guardando un **log**. Evita sobrescribir archivos existentes creando nombres únicos.

## Características

- Recorre `C:\` de forma recursiva y copia solo fotos y vídeos.
- Mantiene la misma estructura de carpetas en el destino.
- Excluye rutas de sistema para acelerar y evitar errores de permisos.
- Crea nombres únicos cuando el archivo ya existe (p. ej., `nombre (1).ext`).
- Muestra barra de progreso con porcentaje y tiempo estimado restante.
- Genera un log detallado de aciertos y errores.
- Listas de extensiones y exclusiones configurables.
- No borra ni modifica nada del origen.

## Requisitos

- Windows 10/11.
- PowerShell 5.1 o PowerShell 7+.
- Permisos de lectura en `C:\` y de escritura en la unidad de destino.

## Instalación

1.  Clona o descarga este repositorio.
2.  Verifica que el archivo `Backup-FotosVideos-C.ps1` esté en la raíz del proyecto.
3.  (Opcional) Ajusta la política de ejecución solo para la sesión actual:

    ```powershell
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

    ```

## Configuración

Edita la **sección de configuración** al inicio del script (ruta de destino y origen):

- **`$destRoot`**: carpeta raíz donde se guardará el backup (se crea si no existe).  
  Ej.: `T:\Backup_FotosVideos_C`
- **`$sourceRoot`**: carpeta a escanear (por defecto, `C:\`).

### Extensiones soportadas

- **Imágenes**: `.jpg .jpeg .png .gif .bmp .tif .tiff .webp .heic .heif .raw .cr2 .nef .arw .rw2 .dng`
- **Vídeos**: `.mp4 .mov .m4v .avi .wmv .mkv .mts .m2ts .3gp`

Ajusta los arrays `\$imgExt` y `\$vidExt` en el script si necesitas añadir o quitar formatos.

### Directorios excluidos (por defecto)

```
C:\Windows
C:\Program Files
C:\Program Files (x86)
C:\ProgramData
C:\PerfLogs
C:\$Recycle.Bin
C:\System Volume Information

```

Puedes añadir más rutas en el array `\$excludeDirs`.

## Uso

1.  Abre PowerShell en la carpeta del proyecto.
2.  Ejecuta:

    ```powershell
    .\Backup-FotosVideos-C.ps1

    ```

Durante la ejecución verás:

- La carpeta actual que se está procesando.
- Una barra de progreso con porcentaje y ETA.
- Actualizaciones de estado cada 50 archivos.

## Salida y logs

- Los archivos se copian a `\$destRoot`, preservando subcarpetas respecto a `C:\`.
- Si existe un archivo con el mismo nombre en destino, se creará `nombre (1).ext`, `nombre (2).ext`, etc.
- Se genera un **log** en `\$destRoot` con nombre:  
  `backup_fotos_videos_YYYY-MM-dd_HHmmss.log`

Ejemplo de líneas del log:

```
Inicio: 2025-11-03 18:05:11
Origen: C:\
Destino: T:\Backup_FotosVideos_C
OK  -> T:\Backup_FotosVideos_C\Users\...\DCIM\IMG_0001.JPG
ERR -> C:\Users\...\AppData\...\thumb.db :: Access to the path is denied.
Fin: 2025-11-03 19:47:32
Copiados: 12,345 | Omitidos: 27 | Total vistos: 12,372

```

## Personalización rápida

- **Solo fotos**: elimina `\$vidExt` del combinado `\$wantedExt`.
- **Solo vídeos**: elimina `\$imgExt` del combinado `\$wantedExt`.
- **Excluir nubes/sin conexión**: añade rutas (p. ej., `C:\Users\<usuario>\OneDrive`) a `\$excludeDirs`.

## Buenas prácticas y rendimiento

- Si usas OneDrive, marca carpetas como **“Conservar siempre en este dispositivo”** para forzar la disponibilidad local.
- Ejecuta el script con el equipo enchufado y sin suspensión.
- Comprueba el **espacio libre** en la unidad de destino antes de empezar.

## Limitaciones

- No elimina archivos del destino; **no es sincronización bidireccional**.
- No compara por hash; copia por extensión y ruta, evitando sobrescrituras con nombres únicos.
- Algunas rutas protegidas están excluidas por defecto.

## Solución de problemas

- **“Access is denied”**: habitual en rutas del sistema; el script lo registra y continúa.
- **No se copian ciertos archivos**: revisa extensiones soportadas y rutas excluidas.
- **OneDrive/Dropbox**: asegúrate de que los archivos estén disponibles sin conexión.

## Estructura del proyecto

```
ps-media-backup/
├─ Backup-FotosVideos-C.ps1
└─ README.md

```
