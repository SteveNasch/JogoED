# Feature Specification: Núcleo da batalha

**Feature Branch**: `001-nucleo-batalha`

**Created**: 2026-11-13

**Status**: Draft

**Input**: User description: "Leia docs/visao-do-jogo.md para entender o jogo inteiro. Esta
funcionalidade cobre SÓ o núcleo da batalha: uma luta completa do Arthur contra um inimigo,
com a regra de combate descrita na seção COMBATE da visão (alvo por rodada, mão persistente de
5 cartas mais 1 por rodada, montagem da expressão com desfazer e limpar, operadores e
precedência, dano igual à soma do ataque das cartas, erro sem dano, ataque do inimigo ao fim
de toda rodada, Pular, cartas especiais Chama, Foco, Guarda e Vital com escudo e cura indo
para o Arthur, garantia de mão mínima e alvo alcançável) e as telas de vitória e derrota da
luta. Fora desta funcionalidade: mapa, atos, chefes, prova, recompensas, descanso, história,
menus, tutorial e arte final. Os sprites e sons ficam como placeholders neutros do Godot,
registrados como pendência."

Referência do jogo inteiro: `docs/visao-do-jogo.md` (seção "Combate").

## Clarifications

### Session 2026-11-13

- Q: Que baralho a luta desta funcionalidade usa, se as especiais e ÷, x2, /2 e ^2 só
  chegariam pelas recompensas? → A: o baralho inicial da visão mais 1 de cada carta extra
  (Chama, Foco, Guarda, Vital, ÷, x2, /2 e ^2), 21 cartas; a partir da 002 a luta recebe o
  baralho da run.
- Q: Quando a mão fica pequena demais para cumprir o mínimo só trocando cartas, o que vale?
  → A: completar só o que falta: depois da carta da rodada, o jogo troca cartas que sobram e,
  se ainda faltar, dá as cartas que faltam. "1 carta por rodada" passa a ser "pelo menos 1".
- Q: A divisão arredonda para baixo ou só vale a divisão exata? → A: arredonda para baixo,
  como no jogo antigo (7 ÷ 2 = 3; 5 /2 = 2).
- Q: Quando o acerto do Arthur derruba o inimigo, o inimigo ainda ataca antes de a luta
  acabar? → A: não; inimigo derrotado não age e a vitória vem na hora.
- Q: Enquanto o jogador monta a conta, o jogo mostra quanto ela está valendo? → A: não; nem
  o valor nem se ela é válida aparecem antes de confirmar.
- Q: O alvo pode ser resolvido com uma carta só? → A: sim; qualquer valor alcançável na
  faixa vale, inclusive igual a uma carta da mão.
- Q: O escudo da Guarda dura só até o ataque daquela rodada ou se acumula? → A: só aquela
  rodada; o que sobrar zera no início da rodada seguinte.
- Q: Depois de cada confirmação ou Pular, o jogo espera um clique ou avança sozinho? → A:
  avança sozinho; o resultado fica na tela por cerca de 1,5 s e a rodada seguinte começa.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Vencer uma luta montando contas (Priority: P1)

O jogador abre a luta e vê o Arthur, o inimigo, a vida dos dois, o número-alvo da rodada e a
mão de cartas. Ele escolhe cartas da mão, em ordem, para montar uma expressão (por exemplo
`3 + 4 × 2`) e confirma. Se a conta der exatamente o alvo, o inimigo perde vida igual à soma
do ataque das cartas usadas. Ao fim da rodada o inimigo ataca o Arthur, uma carta nova chega
à mão e um alvo novo aparece. Quando a vida do inimigo chega a zero, aparece a tela de vitória.

**Why this priority**: é o laço central do jogo; sem ele nenhuma outra parte existe. Sozinha,
esta história já é uma luta jogável do começo ao fim.

