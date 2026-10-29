# Modelo de amenazas — Poke-tools

> **Fase AI-DLC:** `02-design`  ·  **Método:** STRIDE + priorización DREAD
> **Autor:** vladeParica  ·  **Fecha:** 2026-10-29

## 1. Alcance y activos
El sistema corre en la PC del jugador, sin servidor ni cuentas. Lo que hay que proteger:
- **La PC del jugador**: los bots ejecutan comandos del sistema (`os.execute` para crear
  carpetas y lanzar `curl`).
- **El webhook de Discord y el tema de ntfy** del jugador ([clasificación](../00-project/data-classification.md)).
- **La partida del jugador**: el bot pulsa botones y reinicia el juego; un fallo puede
  hacer perder progreso no guardado.
- **El repositorio**: no debe contener ROMs, partidas ni secretos.

## 2. Flujo de datos
Ver el [diagrama de contenedores](../architecture/c4-container.md). Entradas no
confiables: el **JSON** y el **archivo de ruta** (los puede escribir o descargar
cualquiera). Salida a la red: los **avisos** del Train Bot.

## 3. Análisis STRIDE
| Categoría | Amenaza | Componente | Mitigación |
|---|---|---|---|
| **S**uplantación | Alguien adivina el tema de ntfy y envía avisos falsos o lee los reales | Avisos | Tema largo y difícil de adivinar (documentado en el JSON); los avisos no llevan datos sensibles |
| **T**ampering | Un JSON o una ruta descargados con contenido malicioso para inyectar comandos en `os.execute` | Configuración, avisos | El tema de ntfy solo admite `[A-Za-z0-9_-]`; la URL de Discord solo `https://` + caracteres seguros; el texto del aviso se filtra a una lista blanca de caracteres antes de pasarlo a curl |
| **T**ampering | `logDir` o `sharedDir` con comillas o variables para inyectar en el `mkdir` | Log | La ruta va entre comillas dobles y, si contiene `"`, `%`, `$` o `` ` ``, no se pasa al shell: el bot usa la carpeta del script |
| **R**epudio | No saber qué hizo el bot mientras el jugador no miraba | Log | `shiny_log.txt` / `train_log.txt` con fecha, versión del juego y cada evento relevante |
| **I**nformación expuesta | Subir al repo un JSON con el webhook o una ROM/partida | Repositorio | `.gitignore` bloquea ROMs, partidas, savestates, logs y bloqueos; los ejemplos usan `notify: null`; revisión en PR ([CONTRIBUTING](../../CONTRIBUTING.md)) |
| **D**enegación de servicio | Dos instancias pulsando botones a la vez; aviso que bloquea el emulador | Bucle, avisos | Archivos de bloqueo; curl en segundo plano con `-m 15` |
| **D**enegación de servicio | El bot reinicia el juego con progreso sin guardar | Modos | `resetOnLoad` documentado; el jugador guarda antes de iniciar (README) |
| **E**levación de privilegios | El script corre con los permisos del usuario | Todos | No se piden permisos extra; solo `mkdir` y `curl`. Los scripts de terceros se deben revisar antes de cargarlos (consejo en [SECURITY](../../SECURITY.md)) |

## 4. Priorización DREAD
| Amenaza | D | R | E | A | D | Total |
|---|---|---|---|---|---|---|
| Inyección de comandos vía `notify` en un JSON descargado | 8 | 2 | 2 | 2 | 3 | **17** (mitigada) |
| Webhook de Discord publicado en el repo | 4 | 8 | 6 | 1 | 6 | **25** |
| Tema de ntfy adivinado | 2 | 5 | 4 | 1 | 3 | **15** |
| Inyección vía `logDir` / `sharedDir` | 8 | 2 | 2 | 1 | 2 | **15** (mitigada) |
| Pérdida de progreso por reinicio | 4 | 6 | 1 | 3 | 8 | **22** |

## 5. Riesgos aceptados
- El jugador ejecuta scripts Lua con sus permisos: es como funciona VBA-rr; se acepta.
- Los avisos de ntfy.sh viajan por un servicio público: se acepta porque solo llevan el
  estado del bot.
