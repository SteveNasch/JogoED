# Assets pendentes

Lista do que a equipe precisa fornecer (princípio IV da constituição). O Claude não cria
sprites, músicas nem sons: o jogo usa placeholders neutros do Godot até cada arquivo chegar.

Como usar esta lista:
- Achou ou fez o arquivo? Coloque na pasta indicada, preencha **Origem e licença** e mude a
  situação para "entregue". A troca do placeholder na cena é uma tarefa à parte.
- Não achou? Avise: o Claude só pode gerar um asset com base nos sprites já entregues e com
  autorização explícita para aquele item.
- Situações: **pendente** (falta o arquivo), **entregue** (arquivo no repositório, ainda
  com placeholder na cena) e **aplicado** (já aparece no jogo).
- Os números identificam cada item e não mudam (o código e as specs citam "asset 15", por
  exemplo); item novo recebe o próximo número livre, mesmo que fique numa tabela do meio.

Medidas pensadas para a resolução base de 640×360 (ver
`specs/001-nucleo-batalha/research.md`, D3). Imagens em PNG com fundo transparente, sem
suavização, na medida exata (o jogo amplia sozinho em 2×, 3×…). Animações em uma tira
horizontal, com todos os quadros do mesmo tamanho.

## Funcionalidade 001: núcleo da batalha

### Imagens

| # | Asset | Tamanho (px) | Quadros | Onde é usado | Placeholder atual | Situação | Origem e licença |
|---|---|---|---|---|---|---|---|
| 1 | Arthur parado | 64×64 | 2 a 4 | painel do Arthur na luta | `ColorRect` 64×64 azul, `Color(0.25, 0.4, 0.8)` (nó `PainelArthur/Sprite` em `batalha/tela_batalha.tscn`), + `Label` com o nome | pendente | |
| 2 | Arthur atacando (opcional) | 64×64 | 4 a 6 | acerto de uma conta | sem animação | pendente | |
| 3 | Arthur levando dano (opcional) | 64×64 | 2 a 3 | ataque do inimigo | sem animação | pendente | |
| 4 | Inimigo padrão parado | 64×64 | 2 a 4 | painel do inimigo na luta | `ColorRect` 64×64 vermelho, `Color(0.8, 0.25, 0.25)` (nó `PainelInimigo/Sprite` em `batalha/tela_batalha.tscn`), + `Label` com o nome | pendente | |
| 5 | Inimigo atacando (opcional) | 64×64 | 4 a 6 | fim de cada rodada | sem animação | pendente | |
| 6 | Inimigo levando dano (opcional) | 64×64 | 2 a 3 | acerto de uma conta | sem animação | pendente | |
| 7 | Fundo da luta (calabouço) | 640×360 | 1 | fundo da tela de luta | cor de fundo padrão do Godot (sem nó na cena; o projeto não define `default_clear_color`) | pendente | |
| 8 | Frente de carta de número | 48×64 | 1 | mão e expressão | `Panel` `Fundo` com o estilo do tema padrão + `Label` `Simbolo` e `Ataque` (`cartas/carta.tscn`) | pendente | |
| 9 | Frente de carta de operador | 48×64 | 1 | mão e expressão | o mesmo `Panel` `Fundo` + `Label` `Simbolo` e `Ataque` (`cartas/carta.tscn`) | pendente | |
| 10 | Frente de carta especial | 48×64 | 1 | Chama, Foco, Guarda e Vital | o mesmo `Panel` `Fundo` + `Label` `Simbolo`, `Ataque`, `Nome` e `Efeito` (`cartas/carta.tscn`) | pendente | |
| 11 | Ícones de efeito: chama, foco, guarda, vital | 16×16 cada | 1 | canto das cartas especiais | nome e efeito por extenso (`Label` `Nome` e `Efeito` em `cartas/carta.tscn`) | pendente | |
| 12 | Ícones de status: vida, escudo, ataque | 16×16 cada | 1 | painéis do Arthur e do inimigo | texto ("Vida", "Escudo", "Ataque") nos `Label` `Vida`, `Escudo` e `Ataque` de `combatentes/painel_combatente.tscn` | pendente | |
| 13 | Moldura de botão e de painel (opcional) | 16×16, para esticar pelas bordas | 1 | botões Desfazer, Limpar, Confirmar, Pular; telas de vitória e derrota | `Button` e `Panel` com o estilo do tema padrão do Godot (`tema.tres` só muda o tamanho da fonte) | pendente | |
| 23 | Ícone do jogo | 64×64 (SVG ou PNG) | 1 | janela do jogo e executável exportado | ícone padrão do Godot (sem arquivo no projeto) | pendente | |

