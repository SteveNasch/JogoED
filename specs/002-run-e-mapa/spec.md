# Feature Specification: Run e mapa

**Feature Branch**: nenhum; o trabalho é feito direto em `main`, e a funcionalidade é
identificada pela pasta `specs/002-run-e-mapa` (`.specify/feature.json`)

**Created**: 2026-11-13

**Status**: Draft

**Input**: User description: "Leia docs/visao-do-jogo.md para entender o jogo inteiro. A
batalha (funcionalidade 001) já existe. Esta funcionalidade cobre SÓ a run e o mapa,
conforme a seção "Run, mapa e progressão" da visão: três atos (calabouço, salões, torre),
cada um com um mapa curto gerado a cada run e caminhos ramificados; casas de batalha, elite,
descanso e recompensa (escolher 1 entre 3 cartas); vida do Arthur e baralho que passam de uma
casa para a outra; dificuldade crescendo com a profundidade e definida num único arquivo de
dados editável sem mexer no código; derrota que encerra a run e recomeça do calabouço com
mapa novo e baralho inicial. A casa de chefe de cada ato existe no mapa, mas usa por enquanto
uma batalha comum mais forte (os chefes de verdade são a funcionalidade 003). Fora desta
funcionalidade: chefes especiais, prova, história, menus e tutorial."

Referência do jogo inteiro: `docs/visao-do-jogo.md` (seção "Run, mapa e progressão"). A luta
em si é a da 001 (`specs/001-nucleo-batalha/spec.md`) e não muda aqui.

## Clarifications

### Session 2026-11-13

- Q: Quantos andares cada ato tem e quantas casas por andar? → A: 5 andares contando o do
  chefe (4 comuns e o chefe), com 2 ou 3 casas em cada andar comum (valores nos dados).
- Q: Além da casa de recompensa, quais vitórias em luta dão a escolha de 1 entre 3 cartas?
  → A: a elite e o chefe; a batalha comum não dá carta. O chefe do ato 3 encerra a run, então
  não dá recompensa.
- Q: Quanto a casa de descanso cura? → A: 30% da vida máxima, arredondado para baixo (12 com
  a máxima de 40); a porcentagem fica nos dados.

### Session 2026-11-18

- Q: O jogo deve guardar alguma coisa entre uma run e outra? → A: não; nada é guardado (nem a
  run em andamento nem o melhor resultado), e fechar o jogo perde a run.
- Q: Nos andares 2 a 4, onde podem cair a elite, os descansos e as recompensas? → A: sorteio
  com duas regras: a elite nunca fica no andar 2, e o último andar comum (o 4, no padrão) tem
  pelo menos um descanso.
- Q (no plan): Com o baralho inicial, a mão do começo de uma luta chega no máximo a 10, abaixo
  da faixa padrão do ato 3 (12 a 24). Isso precisa mudar? → A: não; é esperado. São as cartas
  ganhas durante a run que tornam as faixas maiores alcançáveis; até lá, o alvo é o valor
  possível mais próximo da faixa (regra da 001). Os valores padrão ficam (medição no research
  da 002, D7).
- Q (no analyze): A run nova tem de ter um mapa diferente do anterior? → A: tem de ter uma
  semente nova; duas sementes podem, muito raramente, dar o mesmo mapa. O teste da cena confere
  a semente nova, e a diferença de mapa é conferida na lógica, com sementes fixas (SC-006).
- Q (no analyze): Mudar o arquivo de dificuldade vale já no "Começar de novo"? → A: não; o
  arquivo é lido uma vez, então a mudança vale na próxima vez que o jogo abrir (FR-027,
  SC-005). Ler de novo a cada run seria código que nada pede.
- Q (no analyze): E se os dados pedirem um mapa que não cabe na tela (casas saindo pelas
  pontas ou andares sobrepostos)? → A: é erro de dados (FR-028): no máximo 7 casas num andar e
  8 andares comuns, o que cabe na tela do mapa de 640×360.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Atravessar o calabouço pelo mapa (Priority: P1)

