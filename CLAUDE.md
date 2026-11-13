# JogoED

Jogo da disciplina de Entretenimento Digital (BCC, IFSP Salto), feito com Spec Kit.
As regras do projeto estão na constituição: `.specify/memory/constitution.md`.

## Git

- Sempre fazer commit logo depois de cada alteração, em português, uma mudança por commit.

## Funcionalidade atual: 001, núcleo da batalha

- Plano: `specs/001-nucleo-batalha/plan.md` (decisões em `research.md`, interfaces em `contracts/`).
- Godot 4.7.2-stable, GDScript tipado, GUT 9.7.1 em `addons/gut/`.
- Testes: `godot --headless --path . --import` e depois
  `godot --headless --path . -s addons/gut/gut_cmdln.gd` (detalhes no `quickstart.md`).
- Assets: nunca criar; registrar o que falta em `docs/assets-pendentes.md`.