**Independent Test**: começar uma luta, acertar o alvo em rodadas seguidas até o inimigo
cair e conferir o dano de cada acerto, o ataque do inimigo a cada rodada, a carta nova por
rodada e a tela de vitória.

**Acceptance Scenarios**:

1. **Given** uma luta nova, **When** ela começa, **Then** o Arthur tem 40 de vida e 0 de
   escudo, o inimigo tem a vida cheia, a mão tem 5 cartas e um alvo alcançável com essas
   cartas é mostrado.
2. **Given** o inimigo com 20 de vida, alvo 11 e a mão com 3, +, 4, × e 2, **When** o
   jogador monta `3 + 4 × 2` e confirma, **Then** a conta vale 11 (o × vem antes do +), o
   inimigo perde 3 + 1 + 4 + 3 + 2 = 13 de vida (fica com 7), as cinco cartas vão para o
   descarte e o inimigo ataca o Arthur.
3. **Given** o fim de uma rodada com os dois vivos e a mão já cumprindo o mínimo (FR-006),
   **When** a rodada seguinte começa, **Then** exatamente 1 carta nova entra na mão, as cartas que sobraram continuam nela e um
   alvo novo aparece.
4. **Given** um acerto que leva a vida do inimigo a 0, **When** o dano é aplicado, **Then** a
   luta acaba na hora com a tela de vitória, sem ataque do inimigo.
5. **Given** a tela de vitória, **When** o jogador escolhe lutar de novo, **Then** uma luta
   nova começa do zero (vida cheia dos dois, baralho embaralhado, mão de 5).

---

### User Story 2 - Errar, apanhar e perder (Priority: P2)

O jogador monta uma expressão que não dá o alvo (ou que não é uma conta válida, como
`3 4 +`) e confirma. As cartas usadas são gastas, o inimigo não perde vida, o jogo mostra o
valor que a conta deu (ou que ela é inválida) e o inimigo ataca. Se a vida do Arthur chega a
zero, aparece a tela de derrota.

**Why this priority**: sem o custo do erro e sem a derrota a luta não tem desafio; depende da
história 1.

**Independent Test**: confirmar contas erradas e inválidas e conferir que não há dano, que
as cartas foram gastas e que o Arthur apanha; repetir até a derrota.

**Acceptance Scenarios**:

1. **Given** alvo 9, **When** o jogador confirma `2 + 5` (vale 7), **Then** o inimigo não
   perde vida, as duas cartas numéricas e o + vão para o descarte, o jogo mostra "7, alvo era
   9" e o inimigo ataca o Arthur.
2. **Given** qualquer alvo, **When** o jogador confirma uma expressão inválida (`3 4`, `+ 3`,
   `5 ×` ou `6 ÷ 0`), **Then** o resultado é igual ao de um erro: cartas gastas, sem dano,
   aviso de conta inválida e ataque do inimigo.
3. **Given** o Arthur com vida menor ou igual ao ataque do inimigo e sem escudo, **When** a
   rodada termina, **Then** a luta acaba com a tela de derrota.
4. **Given** a tela de derrota, **When** o jogador escolhe tentar de novo, **Then** uma luta
   nova começa do zero.

---

### User Story 3 - Corrigir a conta e usar o Pular (Priority: P2)

Antes de confirmar, o jogador pode desfazer a última carta posta ou limpar a expressão
inteira, e as cartas voltam para a mão sem custo. Se nenhuma conta parece possível ou boa,
ele usa o Pular: abre mão da rodada, recebe o ataque do inimigo e ganha uma carta extra.

**Why this priority**: dá controle e estratégia ao jogador (trocar vida por cartas); depende
da história 1.

**Independent Test**: montar e desmontar expressões conferindo a mão; usar o Pular e
conferir a vida do Arthur e o tamanho da mão.

**Acceptance Scenarios**:

1. **Given** a expressão `3 + 4`, **When** o jogador desfaz, **Then** a expressão vira
   `3 +` e o 4 volta para a mão; a rodada continua.