O jogador abre o jogo e vê o mapa do calabouço (ato 1): casas ligadas por caminhos que se
ramificam, do primeiro andar até o chefe no topo. Ele escolhe uma das casas do primeiro
andar, luta, volta ao mapa com a vida que sobrou e escolhe a próxima casa entre as ligadas à
atual. Assim ele sobe andar por andar até a casa do chefe; vencendo o chefe, o ato termina.

**Why this priority**: é o que transforma lutas soltas em uma run; sem o mapa e a vida que
passa de uma luta para a outra, nenhuma outra parte desta funcionalidade existe. Sozinha,
esta história já é um ato jogável do começo ao fim.

**Independent Test**: começar uma run, conferir o mapa do ato 1 (andares, ligações, tipos de
casa), percorrer um caminho até o chefe vencendo as lutas e conferir que a vida no início de
cada luta é a que sobrou da anterior.

**Acceptance Scenarios**:

1. **Given** o jogo recém-aberto, **When** ele termina de carregar, **Then** aparece o mapa
   do calabouço com todas as casas e ligações à vista, o Arthur com 40 de 40 de vida, o
   baralho com 13 cartas e só as casas do primeiro andar disponíveis para escolher.
2. **Given** o Arthur numa casa do andar 2, **When** o jogador clica numa casa do andar 3
   ligada à atual, **Then** o conteúdo daquela casa começa; **When** clica numa casa não
   ligada, num andar abaixo ou dois andares acima, **Then** nada acontece.
3. **Given** o Arthur com 31 de vida escolhendo uma casa de batalha, **When** a luta começa,
   **Then** ela começa com o Arthur com 31 de vida, o baralho da run e um inimigo comum do
   calabouço com a vida e o ataque da profundidade daquela casa.
4. **Given** uma luta vencida com o Arthur terminando com 24 de vida, **When** o jogador
   volta ao mapa, **Then** a casa aparece como visitada, o Arthur está nela, a vida mostrada é
   24 de 40 e só as casas do andar seguinte ligadas a ela ficam disponíveis.
5. **Given** o Arthur no último andar antes do chefe, **When** escolhe a casa do chefe e
   vence a luta, **Then** o ato 1 termina e, depois da recompensa do chefe (FR-022), começa o
   ato 2 (história 4).

---

### User Story 2 - Perder e recomeçar a run (Priority: P1)

Se a vida do Arthur chega a zero em qualquer luta, a run acaba: o jogo mostra até onde ele
chegou e oferece começar de novo. A run nova começa do calabouço, com mapa novo, vida cheia
e o baralho inicial; nada da run anterior fica.

**Why this priority**: sem a derrota que zera tudo não há roguelike; é a outra metade do laço
da história 1 e é pequena.

**Independent Test**: perder uma luta de propósito no meio de uma run em que o baralho já
ganhou cartas, conferir o resumo da derrota e conferir que a run nova tem semente nova (na
prática, outro mapa), vida 40 e as 13 cartas do baralho inicial.

**Acceptance Scenarios**:

1. **Given** uma run no ato 2 com 16 cartas no baralho, **When** a vida do Arthur chega a 0
   numa luta, **Then** a run acaba e aparece a tela de fim de run com o ato e o andar
   alcançados e quantas lutas foram vencidas.
2. **Given** a tela de fim de run por derrota, **When** o jogador escolhe começar de novo,
   **Then** aparece o mapa do calabouço gerado de novo (outra semente), o Arthur com 40 de 40
   de vida e o baralho com as 13 cartas iniciais.
3. **Given** uma derrota na casa do chefe, **When** a luta termina, **Then** o resultado é o
   mesmo de qualquer outra derrota.

---

### User Story 3 - Descansar e ganhar cartas (Priority: P2)

No caminho o jogador encontra casas de descanso, que curam parte da vida do Arthur, e casas
de recompensa, em que escolhe 1 entre 3 cartas para pôr no baralho (ou não pega nenhuma). A
mesma escolha aparece depois de vencer uma elite ou o chefe dos atos 1 e 2. As cartas ganhas
aparecem nas lutas seguintes da mesma run.

