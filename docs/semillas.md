# Semillas y objetivos calculados

Todo para la **partida nueva TID 39422 / SID 4042** salvo que se diga otra cosa.
"Semillas" = valores de `initialSeeds` para el modo **Semilla inicial** del Shiny Bot.
Todas las de una lista llevan al **mismo** Pokémon; más semillas = más probabilidad
de caer en una en cada reinicio (cada reinicio solo alcanza 1 de 64 "clases").

Para recalcular o buscar otros: `tools/rng/` (ver su README).

## Posiciones 6×31 de Method 1 (estáticos, regalos, iniciales)

Solo existen 6 en todo el ciclo del RNG. Shiny para esta partida:

| Naturaleza | PID | Semilla @ avance |
|---|---|---|
| Modest | F9426F72 | BC75 @15061 · 0A16 @19914 · 9BAF @70379 |
| Timid | 7942EF72 | 448B @9919 · A8C0 @113784 |

Usado para el **Squirtle Modest 6×31 shiny** (semilla 9BAF).

## Snorlax (Ruta 12/16, Estático RNG)

| Naturaleza | PS/At/Df/AtE/DfE/Vel | Semilla @ avance |
|---|---|---|
| Adamant | 31/30/26/28/31/21 | 7A82 @50806 |
| Careful | 31/30/26/28/31/21 | 0DD4 @46812 |

Filtro: `"natures": ["Adamant","Careful"]`, `"minIVs": {"hp":31,"atk":30,"def":26,"spd":31}`.
Lista completa (< 2M avances):

```
"7A82","837D","F5DD","6F2E","7667","C241","6864","6AC3","3925","90EB","CC71","5D52","34A2","36FA","9A7E","7585","0628","F48C","360C","4F54","7B8F","7C90","DB45","4654","BF92","D974","F4F7","9198","17AC","B13A","5E8A","F398","0DD4","F192","0328","D2C3","2B27","A82E","208F","60F7","36ED","A18A","35B6","E031","353F","4E19","E10C","95C4","586E","7F8F","E461"
```

## Gastly Modest 6×31 shiny (Torre Pokémon 3F–6F, Salvaje RNG)

PID F9426F72, slot 0 (Gastly), H-1. Conseguido y entrenado.

```
"BC75","0A16","9BAF","BBA5","AF80","19F6","151E","DAD6","E651","6336","0CEA","2298","A90E","0302","CF0E","9C40","301E","E24B","9726","C450","75A6","5F87","CA1C","2EA8","79ED","9C4A","411A","ECC1","AFCF","3C55","BF7F","63F7","7529","D441","2860","E598"
```

## Zubat shiny (Túnel Roca 1F/B1F o Mt. Moon 1F, slot 0)

| Naturaleza | PS/At/Df/AtE/DfE/Vel |
|---|---|
| Jolly | 27/28/24/16/29/29 |
| Adamant | 29/29/29/3/24/28 |

Filtro: `"natures": ["Jolly","Adamant"]`, `"minIVs": {"hp":27,"atk":28,"def":24,"spd":24,"spe":28}`.

```
"F630","B785","DF04","EAA9","1044","9858","C2B6","0CE8","81B2","74F0","E087","7BBB","0ED6","D739","F901","F56A","A3D1","D295","082C","0AED","879B","CA9F","E3F7","D89D","8538","9B87","7F57","732A","2CA9","D14A","F7BD","8C81","77E4","38BA","B2D3","3A67","7C26","8C98","BD6B","61DF","2F8E","A513","C935","97DB","4429","B65F","E3B2","7778","10DE","508A","FA3D","51F3","3F99","06D6","981C","7543","CB83","4515","A4C6","67DA","5307","1245","D90E","2569","31C9","EAAE","5D93","4C95","0D2B","7C0F","0CAE","D69D","F7CF","8820","6BD7","728A"
```

## Ditto 6×31 (Ruta 14 / Mansión / Cueva Celeste)

Iguales en Rojo Fuego y Verde Hoja: 448B ~9890 (Timid), BC75 ~15034, 5433 ~37237,
38F2 ~70200 (Modest), BDD1 ~122600 (Calm). Shiny solo con TID^SID en las ventanas
0x9630 / 0xB378 / 0x79F8 (modo Partida nueva).

## Pokémon que NO se pueden RNG (intercambios fijos del juego)

- **Farfetch'd** "CH'DING" (Carmín, por Spearow): Adamant, IVs 20/25/21/15/20/24, nunca shiny.
- **Jynx** "ZYNX" (Celeste, por Poliwhirl): Mild, IVs 18/17/18/25/21/22, nunca shiny.
  No salen salvajes en FRLG: solo criándolos (huevo).
