# Visão do jogo: Answer Quest

Documento de referência para todos os `/speckit-specify`. Ele descreve o jogo inteiro; cada
funcionalidade (seção "Funcionalidades", no fim) implementa só uma parte.

Origem: entrevista com o Estêvão em 13/11/2026. A regra de combate vem do Answer Quest antigo
(repositório público `answer-quest`), mantida de propósito; tema, história e visual são novos.

## Resumo

Roguelike de cartas em que o jogador monta contas matemáticas com cartas de número e de
operador para derrotar inimigos, subindo um castelo em três atos até enfrentar a "prova" como
chefe final. Jogo para PC, só em português, para entretenimento geral, com um lado educativo
declarado. Uma run completa dura de 20 a 30 minutos.

## História e tema

Arthur, um estudante, estudava para uma prova difícil de matemática quando foi engolido pelo
próprio livro e acordou no calabouço de um castelo fantástico. Para sair, ele sobe os andares
do castelo em três atos: o calabouço (ato 1), os salões (ato 2) e a torre mais alta (ato 3).
O chefe final, no topo da torre, é a própria prova. Ao vencê-la, Arthur acorda do sonho.

- Clima: aventura séria, no estilo de Slay the Spire.
- Visual: pixel art.
- Inimigos: monstros cuja aparência traz pequenas referências ao estilo de ataque deles. A
  diferença é só visual: todos seguem a mesma regra de combate (vida e dano).
- Chefes dos atos 1 e 2 (sugestão, a aprovar pela equipe): "Carcereiro da Tabuada"
  (calabouço) e "Bibliotecário Esquecido" (salões).

## Combate

- Cada rodada mostra um número-alvo. O jogador monta uma expressão escolhendo cartas da mão,
  em ordem, e confirma.
- Cartas de número: valores de 1 a 10. Cartas de operador: soma (+), subtração (−),
  multiplicação (×), divisão (÷), dobrar (x2), metade (/2) e quadrado (^2).
- x2, /2 e ^2 se aplicam ao número imediatamente antes delas. Precedência matemática usual:
  primeiro x2, /2 e ^2, depois × e ÷, depois + e −.
- A divisão usa números inteiros e arredonda para baixo; divisão por zero é inválida.
- Se a expressão der exatamente o alvo, o inimigo recebe dano igual à soma do valor de ataque
  das cartas usadas, e os efeitos especiais das cartas são aplicados.
- Se a expressão for inválida ou der outro valor, as cartas usadas são gastas e não há dano.
- Toda rodada termina com o ataque do inimigo ao Arthur, acertando ou não, enquanto o
  inimigo está vivo: o acerto que o derrota encerra a luta sem ataque (decidido na spec 001).
- Antes de confirmar, o jogador pode desfazer a última carta ou limpar a expressão.
- "Pular": o jogador abre mão de tentar, recebe o ataque do inimigo e ganha uma carta extra.
- Mão persistente: 5 cartas no início da batalha e 1 a cada rodada nova, mais as que a
  garantia de mão mínima exigir (decidido na spec 001: o jogo nunca tira cartas da mão, só
  completa o que falta). Cartas jogadas vão para o descarte.
- Baralho inicial: dois de cada número de 1 a 5, além de +, − e ×.
- Arthur começa com 40 de vida, que passa de uma batalha para a outra.
- Cartas especiais são números com efeito extra: Chama (dano adicional), Foco (compra
  carta), Guarda (escudo para o Arthur) e Vital (cura o Arthur).
- A mão distribuída sempre garante o mínimo para resolver (pelo menos 3 números, uma soma e
  uma subtração), e todo alvo sorteado precisa ser alcançável.

## Run, mapa e progressão

- Cada ato tem um mapa curto gerado a cada run, com caminhos que se ramificam. Casas
  possíveis: batalha, elite (inimigo mais forte), descanso (cura parte da vida), recompensa
  (escolher 1 entre 3 cartas para o baralho) e, no fim, o chefe do ato.
- A dificuldade cresce com a profundidade: alvos maiores, que pedem mais cartas, e inimigos
  com mais vida e mais ataque.
- Todo o equilíbrio de dificuldade fica num único arquivo de dados, editável sem mexer no
  código.
- Se Arthur perde toda a vida, a run acaba e ele recomeça do calabouço, com mapa novo e o
  baralho inicial.

## Chefe final: a prova

A prova é dividida em "questões" em sequência. Cada questão é uma fase da luta com uma regra
própria (por exemplo, um alvo bem maior ou a obrigação de usar um operador específico). Vencer
todas as questões vence a prova.

## Lado educativo

- A primeira batalha da primeira run funciona como tutorial: ensina a montar a expressão, a
  precedência dos operadores, o "Pular" e o efeito das cartas especiais.
- Cada símbolo matemático é explicado ao jogador na primeira vez em que aparece, com um
  exemplo curto.

## Telas

Menu principal; cena curta de abertura (Arthur estudando e sendo engolido pelo livro); mapa
do ato; batalha; descanso; recompensa; pausa durante a run com volume separado de música e de
efeitos; derrota; cena final (Arthur acorda); créditos (equipe, além de origem e licença de
cada sprite, música e som usados).

## Som

Música e efeitos sonoros fornecidos pela equipe, no clima de aventura séria do jogo.

## Fora do escopo

Multijogador, celular, outros idiomas, compras, conta online, comportamentos diferentes por
tipo de inimigo.

## Pontos em aberto (para os `/speckit-clarify`)