**Why this priority**: são as escolhas que dão estratégia ao mapa (que caminho seguir), mas
o laço de lutar e subir funciona sem elas.

**Independent Test**: passar por uma casa de descanso com a vida baixa e conferir a cura;
passar por uma casa de recompensa, escolher uma carta e conferir que ela está no baralho da
luta seguinte.

**Acceptance Scenarios**:

1. **Given** o Arthur com 20 de 40 de vida, **When** entra numa casa de descanso, **Then** a
   vida sobe 12 (30% da máxima), ficando com 32, o jogo mostra quanto curou e, ao continuar,
   volta ao mapa.
2. **Given** uma casa de recompensa, **When** ela abre, **Then** aparecem 3 cartas
   diferentes entre si, cada uma com o símbolo, o ataque e, se for especial, o efeito, mais a
   opção de não pegar nenhuma.
3. **Given** a escolha da Chama na recompensa, **When** o jogador volta ao mapa e entra na
   luta seguinte, **Then** o baralho da run tem 1 carta a mais e a Chama pode aparecer na mão
   daquela luta.
4. **Given** a recompensa aberta, **When** o jogador escolhe não pegar nenhuma, **Then** o
   baralho continua igual e o jogo volta ao mapa.
5. **Given** a vitória numa luta de elite ou de chefe dos atos 1 e 2, **When** o jogador
   continua depois do aviso de vitória, **Then** abre uma recompensa igual à da casa de
   recompensa e, depois dela, o jogo volta ao mapa (ou vai ao ato seguinte, no chefe).
6. **Given** a vitória numa batalha comum, **When** o jogador continua, **Then** o jogo
   volta direto ao mapa, sem recompensa.
7. **Given** o Arthur com 35 de 40 de vida, **When** entra numa casa de descanso, **Then**
   ele fica com 40 (a cura não passa da máxima) e o jogo mostra que curou 5.

---

### User Story 4 - Subir os três atos com dificuldade crescente (Priority: P2)

Depois do calabouço vêm os salões (ato 2) e a torre (ato 3), cada um com o próprio mapa. Quanto
mais fundo na run, maiores os alvos e mais fortes os inimigos. Quem cuida do equilíbrio muda
esses números num único arquivo de dados, sem mexer no código. Vencer o chefe da torre vence a
run.

**Why this priority**: completa a run inteira e o equilíbrio da dificuldade, mas depende das
histórias 1 e 2.

**Independent Test**: vencer o chefe do ato 1 e conferir a passagem para o ato 2 com a vida
e o baralho mantidos; conferir nos dados padrão que alvo, vida e ataque crescem com a
profundidade; mudar um número no arquivo de dificuldade e conferir o efeito ao abrir o jogo de novo;
vencer o chefe do ato 3 e conferir o fim da run com vitória.

**Acceptance Scenarios**:

1. **Given** o chefe do calabouço vencido com o Arthur com 18 de vida e 15 cartas no baralho,
   depois da recompensa do chefe, **When** o ato 2 começa, **Then** aparece o mapa dos salões, com o Arthur com 18 de vida,
   as mesmas 15 cartas e só as casas do primeiro andar disponíveis.
2. **Given** os dados padrão, **When** se compara uma batalha do primeiro andar do ato 1 com
   uma do primeiro andar do ato 3, **Then** a da torre tem faixa de alvo, vida e ataque do
   inimigo maiores.
3. **Given** o arquivo de dificuldade com a vida do inimigo comum do ato 1 trocada de 12 para
   20, **When** o jogo é aberto de novo e o jogador entra numa batalha do ato 1, **Then** o
   inimigo tem 20 de vida, sem nenhuma mudança no código.
4. **Given** o Arthur na casa do chefe da torre, **When** vence a luta, **Then** a run acaba
   com vitória e aparece a tela de fim de run com o resumo e a opção de começar de novo.
