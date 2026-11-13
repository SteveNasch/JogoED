# Specification Quality Checklist: Núcleo da batalha

**Purpose**: conferir se a especificação está completa e com qualidade antes de planejar
**Created**: 2026-11-13
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] Sem detalhes de implementação (linguagens, frameworks, APIs)
- [x] Focada no valor para o jogador e no objetivo do projeto
- [x] Escrita para quem não é da área técnica
- [x] Todas as seções obrigatórias preenchidas

## Requirement Completeness

- [x] Nenhum marcador [NEEDS CLARIFICATION] sobrou
- [x] Requisitos testáveis e sem ambiguidade
- [x] Critérios de sucesso mensuráveis
- [x] Critérios de sucesso independentes de tecnologia (sem detalhes de implementação)
- [x] Todos os cenários de aceitação definidos
- [x] Casos-limite identificados
- [x] Escopo bem delimitado
- [x] Dependências e premissas identificadas

## Feature Readiness

- [x] Todo requisito funcional tem critério de aceitação claro
- [x] Os cenários do jogador cobrem os fluxos principais
- [x] A funcionalidade atende aos resultados mensuráveis dos critérios de sucesso
- [x] Nenhum detalhe de implementação vazou para a especificação

## Notes

- 1ª passada: três marcadores [NEEDS CLARIFICATION] (baralho da luta, mão pequena e
  divisão), resolvidos pelo Estêvão em 2026-11-13 e registrados em "Clarifications".
- O cenário 2 da história 1 matava o inimigo padrão (12 de vida) com 13 de dano e contradizia
  o cenário 4; corrigido para um inimigo com 20 de vida.
- FR-029 (mesma semente, mesma luta) e FR-030 (placeholders do motor) citam o motor e o
  sorteio só como exigência verificável, sem escolher tecnologia; exigidos pela constituição
  (princípios II e IV).
- Inimigo derrotado não ataca: era o ponto aberto para o `/speckit-clarify` e foi
  confirmado lá (ver "Clarifications" da spec).