2. **Given** uma expressão com cartas, **When** o jogador limpa, **Then** todas as cartas
   voltam para a mão, a expressão fica vazia e a rodada continua.
3. **Given** a mão com 4 cartas e expressão vazia, **When** o jogador usa o Pular, **Then** o
   inimigo ataca o Arthur, 1 carta extra entra na mão e a rodada seguinte começa com a sua
   carta normal, deixando a mão com 6 cartas.
4. **Given** a expressão vazia, **When** o jogador tenta confirmar, **Then** nada acontece
   (a confirmação fica indisponível) e a rodada continua.

---

### User Story 4 - Cartas especiais (Priority: P3)

Algumas cartas de número trazem um efeito extra que só acontece quando a conta acerta o alvo:
Chama causa dano adicional ao inimigo, Foco compra uma carta, Guarda dá escudo ao Arthur e
Vital cura o Arthur.

**Why this priority**: dão variedade às lutas, mas a luta funciona sem elas.

**Independent Test**: acertar contas que usam cada carta especial e conferir o efeito; errar
uma conta com carta especial e conferir que nada acontece.

**Acceptance Scenarios**:

1. **Given** um acerto que usa a Chama, **When** o dano é aplicado, **Then** o inimigo
   perde a soma do ataque das cartas mais 3.
2. **Given** um acerto que usa o Foco, **When** os efeitos são aplicados, **Then** 1 carta
   entra na mão na hora, antes do ataque do inimigo.
3. **Given** um acerto que usa a Guarda e o inimigo com ataque 3, **When** o inimigo ataca
   no fim da rodada, **Then** o escudo de 5 absorve o ataque inteiro, o Arthur não perde vida
   e o escudo que sobrou zera ao começar a rodada seguinte.
4. **Given** o Arthur com 39 de 40 de vida, **When** acerta uma conta com a Vital, **Then**
   ele fica com 40 (a cura não passa da vida máxima).
5. **Given** uma conta errada que usa qualquer carta especial, **When** é confirmada,
   **Then** nenhum efeito especial acontece.

---

### Edge Cases

- O alvo sorteado é igual a uma carta da mão (por exemplo, alvo 7 com um 7): confirmar só
  essa carta é um acerto, com o dano do ataque dela.
- A conta tem resultado intermediário negativo (`2 − 5 + 9`): é válida e vale 6.
- Unários encadeados (`3 ^2 x2` = 18) são aplicados na ordem, ao número que os antecede.
- Unário depois de operador binário ou no início (`3 + x2`, `^2 3`): conta inválida.
- Divisão com resto (`7 ÷ 2` = 3) e metade de número ímpar (`5 /2` = 2): arredondam para
  baixo (FR-014).
- A pilha de compra acaba: o descarte é embaralhado e vira a pilha de compra; se as duas
  estiverem vazias (todas as cartas na mão), a compra é pulada e a luta segue.
- A mão fica com 2 cartas depois de uma conta longa: na rodada seguinte entra a carta da
  rodada e o jogo completa o que faltar do mínimo (FR-006).
- O Pular é usado com cartas na expressão: elas voltam para a mão antes do ataque.
- O ataque do inimigo é menor que o escudo: o escudo absorve tudo e o resto zera na rodada
  seguinte.
- O jogador clica em cartas ou ações enquanto o resultado da rodada está na tela: nada
  acontece até a rodada seguinte começar.
- O Foco compra com as duas pilhas vazias: o efeito não faz nada e a luta segue.
- A garantia de mão mínima não consegue ser cumprida porque o baralho não tem cartas
  suficientes daquele tipo: a rodada começa com a melhor mão possível e o alvo continua
  alcançável.

## Requirements *(mandatory)*

### Functional Requirements

**Início e cartas**

