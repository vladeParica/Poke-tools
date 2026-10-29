# Monitoreo — Poke-tools

> **Fase AI-DLC:** `06-monitoring`
> Los bots corren horas sin nadie mirando. Esto es lo que el jugador tiene para saber
> qué están haciendo y enterarse cuando algo pasa.

## Salud
- **Panel** (tecla 9): modo o estado actual, intentos, objetivo, EVs ganados, último
  mensaje. El nivel completo añade una línea de diagnóstico (`Menu`, `Espera`, `Cursor`,
  `Combate`, `Pos`) para comprobar las direcciones en otros idiomas.
- **Consola de Lua**: juego e idioma detectados, errores de configuración y avisos al cargar.
- "Sano" = el panel cambia de estado y los contadores avanzan.

## Métricas
| Métrica | Por qué importa | Dónde |
|---|---|---|
| Intentos / reinicios hasta el hallazgo | Saber si el filtro es demasiado estricto | Panel, `shiny_log.txt` |
| Retraso calibrado | Si varía mucho, hay lag | Consola, panel |
| Combates peleados / huidos | Si huye de casi todo, la zona no sirve | Panel, `train_log.txt` |
| EVs ganados por combate | Detectar Pokérus o Brazal Firme | Panel ("+2 Vel (Diglett)") |
| Viajes al Centro | Si son muchos, subir `healBelow` o cambiar de zona | Panel, `train_log.txt` |

## Avisos
| Situación | Severidad | Cómo se entera el jugador |
|---|---|---|
| Objetivo encontrado (Shiny Bot) | Alta | Juego en pausa + mensaje + `shiny_log.txt` |
| Entrenamiento completo | Alta | Pausa + aviso `notify` |
| Shiny salvaje en el Train Bot | Alta | Pausa (`stopOnShiny`) + aviso |
| Quiere aprender un ataque (`ask`) | Media | Aviso; espera `askTimeout` |
| Evolución con `evolve: true` | Media | Aviso; el jugador termina la escena y el bot sigue |
| Bot detenido por un problema (ruta bloqueada, juego reiniciado, otra instancia) | Media | Pausa + mensaje naranja en el panel + línea en el log + aviso |

Los avisos al celular (`notify`) solo existen en el Train Bot.

## Objetivos de servicio
No aplican SLOs: es una herramienta local. La expectativa es que el bot **nunca siga
pulsando botones en un estado que no entiende**: ante la duda se detiene y lo dice.

## Logs
- `logs/shiny_log.txt` y `logs/train_log.txt`: una línea por evento, con fecha y versión
  del juego (`[FireRed USA v1.0]`).
- `logs/` está en `.gitignore`.