- ~~Quantas questões a prova tem~~ Decidido em 17/11 (corte de escopo): até 3. A regra de cada
  uma fica para o clarify da 003.
- ~~Quanto o descanso cura (no jogo antigo, 8 de vida)~~ Decidido em 13/11 (spec 002): 30%
  da vida máxima (12).
- ~~Quantas casas tem cada ato~~ Decidido em 13/11 (spec 002): 5 andares (4 comuns, de 2 a 3
  casas, e o chefe). Elite e chefe também dão recompensa de carta.
- ~~Se a divisão que arredonda para baixo continua ou se só vale divisão exata~~ Decidido em
  13/11 (spec 001): continua arredondando para baixo.
- Se existe algum registro entre runs, como o melhor resultado.

## Funcionalidades

Uma por `/speckit-specify`, nesta ordem. Cada uma só começa quando a anterior estiver com os
testes passando e com commit. Ciclo de cada uma: specify → clarify → plan → tasks → analyze →
implement.

| # | Funcionalidade | Prazo sugerido | Modelo no `plan` |
|---|---|---|---|
| 001 | Núcleo da batalha | 20/11 | Fable 5.2, `high` |
| 002 | Run e mapa | 20/11 | Fable 5.2, `high` |
| 003 | Chefes e a prova (enxuta) | 28/11 | Opus 5.5, `xhigh` |
| 004 | Telas, história e tutorial (antigas 004 e 005) | 29/11 | Opus 5.5, `xhigh` |

Tarde de 29/11: trocar placeholders pela arte da equipe, corrigir e ensaiar. Entrega: 30/11.
Replanejado em 17/11; o calendário dia a dia está em [roteiro-speckit.md](roteiro-speckit.md).

Arte e som não têm specify próprio: pela constituição (princípio IV), o código usa
placeholders neutros registrados como pendência, e a equipe troca conforme os arquivos chegam.

### Prompts prontos

001, núcleo da batalha:

```text
/speckit-specify Leia docs/visao-do-jogo.md para entender o jogo inteiro. Esta funcionalidade cobre SÓ o núcleo da batalha: uma luta completa do Arthur contra um inimigo, com a regra da seção "Combate" da visão (alvo por rodada, mão persistente de 5 cartas mais 1 por rodada, montagem da expressão com desfazer e limpar, operadores e precedência, dano igual à soma do ataque das cartas, erro sem dano, ataque do inimigo ao fim de toda rodada, Pular, cartas especiais Chama, Foco, Guarda e Vital com escudo e cura indo para o Arthur, garantia de mão mínima e alvo alcançável) e as telas de vitória e derrota da luta. Fora desta funcionalidade: mapa, atos, chefes, prova, recompensas, descanso, história, menus, tutorial e arte final. Sprites e sons ficam como placeholders neutros do Godot, registrados como pendência.
```

002, run e mapa:

```text
/speckit-specify Leia docs/visao-do-jogo.md para entender o jogo inteiro. A batalha (funcionalidade 001) já existe. Esta funcionalidade cobre SÓ a run e o mapa, conforme a seção "Run, mapa e progressão" da visão: três atos (calabouço, salões, torre), cada um com um mapa curto gerado a cada run e caminhos ramificados; casas de batalha, elite, descanso e recompensa (escolher 1 entre 3 cartas); vida do Arthur e baralho que passam de uma casa para a outra; dificuldade crescendo com a profundidade e definida num único arquivo de dados editável sem mexer no código; derrota que encerra a run e recomeça do calabouço com mapa novo e baralho inicial. A casa de chefe de cada ato existe no mapa, mas usa por enquanto uma batalha comum mais forte (os chefes de verdade são a funcionalidade 003). Fora desta funcionalidade: chefes especiais, prova, história, menus e tutorial.
```

003, chefes e a prova:

```text
/speckit-specify Leia docs/visao-do-jogo.md para entender o jogo inteiro. A batalha (001) e a run com mapa (002) já existem. Esta funcionalidade cobre SÓ os chefes, em versão enxuta: o chefe do calabouço e o dos salões, no fim dos atos 1 e 2, são batalhas de elite reforçadas (mais vida e mais ataque, sem regra própria), com os valores no arquivo de dados de dificuldade; e a prova como chefe final da torre, conforme a seção "Chefe final: a prova" da visão, com no máximo 3 questões em sequência, cada uma uma fase com regra própria; vencer todas vence a prova e encerra a run com vitória. Fora desta funcionalidade: cenas de história, menus e tutorial.
```

004, telas, história e tutorial (as antigas 004 e 005, juntas em 17/11):

```text
/speckit-specify Leia docs/visao-do-jogo.md para entender o jogo inteiro. Batalha (001), run e mapa (002) e chefes (003) já existem. Esta funcionalidade cobre as telas, a história e o lado educativo, em versão enxuta, conforme as seções "História e tema", "Telas" e "Lado educativo" da visão: menu principal; cena de abertura e cena final como telas de texto com imagem fixa (Arthur estudando e sendo engolido pelo livro; Arthur acorda depois de vencer a prova); tela de derrota; pausa durante a run com volume separado de música e de efeitos; créditos com a equipe e a origem e licença de cada asset; e a primeira batalha da primeira run como tutorial por dicas de texto, passo a passo (montar a expressão, precedência dos operadores, Pular e cartas especiais), que o jogador pode pular, com cada símbolo matemático explicado numa dica curta na primeira vez em que aparece. Textos só em português.
```
