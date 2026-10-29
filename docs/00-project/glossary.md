# Glosario — Poke-tools

> **Fase AI-DLC:** `00-project`
> El vocabulario común del proyecto. Los nombres del juego van en español (como los ve el
> jugador); los de código o datos de pret, en inglés.

| Término | Definición |
|---|---|
| **FRLG** | Pokémon Rojo Fuego (FireRed) y Verde Hoja (LeafGreen), GBA. |
| **VBA-rr** | VisualBoyAdvance-ReRecording: emulador de GBA con Lua 5.1 para leer memoria y pulsar botones. |
| **Bot** | Script Lua que juega solo. Hay dos: **Shiny Bot** y **Train Bot**. |
| **Modo** | Lo que hace el Shiny Bot en una corrida (Salvaje, Estático RNG…). Se cambia con la tecla 8. |
| **Instancia** | Una ventana de Lua corriendo un bot. El Shiny Bot admite varias; el Train Bot solo una. |
| **Corrida** | Desde que se pulsa 7 hasta que el bot se detiene o encuentra el objetivo. |
| **RNG / LCRNG** | Generador de números aleatorios del juego: `s = s*0x41C64E6D + 0x6073`. Todo lo aleatorio sale de él. |
| **Avance** | Una llamada al RNG. "El objetivo está en el avance 2786" = tras 2786 llamadas desde la semilla. |
| **Semilla inicial** | Estado del RNG al cargar la partida; la fija el momento en que se pulsa A en el título (16 bits). |
| **Objetivo** | Avance del RNG que produce el Pokémon buscado. |
| **Calibrar** | Medir cuántos avances pasan entre la pulsación del bot y la creación del Pokémon (el **retraso**). |
| **Method 1 / Method H-1** | Orden en que el juego pide números al RNG para crear un Pokémon (estáticos/regalos vs. salvajes). |
| **PID** | Número de 32 bits que fija naturaleza, género, habilidad y si es shiny. |
| **TID / SID** | ID de entrenador visible y secreta. Junto con el PID deciden el shiny. |
| **TSV** | `TID xor SID`; lo que busca el modo Partida nueva. |
| **Shiny** | `(TID ^ SID ^ PIDalto ^ PIDbajo) < 8`. |
| **IVs** | Valores individuales (0–31) por estadística. "6×31" = los seis al máximo. |
| **EVs** | Puntos de esfuerzo que da cada combate; máx. 255 por estadística y 510 en total. |
| **Soft reset** | Reiniciar el juego (A+B+START+SELECT) para cambiar la semilla. |
| **Tele Pokémon** | Objeto (Teachy TV) que avanza el RNG ~313 veces por frame; el bot la abre registrada en SELECT. |
| **Roamer** | Pokémon legendario que se mueve por el mapa (Raikou, Entei, Suicune). |
| **Punto de entreno** | Casilla donde el Train Bot camina buscando combates. |
| **Ruta** | Archivo `FRLG_TrainRoute*.txt` con la ida (`GO`) al lugar de curación y la vuelta (`BACK`). |
| **`healMode`** | Cómo se cura el Train Bot: `nurse` (enfermera) o `tile` (casilla que cura, Torre Pokémon 5F). |
| **Panel** | Texto que el bot dibuja sobre el juego (tecla 9). |
| **Simulador / mock** | Lua que imita la memoria y los botones del juego para probar los bots sin emulador. |
| **pret** | Proyecto de decompilación `pret/pokefirered`: fuente de símbolos y datos del juego. |
| **Generado** | `FRLG_ShinyBot.lua` y `FRLG_TrainBot.lua`: salen de `src/` con `build.py`; no se editan a mano. |
