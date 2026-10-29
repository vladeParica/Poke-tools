# Cómo contribuir

Gracias por querer mejorar los bots. Antes de empezar, lee la
[documentación del proyecto](docs/README.md), sobre todo la
[arquitectura](docs/02-design/architecture.md) y las [decisiones (ADR)](docs/00-project/adr/).

## Reglas
- **No romper lo que ya funciona.** Un cambio en un modo no debe afectar a los demás.
- **El Shiny Bot solo busca.** Las funciones de otro tipo van en un bot aparte ([ADR-0003](docs/00-project/adr/0003-bots-separados.md)).
- **Todo lo que ve el jugador va en español** (panel, consola, log, JSON).
- **El repo es genérico:** nada de una partida concreta (TID/SID, semillas para ella).
  En los ejemplos usa valores neutros (TID 12345 / SID 54321).
- **Nunca subas ROMs, partidas, savestates ni JSON con `notify` real.**
- Lo que no pudiste probar en el juego real, dilo en el PR.

## Preparar el entorno
```
pip install -r requirements-dev.txt
git config core.hooksPath .githooks
```

## Flujo de trabajo
1. Edita **`*/src/*`**, nunca los `.lua` generados ([ADR-0002](docs/00-project/adr/0002-script-unico-generado.md)).
2. Regenera: `python shinybot/build.py` y `python trainbot/build.py`.
3. Corre las pruebas del simulador ([estrategia de pruebas](docs/04-testing/test-strategy.md))
   y compara con el resultado esperado de cada escenario.
4. Si cambias el JSON, la ruta o las teclas, actualiza los
   [contratos](docs/02-design/api-contracts.md) y el [CHANGELOG](CHANGELOG.md).
5. Si cambias una decisión de diseño, actualiza su ADR o crea una nueva.

## Commits
[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) **en inglés**, de
**3 líneas como máximo** y **sin líneas `Co-Authored-By`**. El hook `.githooks/commit-msg`
lo comprueba.

```
feat(trainbot): pause on evolution
fix(shinybot): recalibrate after lag
docs: reusable training routes
```

## Pull requests
Rellena la plantilla del PR. El CI tiene que pasar: comprueba que los `.lua` generados
coinciden con `src/` y que todos los escenarios del simulador corren sin errores.
