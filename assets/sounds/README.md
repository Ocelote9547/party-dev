# Música de la app — `assets/sounds/`

La app reproduce una pista en loop según dónde estés, con fade de
entrada (800 ms) y de salida (500 ms). Si una pista no existe,
usa la siguiente de la lista y si no hay ninguna, un pad generado.

## Archivos

| Archivo                 | Cuándo suena                          | Volumen |
|-------------------------|---------------------------------------|---------|
| `menu.mp3`              | Menús (inicio, juegos, ajustes...)    | 12%     |
| `musica_mentira.mp3`    | IMPOSTOR, ESPIA, SECRETOS, MÁSCARA, ALIENÍGENA | 15% |
| `musica_palabras.mp3`   | ADIVINA, TABÚ, DIBUJA, BOMBA          | 15%     |
| `musica_reto.mp3`       | ES UN 10, MÍMICA, VERDAD O RETO       | 15%     |
| `musica_opinion.mp3`    | DEBATE                                | 15%     |
| `musica_grupo.mp3`      | QUIÉN ES MÁS, YO NUNCA, ¿QUIÉN SOY?, MATAR CASAR BESAR | 15% |
| `musica_misterio.mp3`   | PUEBLO DUERME (oscura, nada alegre)   | 15%     |
| `game.mp3`              | Fallback si falta la de su conjunto   | 15%     |

## Formato recomendado

- MP3 128 kbps, 1-2 MB por pista (más peso = APK más grande).
- Trozo con groove estable de 30-60 s (o canción entera si el loop no se nota).
- Sin silencios al inicio/final para que el loop no tenga huecos.
- Tras añadir archivos: **reinicio completo** (`flutter run` de nuevo,
  no vale hot reload) para que se empaqueten.

## Fallback

Los `*.wav` de 1 KB son placeholders antiguos ya sin uso
(los efectos se generan en memoria). No borrar `game.mp3`/`menu.mp3`
si quieres música real: sin ellos suena el pad generado.
