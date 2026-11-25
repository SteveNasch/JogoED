# JogoED

Jogo da disciplina de Entretenimento Digital (BCC, IFSP Salto), feito com Spec Kit.
As regras do projeto estão na constituição: `.specify/memory/constitution.md`.

## Git

- Sempre fazer commit logo depois de cada alteração, em português, uma mudança por commit.

## Funcionalidade atual: 002, run e mapa

- Plano: `specs/002-run-e-mapa/plan.md` (decisões em `research.md`, interfaces em `contracts/`).
- A 001 está com o T035 jogado (18/11). O converge dela foi adiado de propósito (decisão de
  25/11): um converge só confere a 001 e a 002 juntas, no fim da 002. Pode implementar a 002.
- A luta da 001 é usada só pela interface `TelaBatalha.iniciar(...)` e o sinal `luta_terminou`;
  nenhum script de jogo da 001 muda (o que muda fora das pastas novas está no research, D1).
- A run (`run/run.gd`) é `RefCounted`, sem cena; a cena principal passa a ser `run/tela_run.tscn`.
- Todo o equilíbrio da run fica em `dados/dificuldade.tres`; nada de número solto no código.
- Todo sorteio usa um `RandomNumberGenerator` com semente vinda de fora (research D3).
- Godot 4.7.2-stable, GDScript tipado, GUT 9.7.1 em `addons/gut/`.
- Testes: `godot --headless --path . --import` e depois
  `godot --headless --path . -s addons/gut/gut_cmdln.gd` (detalhes no `quickstart.md`).
- Assets: nunca criar; registrar o que falta em `docs/assets-pendentes.md` (002: itens 24 a 34).

## GodotPrompter

- Antes de implementar qualquer sistema Godot (cena, UI, sinais, testes etc.), procurar a skill
  `godot-prompter:*` correspondente e usá-la; vale também para subagentes. Índice:
  `godot-prompter:using-godot-prompter`.
- Antes de construir, dizer qual padrão foi escolhido, qual alternativa foi descartada e por quê.
