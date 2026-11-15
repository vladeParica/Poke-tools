# Guía de Rojo Fuego y Verde Hoja

Guía de referencia generada desde los datos del juego, sin datos escritos a mano: `python tools/guia/gen_guia.py` la vuelve a crear.

| Sección | Contenido |
|---|---|
| [Pokémon](pokemon/README.md) | Una página por especie: tipos, habilidades, stats, EVs, captura, crecimiento, evolución, ataques, MT/MO, tutores y dónde encontrarlo en cada versión |
| [Ataques](ataques.md) | Todos los ataques y qué Pokémon los aprenden por nivel (con el nivel), por MT/MO y por tutor |
| [MT y MO](mts.md) | Todas, con su ataque y cómo se consigue cada una |
| [Objetos](objetos.md) | Suelo, ocultos, regalos y tiendas por mapa; vitaminas y piedras evolutivas |
| [Tutores](tutores.md) | Tutores de ataques y los ataques definitivos de los iniciales |
| [Entrenadores](entrenadores.md) | Líderes, Alto Mando, Campeón y rival, con equipos y premios |
| [EVs](evs.md) | Mejores zonas para entrenar cada EV en cada versión |
| [Diferencias](diferencias.md) | Pokémon exclusivos de cada versión |

## De dónde salen los datos

- **Juego**: la decompilación [pret/pokefirered](https://github.com/pret/pokefirered), commit `ce6406d8c2eaf46d543c8a2606de0c3cb1951982`: especies, ataques, MT, tutores, evoluciones, encuentros, guiones de los mapas, tiendas, premios y entrenadores.
- **Nombres en español e inglés**: las tablas de [PokeAPI](https://github.com/PokeAPI/pokeapi/tree/master/data/v2/csv), unidas por número nacional (Pokémon), número de ataque o habilidad (son los mismos en la 3.ª generación) y nombre del objeto. Si no hay nombre en español, la guía pone "nombre en español sin verificar".
- Los **lugares** llevan el nombre en inglés del juego (las secciones del mapa de pret): no hay una fuente de datos con los nombres en español de Kanto y las Islas Sete.
- **Físico o especial**: en la 3.ª generación depende del tipo del ataque (`IS_TYPE_PHYSICAL` en `include/battle.h`).
- **Potencia "variable"**: pret pone potencia 1 a los ataques que calculan el daño a su manera.
- **Probabilidad** de un encuentro: la de ese método (andando, Surf, Golpe Roca o cada caña), sumando los huecos de la especie.
- **Imágenes**: los sprites de Rojo Fuego/Verde Hoja y los iconos de objetos del repositorio [PokeAPI/sprites](https://github.com/PokeAPI/sprites). Solo se enlazan: no se guardan en este repositorio y se cargan al ver la página (como los fondos del configurador, ADR-0013). Sin conexión no se ven.

Objetos sin nombre en español en PokeAPI: `X_DEFEND`, `X_SPECIAL`, `ITEMFINDER`.