- **FR-001**: A luta MUST começar com o Arthur com 40 de vida (máxima 40) e 0 de escudo, e
  com um inimigo de vida e ataque definidos nos dados do jogo (padrão: 12 de vida, 3 de
  ataque).
- **FR-002**: O baralho da luta MUST ter 21 cartas: o baralho inicial da visão (dois de cada
  número de 1 a 5, +, − e ×) mais uma de cada carta extra (Chama, Foco, Guarda, Vital, ÷, x2,
  /2 e ^2). Ele MUST ser embaralhado no início da luta.
- **FR-003**: No início da luta MUST entrar 5 cartas na mão. A cada rodada nova MUST entrar
  1 carta, mais as que a garantia de FR-006 exigir, antes de o alvo aparecer.
- **FR-004**: A mão MUST persistir entre as rodadas: só saem dela as cartas confirmadas numa
  expressão (acerto ou erro), que vão para o descarte.
- **FR-005**: Quando a pilha de compra estiver vazia e for preciso comprar, o descarte MUST
  ser embaralhado e virar a nova pilha de compra. Sem cartas nas duas, a compra é pulada.
- **FR-006**: No início de cada rodada, depois da carta da rodada, a mão MUST ter pelo menos
  3 cartas de número, 1 de soma e 1 de subtração. Para isso o jogo MUST primeiro trocar
  cartas que sobram por cartas do tipo que falta, vindas das pilhas (as trocadas vão para o
  descarte), e, se não houver cartas sobrando para trocar, dar as cartas que faltam. Se o
  baralho não tiver cartas daquele tipo fora da mão, a rodada começa com a melhor mão
  possível.
- **FR-007**: Cada rodada MUST sortear um alvo inteiro positivo dentro da faixa dos dados do
  jogo (padrão: 5 a 12) que seja alcançável com as cartas da mão naquele momento, usando cada
  carta no máximo uma vez e as regras de FR-012 a FR-015. Valores alcançáveis com uma carta
  só também valem. Se nenhum valor da faixa for alcançável, o alvo MUST ser o valor positivo
  alcançável mais próximo da faixa.

**Montagem da expressão**

- **FR-008**: O jogador MUST poder escolher cartas da mão, uma por vez; cada carta escolhida
  sai da mão e entra no fim da expressão, que fica visível na ordem montada.
- **FR-009**: O jogador MUST poder desfazer (a última carta da expressão volta para a mão) e
  limpar (todas voltam para a mão). Nenhum dos dois encerra a rodada nem tem custo.
- **FR-010**: Qualquer sequência de cartas MUST poder ser montada. Antes de confirmar, o
  jogo MUST NOT mostrar o valor da expressão nem se ela é válida; os dois só aparecem depois
  da confirmação.
- **FR-011**: Confirmar MUST ficar indisponível enquanto a expressão estiver vazia.

**Avaliação da conta**

- **FR-012**: Uma expressão MUST ser válida só se começa com número, alterna número e
  operador de duas parcelas (+, −, ×, ÷) e termina em número ou em operador de uma parcela;
  os operadores de uma parcela (x2, /2, ^2) só podem vir logo depois de um número ou de outro
  operador de uma parcela. Divisão por zero torna a expressão inválida.
- **FR-013**: A conta MUST seguir a precedência: primeiro x2, /2 e ^2, aplicados ao número
  logo antes deles e na ordem em que aparecem; depois × e ÷, da esquerda para a direita;
  depois + e −, da esquerda para a direita.
- **FR-014**: A divisão (÷) e a metade (/2) MUST dar um número inteiro arredondado para
  baixo (7 ÷ 2 = 3; 5 /2 = 2; −7 ÷ 2 = −4).
- **FR-015**: Resultados negativos, intermediários ou finais, MUST ser permitidos.

**Resultado da rodada**

- **FR-016**: Se o resultado for exatamente o alvo, o inimigo MUST perder vida igual à soma
  do ataque de todas as cartas usadas (números e operadores, conforme a tabela de cartas) e,
  em seguida, os efeitos das cartas especiais usadas MUST ser aplicados.