5. **Given** um arquivo de dificuldade com um erro (por exemplo, faixa de alvo com mínimo
   maior que o máximo), **When** o jogo abre, **Then** o jogo não começa a run e mostra qual
   valor está errado.

---

### Edge Cases

- O Arthur entra numa casa de descanso com a vida cheia: a cura é 0, o jogo mostra isso e
  volta ao mapa normalmente.
- A recompensa sorteia uma carta que o baralho já tem: vale; o baralho pode ter cópias.
- O conjunto de cartas de recompensa nos dados tem menos de 3 cartas: aparecem todas as que
  houver; se estiver vazio, a casa de recompensa mostra que não há cartas e volta ao mapa.
- O baralho cresce muito com recompensas: a luta continua garantindo a mão mínima e o alvo
  alcançável, como na 001.
- O Arthur chega a uma luta com 1 de vida: a luta começa normalmente com 1 de vida.
- Uma casa de um andar liga a uma só casa do andar seguinte: o jogador não tem escolha
  naquele passo, mas o mapa como um todo ainda tem caminhos ramificados.
- Os dados pedem mais casas de um tipo do que o ato comporta (por exemplo, 10 descansos num
  ato de 12 casas, com o primeiro andar só de batalhas): é um erro de dados, tratado como no
  cenário 5 da história 4.
- Os dados pedem um mapa que não cabe na tela (mais de 7 casas num andar ou mais de 8 andares
  comuns): também é erro de dados, tratado como no cenário 5 da história 4.
- O jogador clica no mapa enquanto uma casa está aberta (luta, descanso, recompensa): o mapa
  não reage até o jogador voltar a ele.
- O jogador fecha o jogo no meio da run: a run se perde; ao abrir de novo começa uma run nova.

## Requirements *(mandatory)*

### Functional Requirements

**Run**

- **FR-001**: Ao abrir o jogo, uma run nova MUST começar direto no mapa do ato 1 (calabouço),
  sem menu (o menu principal é da funcionalidade 004).
- **FR-002**: A run MUST começar com o Arthur com 40 de vida (máxima 40) e com o baralho
  inicial da visão: dois de cada número de 1 a 5, mais +, − e × (13 cartas), definido nos
  dados.
- **FR-003**: A vida do Arthur MUST passar de uma casa para a outra: toda luta começa com a
  vida atual da run, e a vida com que ele termina a luta vencida passa a ser a vida da run.
  A vida máxima não muda nesta funcionalidade.
- **FR-004**: O baralho da run MUST passar de uma casa para a outra: toda luta recebe o
  baralho da run inteiro (embaralhado no início da luta, como na 001), e as cartas ganhas na
  recompensa entram no baralho para todas as lutas seguintes da run. Jogar cartas numa luta
  não tira cartas do baralho da run.
- **FR-005**: Escudo, mão e pilhas de uma luta MUST NOT passar para a luta seguinte; cada
  luta começa como na 001, só com a vida e o baralho vindos da run.
- **FR-006**: Toda a run (mapas, inimigos, recompensas e as lutas) MUST ser reproduzível a
  partir de uma única semente: a mesma semente, com as mesmas escolhas e as mesmas jogadas,
  produz a mesma run. Cada run nova MUST usar uma semente nova.

**Mapa**

- **FR-007**: Cada ato MUST ter o próprio mapa, gerado de novo a cada run.
- **FR-008**: O mapa de um ato MUST ser formado por andares em sequência: os andares comuns e,
  no topo, um andar com uma casa só, a do chefe do ato. O número de andares comuns e o mínimo e
  o máximo de casas por andar comum ficam nos dados (padrão: 4 andares comuns, de 2 a 3 casas
  cada, mais o chefe; 5 andares no total).
- **FR-009**: Cada casa de um andar comum MUST ligar a pelo menos uma casa do andar
  seguinte, e toda casa de um andar acima do primeiro MUST receber ligação de pelo menos uma
  casa do andar anterior. Com isso toda casa é alcançável a partir do primeiro andar e de
  toda casa há caminho até o chefe.
