# Poke-tools — bots para Pokémon Rojo Fuego / Verde Hoja

[![CI](https://github.com/vladeParica/Poke-tools/actions/workflows/ci.yml/badge.svg)](https://github.com/vladeParica/Poke-tools/actions/workflows/ci.yml)
[![Licencia: GPL-3.0](https://img.shields.io/badge/licencia-GPL--3.0-blue.svg)](LICENSE)
![Lua 5.1](https://img.shields.io/badge/Lua-5.1-2C2D72.svg)
![VBA-rr](https://img.shields.io/badge/emulador-VBA--rr-555.svg)

Scripts Lua para el emulador **VBA-rr** que cazan shinies manipulando el RNG y entrenan
EVs y nivel de forma automática en **Pokémon Rojo Fuego y Verde Hoja** (GBA).

| Bot | Para qué |
|---|---|
| [**Shiny Bot**](shinybot/) | Shinies y Pokémon perfectos: a ciegas o con RNG exacto (estáticos, regalos, roamers, salvajes), semilla inicial y SID en partida nueva |
| [**Train Bot**](trainbot/) | EVs exactos y nivel: elige rivales y ataques, aprende ataques y va solo al Centro Pokémon |

## Inicio rápido

1. Instala VBA-rr y desactiva *Pause When Inactive*. La ROM no se incluye.
2. Copia el `.lua` y el `.json` del bot a una carpeta.
3. VBA-rr → *Tools → Lua Scripting → New Lua Script Window* → abre el `.lua` → *Run*.
4. Pulsa **7** para iniciar.

Carga **un solo script a la vez**. Cómo usar cada bot: [Shiny Bot](shinybot/README.md) ·
[Train Bot](trainbot/README.md).

## Documentación

- [Documentación del proyecto](docs/README.md): requisitos, arquitectura, decisiones (ADR),
  pruebas e instalación.
- [Cómo contribuir](CONTRIBUTING.md) · [Cambios](CHANGELOG.md) · [Seguridad](SECURITY.md)

## Créditos y licencia

Basado en [DevonStudios/LuaScripts](https://github.com/DevonStudios/LuaScripts)
(Devon Studios x Real.96) y en los datos de [pret/pokefirered](https://github.com/pret/pokefirered).
Detalle en [docs/00-project/creditos.md](docs/00-project/creditos.md).

Licencia [GPL-3.0](LICENSE). Pokémon es una marca de Nintendo, Game Freak y Creatures;
este proyecto no está afiliado a ellos.