- **FR-017**: Efeitos especiais: Chama MUST causar 3 de dano adicional ao inimigo; Foco MUST
  colocar 1 carta na mão na hora; Guarda MUST dar 5 de escudo ao Arthur; Vital MUST curar 2
  de vida do Arthur sem passar da vida máxima.
- **FR-018**: O escudo MUST absorver dano antes da vida e MUST zerar no início da rodada
  seguinte (ele protege só do ataque da rodada em que foi ganho e não se acumula entre
  rodadas).
- **FR-019**: Se a expressão for inválida ou der outro valor, as cartas usadas MUST ir para
  o descarte, sem dano e sem efeitos especiais, e o jogo MUST mostrar o valor obtido (ou que
  a conta é inválida) junto do alvo.
- **FR-020**: O jogador MUST poder usar o Pular a qualquer momento da rodada: cartas na
  expressão voltam para a mão, o inimigo ataca, 1 carta extra entra na mão e a rodada
  seguinte começa normalmente (com a sua própria carta).
- **FR-021**: Toda rodada (acerto, erro ou Pular) MUST terminar com o inimigo atacando o
  Arthur com o seu valor de ataque, exceto quando o inimigo foi derrotado naquela rodada.
- **FR-022**: Quando a vida do inimigo chegar a 0, a luta MUST acabar com vitória; quando a
  vida do Arthur chegar a 0, MUST acabar com derrota. A vida nunca fica negativa.

**Telas**

- **FR-023**: Durante a luta MUST ficar visíveis: vida e escudo do Arthur, vida e ataque do
  inimigo, alvo, mão, expressão em montagem e as ações Desfazer, Limpar, Confirmar e Pular.
- **FR-024**: Cada carta MUST mostrar o seu número ou símbolo, o seu valor de ataque e, se
  for especial, o nome e o efeito.
- **FR-025**: Depois de cada confirmação ou Pular, o jogo MUST mostrar o que aconteceu: dano
  causado e efeitos (acerto), valor obtido ou conta inválida (erro) e dano recebido pelo
  Arthur. O resultado MUST ficar na tela por cerca de 1,5 segundo (valor nos dados) e a
  rodada seguinte (ou a tela de vitória ou derrota) MUST começar sozinha, sem clique. Nesse
  intervalo as ações do jogador ficam indisponíveis.
- **FR-026**: A tela de vitória MUST mostrar a vitória, a vida restante do Arthur e quantas
  rodadas a luta durou, com a opção de lutar de novo.
- **FR-027**: A tela de derrota MUST mostrar a derrota, a vida restante do inimigo e quantas
  rodadas a luta durou, com a opção de tentar de novo.

**Dados e assets**

- **FR-028**: Vida e ataque do Arthur e do inimigo, faixa do alvo, mínimo da mão, composição
  do baralho e valor, ataque e efeito de cada carta MUST ficar em dados editáveis sem mexer
  no código.
- **FR-029**: A mesma semente de sorteio MUST reproduzir a mesma luta (embaralhamento, mãos
  e alvos), para que os testes sejam repetíveis.
- **FR-030**: Arthur, inimigo, cartas, fundo e sons MUST usar placeholders neutros do motor,
  e cada um MUST constar numa lista de assets pendentes no projeto, com o que é preciso
  (tipo, tamanho, quadros, formato) e onde será usado.

### Key Entities *(include if feature involves data)*