- **FR-010**: Todo mapa MUST ter pelo menos dois caminhos diferentes do primeiro andar até o
  chefe, e as ligações MUST NOT se cruzar na tela.
- **FR-011**: As casas MUST ser de um destes tipos: batalha, elite, descanso, recompensa e
  chefe. Os dados definem quantas casas de cada tipo (batalha, elite, descanso e recompensa)
  cada ato tem (padrão por ato: 3 batalhas no primeiro andar e, nos andares 2 a 4, 8 casas: 3
  batalhas, 1 elite, 2 descansos e 2 recompensas). O primeiro andar de cada ato MUST ter só
  casas de batalha, e o andar do topo, só o chefe. Nos outros andares comuns os tipos são
  sorteados, com duas regras: a casa de elite MUST NOT ficar no andar 2, e o último andar
  comum (o 4, no padrão) MUST ter pelo menos uma casa de descanso.
- **FR-012**: O mapa MUST mostrar o ato inteiro de uma vez: todas as casas com o seu tipo,
  as ligações, a casa em que o Arthur está e o caminho já percorrido. As casas que o jogador
  pode escolher naquele momento MUST ficar destacadas.
- **FR-013**: No início do ato o jogador MUST poder escolher qualquer casa do primeiro andar;
  depois, só as casas do andar seguinte ligadas à casa atual. Não dá para voltar, ficar no
  mesmo andar nem pular andar.
- **FR-014**: Escolher uma casa MUST abrir o conteúdo dela (luta, descanso ou recompensa).
  Quando ele termina sem derrota, o jogo MUST voltar ao mapa com a casa marcada como visitada
  e o Arthur nela.
- **FR-015**: Junto do mapa MUST ficar visíveis o ato atual (número e nome), a vida do
  Arthur (atual e máxima) e quantas cartas o baralho da run tem.

**Casas**

- **FR-016**: Casa de batalha MUST abrir uma luta da 001 contra um inimigo comum do ato, com
  a vida e o ataque do inimigo e a faixa do alvo da profundidade da casa (FR-025).
- **FR-017**: Casa de elite MUST abrir uma luta contra um inimigo elite do ato, com mais
  vida e mais ataque que o inimigo comum da mesma profundidade.
- **FR-018**: Casa de chefe MUST abrir, por enquanto, uma luta comum contra um inimigo mais
  forte que a elite do mesmo ato, com nome provisório e marcada no mapa como chefe. A troca
  pelo chefe de verdade é da funcionalidade 003 e MUST poder ser feita sem mudar o mapa nem
  as outras casas.
- **FR-019**: Depois de uma luta vencida, o jogo MUST mostrar que a luta foi vencida e a vida
  restante do Arthur, e seguir para o próximo passo (recompensa, se houver, ou mapa) com uma
  ação do jogador.
- **FR-020**: Casa de descanso MUST curar o Arthur numa porcentagem da vida máxima definida
  nos dados (padrão: 30%, arredondado para baixo, ou seja 12), sem passar da vida máxima, e mostrar quanto curou antes de voltar ao mapa com uma ação do jogador.
- **FR-021**: Casa de recompensa MUST mostrar 3 cartas diferentes entre si, sorteadas do
  conjunto de recompensas dos dados, cada uma como na luta (símbolo, ataque e, se for
  especial, nome e efeito). O jogador MUST poder escolher 1, que entra no baralho da run, ou
  não pegar nenhuma. Com menos de 3 cartas no conjunto, aparecem todas as que houver.
- **FR-022**: A vitória numa luta de elite ou de chefe dos atos 1 e 2 MUST abrir, depois do
  aviso de vitória, uma recompensa igual à da FR-021. A vitória numa batalha comum MUST NOT dar
  recompensa. O chefe do ato 3 encerra a run (FR-024) e não dá recompensa.

**Fim de ato e fim de run**

