# Idiomas

[Español](IDIOMAS.md) · [English](en/IDIOMAS.md) · [Français](fr/IDIOMAS.md) · [Índice](README.md)

La interfaz está disponible en español, inglés y francés. El selector de idioma aparece en el acceso, Mis partidas, administración y la barra superior del juego. La elección se guarda en el navegador y se aplica sin recargar ni perder los formularios abiertos.

Fechas, números e importes siguen el idioma seleccionado. Los nombres de personas, clubes, estadios, patrocinadores, partidas y lemas oficiales conservan su forma original. Los identificadores, tácticas y datos guardados no cambian de idioma.

Los catálogos de `rugby-frontend/src/i18n` incluyen interfaz, mensajes variables, lesiones, narración y errores de API. Los mensajes históricos se traducen al mostrarse; no se duplican datos en IRIS. Los parámetros que contienen nombres se conservan y los valores descriptivos se traducen de forma explícita.

Las pruebas de idioma comprueban ambos catálogos, sus parámetros, vocabulario de rugby y errores: `npm run test:e2e --prefix rugby-frontend -- i18n.spec.ts`.
