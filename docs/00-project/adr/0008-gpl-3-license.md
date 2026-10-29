# ADR-0008 — Licencia GPL-3.0

> **Fase AI-DLC:** `00-project`  ·  **Estado:** aceptada
> **Fecha:** 2026-10-29  ·  **Dueño:** vladeParica

## Contexto
Los bots usan direcciones de memoria y tablas de nombres de
[DevonStudios/LuaScripts](https://github.com/DevonStudios/LuaScripts), que se distribuye
bajo **GPL-3.0**. Una obra derivada que se redistribuye debe usar la misma licencia y
publicar su código. El repositorio no tenía licencia.

## Decisión
El repositorio se publica bajo **GPL-3.0** (archivo `LICENSE` en la raíz).

## Alternativas consideradas
- **MIT u otra permisiva** — no es compatible con incluir código GPL-3.0.
- **Sin licencia** — por defecto nadie puede reutilizar el código, y no deja claras las
  obligaciones heredadas de la base.
- **Reescribir sin la base de Devon Studios** — mucho trabajo y se pierden direcciones ya verificadas.

## Consecuencias
- **Positivas:** cumple con la licencia de la base; cualquiera puede usar y modificar los
  bots si comparte sus cambios con la misma licencia.
- **Costos:** quien redistribuya versiones modificadas tiene que publicar su código fuente.
- Confirmada por el dueño el 2026-10-29.