- **FR-023**: Vencer o chefe dos atos 1 ou 2 MUST levar, depois da recompensa da FR-022, ao
  mapa do ato seguinte (salões, depois torre), com o Arthur antes do primeiro andar, a vida e
  o baralho mantidos.
- **FR-024**: A run MUST acabar com derrota quando a vida do Arthur chega a 0 em qualquer
  luta, e com vitória quando ele vence o chefe do ato 3. Nos dois casos, uma tela simples de
  fim de run MUST mostrar o resultado, o ato e o andar alcançados e quantas lutas foram
  vencidas, com a opção de começar de novo. Começar de novo MUST criar uma run nova pela
  FR-001 e FR-002 (ato 1, mapa novo, vida 40, baralho inicial), sem nada da run anterior.

**Dificuldade e dados**

- **FR-025**: A profundidade de uma casa MUST ser a sua posição na run, contada em andares
  desde o primeiro andar do ato 1 e seguindo entre os atos (o primeiro andar do ato 2 é mais
  fundo que o chefe do ato 1).
- **FR-026**: Para cada profundidade, os dados MUST definir a faixa do alvo das lutas e a
  vida e o ataque do inimigo comum, da elite e do chefe provisório. Nos dados padrão, esses
  valores MUST NOT diminuir de uma profundidade para outra mais funda, e entre os atos MUST
  crescer.
- **FR-027**: Todo o equilíbrio da run MUST ficar num único arquivo de dados, editável sem
  mexer no código: os números da FR-026, o tamanho dos mapas e a quantidade de casas de cada
  tipo por ato, a cura do descanso, o conjunto de cartas de recompensa, o baralho inicial e
  os nomes provisórios dos inimigos de cada ato. Mudar o arquivo MUST valer na próxima vez
  que o jogo for aberto.
- **FR-028**: Ao abrir, antes da primeira run, o jogo MUST conferir o arquivo de dificuldade e, se houver
  valor impossível (faixa de alvo invertida, vida ou ataque menor que 1, mapa sem andares,
  mais casas de um tipo do que o ato comporta, ato sem casa de descanso, elite sem andar
  acima do 2 para ficar, mapa que não cabe na tela, com mais de 7 casas num andar ou mais de 8
  andares comuns, baralho inicial sem carta de número), MUST NOT
  começar a run e MUST mostrar qual valor está errado.
- **FR-029**: A luta MUST continuar garantindo mão mínima e alvo alcançável (001, FR-006 e
  FR-007) com qualquer baralho da run e qualquer faixa de alvo dos dados.

**Assets**

- **FR-030**: Mapa (fundo de cada ato, ícone de cada tipo de casa, ligações, marcador do
  Arthur), inimigos de cada ato, telas de descanso, recompensa, vitória na luta e fim de run
  MUST usar placeholders neutros do motor, e cada um MUST constar na lista de assets
  pendentes do projeto, com o que é preciso (tipo, tamanho, quadros, formato) e onde será
  usado.

### Key Entities *(include if feature involves data)*

- **Run**: uma tentativa do começo do calabouço até a vitória ou a derrota. Tem a semente, o
  ato atual, a casa atual, a vida do Arthur, o baralho da run, as lutas vencidas e o estado
  (em andamento, vitória ou derrota).
- **Ato**: calabouço (1), salões (2) ou torre (3). Tem nome e o mapa daquela run.
- **Mapa do ato**: os andares, as casas de cada andar e as ligações entre casas de andares
  vizinhos.
- **Casa**: um ponto do mapa. Tem tipo (batalha, elite, descanso, recompensa, chefe), andar,
  profundidade, ligações para o andar seguinte e se já foi visitada.
- **Inimigo da casa**: nome provisório, vida e ataque, tirados dos dados pelo ato, pelo tipo
  da casa e pela profundidade.
- **Dados de dificuldade**: o arquivo único com todo o equilíbrio da run (FR-027).
- **Oferta de recompensa**: as até 3 cartas sorteadas numa recompensa e a escolha do jogador.

Valores padrão provisórios (ajustáveis nos dados; o ato 1 parte dos números da 001):