As frentes de carta (8 a 10) precisam de área livre para o jogo escrever por cima: o símbolo
no canto superior esquerdo e o ataque num canto de baixo.

### Fonte

| # | Asset | Formato | Onde é usado | Placeholder atual | Situação | Origem e licença |
|---|---|---|---|---|---|---|
| 14 | Fonte de pixel art | TTF ou OTF, legível com 8 a 16 px de altura | todo o texto do jogo | fonte padrão do Godot, 10 px (`tema.tres`); o alvo usa 32 px | pendente | |

A fonte precisa ter os acentos do português (á, à, â, ã, é, ê, í, ó, ô, õ, ú, ç, maiúsculas
e minúsculas), os algarismos e os símbolos `+ − × ÷ ^ / :`. A licença tem que permitir uso
em jogo; guarde o arquivo da licença junto.

### Sons

Efeitos curtos em WAV; música em Ogg Vorbis (recomendação da documentação do Godot).

| # | Asset | Duração | Onde é usado | Placeholder atual | Situação | Origem e licença |
|---|---|---|---|---|---|---|
| 15 | Carta escolhida | até 0,3 s | clicar numa carta da mão | silêncio: `AudioStreamPlayer` `Carta` sem áudio (`batalha/sons_batalha.tscn`) | pendente | |
| 16 | Acerto | até 1 s | conta deu o alvo; inimigo leva dano | silêncio: `AudioStreamPlayer` `Acerto` sem áudio (`batalha/sons_batalha.tscn`) | pendente | |
| 17 | Erro | até 1 s | conta errada ou inválida (o mesmo som para as duas) | silêncio: `AudioStreamPlayer` `Erro` sem áudio (`batalha/sons_batalha.tscn`) | pendente | |
| 18 | Pular | até 0,5 s | botão Pular | silêncio: `AudioStreamPlayer` `Pulo` sem áudio (`batalha/sons_batalha.tscn`) | pendente | |
| 19 | Arthur leva dano | até 1 s | ataque do inimigo que tira vida do Arthur; toca junto com o som da rodada | silêncio: `AudioStreamPlayer` `DanoRecebido` sem áudio (`batalha/sons_batalha.tscn`) | pendente | |
| 20 | Vitória (opcional) | 2 a 4 s | tela de vitória da luta (tocador de vitória em `fim_de_luta`) | silêncio: `AudioStreamPlayer` `SomVitoria` sem áudio (`luta_avulsa/fim_de_luta.tscn`) | pendente | |
| 21 | Derrota (opcional) | 2 a 4 s | tela de derrota da luta (tocador de derrota em `fim_de_luta`) | silêncio: `AudioStreamPlayer` `SomDerrota` sem áudio (`luta_avulsa/fim_de_luta.tscn`) | pendente | |
| 22 | Música de batalha | 1 a 2 min, em loop | durante a luta (tocador de música em `sons_batalha`) | silêncio: `AudioStreamPlayer` `Musica` sem áudio, com `autoplay` (`batalha/sons_batalha.tscn`) | pendente | |

Clima pedido na visão do jogo: aventura séria, no estilo de Slay the Spire.

### Onde colocar os arquivos

| Tipo | Pasta |
|---|---|
| Arthur e inimigos | `combatentes/sprites/` |
| Cartas e ícones de efeito | `cartas/sprites/` |
| Fundo, ícones de status, molduras | `batalha/sprites/` |
| Fonte | `fontes/` |
| Sons e música | `batalha/sons/` |

As pastas são criadas quando o primeiro arquivo chegar.
