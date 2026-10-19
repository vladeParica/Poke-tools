# Rutas de entrenamiento listas para usar

Rutas grabadas con la tecla **6** del Train Bot. Sirven para cualquier Pokémon y
cualquier partida (FRLG USA o EUR), siempre que empieces **en el mismo punto de entreno**.

| Archivo | EVs | Dónde se entrena | Dónde cura | `healMode` | JSON de ejemplo |
|---|---|---|---|---|---|
| `FRLG_TrainRoute_Diglett.txt` | Velocidad (Diglett +1, Dugtrio +2) | Cueva Diglett B1F, lado de Ruta 11 | Centro Pokémon de Ciudad Carmín | `nurse` | `../gastly/FRLG_TrainBot_Gastly_Fase1.json` |
| `FRLG_TrainRoute_Torre.txt` | At. Esp. (Gastly +1, Haunter +2) | Torre Pokémon, 2 pisos sobre el 5F | Zona purificada del 5F | `tile` | `../gastly/FRLG_TrainBot_Gastly_Fase2.json` |

## Cómo usarlas

1. Copia el `.txt` junto a `FRLG_TrainBot.lua` (con el mismo nombre).
2. En tu `FRLG_TrainBot.json` pon `"routeFile"` con ese nombre y el `healMode` de la tabla.
   Para entrenar solo contra los Pokémon que dan esos EVs, usa `"species"`
   (por ejemplo, `["Diglett", "Dugtrio"]`).
3. Ve al punto de entreno (el primer paso de `GO`) y pulsa **7**.

## Formato

Dos líneas, `GO` (punto de entreno → curación) y `BACK` (curación → punto de entreno).
Cada paso es `grupo mapa x y dirección`, separados por `;`. Las coordenadas son las de
memoria (mapa + 7). Al cargar, el bot limpia los pasos falsos de las puertas (`cleanRoute`).

Recorridos:

- **Diglett:** B1F (1-37, x86 y77) → salida sur (1-38) → Ruta 11 (3-29) → Ciudad Carmín
  (3-5) → Centro Pokémon (9-1), frente a la enfermera.
- **Torre:** mapa 1-94 (x17 y21) → 1-93 → 1-92 (5F), hasta x19 y16, dentro de la zona que cura.

## Añadir una ruta

Graba la tuya con la tecla **6** (ver el README principal), renómbrala
`FRLG_TrainRoute_<Lugar>.txt`, cópiala aquí y añade una fila a la tabla.
