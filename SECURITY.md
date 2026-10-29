# Seguridad

## Qué cubre
Los bots corren en tu PC con tus permisos: crean carpetas y, si configuras `notify`,
lanzan `curl` para enviar avisos. El análisis completo está en el
[modelo de amenazas](docs/02-design/threat-model.md).

## Recomendaciones para usuarios
- Descarga los scripts solo de este repositorio y revisa cualquier `.lua` de terceros
  antes de cargarlo en VBA-rr: un script Lua puede ejecutar comandos en tu PC.
- Tu webhook de Discord y tu tema de ntfy son **secretos**: no los publiques ni subas tu
  JSON con ellos. Si se filtra un webhook, bórralo en Discord y crea otro.
- Usa un tema de ntfy largo y difícil de adivinar.

## Reportar una vulnerabilidad
No abras un issue público. Usa
[**Report a vulnerability**](https://github.com/vladeParica/Poke-tools/security/advisories/new)
en la pestaña *Security* del repositorio, con los pasos para reproducirla.