| Ato | Faixa do alvo | Inimigo comum (vida / ataque) | Elite | Chefe provisório |
|---|---|---|---|---|
| 1, calabouço | 5 a 12 | 12 / 3 | 18 / 4 | 26 / 5 |
| 2, salões | 8 a 18 | 18 / 4 | 26 / 5 | 36 / 6 |
| 3, torre | 12 a 24 | 24 / 5 | 34 / 6 | 46 / 7 |

Dentro de cada ato, a vida dos inimigos sobe um pouco a cada andar (padrão: +1 por andar).
Conjunto de recompensas padrão: números 6 a 10, ×, ÷, x2, /2, ^2, Chama, Foco, Guarda e Vital.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em 1.000 mapas gerados com sementes diferentes para cada ato, 100% cumprem as
  regras de FR-008 a FR-011: toda casa alcançável, caminho de toda casa até o chefe, pelo
  menos dois caminhos diferentes, ligações sem cruzamento, quantidades de cada tipo iguais às
  dos dados, primeiro andar só de batalhas, nenhuma elite no andar 2, pelo menos um descanso
  no último andar comum e chefe sozinho no topo.
- **SC-002**: A mesma semente produz o mesmo mapa, os mesmos inimigos e as mesmas ofertas de
  recompensa em 100% das repetições.
- **SC-003**: Em 1.000 runs simuladas com escolhas automáticas, em 100% das lutas a vida
  inicial do Arthur é a que sobrou da casa anterior (somada à cura do descanso, se houve) e o
  baralho é o inicial mais as cartas escolhidas nas recompensas até ali.
- **SC-004**: Nos dados padrão, uma verificação automática confirma que faixa do alvo, vida e
  ataque nunca diminuem com a profundidade, que a elite é mais forte que o inimigo comum da
  mesma profundidade e que o chefe provisório é mais forte que a elite do ato.
- **SC-005**: Mudar um valor do arquivo de dificuldade (por exemplo a cura do descanso) muda a
  run da próxima vez que o jogo abrir, sem nenhuma alteração no código.
- **SC-006**: Depois de uma derrota, a run nova começa com uma única ação do jogador, no ato
  1, com 40 de vida, as 13 cartas iniciais e uma semente nova (na prática, outro mapa).
- **SC-007**: Uma pessoa da equipe que conhece a regra da luta leva de 20 a 30 minutos para
  uma run que chega ao chefe do ato 3 (meta da visão), medido em pelo menos duas runs jogadas.
- **SC-008**: A run pode ser jogada do início até a derrota e até a vitória sem nenhum asset
  fornecido pela equipe, e 100% dos placeholders novos estão na lista de pendências.

## Assumptions

- A luta é a da 001, sem mudança de regra; esta funcionalidade só escolhe com que vida,
  baralho, inimigo e faixa de alvo cada luta começa e o que acontece depois dela.
- Os números padrão (tabela das entidades e quantidade de casas de cada tipo) são provisórios e servem
  para jogar; o equilíbrio fino é feito depois, mudando só o arquivo de dados.
- O Arthur não se cura sozinho entre os atos; só o descanso cura.
- Nada é guardado entre runs (nem melhor resultado nem progresso): fechar o jogo perde a run
  em andamento (decidido no clarify de 2026-11-18). Se a equipe quiser registro entre runs
  depois, ele pede uma funcionalidade própria.
- A tela de fim de run é simples e provisória; a tela de derrota definitiva e a cena final
  são da funcionalidade 004, e a prova como chefe do ato 3 é da 003.
- Inimigos diferentes só mudam nome, vida e ataque (a visão exclui comportamentos diferentes
  por tipo de inimigo).
- Não há como remover cartas do baralho, loja, ouro, relíquias ou eventos: só as casas
  listadas na visão.
- Jogo para PC, jogado com mouse, na mesma resolução da 001.
- Fora do escopo: chefes especiais, prova, história, menus, pausa, tutorial, explicação dos
  símbolos, arte e som finais, salvar e carregar.
