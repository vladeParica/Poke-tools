# Cambios

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/). Cada bot
tiene su propia versión. Anota aquí cualquier cambio en el JSON, las rutas o las teclas:
son el contrato con los usuarios ([contratos](docs/02-design/api-contracts.md)).

## [Sin publicar]

### Añadido
- Documentación AI-DLC en `docs/` (carta del proyecto, PRD, arquitectura, C4, modelo de
  amenazas, ADRs, pruebas, instalación, monitoreo) y puertas en `.ai-dlc/gates/`.
- Guías de uso de cada bot (`shinybot/README.md`, `trainbot/README.md`).
- Rutas reutilizables documentadas en `trainbot/examples/routes/`.
- CI en GitHub Actions: comprueba que los `.lua` generados están al día y corre el simulador.
- Licencia GPL-3.0, `CONTRIBUTING.md`, `SECURITY.md`, plantillas de issues y PR.

### Cambiado
- Ejemplos del Train Bot movidos a `trainbot/examples/configs/` con nombres por
  estadística (`FRLG_TrainBot_Velocidad_Diglett.json`, `FRLG_TrainBot_AtEsp_Torre.json`).
- `tools/rng/`: el TID y el SID se pasan al compilar (`-DTID -DSID`) o como argumentos;
  ya no vienen fijos.

### Seguridad
- Los dos bots ya no pasan al shell una carpeta de logs (`logDir`, `sharedDir`) que
  contenga `"`, `%`, `$` o `` ` ``; en ese caso usan la carpeta del script.

### Quitado
- Notas de una partida concreta (semillas calculadas, plan de equipo).

## Shiny Bot 4.3 — Train Bot 1.10
Primera versión publicada en este repositorio.

- **Shiny Bot 4.3:** modos Salvaje, Estático, Regalo, Roamer, sus variantes RNG, Salvaje
  RNG a un paso del encuentro, Partida nueva y Semilla inicial; Tele Pokémon; varias instancias.
- **Train Bot 1.10:** EVs exactos y nivel, decisor de combate, aprender ataques, evolución,
  rutas grabadas, curación con enfermera o casilla, avisos ntfy/Discord.
