# Clasificación de datos — Poke-tools

> **Fase AI-DLC:** `00-project`
> Todo corre en la PC del jugador; no hay servidor ni base de datos. Los únicos datos que
> salen de la máquina son los avisos opcionales del Train Bot.

| Dato | Dónde vive | Sensibilidad | Manejo |
|---|---|---|---|
| ROM del juego | PC del jugador | **Restringido** (derechos de autor) | Nunca en el repo; `.gitignore` bloquea `*.gba` |
| Partidas y savestates (`.sav`, `.sgm`, `.sg0-9`) | PC del jugador | **Restringido** (contenido con derechos y privado) | Nunca en el repo; bloqueados en `.gitignore` |
| URL del webhook de Discord (`notify.discord`) | JSON local | **Confidencial** (quien la tenga puede publicar en el canal) | No subir JSON con webhooks reales; los ejemplos usan `null` |
| Tema de ntfy (`notify.ntfy`) | JSON local | **Confidencial** (los temas de ntfy.sh son públicos: quien adivine el nombre lee los avisos) | Usar un nombre difícil de adivinar; no subirlo |
| Texto de los avisos | ntfy.sh / Discord | **Interno** | Solo estado del bot (especie, nivel, EVs); se filtran los caracteres antes de enviarlo |
| TID / SID y semillas de una partida concreta | PC del jugador | **Interno** | No se suben al repo: los ejemplos usan valores neutros (TID 12345 / SID 54321) |
| Logs (`logs/*.txt`), bloqueos (`*.lock`, `*.flag`) | Carpeta del script | **Interno** | Generados; ignorados por git |
| Rutas grabadas (`FRLG_TrainRoute*.txt`) | Carpeta del script | **Público** | Solo coordenadas del mapa; las de `trainbot/examples/routes/` se comparten a propósito |
| Configuración (`*.json`) | Carpeta del script | **Interno** | Las de ejemplo son públicas; las personales pueden llevar `notify` |
| Datos del juego (tablas de especies, ataques…) | `shinybot/src/tables2.lua`, `trainbot/src/train_tables.lua` | **Público** | Derivados de pret/pokefirered y de Devon Studios (ver [créditos](creditos.md)) |

**Niveles:** Público < Interno < Confidencial < Restringido.

## Requisitos transversales
- Ningún dato Restringido entra al repositorio: lo garantiza `.gitignore` y se revisa en
  cada PR (ver [CONTRIBUTING](../../CONTRIBUTING.md)).
- Los avisos se envían por HTTPS (curl a `https://ntfy.sh/…` y a la URL `https://` del webhook).
- No hay datos personales de terceros: el proyecto no recoge nada de otros usuarios.
