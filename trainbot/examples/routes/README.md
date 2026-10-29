# Rutas de entrenamiento listas para usar

Rutas grabadas con la tecla **6** del Train Bot. Sirven para cualquier Pokémon y
cualquier partida (FRLG USA o EUR), siempre que empieces **en el mismo punto de entreno**.

| Archivo | EVs | Dónde se entrena | Dónde cura | `healMode` | JSON de ejemplo |
|---|---|---|---|---|---|
| `FRLG_TrainRoute_Diglett.txt` | Velocidad (Diglett +1, Dugtrio +2) | Cueva Diglett B1F, lado de Ruta 11 | Centro Pokémon de Ciudad Carmín | `nurse` | `../configs/FRLG_TrainBot_Velocidad_Diglett.json` |
| `FRLG_TrainRoute_Torre.txt` | At. Esp. (Gastly +1, Haunter +2) | Torre Pokémon, 2 pisos sobre el 5F | Zona purificada del 5F | `tile` | `../configs/FRLG_TrainBot_AtEsp_Torre.json` |

## Cómo usarlas

1. Copia el `.txt` junto a `FRLG_TrainBot.lua` (con el mismo nombre).
2. En tu `FRLG_TrainBot.json` pon `"routeFile"` con ese nombre y el `healMode` de la tabla.
   Para entrenar solo contra los Pokémon que dan esos EVs, usa `"species"`
   (por ejemplo, `["Diglett", "Dugtrio"]`).
3. Ve a uno de los puntos de inicio (ver abajo) y pulsa **7**.

## Dónde empezar

No hace falta saber la coordenada exacta del punto de entreno. Al pulsar **7**, el bot:

- **entrena ahí mismo** si estás a 2 casillas o menos del punto de entreno, en el mismo mapa;
- **camina hasta el punto de entreno** si estás parado en cualquier casilla del camino
  de vuelta (`BACK`), mire hacia donde mire;
- **se detiene** con "El personaje no está en el punto de entreno" en cualquier otro sitio.

Lo más fácil es empezar donde cura, que es el primer paso de `BACK`:

| Ruta | Empieza aquí |
|---|---|
| Diglett | Centro Pokémon de Ciudad Carmín, **frente a la enfermera** (mapa 9.1, casilla 14,11) |
| Torre | Torre Pokémon 5F, **dentro de la zona purificada** (mapa 1.92, casilla 19,16) |

Para ver tu posición, pulsa **9** hasta el panel de diagnóstico: la línea `Pos` muestra
`grupo.mapa (x,y)` con las mismas coordenadas que el archivo de ruta.

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
