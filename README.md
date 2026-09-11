# Neon Runner 2087

Endless runner 3D em **Godot 4.7** (portrait 720×1280, renderer mobile) para Android.
Corra, desvie, colete **energia**, mantenha o **combo** e desbloqueie novos mapas.

## Como jogar
- **Deslize para o lado** para trocar de faixa.
- **Deslize para cima (ou toque)** para pular.
- **Deslize para baixo** para deslizar por baixo dos obstáculos.
- Toque nas **orbs de energia** e mantenha o combo para multiplicar o ganho.

## Sistema de progressão
- **Energia** é permanente (salva no dispositivo) e usada para desbloquear mapas.
- **Combo**: acertos seguidos aumentam o multiplicador (x1.5 → x5). Errar zera o combo.
- **Mapas**: Neon City (início), Tokyo Neon (5000 ⚡), Moscow Frost (15000 ⚡).
- **Recompensa de anúncio** (AdMob): +200 energia por vídeo assistido.
- Recordes de tempo e pontuação salvos por mapa.

## Estrutura
```
assets/        Modelos 3D, texturas e áudio (ver CREDITS.md)
scenes/        Cenas (main.tscn, menu.tscn)
scripts/       Lógica (player, world, combo, progress, audio, ads...)
build/         APK exportado (não versionado)
```

## Build Android
```powershell
Godot_v4.7.2-stable_win64.exe --headless --path . --export-debug "Android" build/neon-runner.apk
```

## Créditos
Todos os assets externos licenciados para uso comercial estão documentados
em **CREDITS.md** — por favor, mantenha ao distribuir o jogo.

---
Projeto portfólio — feito com Godot 4.7.2.