- **Carta**: número ou operador. Tem o valor na conta, o valor de ataque e, se especial, um
  efeito com intensidade. Valores padrão (do Answer Quest antigo):

  | Carta | Na conta | Ataque | Efeito |
  |---|---|---|---|
  | 1, 2, 3, 4, 5 | o próprio número | 1, 2, 3, 4, 5 | — |
  | 6, 7, 8, 9, 10 | o próprio número | 3, 4, 4, 5, 6 | — |
  | + | soma | 1 | — |
  | − | subtração | 1 | — |
  | × | multiplicação | 3 | — |
  | ÷ | divisão | 3 | — |
  | x2 | dobra o número anterior | 2 | — |
  | /2 | metade do número anterior | 3 | — |
  | ^2 | quadrado do número anterior | 4 | — |
  | Chama | 5 | 5 | +3 de dano ao inimigo |
  | Foco | 4 | 1 | compra 1 carta |
  | Guarda | 6 | 2 | 5 de escudo ao Arthur |
  | Vital | 7 | 3 | cura 2 do Arthur |

- **Baralho da luta**: as cartas da luta divididas em pilha de compra, mão, expressão e
  descarte; cada carta está em exatamente um desses lugares.
- **Combatente**: Arthur ou inimigo. Tem nome, vida atual, vida máxima e escudo; o inimigo
  tem também o valor de ataque.
- **Rodada**: alvo, expressão montada e resultado (acerto, erro, conta inválida ou Pular).
- **Luta**: os dois combatentes, o baralho, o número da rodada e o estado final (em
  andamento, vitória ou derrota).
- **Asset pendente**: item da lista de placeholders, com descrição e onde é usado.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um jogador que leu a regra consegue terminar uma luta contra o inimigo padrão,
  vencendo ou perdendo, em até 5 minutos.
- **SC-002**: Em 1.000 lutas simuladas com sementes diferentes, 100% dos alvos sorteados são
  alcançáveis com a mão da rodada.
- **SC-003**: Em 1.000 lutas simuladas, 100% das mãos de início de rodada cumprem o mínimo de
  3 números, 1 soma e 1 subtração sempre que o baralho tiver cartas para isso.
- **SC-004**: Um conjunto de pelo menos 30 expressões de referência (precedência, unários
  encadeados, divisão, negativos e inválidas) é avaliado 100% de acordo com FR-012 a FR-015.
- **SC-005**: Depois de cada ação do jogador, o resultado (dano, erro, ataque recebido)
  aparece na tela em menos de 1 segundo.
- **SC-006**: A luta pode ser jogada do início até a vitória e até a derrota sem nenhum asset
  fornecido pela equipe, e 100% dos placeholders usados estão na lista de pendências.
- **SC-007**: Mudar um valor de equilíbrio (por exemplo a vida do inimigo) nos dados muda a
  luta seguinte sem nenhuma alteração no código.
- **SC-008**: A mesma semente, com as mesmas ações do jogador, produz a mesma luta em 100%
  das repetições.

## Assumptions

- Os números padrão (vida 40 do Arthur, inimigo com 12 de vida e 3 de ataque, faixa de alvo
  5 a 12, ataque das cartas e intensidade dos efeitos) vêm do Answer Quest antigo e podem
  ser ajustados nos dados sem mudar esta especificação.
- Inimigo derrotado não ataca (confirmado no clarify): a frase da visão "toda rodada
  termina com o ataque do inimigo" vale enquanto ele está vivo; o jogo antigo fazia diferente.
- A mão não tem limite de tamanho; o limite natural é o próprio baralho.
- Nesta funcionalidade cada luta é independente e começa com o Arthur com 40 de vida; a vida
  passando de uma luta para a outra é da funcionalidade 002.
- Existe um único inimigo padrão, com nome provisório definido nos dados; nomes, visual e
  inimigos diferentes ficam para as próximas funcionalidades.
- "Lutar de novo" e "Tentar de novo" só reiniciam esta luta, porque mapa e menus estão fora
  desta funcionalidade.
- Jogo para PC, jogado com mouse; atalhos de teclado não são exigidos.
- Fora do escopo: mapa, atos, chefes, prova, recompensas, descanso, história, menus,
  tutorial, explicação dos símbolos e arte e som finais.
