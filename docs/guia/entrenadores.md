# Entrenadores

[Guía](README.md)

Equipos de `src/data/trainer_parties.h`. *(por defecto)*: el entrenador no tiene ataques propios y su Pokémon lleva los 4 últimos que aprende por nivel. Dinero = 4 × nivel de su último Pokémon × valor de su clase (× 2 en combate doble), de `src/battle_script_commands.c` y `gTrainerMoneyTable`.

- [Líderes de gimnasio](#líderes-de-gimnasio)
- [Alto Mando y Campeón](#alto-mando-y-campeón)
- [Rival](#rival)

## Líderes de gimnasio

### Brock — Pewter City · Gym

- Medalla n.º 1
- Premio: 1400 ₽, <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/tm-rock.png" alt="MT39" width="24" height="24"> [MT39 (TM39)](mts.md#tm39) (Tumba Rocas)
- Objetos que usa: ninguno

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/74.png" alt="Geodude" width="32" height="32"> [Geodude](pokemon/074-geodude.md) | 12 | [Placaje](ataques.md#mv-tackle), [Rizo Defensa](ataques.md#mv-defense-curl) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/95.png" alt="Onix" width="32" height="32"> [Onix](pokemon/095-onix.md) | 14 | [Placaje](ataques.md#mv-tackle), [Atadura](ataques.md#mv-bind), [Tumba Rocas](ataques.md#mv-rock-tomb) | — |

### Misty — Cerulean City · Gym

- Medalla n.º 2
- Premio: 2100 ₽, <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/tm-water.png" alt="MT03" width="24" height="24"> [MT03 (TM03)](mts.md#tm03) (Hidropulso)
- Objetos que usa: Superpoción

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/120.png" alt="Staryu" width="32" height="32"> [Staryu](pokemon/120-staryu.md) | 18 | [Placaje](ataques.md#mv-tackle), [Fortaleza](ataques.md#mv-harden), [Recuperación](ataques.md#mv-recover), [Hidropulso](ataques.md#mv-water-pulse) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/121.png" alt="Starmie" width="32" height="32"> [Starmie](pokemon/121-starmie.md) | 21 | [Meteoros](ataques.md#mv-swift), [Recuperación](ataques.md#mv-recover), [Giro Rápido](ataques.md#mv-rapid-spin), [Hidropulso](ataques.md#mv-water-pulse) | — |

### Lt. Surge — Vermilion City · Gym

- Medalla n.º 3
- Premio: 2400 ₽, <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/tm-electric.png" alt="MT34" width="24" height="24"> [MT34 (TM34)](mts.md#tm34) (Onda Voltio)
- Objetos que usa: Superpoción, Cura Total

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/100.png" alt="Voltorb" width="32" height="32"> [Voltorb](pokemon/100-voltorb.md) | 21 | [Bomba Sónica](ataques.md#mv-sonic-boom), [Placaje](ataques.md#mv-tackle), [Chirrido](ataques.md#mv-screech), [Onda Voltio](ataques.md#mv-shock-wave) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/25.png" alt="Pikachu" width="32" height="32"> [Pikachu](pokemon/025-pikachu.md) | 18 | [Ataque Rápido](ataques.md#mv-quick-attack), [Onda Trueno](ataques.md#mv-thunder-wave), [Doble Equipo](ataques.md#mv-double-team), [Onda Voltio](ataques.md#mv-shock-wave) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/26.png" alt="Raichu" width="32" height="32"> [Raichu](pokemon/026-raichu.md) | 24 | [Ataque Rápido](ataques.md#mv-quick-attack), [Onda Trueno](ataques.md#mv-thunder-wave), [Doble Equipo](ataques.md#mv-double-team), [Onda Voltio](ataques.md#mv-shock-wave) | — |

### Erika — Celadon City · Gym

- Medalla n.º 4
- Premio: 2900 ₽, <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/tm-grass.png" alt="MT19" width="24" height="24"> [MT19 (TM19)](mts.md#tm19) (Gigadrenado)
- Objetos que usa: Hiperpoción, Cura Total

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/71.png" alt="Victreebel" width="32" height="32"> [Victreebel](pokemon/071-victreebel.md) | 29 | [Paralizador](ataques.md#mv-stun-spore), [Ácido](ataques.md#mv-acid), [Polvo Veneno](ataques.md#mv-poison-powder), [Gigadrenado](ataques.md#mv-giga-drain) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/114.png" alt="Tangela" width="32" height="32"> [Tangela](pokemon/114-tangela.md) | 24 | [Polvo Veneno](ataques.md#mv-poison-powder), [Restricción](ataques.md#mv-constrict), [Arraigo](ataques.md#mv-ingrain), [Gigadrenado](ataques.md#mv-giga-drain) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/45.png" alt="Vileplume" width="32" height="32"> [Vileplume](pokemon/045-vileplume.md) | 29 | [Somnífero](ataques.md#mv-sleep-powder), [Ácido](ataques.md#mv-acid), [Paralizador](ataques.md#mv-stun-spore), [Gigadrenado](ataques.md#mv-giga-drain) | — |

### Koga — Fuchsia City · Gym

- Medalla n.º 5
- Premio: 4300 ₽, <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/tm-poison.png" alt="MT06" width="24" height="24"> [MT06 (TM06)](mts.md#tm06) (Tóxico)
- Objetos que usa: Hiperpoción, Hiperpoción, Cura Total

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/109.png" alt="Koffing" width="32" height="32"> [Koffing](pokemon/109-koffing.md) | 37 | [Autodestrucción](ataques.md#mv-self-destruct), [Residuos](ataques.md#mv-sludge), [Pantalla de Humo](ataques.md#mv-smokescreen), [Tóxico](ataques.md#mv-toxic) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/89.png" alt="Muk" width="32" height="32"> [Muk](pokemon/089-muk.md) | 39 | [Reducción](ataques.md#mv-minimize), [Residuos](ataques.md#mv-sludge), [Armadura Ácida](ataques.md#mv-acid-armor), [Tóxico](ataques.md#mv-toxic) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/109.png" alt="Koffing" width="32" height="32"> [Koffing](pokemon/109-koffing.md) | 37 | [Autodestrucción](ataques.md#mv-self-destruct), [Residuos](ataques.md#mv-sludge), [Pantalla de Humo](ataques.md#mv-smokescreen), [Tóxico](ataques.md#mv-toxic) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/110.png" alt="Weezing" width="32" height="32"> [Weezing](pokemon/110-weezing.md) | 43 | [Placaje](ataques.md#mv-tackle), [Residuos](ataques.md#mv-sludge), [Pantalla de Humo](ataques.md#mv-smokescreen), [Tóxico](ataques.md#mv-toxic) | — |

### Sabrina — Saffron City · Gym

- Medalla n.º 6
- Premio: 4300 ₽, <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/tm-psychic.png" alt="MT04" width="24" height="24"> [MT04 (TM04)](mts.md#tm04) (Paz Mental)
- Objetos que usa: Hiperpoción, Hiperpoción, Cura Total

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/64.png" alt="Kadabra" width="32" height="32"> [Kadabra](pokemon/064-kadabra.md) | 38 | [Psicorrayo](ataques.md#mv-psybeam), [Reflejo](ataques.md#mv-reflect), [Premonición](ataques.md#mv-future-sight), [Paz Mental](ataques.md#mv-calm-mind) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/122.png" alt="Mr. Mime" width="32" height="32"> [Mr. Mime](pokemon/122-mr-mime.md) | 37 | [Barrera](ataques.md#mv-barrier), [Psicorrayo](ataques.md#mv-psybeam), [Relevo](ataques.md#mv-baton-pass), [Paz Mental](ataques.md#mv-calm-mind) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/49.png" alt="Venomoth" width="32" height="32"> [Venomoth](pokemon/049-venomoth.md) | 38 | [Psicorrayo](ataques.md#mv-psybeam), [Tornado](ataques.md#mv-gust), [Chupavidas](ataques.md#mv-leech-life), [Supersónico](ataques.md#mv-supersonic) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/65.png" alt="Alakazam" width="32" height="32"> [Alakazam](pokemon/065-alakazam.md) | 43 | [Psíquico](ataques.md#mv-psychic), [Recuperación](ataques.md#mv-recover), [Premonición](ataques.md#mv-future-sight), [Paz Mental](ataques.md#mv-calm-mind) | — |

### Blaine — Cinnabar Island · Gym

- Medalla n.º 7
- Premio: 4700 ₽, <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/tm-fire.png" alt="MT38" width="24" height="24"> [MT38 (TM38)](mts.md#tm38) (Llamarada)
- Objetos que usa: Hiperpoción, Hiperpoción, Cura Total

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/58.png" alt="Growlithe" width="32" height="32"> [Growlithe](pokemon/058-growlithe.md) | 42 | [Mordisco](ataques.md#mv-bite), [Rugido](ataques.md#mv-roar), [Derribo](ataques.md#mv-take-down), [Llamarada](ataques.md#mv-fire-blast) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/77.png" alt="Ponyta" width="32" height="32"> [Ponyta](pokemon/077-ponyta.md) | 40 | [Pisotón](ataques.md#mv-stomp), [Bote](ataques.md#mv-bounce), [Giro Fuego](ataques.md#mv-fire-spin), [Llamarada](ataques.md#mv-fire-blast) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/78.png" alt="Rapidash" width="32" height="32"> [Rapidash](pokemon/078-rapidash.md) | 42 | [Pisotón](ataques.md#mv-stomp), [Bote](ataques.md#mv-bounce), [Giro Fuego](ataques.md#mv-fire-spin), [Llamarada](ataques.md#mv-fire-blast) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/59.png" alt="Arcanine" width="32" height="32"> [Arcanine](pokemon/059-arcanine.md) | 47 | [Mordisco](ataques.md#mv-bite), [Rugido](ataques.md#mv-roar), [Derribo](ataques.md#mv-take-down), [Llamarada](ataques.md#mv-fire-blast) | — |

### Giovanni — Viridian City · Gym

- Medalla n.º 8
- Premio: 5000 ₽, <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/tm-ground.png" alt="MT26" width="24" height="24"> [MT26 (TM26)](mts.md#tm26) (Terremoto)
- Objetos que usa: Hiperpoción, Hiperpoción, Cura Total

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/111.png" alt="Rhyhorn" width="32" height="32"> [Rhyhorn](pokemon/111-rhyhorn.md) | 45 | [Derribo](ataques.md#mv-take-down), [Pedrada](ataques.md#mv-rock-blast), [Cara Susto](ataques.md#mv-scary-face), [Terremoto](ataques.md#mv-earthquake) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/51.png" alt="Dugtrio" width="32" height="32"> [Dugtrio](pokemon/051-dugtrio.md) | 42 | [Cuchillada](ataques.md#mv-slash), [Bucle Arena](ataques.md#mv-sand-tomb), [Bofetón Lodo](ataques.md#mv-mud-slap), [Terremoto](ataques.md#mv-earthquake) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/31.png" alt="Nidoqueen" width="32" height="32"> [Nidoqueen](pokemon/031-nidoqueen.md) | 44 | [Golpe Cuerpo](ataques.md#mv-body-slam), [Doble Patada](ataques.md#mv-double-kick), [Picotazo Veneno](ataques.md#mv-poison-sting), [Terremoto](ataques.md#mv-earthquake) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/34.png" alt="Nidoking" width="32" height="32"> [Nidoking](pokemon/034-nidoking.md) | 45 | [Saña](ataques.md#mv-thrash), [Doble Patada](ataques.md#mv-double-kick), [Picotazo Veneno](ataques.md#mv-poison-sting), [Terremoto](ataques.md#mv-earthquake) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/111.png" alt="Rhyhorn" width="32" height="32"> [Rhyhorn](pokemon/111-rhyhorn.md) | 50 | [Derribo](ataques.md#mv-take-down), [Pedrada](ataques.md#mv-rock-blast), [Cara Susto](ataques.md#mv-scary-face), [Terremoto](ataques.md#mv-earthquake) | — |

## Alto Mando y Campeón

### Lorelei — Pokémon League · Loreleis Room

- Premio: 5400 ₽
- Objetos que usa: Restaurar Todo, Restaurar Todo

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/87.png" alt="Dewgong" width="32" height="32"> [Dewgong](pokemon/087-dewgong.md) | 52 | [Rayo Hielo](ataques.md#mv-ice-beam), [Surf](ataques.md#mv-surf), [Granizo](ataques.md#mv-hail), [Velo Sagrado](ataques.md#mv-safeguard) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/91.png" alt="Cloyster" width="32" height="32"> [Cloyster](pokemon/091-cloyster.md) | 51 | [Púas](ataques.md#mv-spikes), [Protección](ataques.md#mv-protect), [Granizo](ataques.md#mv-hail), [Buceo](ataques.md#mv-dive) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/80.png" alt="Slowbro" width="32" height="32"> [Slowbro](pokemon/080-slowbro.md) | 52 | [Rayo Hielo](ataques.md#mv-ice-beam), [Surf](ataques.md#mv-surf), [Amnesia](ataques.md#mv-amnesia), [Bostezo](ataques.md#mv-yawn) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/124.png" alt="Jynx" width="32" height="32"> [Jynx](pokemon/124-jynx.md) | 54 | [Puño Hielo](ataques.md#mv-ice-punch), [Doble Bofetón](ataques.md#mv-double-slap), [Beso Amoroso](ataques.md#mv-lovely-kiss), [Atracción](ataques.md#mv-attract) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/131.png" alt="Lapras" width="32" height="32"> [Lapras](pokemon/131-lapras.md) | 54 | [Rayo Confuso](ataques.md#mv-confuse-ray), [Rayo Hielo](ataques.md#mv-ice-beam), [Surf](ataques.md#mv-surf), [Golpe Cuerpo](ataques.md#mv-body-slam) | <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/sitrus-berry.png" alt="Baya Zidra" width="24" height="24"> Baya Zidra (Sitrus Berry) |

### Bruno — Pokémon League · Brunos Room

- Premio: 5600 ₽
- Objetos que usa: Restaurar Todo, Restaurar Todo

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/95.png" alt="Onix" width="32" height="32"> [Onix](pokemon/095-onix.md) | 51 | [Terremoto](ataques.md#mv-earthquake), [Tumba Rocas](ataques.md#mv-rock-tomb), [Cola Férrea](ataques.md#mv-iron-tail), [Rugido](ataques.md#mv-roar) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/107.png" alt="Hitmonchan" width="32" height="32"> [Hitmonchan](pokemon/107-hitmonchan.md) | 53 | [Gancho Alto](ataques.md#mv-sky-uppercut), [Ultrapuño](ataques.md#mv-mach-punch), [Tumba Rocas](ataques.md#mv-rock-tomb), [Contraataque](ataques.md#mv-counter) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/106.png" alt="Hitmonlee" width="32" height="32"> [Hitmonlee](pokemon/106-hitmonlee.md) | 53 | [Megapatada](ataques.md#mv-mega-kick), [Profecía](ataques.md#mv-foresight), [Demolición](ataques.md#mv-brick-break), [Fachada](ataques.md#mv-facade) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/95.png" alt="Onix" width="32" height="32"> [Onix](pokemon/095-onix.md) | 54 | [Doble Filo](ataques.md#mv-double-edge), [Terremoto](ataques.md#mv-earthquake), [Cola Férrea](ataques.md#mv-iron-tail), [Bucle Arena](ataques.md#mv-sand-tomb) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/68.png" alt="Machamp" width="32" height="32"> [Machamp](pokemon/068-machamp.md) | 56 | [Tajo Cruzado](ataques.md#mv-cross-chop), [Corpulencia](ataques.md#mv-bulk-up), [Cara Susto](ataques.md#mv-scary-face), [Tumba Rocas](ataques.md#mv-rock-tomb) | <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/sitrus-berry.png" alt="Baya Zidra" width="24" height="24"> Baya Zidra (Sitrus Berry) |

### Agatha — Pokémon League · Agathas Room

- Premio: 5800 ₽
- Objetos que usa: Restaurar Todo, Restaurar Todo

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/94.png" alt="Gengar" width="32" height="32"> [Gengar](pokemon/094-gengar.md) | 54 | [Puño Sombra](ataques.md#mv-shadow-punch), [Rayo Confuso](ataques.md#mv-confuse-ray), [Tóxico](ataques.md#mv-toxic), [Doble Equipo](ataques.md#mv-double-team) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/42.png" alt="Golbat" width="32" height="32"> [Golbat](pokemon/042-golbat.md) | 54 | [Rayo Confuso](ataques.md#mv-confuse-ray), [Colmillo Veneno](ataques.md#mv-poison-fang), [Aire Afilado](ataques.md#mv-air-cutter), [Mordisco](ataques.md#mv-bite) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/93.png" alt="Haunter" width="32" height="32"> [Haunter](pokemon/093-haunter.md) | 53 | [Hipnosis](ataques.md#mv-hypnosis), [Comesueños](ataques.md#mv-dream-eater), [Maldición](ataques.md#mv-curse), [Mal de Ojo](ataques.md#mv-mean-look) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/24.png" alt="Arbok" width="32" height="32"> [Arbok](pokemon/024-arbok.md) | 56 | [Bomba Lodo](ataques.md#mv-sludge-bomb), [Chirrido](ataques.md#mv-screech), [Cola Férrea](ataques.md#mv-iron-tail), [Mordisco](ataques.md#mv-bite) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/94.png" alt="Gengar" width="32" height="32"> [Gengar](pokemon/094-gengar.md) | 58 | [Bola Sombra](ataques.md#mv-shadow-ball), [Bomba Lodo](ataques.md#mv-sludge-bomb), [Hipnosis](ataques.md#mv-hypnosis), [Pesadilla](ataques.md#mv-nightmare) | <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/sitrus-berry.png" alt="Baya Zidra" width="24" height="24"> Baya Zidra (Sitrus Berry) |

### Lance — Pokémon League · Lances Room

- Premio: 6000 ₽
- Objetos que usa: Restaurar Todo, Restaurar Todo

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/130.png" alt="Gyarados" width="32" height="32"> [Gyarados](pokemon/130-gyarados.md) | 56 | [Hiperrayo](ataques.md#mv-hyper-beam), [Furia Dragón](ataques.md#mv-dragon-rage), [Ciclón](ataques.md#mv-twister), [Mordisco](ataques.md#mv-bite) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/148.png" alt="Dragonair" width="32" height="32"> [Dragonair](pokemon/148-dragonair.md) | 54 | [Hiperrayo](ataques.md#mv-hyper-beam), [Velo Sagrado](ataques.md#mv-safeguard), [Furia Dragón](ataques.md#mv-dragon-rage), [Enfado](ataques.md#mv-outrage) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/148.png" alt="Dragonair" width="32" height="32"> [Dragonair](pokemon/148-dragonair.md) | 54 | [Hiperrayo](ataques.md#mv-hyper-beam), [Velo Sagrado](ataques.md#mv-safeguard), [Onda Trueno](ataques.md#mv-thunder-wave), [Enfado](ataques.md#mv-outrage) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/142.png" alt="Aerodactyl" width="32" height="32"> [Aerodactyl](pokemon/142-aerodactyl.md) | 58 | [Hiperrayo](ataques.md#mv-hyper-beam), [Poder Pasado](ataques.md#mv-ancient-power), [Ataque Ala](ataques.md#mv-wing-attack), [Cara Susto](ataques.md#mv-scary-face) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/149.png" alt="Dragonite" width="32" height="32"> [Dragonite](pokemon/149-dragonite.md) | 60 | [Hiperrayo](ataques.md#mv-hyper-beam), [Velo Sagrado](ataques.md#mv-safeguard), [Enfado](ataques.md#mv-outrage), [Ataque Ala](ataques.md#mv-wing-attack) | <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/sitrus-berry.png" alt="Baya Zidra" width="24" height="24"> Baya Zidra (Sitrus Berry) |

### Lorelei (revancha) — Pokémon League · Loreleis Room

- Premio: 6600 ₽
- Objetos que usa: Restaurar Todo, Restaurar Todo

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/87.png" alt="Dewgong" width="32" height="32"> [Dewgong](pokemon/087-dewgong.md) | 64 | [Rayo Hielo](ataques.md#mv-ice-beam), [Surf](ataques.md#mv-surf), [Rayo Señal](ataques.md#mv-signal-beam), [Doble Equipo](ataques.md#mv-double-team) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/91.png" alt="Cloyster" width="32" height="32"> [Cloyster](pokemon/091-cloyster.md) | 63 | [Rayo Hielo](ataques.md#mv-ice-beam), [Surf](ataques.md#mv-surf), [Supersónico](ataques.md#mv-supersonic), [Danza Lluvia](ataques.md#mv-rain-dance) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/221.png" alt="Piloswine" width="32" height="32"> [Piloswine](pokemon/221-piloswine.md) | 63 | [Ventisca](ataques.md#mv-blizzard), [Terremoto](ataques.md#mv-earthquake), [Doble Filo](ataques.md#mv-double-edge), [Avalancha](ataques.md#mv-rock-slide) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/124.png" alt="Jynx" width="32" height="32"> [Jynx](pokemon/124-jynx.md) | 66 | [Rayo Hielo](ataques.md#mv-ice-beam), [Psíquico](ataques.md#mv-psychic), [Beso Amoroso](ataques.md#mv-lovely-kiss), [Atracción](ataques.md#mv-attract) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/131.png" alt="Lapras" width="32" height="32"> [Lapras](pokemon/131-lapras.md) | 66 | [Rayo Hielo](ataques.md#mv-ice-beam), [Surf](ataques.md#mv-surf), [Psíquico](ataques.md#mv-psychic), [Trueno](ataques.md#mv-thunder) | <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/cheri-berry.png" alt="Baya Zreza" width="24" height="24"> Baya Zreza (Cheri Berry) |

### Bruno (revancha) — Pokémon League · Brunos Room

- Premio: 6800 ₽
- Objetos que usa: Restaurar Todo, Restaurar Todo

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/208.png" alt="Steelix" width="32" height="32"> [Steelix](pokemon/208-steelix.md) | 65 | [Terremoto](ataques.md#mv-earthquake), [Cola Férrea](ataques.md#mv-iron-tail), [Triturar](ataques.md#mv-crunch), [Tumba Rocas](ataques.md#mv-rock-tomb) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/107.png" alt="Hitmonchan" width="32" height="32"> [Hitmonchan](pokemon/107-hitmonchan.md) | 65 | [Gancho Alto](ataques.md#mv-sky-uppercut), [Ultrapuño](ataques.md#mv-mach-punch), [Avalancha](ataques.md#mv-rock-slide), [Contraataque](ataques.md#mv-counter) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/106.png" alt="Hitmonlee" width="32" height="32"> [Hitmonlee](pokemon/106-hitmonlee.md) | 65 | [Megapatada](ataques.md#mv-mega-kick), [Profecía](ataques.md#mv-foresight), [Terremoto](ataques.md#mv-earthquake), [Avalancha](ataques.md#mv-rock-slide) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/208.png" alt="Steelix" width="32" height="32"> [Steelix](pokemon/208-steelix.md) | 66 | [Terremoto](ataques.md#mv-earthquake), [Cola Férrea](ataques.md#mv-iron-tail), [Triturar](ataques.md#mv-crunch), [Dragoaliento](ataques.md#mv-dragon-breath) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/68.png" alt="Machamp" width="32" height="32"> [Machamp](pokemon/068-machamp.md) | 68 | [Tajo Cruzado](ataques.md#mv-cross-chop), [Terremoto](ataques.md#mv-earthquake), [Demolición](ataques.md#mv-brick-break), [Avalancha](ataques.md#mv-rock-slide) | <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/persim-berry.png" alt="Baya Caquic" width="24" height="24"> Baya Caquic (Persim Berry) |

### Agatha (revancha) — Pokémon League · Agathas Room

- Premio: 7000 ₽
- Objetos que usa: Restaurar Todo, Restaurar Todo

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/94.png" alt="Gengar" width="32" height="32"> [Gengar](pokemon/094-gengar.md) | 66 | [Bola Sombra](ataques.md#mv-shadow-ball), [Psíquico](ataques.md#mv-psychic), [Rayo Confuso](ataques.md#mv-confuse-ray), [Hipnosis](ataques.md#mv-hypnosis) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/169.png" alt="Crobat" width="32" height="32"> [Crobat](pokemon/169-crobat.md) | 66 | [Bomba Lodo](ataques.md#mv-sludge-bomb), [Aire Afilado](ataques.md#mv-air-cutter), [Bola Sombra](ataques.md#mv-shadow-ball), [Rayo Confuso](ataques.md#mv-confuse-ray) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/200.png" alt="Misdreavus" width="32" height="32"> [Misdreavus](pokemon/200-misdreavus.md) | 65 | [Bola Sombra](ataques.md#mv-shadow-ball), [Psíquico](ataques.md#mv-psychic), [Rayo](ataques.md#mv-thunderbolt), [Atracción](ataques.md#mv-attract) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/24.png" alt="Arbok" width="32" height="32"> [Arbok](pokemon/024-arbok.md) | 68 | [Bomba Lodo](ataques.md#mv-sludge-bomb), [Terremoto](ataques.md#mv-earthquake), [Gigadrenado](ataques.md#mv-giga-drain), [Doble Equipo](ataques.md#mv-double-team) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/94.png" alt="Gengar" width="32" height="32"> [Gengar](pokemon/094-gengar.md) | 70 | [Bola Sombra](ataques.md#mv-shadow-ball), [Psíquico](ataques.md#mv-psychic), [Rayo](ataques.md#mv-thunderbolt), [Bomba Lodo](ataques.md#mv-sludge-bomb) | <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/chesto-berry.png" alt="Baya Atania" width="24" height="24"> Baya Atania (Chesto Berry) |

### Lance (revancha) — Pokémon League · Lances Room

- Premio: 7200 ₽
- Objetos que usa: Restaurar Todo, Restaurar Todo

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/130.png" alt="Gyarados" width="32" height="32"> [Gyarados](pokemon/130-gyarados.md) | 68 | [Hiperrayo](ataques.md#mv-hyper-beam), [Danza Dragón](ataques.md#mv-dragon-dance), [Terremoto](ataques.md#mv-earthquake), [Onda Trueno](ataques.md#mv-thunder-wave) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/149.png" alt="Dragonite" width="32" height="32"> [Dragonite](pokemon/149-dragonite.md) | 66 | [Hiperrayo](ataques.md#mv-hyper-beam), [Terremoto](ataques.md#mv-earthquake), [Garra Dragón](ataques.md#mv-dragon-claw), [Lanzallamas](ataques.md#mv-flamethrower) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/230.png" alt="Kingdra" width="32" height="32"> [Kingdra](pokemon/230-kingdra.md) | 66 | [Hiperrayo](ataques.md#mv-hyper-beam), [Danza Dragón](ataques.md#mv-dragon-dance), [Surf](ataques.md#mv-surf), [Rayo Hielo](ataques.md#mv-ice-beam) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/142.png" alt="Aerodactyl" width="32" height="32"> [Aerodactyl](pokemon/142-aerodactyl.md) | 70 | [Hiperrayo](ataques.md#mv-hyper-beam), [Poder Pasado](ataques.md#mv-ancient-power), [Golpe Aéreo](ataques.md#mv-aerial-ace), [Terremoto](ataques.md#mv-earthquake) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/149.png" alt="Dragonite" width="32" height="32"> [Dragonite](pokemon/149-dragonite.md) | 72 | [Hiperrayo](ataques.md#mv-hyper-beam), [Enfado](ataques.md#mv-outrage), [Rayo](ataques.md#mv-thunderbolt), [Rayo Hielo](ataques.md#mv-ice-beam) | <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/persim-berry.png" alt="Baya Caquic" width="24" height="24"> Baya Caquic (Persim Berry) |

### Campeón: tu rival (en pret, Terry), su inicial: Squirtle — Pokémon League · Champions Room

- Premio: 6300 ₽
- Objetos que usa: Restaurar Todo, Restaurar Todo, Restaurar Todo, Restaurar Todo

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/18.png" alt="Pidgeot" width="32" height="32"> [Pidgeot](pokemon/018-pidgeot.md) | 59 | [Golpe Aéreo](ataques.md#mv-aerial-ace), [Danza Pluma](ataques.md#mv-feather-dance), [Ataque Arena](ataques.md#mv-sand-attack), [Remolino](ataques.md#mv-whirlwind) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/65.png" alt="Alakazam" width="32" height="32"> [Alakazam](pokemon/065-alakazam.md) | 57 | [Psíquico](ataques.md#mv-psychic), [Premonición](ataques.md#mv-future-sight), [Recuperación](ataques.md#mv-recover), [Reflejo](ataques.md#mv-reflect) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/112.png" alt="Rhydon" width="32" height="32"> [Rhydon](pokemon/112-rhydon.md) | 59 | [Derribo](ataques.md#mv-take-down), [Terremoto](ataques.md#mv-earthquake), [Tumba Rocas](ataques.md#mv-rock-tomb), [Cara Susto](ataques.md#mv-scary-face) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/59.png" alt="Arcanine" width="32" height="32"> [Arcanine](pokemon/059-arcanine.md) | 59 | [Velocidad Extrema](ataques.md#mv-extreme-speed), [Lanzallamas](ataques.md#mv-flamethrower), [Rugido](ataques.md#mv-roar), [Mordisco](ataques.md#mv-bite) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/103.png" alt="Exeggutor" width="32" height="32"> [Exeggutor](pokemon/103-exeggutor.md) | 61 | [Gigadrenado](ataques.md#mv-giga-drain), [Bomba Huevo](ataques.md#mv-egg-bomb), [Somnífero](ataques.md#mv-sleep-powder), [Pantalla de Luz](ataques.md#mv-light-screen) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/9.png" alt="Blastoise" width="32" height="32"> [Blastoise](pokemon/009-blastoise.md) | 63 | [Hidrobomba](ataques.md#mv-hydro-pump), [Danza Lluvia](ataques.md#mv-rain-dance), [Cabezazo](ataques.md#mv-skull-bash), [Mordisco](ataques.md#mv-bite) | <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/sitrus-berry.png" alt="Baya Zidra" width="24" height="24"> Baya Zidra (Sitrus Berry) |

### Campeón: tu rival (en pret, Terry), su inicial: Bulbasaur — Pokémon League · Champions Room

- Premio: 6300 ₽
- Objetos que usa: Restaurar Todo, Restaurar Todo, Restaurar Todo, Restaurar Todo

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/18.png" alt="Pidgeot" width="32" height="32"> [Pidgeot](pokemon/018-pidgeot.md) | 59 | [Golpe Aéreo](ataques.md#mv-aerial-ace), [Danza Pluma](ataques.md#mv-feather-dance), [Ataque Arena](ataques.md#mv-sand-attack), [Remolino](ataques.md#mv-whirlwind) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/65.png" alt="Alakazam" width="32" height="32"> [Alakazam](pokemon/065-alakazam.md) | 57 | [Psíquico](ataques.md#mv-psychic), [Premonición](ataques.md#mv-future-sight), [Recuperación](ataques.md#mv-recover), [Reflejo](ataques.md#mv-reflect) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/112.png" alt="Rhydon" width="32" height="32"> [Rhydon](pokemon/112-rhydon.md) | 59 | [Derribo](ataques.md#mv-take-down), [Terremoto](ataques.md#mv-earthquake), [Tumba Rocas](ataques.md#mv-rock-tomb), [Cara Susto](ataques.md#mv-scary-face) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/130.png" alt="Gyarados" width="32" height="32"> [Gyarados](pokemon/130-gyarados.md) | 59 | [Hidrobomba](ataques.md#mv-hydro-pump), [Furia Dragón](ataques.md#mv-dragon-rage), [Mordisco](ataques.md#mv-bite), [Saña](ataques.md#mv-thrash) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/59.png" alt="Arcanine" width="32" height="32"> [Arcanine](pokemon/059-arcanine.md) | 61 | [Velocidad Extrema](ataques.md#mv-extreme-speed), [Lanzallamas](ataques.md#mv-flamethrower), [Rugido](ataques.md#mv-roar), [Mordisco](ataques.md#mv-bite) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/3.png" alt="Venusaur" width="32" height="32"> [Venusaur](pokemon/003-venusaur.md) | 63 | [Rayo Solar](ataques.md#mv-solar-beam), [Fotosíntesis](ataques.md#mv-synthesis), [Día Soleado](ataques.md#mv-sunny-day), [Desarrollo](ataques.md#mv-growth) | <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/sitrus-berry.png" alt="Baya Zidra" width="24" height="24"> Baya Zidra (Sitrus Berry) |

### Campeón: tu rival (en pret, Terry), su inicial: Charmander — Pokémon League · Champions Room

- Premio: 6300 ₽
- Objetos que usa: Restaurar Todo, Restaurar Todo, Restaurar Todo, Restaurar Todo

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/18.png" alt="Pidgeot" width="32" height="32"> [Pidgeot](pokemon/018-pidgeot.md) | 59 | [Golpe Aéreo](ataques.md#mv-aerial-ace), [Danza Pluma](ataques.md#mv-feather-dance), [Ataque Arena](ataques.md#mv-sand-attack), [Remolino](ataques.md#mv-whirlwind) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/65.png" alt="Alakazam" width="32" height="32"> [Alakazam](pokemon/065-alakazam.md) | 57 | [Psíquico](ataques.md#mv-psychic), [Premonición](ataques.md#mv-future-sight), [Recuperación](ataques.md#mv-recover), [Reflejo](ataques.md#mv-reflect) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/112.png" alt="Rhydon" width="32" height="32"> [Rhydon](pokemon/112-rhydon.md) | 59 | [Derribo](ataques.md#mv-take-down), [Terremoto](ataques.md#mv-earthquake), [Tumba Rocas](ataques.md#mv-rock-tomb), [Cara Susto](ataques.md#mv-scary-face) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/103.png" alt="Exeggutor" width="32" height="32"> [Exeggutor](pokemon/103-exeggutor.md) | 59 | [Gigadrenado](ataques.md#mv-giga-drain), [Bomba Huevo](ataques.md#mv-egg-bomb), [Somnífero](ataques.md#mv-sleep-powder), [Pantalla de Luz](ataques.md#mv-light-screen) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/130.png" alt="Gyarados" width="32" height="32"> [Gyarados](pokemon/130-gyarados.md) | 61 | [Hidrobomba](ataques.md#mv-hydro-pump), [Furia Dragón](ataques.md#mv-dragon-rage), [Mordisco](ataques.md#mv-bite), [Saña](ataques.md#mv-thrash) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/6.png" alt="Charizard" width="32" height="32"> [Charizard](pokemon/006-charizard.md) | 63 | [Llamarada](ataques.md#mv-fire-blast), [Golpe Aéreo](ataques.md#mv-aerial-ace), [Cuchillada](ataques.md#mv-slash), [Giro Fuego](ataques.md#mv-fire-spin) | <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/sitrus-berry.png" alt="Baya Zidra" width="24" height="24"> Baya Zidra (Sitrus Berry) |

### Campeón: tu rival (en pret, Terry), su inicial: Squirtle (revancha) — Pokémon League · Champions Room

- Premio: 7500 ₽
- Objetos que usa: Restaurar Todo, Restaurar Todo, Restaurar Todo, Restaurar Todo

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/214.png" alt="Heracross" width="32" height="32"> [Heracross](pokemon/214-heracross.md) | 72 | [Megacuerno](ataques.md#mv-megahorn), [Terremoto](ataques.md#mv-earthquake), [Contraataque](ataques.md#mv-counter), [Tumba Rocas](ataques.md#mv-rock-tomb) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/65.png" alt="Alakazam" width="32" height="32"> [Alakazam](pokemon/065-alakazam.md) | 73 | [Psíquico](ataques.md#mv-psychic), [Bola Sombra](ataques.md#mv-shadow-ball), [Paz Mental](ataques.md#mv-calm-mind), [Reflejo](ataques.md#mv-reflect) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/248.png" alt="Tyranitar" width="32" height="32"> [Tyranitar](pokemon/248-tyranitar.md) | 72 | [Triturar](ataques.md#mv-crunch), [Terremoto](ataques.md#mv-earthquake), [Rayo](ataques.md#mv-thunderbolt), [Golpe Aéreo](ataques.md#mv-aerial-ace) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/59.png" alt="Arcanine" width="32" height="32"> [Arcanine](pokemon/059-arcanine.md) | 73 | [Velocidad Extrema](ataques.md#mv-extreme-speed), [Sofoco](ataques.md#mv-overheat), [Golpe Aéreo](ataques.md#mv-aerial-ace), [Cola Férrea](ataques.md#mv-iron-tail) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/103.png" alt="Exeggutor" width="32" height="32"> [Exeggutor](pokemon/103-exeggutor.md) | 73 | [Gigadrenado](ataques.md#mv-giga-drain), [Psíquico](ataques.md#mv-psychic), [Somnífero](ataques.md#mv-sleep-powder), [Pantalla de Luz](ataques.md#mv-light-screen) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/9.png" alt="Blastoise" width="32" height="32"> [Blastoise](pokemon/009-blastoise.md) | 75 | [Hidrobomba](ataques.md#mv-hydro-pump), [Rayo Hielo](ataques.md#mv-ice-beam), [Terremoto](ataques.md#mv-earthquake), [Danza Lluvia](ataques.md#mv-rain-dance) | <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/sitrus-berry.png" alt="Baya Zidra" width="24" height="24"> Baya Zidra (Sitrus Berry) |

### Campeón: tu rival (en pret, Terry), su inicial: Bulbasaur (revancha) — Pokémon League · Champions Room

- Premio: 7500 ₽
- Objetos que usa: Restaurar Todo, Restaurar Todo, Restaurar Todo, Restaurar Todo

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/214.png" alt="Heracross" width="32" height="32"> [Heracross](pokemon/214-heracross.md) | 72 | [Megacuerno](ataques.md#mv-megahorn), [Terremoto](ataques.md#mv-earthquake), [Contraataque](ataques.md#mv-counter), [Tumba Rocas](ataques.md#mv-rock-tomb) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/65.png" alt="Alakazam" width="32" height="32"> [Alakazam](pokemon/065-alakazam.md) | 73 | [Psíquico](ataques.md#mv-psychic), [Bola Sombra](ataques.md#mv-shadow-ball), [Paz Mental](ataques.md#mv-calm-mind), [Reflejo](ataques.md#mv-reflect) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/248.png" alt="Tyranitar" width="32" height="32"> [Tyranitar](pokemon/248-tyranitar.md) | 72 | [Triturar](ataques.md#mv-crunch), [Terremoto](ataques.md#mv-earthquake), [Rayo](ataques.md#mv-thunderbolt), [Golpe Aéreo](ataques.md#mv-aerial-ace) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/130.png" alt="Gyarados" width="32" height="32"> [Gyarados](pokemon/130-gyarados.md) | 73 | [Hidrobomba](ataques.md#mv-hydro-pump), [Danza Dragón](ataques.md#mv-dragon-dance), [Terremoto](ataques.md#mv-earthquake), [Hiperrayo](ataques.md#mv-hyper-beam) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/59.png" alt="Arcanine" width="32" height="32"> [Arcanine](pokemon/059-arcanine.md) | 73 | [Velocidad Extrema](ataques.md#mv-extreme-speed), [Sofoco](ataques.md#mv-overheat), [Golpe Aéreo](ataques.md#mv-aerial-ace), [Cola Férrea](ataques.md#mv-iron-tail) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/3.png" alt="Venusaur" width="32" height="32"> [Venusaur](pokemon/003-venusaur.md) | 75 | [Rayo Solar](ataques.md#mv-solar-beam), [Bomba Lodo](ataques.md#mv-sludge-bomb), [Terremoto](ataques.md#mv-earthquake), [Día Soleado](ataques.md#mv-sunny-day) | <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/sitrus-berry.png" alt="Baya Zidra" width="24" height="24"> Baya Zidra (Sitrus Berry) |

### Campeón: tu rival (en pret, Terry), su inicial: Charmander (revancha) — Pokémon League · Champions Room

- Premio: 7500 ₽
- Objetos que usa: Restaurar Todo, Restaurar Todo, Restaurar Todo, Restaurar Todo

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/214.png" alt="Heracross" width="32" height="32"> [Heracross](pokemon/214-heracross.md) | 72 | [Megacuerno](ataques.md#mv-megahorn), [Terremoto](ataques.md#mv-earthquake), [Contraataque](ataques.md#mv-counter), [Tumba Rocas](ataques.md#mv-rock-tomb) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/65.png" alt="Alakazam" width="32" height="32"> [Alakazam](pokemon/065-alakazam.md) | 73 | [Psíquico](ataques.md#mv-psychic), [Bola Sombra](ataques.md#mv-shadow-ball), [Paz Mental](ataques.md#mv-calm-mind), [Reflejo](ataques.md#mv-reflect) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/248.png" alt="Tyranitar" width="32" height="32"> [Tyranitar](pokemon/248-tyranitar.md) | 72 | [Triturar](ataques.md#mv-crunch), [Terremoto](ataques.md#mv-earthquake), [Rayo](ataques.md#mv-thunderbolt), [Golpe Aéreo](ataques.md#mv-aerial-ace) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/103.png" alt="Exeggutor" width="32" height="32"> [Exeggutor](pokemon/103-exeggutor.md) | 73 | [Gigadrenado](ataques.md#mv-giga-drain), [Psíquico](ataques.md#mv-psychic), [Somnífero](ataques.md#mv-sleep-powder), [Pantalla de Luz](ataques.md#mv-light-screen) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/130.png" alt="Gyarados" width="32" height="32"> [Gyarados](pokemon/130-gyarados.md) | 73 | [Hidrobomba](ataques.md#mv-hydro-pump), [Danza Dragón](ataques.md#mv-dragon-dance), [Terremoto](ataques.md#mv-earthquake), [Hiperrayo](ataques.md#mv-hyper-beam) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/6.png" alt="Charizard" width="32" height="32"> [Charizard](pokemon/006-charizard.md) | 75 | [Llamarada](ataques.md#mv-fire-blast), [Garra Dragón](ataques.md#mv-dragon-claw), [Golpe Aéreo](ataques.md#mv-aerial-ace), [Terremoto](ataques.md#mv-earthquake) | <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/sitrus-berry.png" alt="Baya Zidra" width="24" height="24"> Baya Zidra (Sitrus Berry) |

## Rival

Su equipo depende de su inicial (el que tiene ventaja sobre el tuyo).

### Combate 1 — Pallet Town · Professor Oaks Lab

`TRAINER_RIVAL_OAKS_LAB_*`

**Su inicial: Squirtle** — premio 80 ₽

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/7.png" alt="Squirtle" width="32" height="32"> [Squirtle](pokemon/007-squirtle.md) | 5 | [Placaje](ataques.md#mv-tackle), [Agitacola](ataques.md#mv-tail-whip) *(por defecto)* | — |

**Su inicial: Bulbasaur** — premio 80 ₽

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/1.png" alt="Bulbasaur" width="32" height="32"> [Bulbasaur](pokemon/001-bulbasaur.md) | 5 | [Placaje](ataques.md#mv-tackle), [Gruñido](ataques.md#mv-growl) *(por defecto)* | — |

**Su inicial: Charmander** — premio 80 ₽

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/4.png" alt="Charmander" width="32" height="32"> [Charmander](pokemon/004-charmander.md) | 5 | [Arañazo](ataques.md#mv-scratch), [Gruñido](ataques.md#mv-growl) *(por defecto)* | — |

### Combate 2 — Route 22

`TRAINER_RIVAL_ROUTE22_EARLY_*`

**Su inicial: Squirtle** — premio 144 ₽

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/16.png" alt="Pidgey" width="32" height="32"> [Pidgey](pokemon/016-pidgey.md) | 9 | [Placaje](ataques.md#mv-tackle), [Ataque Arena](ataques.md#mv-sand-attack) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/7.png" alt="Squirtle" width="32" height="32"> [Squirtle](pokemon/007-squirtle.md) | 9 | [Placaje](ataques.md#mv-tackle), [Agitacola](ataques.md#mv-tail-whip) | — |

**Su inicial: Bulbasaur** — premio 144 ₽

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/16.png" alt="Pidgey" width="32" height="32"> [Pidgey](pokemon/016-pidgey.md) | 9 | [Placaje](ataques.md#mv-tackle), [Ataque Arena](ataques.md#mv-sand-attack) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/1.png" alt="Bulbasaur" width="32" height="32"> [Bulbasaur](pokemon/001-bulbasaur.md) | 9 | [Placaje](ataques.md#mv-tackle), [Gruñido](ataques.md#mv-growl) | — |

**Su inicial: Charmander** — premio 144 ₽

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/16.png" alt="Pidgey" width="32" height="32"> [Pidgey](pokemon/016-pidgey.md) | 9 | [Placaje](ataques.md#mv-tackle), [Ataque Arena](ataques.md#mv-sand-attack) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/4.png" alt="Charmander" width="32" height="32"> [Charmander](pokemon/004-charmander.md) | 9 | [Arañazo](ataques.md#mv-scratch), [Gruñido](ataques.md#mv-growl) | — |

### Combate 3 — Cerulean City

`TRAINER_RIVAL_CERULEAN_*`

**Su inicial: Squirtle** — premio 288 ₽

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/17.png" alt="Pidgeotto" width="32" height="32"> [Pidgeotto](pokemon/017-pidgeotto.md) | 17 | [Placaje](ataques.md#mv-tackle), [Ataque Arena](ataques.md#mv-sand-attack), [Tornado](ataques.md#mv-gust), [Ataque Rápido](ataques.md#mv-quick-attack) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/63.png" alt="Abra" width="32" height="32"> [Abra](pokemon/063-abra.md) | 16 | [Teletransporte](ataques.md#mv-teleport) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/19.png" alt="Rattata" width="32" height="32"> [Rattata](pokemon/019-rattata.md) | 15 | [Placaje](ataques.md#mv-tackle), [Agitacola](ataques.md#mv-tail-whip), [Ataque Rápido](ataques.md#mv-quick-attack) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/7.png" alt="Squirtle" width="32" height="32"> [Squirtle](pokemon/007-squirtle.md) | 18 | [Placaje](ataques.md#mv-tackle), [Agitacola](ataques.md#mv-tail-whip), [Refugio](ataques.md#mv-withdraw), [Pistola Agua](ataques.md#mv-water-gun) | — |

**Su inicial: Bulbasaur** — premio 288 ₽

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/17.png" alt="Pidgeotto" width="32" height="32"> [Pidgeotto](pokemon/017-pidgeotto.md) | 17 | [Placaje](ataques.md#mv-tackle), [Ataque Arena](ataques.md#mv-sand-attack), [Tornado](ataques.md#mv-gust), [Ataque Rápido](ataques.md#mv-quick-attack) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/63.png" alt="Abra" width="32" height="32"> [Abra](pokemon/063-abra.md) | 16 | [Teletransporte](ataques.md#mv-teleport) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/19.png" alt="Rattata" width="32" height="32"> [Rattata](pokemon/019-rattata.md) | 15 | [Placaje](ataques.md#mv-tackle), [Agitacola](ataques.md#mv-tail-whip), [Ataque Rápido](ataques.md#mv-quick-attack) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/1.png" alt="Bulbasaur" width="32" height="32"> [Bulbasaur](pokemon/001-bulbasaur.md) | 18 | [Somnífero](ataques.md#mv-sleep-powder), [Polvo Veneno](ataques.md#mv-poison-powder), [Látigo Cepa](ataques.md#mv-vine-whip), [Drenadoras](ataques.md#mv-leech-seed) | — |

**Su inicial: Charmander** — premio 288 ₽

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/17.png" alt="Pidgeotto" width="32" height="32"> [Pidgeotto](pokemon/017-pidgeotto.md) | 17 | [Placaje](ataques.md#mv-tackle), [Ataque Arena](ataques.md#mv-sand-attack), [Tornado](ataques.md#mv-gust), [Ataque Rápido](ataques.md#mv-quick-attack) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/63.png" alt="Abra" width="32" height="32"> [Abra](pokemon/063-abra.md) | 16 | [Teletransporte](ataques.md#mv-teleport) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/19.png" alt="Rattata" width="32" height="32"> [Rattata](pokemon/019-rattata.md) | 15 | [Placaje](ataques.md#mv-tackle), [Agitacola](ataques.md#mv-tail-whip), [Ataque Rápido](ataques.md#mv-quick-attack) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/4.png" alt="Charmander" width="32" height="32"> [Charmander](pokemon/004-charmander.md) | 18 | [Garra Metal](ataques.md#mv-metal-claw), [Ascuas](ataques.md#mv-ember), [Gruñido](ataques.md#mv-growl), [Arañazo](ataques.md#mv-scratch) | — |

### Combate 4 — S.S. Anne · 2F Corridor

`TRAINER_RIVAL_SS_ANNE_*`

**Su inicial: Squirtle** — premio 720 ₽

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/17.png" alt="Pidgeotto" width="32" height="32"> [Pidgeotto](pokemon/017-pidgeotto.md) | 19 | [Placaje](ataques.md#mv-tackle), [Ataque Arena](ataques.md#mv-sand-attack), [Tornado](ataques.md#mv-gust), [Ataque Rápido](ataques.md#mv-quick-attack) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/20.png" alt="Raticate" width="32" height="32"> [Raticate](pokemon/020-raticate.md) | 16 | [Placaje](ataques.md#mv-tackle), [Agitacola](ataques.md#mv-tail-whip), [Ataque Rápido](ataques.md#mv-quick-attack), [Hipercolmillo](ataques.md#mv-hyper-fang) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/64.png" alt="Kadabra" width="32" height="32"> [Kadabra](pokemon/064-kadabra.md) | 18 | [Teletransporte](ataques.md#mv-teleport), [Kinético](ataques.md#mv-kinesis), [Confusión](ataques.md#mv-confusion), [Anulación](ataques.md#mv-disable) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/8.png" alt="Wartortle" width="32" height="32"> [Wartortle](pokemon/008-wartortle.md) | 20 | [Burbuja](ataques.md#mv-bubble), [Refugio](ataques.md#mv-withdraw), [Pistola Agua](ataques.md#mv-water-gun), [Mordisco](ataques.md#mv-bite) *(por defecto)* | — |

**Su inicial: Bulbasaur** — premio 720 ₽

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/17.png" alt="Pidgeotto" width="32" height="32"> [Pidgeotto](pokemon/017-pidgeotto.md) | 19 | [Placaje](ataques.md#mv-tackle), [Ataque Arena](ataques.md#mv-sand-attack), [Tornado](ataques.md#mv-gust), [Ataque Rápido](ataques.md#mv-quick-attack) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/20.png" alt="Raticate" width="32" height="32"> [Raticate](pokemon/020-raticate.md) | 16 | [Placaje](ataques.md#mv-tackle), [Agitacola](ataques.md#mv-tail-whip), [Ataque Rápido](ataques.md#mv-quick-attack), [Hipercolmillo](ataques.md#mv-hyper-fang) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/64.png" alt="Kadabra" width="32" height="32"> [Kadabra](pokemon/064-kadabra.md) | 18 | [Teletransporte](ataques.md#mv-teleport), [Kinético](ataques.md#mv-kinesis), [Confusión](ataques.md#mv-confusion), [Anulación](ataques.md#mv-disable) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/2.png" alt="Ivysaur" width="32" height="32"> [Ivysaur](pokemon/002-ivysaur.md) | 20 | [Drenadoras](ataques.md#mv-leech-seed), [Látigo Cepa](ataques.md#mv-vine-whip), [Polvo Veneno](ataques.md#mv-poison-powder), [Somnífero](ataques.md#mv-sleep-powder) *(por defecto)* | — |

**Su inicial: Charmander** — premio 720 ₽

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/17.png" alt="Pidgeotto" width="32" height="32"> [Pidgeotto](pokemon/017-pidgeotto.md) | 19 | [Placaje](ataques.md#mv-tackle), [Ataque Arena](ataques.md#mv-sand-attack), [Tornado](ataques.md#mv-gust), [Ataque Rápido](ataques.md#mv-quick-attack) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/20.png" alt="Raticate" width="32" height="32"> [Raticate](pokemon/020-raticate.md) | 16 | [Placaje](ataques.md#mv-tackle), [Agitacola](ataques.md#mv-tail-whip), [Ataque Rápido](ataques.md#mv-quick-attack), [Hipercolmillo](ataques.md#mv-hyper-fang) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/64.png" alt="Kadabra" width="32" height="32"> [Kadabra](pokemon/064-kadabra.md) | 18 | [Teletransporte](ataques.md#mv-teleport), [Kinético](ataques.md#mv-kinesis), [Confusión](ataques.md#mv-confusion), [Anulación](ataques.md#mv-disable) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/5.png" alt="Charmeleon" width="32" height="32"> [Charmeleon](pokemon/005-charmeleon.md) | 20 | [Gruñido](ataques.md#mv-growl), [Ascuas](ataques.md#mv-ember), [Garra Metal](ataques.md#mv-metal-claw), [Pantalla de Humo](ataques.md#mv-smokescreen) *(por defecto)* | — |

### Combate 5 — Pokémon Tower · 2F

`TRAINER_RIVAL_POKEMON_TOWER_*`

**Su inicial: Squirtle** — premio 900 ₽

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/17.png" alt="Pidgeotto" width="32" height="32"> [Pidgeotto](pokemon/017-pidgeotto.md) | 25 | [Ataque Arena](ataques.md#mv-sand-attack), [Tornado](ataques.md#mv-gust), [Ataque Rápido](ataques.md#mv-quick-attack), [Remolino](ataques.md#mv-whirlwind) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/58.png" alt="Growlithe" width="32" height="32"> [Growlithe](pokemon/058-growlithe.md) | 23 | [Rugido](ataques.md#mv-roar), [Ascuas](ataques.md#mv-ember), [Malicioso](ataques.md#mv-leer), [Rastreo](ataques.md#mv-odor-sleuth) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/102.png" alt="Exeggcute" width="32" height="32"> [Exeggcute](pokemon/102-exeggcute.md) | 22 | [Hipnosis](ataques.md#mv-hypnosis), [Reflejo](ataques.md#mv-reflect), [Drenadoras](ataques.md#mv-leech-seed), [Confusión](ataques.md#mv-confusion) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/64.png" alt="Kadabra" width="32" height="32"> [Kadabra](pokemon/064-kadabra.md) | 20 | [Teletransporte](ataques.md#mv-teleport), [Kinético](ataques.md#mv-kinesis), [Confusión](ataques.md#mv-confusion), [Anulación](ataques.md#mv-disable) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/8.png" alt="Wartortle" width="32" height="32"> [Wartortle](pokemon/008-wartortle.md) | 25 | [Refugio](ataques.md#mv-withdraw), [Pistola Agua](ataques.md#mv-water-gun), [Mordisco](ataques.md#mv-bite), [Giro Rápido](ataques.md#mv-rapid-spin) *(por defecto)* | — |

**Su inicial: Bulbasaur** — premio 900 ₽

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/17.png" alt="Pidgeotto" width="32" height="32"> [Pidgeotto](pokemon/017-pidgeotto.md) | 25 | [Ataque Arena](ataques.md#mv-sand-attack), [Tornado](ataques.md#mv-gust), [Ataque Rápido](ataques.md#mv-quick-attack), [Remolino](ataques.md#mv-whirlwind) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/130.png" alt="Gyarados" width="32" height="32"> [Gyarados](pokemon/130-gyarados.md) | 23 | [Saña](ataques.md#mv-thrash), [Mordisco](ataques.md#mv-bite) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/58.png" alt="Growlithe" width="32" height="32"> [Growlithe](pokemon/058-growlithe.md) | 22 | [Rugido](ataques.md#mv-roar), [Ascuas](ataques.md#mv-ember), [Malicioso](ataques.md#mv-leer), [Rastreo](ataques.md#mv-odor-sleuth) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/64.png" alt="Kadabra" width="32" height="32"> [Kadabra](pokemon/064-kadabra.md) | 20 | [Teletransporte](ataques.md#mv-teleport), [Kinético](ataques.md#mv-kinesis), [Confusión](ataques.md#mv-confusion), [Anulación](ataques.md#mv-disable) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/2.png" alt="Ivysaur" width="32" height="32"> [Ivysaur](pokemon/002-ivysaur.md) | 25 | [Látigo Cepa](ataques.md#mv-vine-whip), [Polvo Veneno](ataques.md#mv-poison-powder), [Somnífero](ataques.md#mv-sleep-powder), [Hoja Afilada](ataques.md#mv-razor-leaf) *(por defecto)* | — |

**Su inicial: Charmander** — premio 900 ₽

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/17.png" alt="Pidgeotto" width="32" height="32"> [Pidgeotto](pokemon/017-pidgeotto.md) | 25 | [Ataque Arena](ataques.md#mv-sand-attack), [Tornado](ataques.md#mv-gust), [Ataque Rápido](ataques.md#mv-quick-attack), [Remolino](ataques.md#mv-whirlwind) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/102.png" alt="Exeggcute" width="32" height="32"> [Exeggcute](pokemon/102-exeggcute.md) | 23 | [Hipnosis](ataques.md#mv-hypnosis), [Reflejo](ataques.md#mv-reflect), [Drenadoras](ataques.md#mv-leech-seed), [Confusión](ataques.md#mv-confusion) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/130.png" alt="Gyarados" width="32" height="32"> [Gyarados](pokemon/130-gyarados.md) | 22 | [Saña](ataques.md#mv-thrash), [Mordisco](ataques.md#mv-bite) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/64.png" alt="Kadabra" width="32" height="32"> [Kadabra](pokemon/064-kadabra.md) | 20 | [Teletransporte](ataques.md#mv-teleport), [Kinético](ataques.md#mv-kinesis), [Confusión](ataques.md#mv-confusion), [Anulación](ataques.md#mv-disable) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/5.png" alt="Charmeleon" width="32" height="32"> [Charmeleon](pokemon/005-charmeleon.md) | 25 | [Gruñido](ataques.md#mv-growl), [Ascuas](ataques.md#mv-ember), [Garra Metal](ataques.md#mv-metal-claw), [Pantalla de Humo](ataques.md#mv-smokescreen) *(por defecto)* | — |

### Combate 6 — Silph Co. · 7F

`TRAINER_RIVAL_SILPH_*`

**Su inicial: Squirtle** — premio 1440 ₽

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/18.png" alt="Pidgeot" width="32" height="32"> [Pidgeot](pokemon/018-pidgeot.md) | 37 | [Ataque Rápido](ataques.md#mv-quick-attack), [Remolino](ataques.md#mv-whirlwind), [Ataque Ala](ataques.md#mv-wing-attack), [Danza Pluma](ataques.md#mv-feather-dance) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/58.png" alt="Growlithe" width="32" height="32"> [Growlithe](pokemon/058-growlithe.md) | 38 | [Rastreo](ataques.md#mv-odor-sleuth), [Derribo](ataques.md#mv-take-down), [Rueda Fuego](ataques.md#mv-flame-wheel), [Refuerzo](ataques.md#mv-helping-hand) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/102.png" alt="Exeggcute" width="32" height="32"> [Exeggcute](pokemon/102-exeggcute.md) | 35 | [Drenadoras](ataques.md#mv-leech-seed), [Confusión](ataques.md#mv-confusion), [Paralizador](ataques.md#mv-stun-spore), [Polvo Veneno](ataques.md#mv-poison-powder) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/65.png" alt="Alakazam" width="32" height="32"> [Alakazam](pokemon/065-alakazam.md) | 35 | [Reflejo](ataques.md#mv-reflect), [Recuperación](ataques.md#mv-recover), [Premonición](ataques.md#mv-future-sight), [Paz Mental](ataques.md#mv-calm-mind) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/9.png" alt="Blastoise" width="32" height="32"> [Blastoise](pokemon/009-blastoise.md) | 40 | [Pistola Agua](ataques.md#mv-water-gun), [Mordisco](ataques.md#mv-bite), [Giro Rápido](ataques.md#mv-rapid-spin), [Protección](ataques.md#mv-protect) *(por defecto)* | — |

**Su inicial: Bulbasaur** — premio 1440 ₽

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/18.png" alt="Pidgeot" width="32" height="32"> [Pidgeot](pokemon/018-pidgeot.md) | 37 | [Ataque Rápido](ataques.md#mv-quick-attack), [Remolino](ataques.md#mv-whirlwind), [Ataque Ala](ataques.md#mv-wing-attack), [Danza Pluma](ataques.md#mv-feather-dance) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/130.png" alt="Gyarados" width="32" height="32"> [Gyarados](pokemon/130-gyarados.md) | 38 | [Mordisco](ataques.md#mv-bite), [Furia Dragón](ataques.md#mv-dragon-rage), [Malicioso](ataques.md#mv-leer), [Ciclón](ataques.md#mv-twister) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/58.png" alt="Growlithe" width="32" height="32"> [Growlithe](pokemon/058-growlithe.md) | 35 | [Malicioso](ataques.md#mv-leer), [Rastreo](ataques.md#mv-odor-sleuth), [Derribo](ataques.md#mv-take-down), [Rueda Fuego](ataques.md#mv-flame-wheel) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/65.png" alt="Alakazam" width="32" height="32"> [Alakazam](pokemon/065-alakazam.md) | 35 | [Reflejo](ataques.md#mv-reflect), [Recuperación](ataques.md#mv-recover), [Premonición](ataques.md#mv-future-sight), [Paz Mental](ataques.md#mv-calm-mind) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/3.png" alt="Venusaur" width="32" height="32"> [Venusaur](pokemon/003-venusaur.md) | 40 | [Polvo Veneno](ataques.md#mv-poison-powder), [Somnífero](ataques.md#mv-sleep-powder), [Hoja Afilada](ataques.md#mv-razor-leaf), [Dulce Aroma](ataques.md#mv-sweet-scent) *(por defecto)* | — |

**Su inicial: Charmander** — premio 1440 ₽

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/18.png" alt="Pidgeot" width="32" height="32"> [Pidgeot](pokemon/018-pidgeot.md) | 37 | [Ataque Rápido](ataques.md#mv-quick-attack), [Remolino](ataques.md#mv-whirlwind), [Ataque Ala](ataques.md#mv-wing-attack), [Danza Pluma](ataques.md#mv-feather-dance) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/102.png" alt="Exeggcute" width="32" height="32"> [Exeggcute](pokemon/102-exeggcute.md) | 38 | [Confusión](ataques.md#mv-confusion), [Paralizador](ataques.md#mv-stun-spore), [Polvo Veneno](ataques.md#mv-poison-powder), [Somnífero](ataques.md#mv-sleep-powder) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/130.png" alt="Gyarados" width="32" height="32"> [Gyarados](pokemon/130-gyarados.md) | 35 | [Mordisco](ataques.md#mv-bite), [Furia Dragón](ataques.md#mv-dragon-rage), [Malicioso](ataques.md#mv-leer), [Ciclón](ataques.md#mv-twister) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/65.png" alt="Alakazam" width="32" height="32"> [Alakazam](pokemon/065-alakazam.md) | 35 | [Reflejo](ataques.md#mv-reflect), [Recuperación](ataques.md#mv-recover), [Premonición](ataques.md#mv-future-sight), [Paz Mental](ataques.md#mv-calm-mind) *(por defecto)* | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/6.png" alt="Charizard" width="32" height="32"> [Charizard](pokemon/006-charizard.md) | 40 | [Pantalla de Humo](ataques.md#mv-smokescreen), [Cara Susto](ataques.md#mv-scary-face), [Lanzallamas](ataques.md#mv-flamethrower), [Ataque Ala](ataques.md#mv-wing-attack) *(por defecto)* | — |

### Combate 7 — Route 22

`TRAINER_RIVAL_ROUTE22_LATE_*`

**Su inicial: Squirtle** — premio 1908 ₽

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/18.png" alt="Pidgeot" width="32" height="32"> [Pidgeot](pokemon/018-pidgeot.md) | 47 | [Danza Pluma](ataques.md#mv-feather-dance), [Ataque Ala](ataques.md#mv-wing-attack), [Tornado](ataques.md#mv-gust), [Ataque Rápido](ataques.md#mv-quick-attack) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/111.png" alt="Rhyhorn" width="32" height="32"> [Rhyhorn](pokemon/111-rhyhorn.md) | 45 | [Derribo](ataques.md#mv-take-down), [Perforador](ataques.md#mv-horn-drill), [Pedrada](ataques.md#mv-rock-blast), [Ataque Furia](ataques.md#mv-fury-attack) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/58.png" alt="Growlithe" width="32" height="32"> [Growlithe](pokemon/058-growlithe.md) | 45 | [Rueda Fuego](ataques.md#mv-flame-wheel), [Derribo](ataques.md#mv-take-down), [Malicioso](ataques.md#mv-leer), [Agilidad](ataques.md#mv-agility) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/102.png" alt="Exeggcute" width="32" height="32"> [Exeggcute](pokemon/102-exeggcute.md) | 45 | [Rayo Solar](ataques.md#mv-solar-beam), [Somnífero](ataques.md#mv-sleep-powder), [Polvo Veneno](ataques.md#mv-poison-powder), [Paralizador](ataques.md#mv-stun-spore) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/65.png" alt="Alakazam" width="32" height="32"> [Alakazam](pokemon/065-alakazam.md) | 47 | [Psíquico](ataques.md#mv-psychic), [Paz Mental](ataques.md#mv-calm-mind), [Premonición](ataques.md#mv-future-sight), [Anulación](ataques.md#mv-disable) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/9.png" alt="Blastoise" width="32" height="32"> [Blastoise](pokemon/009-blastoise.md) | 53 | [Pistola Agua](ataques.md#mv-water-gun), [Danza Lluvia](ataques.md#mv-rain-dance), [Mordisco](ataques.md#mv-bite), [Giro Rápido](ataques.md#mv-rapid-spin) | — |

**Su inicial: Bulbasaur** — premio 1908 ₽

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/18.png" alt="Pidgeot" width="32" height="32"> [Pidgeot](pokemon/018-pidgeot.md) | 47 | [Danza Pluma](ataques.md#mv-feather-dance), [Ataque Ala](ataques.md#mv-wing-attack), [Tornado](ataques.md#mv-gust), [Ataque Rápido](ataques.md#mv-quick-attack) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/111.png" alt="Rhyhorn" width="32" height="32"> [Rhyhorn](pokemon/111-rhyhorn.md) | 45 | [Derribo](ataques.md#mv-take-down), [Perforador](ataques.md#mv-horn-drill), [Pedrada](ataques.md#mv-rock-blast), [Ataque Furia](ataques.md#mv-fury-attack) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/130.png" alt="Gyarados" width="32" height="32"> [Gyarados](pokemon/130-gyarados.md) | 45 | [Hidrobomba](ataques.md#mv-hydro-pump), [Ciclón](ataques.md#mv-twister), [Malicioso](ataques.md#mv-leer), [Danza Lluvia](ataques.md#mv-rain-dance) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/58.png" alt="Growlithe" width="32" height="32"> [Growlithe](pokemon/058-growlithe.md) | 45 | [Rueda Fuego](ataques.md#mv-flame-wheel), [Derribo](ataques.md#mv-take-down), [Malicioso](ataques.md#mv-leer), [Agilidad](ataques.md#mv-agility) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/65.png" alt="Alakazam" width="32" height="32"> [Alakazam](pokemon/065-alakazam.md) | 47 | [Psíquico](ataques.md#mv-psychic), [Paz Mental](ataques.md#mv-calm-mind), [Premonición](ataques.md#mv-future-sight), [Anulación](ataques.md#mv-disable) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/3.png" alt="Venusaur" width="32" height="32"> [Venusaur](pokemon/003-venusaur.md) | 53 | [Hoja Afilada](ataques.md#mv-razor-leaf), [Dulce Aroma](ataques.md#mv-sweet-scent), [Desarrollo](ataques.md#mv-growth), [Fotosíntesis](ataques.md#mv-synthesis) | — |

**Su inicial: Charmander** — premio 1908 ₽

| Pokémon | Nv | Ataques | Objeto |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/18.png" alt="Pidgeot" width="32" height="32"> [Pidgeot](pokemon/018-pidgeot.md) | 47 | [Danza Pluma](ataques.md#mv-feather-dance), [Ataque Ala](ataques.md#mv-wing-attack), [Tornado](ataques.md#mv-gust), [Ataque Rápido](ataques.md#mv-quick-attack) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/111.png" alt="Rhyhorn" width="32" height="32"> [Rhyhorn](pokemon/111-rhyhorn.md) | 45 | [Derribo](ataques.md#mv-take-down), [Perforador](ataques.md#mv-horn-drill), [Pedrada](ataques.md#mv-rock-blast), [Ataque Furia](ataques.md#mv-fury-attack) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/102.png" alt="Exeggcute" width="32" height="32"> [Exeggcute](pokemon/102-exeggcute.md) | 45 | [Rayo Solar](ataques.md#mv-solar-beam), [Somnífero](ataques.md#mv-sleep-powder), [Polvo Veneno](ataques.md#mv-poison-powder), [Paralizador](ataques.md#mv-stun-spore) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/130.png" alt="Gyarados" width="32" height="32"> [Gyarados](pokemon/130-gyarados.md) | 45 | [Hidrobomba](ataques.md#mv-hydro-pump), [Ciclón](ataques.md#mv-twister), [Malicioso](ataques.md#mv-leer), [Danza Lluvia](ataques.md#mv-rain-dance) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/65.png" alt="Alakazam" width="32" height="32"> [Alakazam](pokemon/065-alakazam.md) | 47 | [Psíquico](ataques.md#mv-psychic), [Paz Mental](ataques.md#mv-calm-mind), [Premonición](ataques.md#mv-future-sight), [Anulación](ataques.md#mv-disable) | — |
| <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iii/firered-leafgreen/6.png" alt="Charizard" width="32" height="32"> [Charizard](pokemon/006-charizard.md) | 53 | [Lanzallamas](ataques.md#mv-flamethrower), [Ataque Ala](ataques.md#mv-wing-attack), [Cuchillada](ataques.md#mv-slash), [Cara Susto](ataques.md#mv-scary-face) | — |
