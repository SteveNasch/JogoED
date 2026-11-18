# Research: Run e mapa (002)

**Data**: 2026-11-18 | **Plano**: [plan.md](plan.md) | **Spec**: [spec.md](spec.md)

Cada decisão traz o que foi escolhido, o motivo, as alternativas descartadas e a página da
documentação oficial do Godot 4.7 que a sustenta. As páginas foram lidas no ramo `4.7` do
repositório `godotengine/godot-docs` (commit `9adca4c`) em 18/11/2026; os links apontam para a
versão publicada em `docs.godotengine.org/en/4.7/`. O que foi medido nesta máquina (Godot
4.7.2-stable, Linux, modo headless) está marcado como **medido**. Decisões que só repetem a 001
apontam para o [research da 001](../001-nucleo-batalha/research.md) em vez de repetir a fonte.

Antes de desenhar, foram consultadas as skills do GodotPrompter `procedural-generation`,
`resource-pattern`, `scene-organization`, `state-machine` e `godot-ui`. O padrão escolhido e o
descartado em cada caso estão nas decisões abaixo.

Não ficou nenhum "NEEDS CLARIFICATION" do contexto técnico.

## D1. Reaproveitar a 001 sem reescrevê-la

- **Decisão**: a run usa a luta só pela interface pública da 001
  ([contracts/batalha.md da 001](../001-nucleo-batalha/contracts/batalha.md)):
  `TelaBatalha.iniciar(cartas, vida_arthur, dados_inimigo, regras, semente)` e o sinal
  `luta_terminou(resultado: ResultadoLuta)`. Nenhum script de jogo de `batalha/`, `cartas/`,
  `contas/` ou `combatentes/` muda (só dois arquivos de teste). O que muda fora das pastas
  novas:

  | Arquivo da 001 | Mudança | Por quê |
  |---|---|---|
  | `project.godot` | `application/run/main_scene` passa a ser `res://run/tela_run.tscn` | o mapa entra no lugar da luta avulsa |
  | `.gutconfig.json` | 4 pastas novas em `dirs` (`mapa/`, `run/`, `descanso/`, `recompensa/`, cada uma com `testes/`) | o GUT só roda os testes das pastas listadas |
  | `cartas/testes/teste_arquivos_cartas.gd` | 5 linhas novas na tabela (números 6 a 10) | o teste confere que a pasta `dados/cartas/` tem só as cartas da tabela; as cartas 6 a 10 entram agora, com os valores da tabela de cartas da spec da 001 |
  | `batalha/testes/teste_simulacao.gd` | passa a usar o jogador automático extraído para `batalha/testes/jogador_automatico.gd` | a simulação de runs da 002 também precisa jogar lutas de verdade; extrair evita duas cópias do mesmo jogador (princípio I) |
  | `luta_avulsa/luta_avulsa.gd` | só o comentário do topo: deixa de dizer "cena principal" | o código continua igual |
  | `specs/001-nucleo-batalha/quickstart.md` | "Abrir o jogo" passa a abrir `luta_avulsa.tscn` com F6 | os cenários da 001 continuam jogáveis |

- **A luta avulsa fica** como cena de teste da luta, aberta no editor com F6 (roda a cena
  aberta, sem passar pelo mapa). Ela não é código morto: tem testes próprios, é o jeito de
  repetir os cenários do quickstart da 001 e será útil na 003 para testar um chefe sozinho.
  Não entra em nenhum caminho do jogo.
- **Alternativas**: apagar `luta_avulsa/` (perde o jeito rápido de testar uma luta e os cenários
  da 001 deixam de ser jogáveis); reaproveitar `fim_de_luta` como aviso de vitória da run (o
  botão diz "Lutar de novo" e a derrota da run vai direto para o fim de run, então metade da
  cena ficaria sem uso ou precisaria ser reescrita).
- **Documentação**:
  [ProjectSettings: application/run/main_scene](https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html#class-projectsettings-property-application-run-main-scene)
  ("caminho da cena principal carregada quando o projeto roda").

## D2. Estado da run: classe `Run` (`RefCounted`) com etapas num `enum`

- **Decisão**: todo o estado e todas as regras da run ficam em `Run`, que estende `RefCounted`
  e não é nó: ato, mapas, casa atual, vida, baralho, lutas vencidas e a **etapa** em que a run
  está. A etapa é um `enum` (`MAPA`, `LUTA`, `CHEFE`, `DESCANSO`, `RECOMPENSA`, `VITORIA`,
  `DERROTA`) e só muda dentro de quatro métodos chamados de fora: `escolher_casa()`,
  `terminar_luta()`, `sair_do_descanso()` e `escolher_recompensa()`. Cada método confere a
  etapa atual e não faz nada se for chamado na hora errada (o mesmo cuidado da `Batalha` da
  001). Diagrama e tabela de transições no [data-model.md](data-model.md).
- **Motivo**: é o pedido da orientação (1) e o mesmo desenho da `Batalha` (001, D4): um teste
  cria a `Run` com `.new()` e joga uma run inteira sem tela. O padrão de máquina de estados
  "por enum" da skill `state-machine` é o indicado quando as etapas não têm lógica por quadro
  nem entrada e saída complexas; aqui cada transição é uma chamada de método.
- **Alternativas**: máquina de estados com um nó por estado (padrão "node-based" da skill:
  exigiria árvore de cenas e não deixaria a `Run` ser testada sozinha); estado da run num
  autoload (estado global, difícil de zerar entre testes e entre runs; já descartado na 001,
  D4); estado espalhado na cena principal (a simulação de 1.000 runs teria que abrir tela).
- **Documentação**:
  [When and how to avoid using nodes for everything](https://docs.godotengine.org/en/4.7/tutorials/best_practices/node_alternatives.html)
  ("RefCounted: só um pouco mais complexo que Object").

## D3. Sorteio: um gerador por run e um por mapa, com a semente vinda de fora

- **Decisão**:
  - `GeradorMapa.gerar(dados_mapa, semente)` cria **um** `RandomNumberGenerator`, define a
    `seed` com a semente recebida e usa só ele para o mapa inteiro (orientação 2).
  - A `Run` também tem **um** gerador, com a semente da run. Na criação, ela tira dele as
    sementes dos três mapas, nesta ordem, e gera os três mapas de uma vez; depois, tira dele a
    semente de cada luta (ao entrar na casa) e sorteia as ofertas de recompensa.
  - A cena principal escolhe a semente de cada run nova com `randi()` (como a luta avulsa da
    001). É o único sorteio global do código da 002.
  - Fica proibido no código da 002 o mesmo que na 001 (D8): `shuffle()`, `pick_random()`,
    `randi()` e `randf()` soltos, fora a semente da run. Sorteio sem repetição é
    `lista.pop_at(rng.randi_range(0, lista.size() - 1))`.
- **Motivo**: com isso a run inteira sai de uma semente só (FR-006, SC-002). Gerar os três mapas
  no começo faz o mapa de cada ato depender só da semente, e não das escolhas feitas antes; um
  teste pode conferir os três mapas sem jogar. A documentação diz que a classe
  `RandomNumberGenerator` permite "várias instâncias, cada uma com a sua semente e estado", e
  que a mesma semente dá a mesma sequência.
- **Cuidado com sementes vizinhas**: a referência de `RandomNumberGenerator.seed` avisa que o
  gerador "não tem efeito avalanche" e pode dar sequências parecidas com sementes parecidas.
  As sementes internas saem do próprio gerador da run (já espalhadas); nos testes com muitas
  sementes, a semente do caso `i` é `hash(i)`, não `i`, para os mapas testados serem variados.
- **Alternativas**: um gerador único passado da run para o gerador do mapa (funciona, mas o mapa
  do ato 2 passaria a depender de quantos sorteios a run fez no ato 1); gerar o mapa do ato
  seguinte só ao chegar nele (mesmo problema).
- **Documentação**:
  [Random number generation](https://docs.godotengine.org/en/4.7/tutorials/math/random_number_generation.html)
  (seção "Global scope versus RandomNumberGenerator class");
  [RandomNumberGenerator.seed](https://docs.godotengine.org/en/4.7/classes/class_randomnumbergenerator.html#class-randomnumbergenerator-property-seed);
  [Array.pop_at()](https://docs.godotengine.org/en/4.7/classes/class_array.html#class-array-method-pop-at);
  [@GlobalScope.hash()](https://docs.godotengine.org/en/4.7/classes/class_%40globalscope.html#class-globalscope-method-hash).

## D4. Geração do mapa: andares em camadas e ligações "em escada"

### O algoritmo

O mapa de um ato tem `andares_comuns` andares (padrão 4) e, no topo, o andar do chefe, com uma
casa só. As casas de cada andar ficam em ordem, da esquerda para a direita (`indice` 0, 1, 2).
`GeradorMapa.gerar()` faz três passos, todos com o mesmo gerador:

1. **Tamanho dos andares.** O andar 1 tem `batalhas_primeiro_andar` casas (padrão 3). Os
   andares 2 em diante dividem entre si o total de casas dos tipos (padrão 3 + 1 + 2 + 2 = 8):
   cada andar começa com `casas_minimas_por_andar` e as casas que sobram vão, uma a uma, para um
   andar sorteado entre os que ainda não chegaram em `casas_maximas_por_andar`. Com os dados
   padrão, sai uma das divisões 3-3-2, 3-2-3 ou 2-3-3.
2. **Tipo das casas** (FR-011). O andar 1 é todo de batalhas. Nos andares 2 em diante, nesta
   ordem: um descanso vai para uma vaga sorteada do último andar comum; cada elite vai para uma
   vaga livre sorteada do andar 3 em diante; o resto (batalhas, descansos e recompensas que
   sobraram) vai para as vagas livres, sorteadas uma a uma. O topo é o chefe.
3. **Ligações** (FR-009 e FR-010). Entre dois andares vizinhos com `a` e `b` casas, o gerador
   anda numa grade de `a` por `b` do canto (0, 0) até o canto (a−1, b−1), a cada passo
   sorteando entre ir para a casa seguinte de cima, a seguinte de baixo ou as duas ao mesmo
   tempo (quando uma das duas já está na última, só resta a outra). Cada ponto (i, j) por onde
   ele passa vira uma ligação da casa `i` de baixo para a casa `j` de cima. O último andar comum
   liga todas as suas casas ao chefe.

### Por que as regras sempre valem

- **Toda casa liga para cima e recebe ligação de baixo**: o caminho na grade passa por todas as
  linhas e por todas as colunas, porque começa na primeira e termina na última e só avança de
  uma em uma. Logo, toda casa de baixo tem ao menos uma ligação para cima e toda casa de cima
  recebe ao menos uma (FR-009). Daí, por indução andar a andar, toda casa é alcançável do andar
  1 e de toda casa há caminho até o chefe.
- **Ligações não se cruzam**: duas ligações (i1, j1) e (i2, j2) só se cruzam na tela se
  `i1 < i2` e `j1 > j2` (ou o contrário). No caminho em escada, `i` e `j` nunca diminuem, então
  isso não acontece. A tela põe as casas de cada andar em `x` crescente com o `indice`, então a
  ordem nos dados é a ordem na tela (FR-010).
- **Pelo menos dois caminhos**: o andar 1 tem ao menos 2 casas (a validação exige
  `batalhas_primeiro_andar >= 2`), e de cada uma há caminho até o chefe; dois começos diferentes
  já são dois caminhos diferentes (FR-010).
- **Tipos nos lugares certos**: o descanso reservado garante o último andar comum com
  descanso; as elites só são sorteadas entre vagas do andar 3 em diante. A validação (D6)
  garante que essas vagas existem mesmo quando o andar 2 sai com o máximo de casas.

### Como é testado (SC-001, SC-002)

O teste não confia no raciocínio acima: confere cada regra de forma independente, em 1.000
sementes (`hash(i)`) para cada um dos três atos dos dados padrão e também para configurações
válidas diferentes (por exemplo, 2 andares comuns sem elite; 6 andares comuns; mínimo igual ao
máximo):

- busca em largura a partir do andar 1: toda casa visitada; busca ao contrário a partir do
  chefe: toda casa chega nele;
- contagem de caminhos do andar 1 ao chefe (soma andar a andar): pelo menos 2;
- nenhum par de ligações entre os mesmos andares com `i1 < i2` e `j1 > j2`;
- ligações só entre andares vizinhos, sem repetição;
- quantidade de cada tipo igual à dos dados, andar 1 só de batalhas, nenhuma elite no andar 2,
  pelo menos um descanso no último andar comum, chefe sozinho no topo, cada andar comum entre o
  mínimo e o máximo de casas;
- mesma semente, mesmo mapa (tipos, andares e ligações) e sementes diferentes dando mais de um
  mapa diferente.

### Alternativas

- **Ligações sorteadas livremente, depois conferidas com busca em largura e descartadas se
  falharem** (o "flood-fill" que a skill `procedural-generation` recomenda para cavernas): o
  número de tentativas não tem teto garantido e cruzamentos ainda precisariam de outra regra.
- **Grade de colunas com vários caminhos sobrepostos** (como mapas de outros roguelikes de
  cartas): mais código, e mapas de 2 a 3 casas por andar não precisam disso.
- **Mapas prontos sorteados de uma lista**: não é "gerado de novo a cada run" (FR-007).

- **Documentação**:
  [RandomNumberGenerator.randi_range()](https://docs.godotengine.org/en/4.7/classes/class_randomnumbergenerator.html#class-randomnumbergenerator-method-randi-range)
  ("inteiro entre `from` e `to`, inclusive"). O algoritmo é do projeto, não da documentação.

## D5. Arquivo único de dificuldade: `dados/dificuldade.tres` com sub-recursos

- **Decisão**: um único arquivo `dados/dificuldade.tres`, do tipo `DadosDificuldade`, guarda
  todo o equilíbrio da run (orientação 3, FR-027). Ele é feito de recursos pequenos, um dentro
  do outro, todos salvos **dentro** do mesmo arquivo (sub-recursos):

  ```text
  DadosDificuldade             baralho inicial, cartas de recompensa, cura do descanso, ...
  └── atos: Array[DadosAto]    um por ato: nome, faixa do alvo, vida extra por andar
      ├── comum, elite, chefe: DadosInimigo   (a classe da 001: nome, vida, ataque)
      └── mapa: DadosMapa      andares, casas por andar, quantas casas de cada tipo
  ```

  As cartas (`dados/cartas/*.tres`) e as regras da luta (`dados/regras_batalha.tres`) continuam
  nos arquivos da 001 e são só **apontadas** pelo arquivo de dificuldade: o baralho inicial e o
  conjunto de recompensas são listas de cartas dentro dele; a vida máxima do Arthur e os números
  da mão vêm de `regras_base`. Campos e valores no [data-model.md](data-model.md).
- **Valores por profundidade**: cada ato define os valores do seu primeiro andar e quanto a vida
  sobe a cada andar (`vida_extra_por_andar`). Assim os dados definem o valor de toda
  profundidade (FR-026) com poucos números, e mudar o tamanho do mapa não deixa nenhuma
  profundidade sem valor. Detalhes e fórmulas em D7.
- **Motivo**: a documentação diz que recursos "podem serializar sub-recursos recursivamente" e
  que o `.tres` é texto, bom para o git; o Inspector edita tudo, inclusive listas de recursos
  ("arrastando vários arquivos de uma vez" do painel de arquivos). A skill `resource-pattern`
  recomenda recursos pequenos compostos em vez de um recurso gigante; aqui são quatro classes
  pequenas, e o arquivo continua um só, como a spec pede. `DadosMapa` fica na área `mapa/`
  porque é o que o gerador do mapa lê; `DadosAto` e `DadosDificuldade` ficam na área `run/`.
- **Nada compartilhado é alterado**: a documentação avisa que o motor "só carrega um recurso
  uma vez" e devolve a mesma cópia a todos. Por isso a run nunca escreve nos dados: o baralho da
  run é uma cópia da lista (`Array.duplicate()`, que copia a lista mas compartilha as cartas,
  que são só leitura); as regras de cada luta são `regras_base.duplicate()` com a faixa do ato
  trocada; o inimigo de cada casa é um `DadosInimigo.new()` montado com os valores do ato e do
  andar da casa.
- **"Mudar o arquivo vale na próxima vez que o jogo for aberto" (FR-027)**: a cena principal
  recebe o arquivo por `@export`, então ele é lido e conferido (D6, FR-028) uma vez, quando o
  jogo abre; o "Começar de novo" usa o mesmo arquivo já carregado. Mudou o arquivo no editor,
  a próxima run jogada (rodando o jogo de novo) usa os valores novos, sem mexer no código
  (SC-005). Não há recarga com o jogo aberto: no jogo exportado o arquivo nem pode ser editado,
  porque a exportação converte os `.tres` para binário.
- **Alternativas**: um `.tres` por ato ou por inimigo (vários arquivos, contra a FR-027); uma
  tabela com uma linha por profundidade, 15 linhas de 8 números (mais fácil errar e quebra
  quando o tamanho do mapa muda); JSON (já descartado na 001, D5).
- **Documentação**:
  [Resources](https://docs.godotengine.org/en/4.7/tutorials/scripting/resources.html) (seções
  sobre o carregamento único e "Creating your own resources");
  [GDScript exported properties](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/gdscript_exports.html)
  (seção "Exporting arrays": listas tipadas de recursos no Inspector; listas tipadas aninhadas
  como `Array[Array[float]]` "ainda não são suportadas");
  [Resource.duplicate()](https://docs.godotengine.org/en/4.7/classes/class_resource.html#class-resource-method-duplicate);
  [Array.duplicate()](https://docs.godotengine.org/en/4.7/classes/class_array.html#class-array-method-duplicate).

## D6. Conferência do arquivo de dificuldade antes da run (FR-028)

- **Decisão**: cada classe de dados tem `erros() -> Array[String]`, que devolve uma frase em
  português para cada valor impossível, com o nome do campo como aparece no Inspector (por
  exemplo, `Ato 1 (Calabouço): alvo_minimo (13) é maior que alvo_maximo (12)`).
  `DadosDificuldade.erros()` junta os seus com os de cada `DadosAto`, que junta os seus com os do
  `DadosMapa`. A cena principal chama `erros()` antes de criar a run; se a lista não estiver
  vazia, mostra as frases na tela no lugar do mapa, manda cada uma para o depurador com
  `push_error()` e não cria a run. A lista completa de regras está no
  [data-model.md](data-model.md).
- **Motivo**: a FR-028 pede que o jogo confira e diga qual valor está errado, com o jogo
  rodando, e não só nos testes. Uma função por classe mantém cada regra perto do campo que ela
  confere (funções pequenas, princípio I) e é testável sem tela. `push_error()` "envia a
  mensagem de erro ao depurador e ao terminal", útil para quem roda pelo editor.
- **Diferença para a 001**: na 001 as regras dos arquivos eram só convenções conferidas nos
  testes (data-model da 001). Na 002 a spec exige a conferência em jogo, porque quem equilibra
  muda o arquivo à mão.
- **Alternativas**: `assert()` (derruba o jogo e só funciona em modo de depuração); conferir
  nos setters dos campos (rodam durante o carregamento, campo a campo, sem ver o conjunto);
  conferir só nos testes (não atende a FR-028).
- **Documentação**:
  [@GlobalScope.push_error()](https://docs.godotengine.org/en/4.7/classes/class_%40globalscope.html#class-globalscope-method-push-error).

## D7. Dificuldade por profundidade e custo da busca do alvo

### Fórmulas

- **Profundidade** (FR-025) de uma casa do andar `a` do ato `n`: a soma dos andares dos atos
  anteriores (cada ato tem `andares_comuns + 1`) mais `a`. Com os dados padrão vai de 1 (andar
  1 do calabouço) a 15 (chefe da torre). Não vira função no código: os dados seguem ato e
  andar.
- **Inimigo comum e elite** do andar `a`: vida = vida do `DadosInimigo` do ato +
  `vida_extra_por_andar × (a − 1)`; ataque = ataque do ato. **Chefe**: os valores do ato, sem
  acréscimo (ele está sempre no topo).
- **Faixa do alvo**: a do ato, igual em todos os andares dele.

Com os dados padrão (tabela da spec e +1 de vida por andar), cada tipo de inimigo nunca fica
mais fraco quando a profundidade aumenta, a elite é mais forte que o comum do mesmo andar e o
chefe é mais forte que a elite mais funda do ato (calabouço: elite do andar 4 com 21 de vida e 4
de ataque; chefe com 26 e 5). Um teste confere isso nos dados padrão (SC-004).

### Custo da busca do alvo com faixas maiores (**medido**)

A busca do alvo é a da 001 (D10 de lá), sem mudança. Para saber se ela aguenta as faixas dos
atos 2 e 3 e os baralhos que crescem com as recompensas, um script fora do projeto sorteou 300
mãos por caso (semente fixa), sempre com o mínimo da 001 (3 números, um + e um −) e o resto ao
acaso. O baralho é o inicial (13 cartas) mais 0, 4 ou 8 cartas sorteadas do conjunto padrão de
recompensas. Limite de 3 números no alvo e teto de 10.000 avaliações, como na 001.

Quantas mãos têm **algum** valor da faixa alcançável (as outras recebem o valor possível mais
perto da faixa, pela regra da 001):

| Faixa | Recompensas no baralho | Mão de 5 | Mão de 6 | Mão de 8 | Mão de 12 |
|---|---|---|---|---|---|
| 5 a 12 (ato 1) | 0 | 93% | 99% | 100% | 100% |
| 8 a 18 (ato 2) | 0 | 48% | 68% | 97% | 100% |
| 8 a 18 (ato 2) | 4 | 76% | 90% | 98% | 100% |
| 12 a 24 (ato 3) | 0 | 0% | 8% | 32% | 89% |
| 12 a 24 (ato 3) | 4 | 21% | 39% | 72% | 96% |
| 12 a 24 (ato 3) | 8 | 36% | 57% | 84% | 98% |

Custo (os casos mais caros de cada faixa):

| Faixa | Recompensas | Mão | Avaliações (média / máx.) | Tempo (média / máx.) | Mãos no teto (de 300) |
|---|---|---|---|---|---|
| 5 a 12 | 8 | 12 | 83 / 2.560 | 0,9 ms / 29 ms | 0 |
| 8 a 18 | 8 | 12 | 530 / 10.000 | 5,2 ms / 103 ms | 1 |
| 12 a 24 | 4 | 15 | 892 / 10.000 | 8,8 ms / 97 ms | 2 |
| 12 a 24 | 8 | 15 | 995 / 10.000 | 9,6 ms / 97 ms | 1 |

Cada avaliação custou cerca de 10 microssegundos nesta medição (a da 001 deu 3,5; o script e a
mistura de mãos são outros). Os testes contam avaliações, não tempo.

### O que isso decide

- **Alvo sempre alcançável (FR-029)**: continua garantido pela construção da 001 (o alvo só sai
  de uma conta achada). A simulação da 002 confere isso em todas as rodadas jogadas.
- **Teto da busca**: nas mãos grandes dos atos 2 e 3 o teto é atingido de vez em quando (até 2
  em 300 mãos). A garantia continua, e o pior caso custa cerca de 0,1 s no começo de uma rodada.
  Por isso a simulação da 002 **não** exige "nenhuma busca no teto", como a da 001 exigia para a
  luta avulsa; exige conta de exemplo em toda rodada. Se a pausa incomodar jogando, o freio é
  `limite_buscas_alvo` em `dados/regras_batalha.tres`.
- **Alvo do ato 3 fora da faixa no começo das lutas** (decisão do Estêvão em 18/11): é
  esperado. Com o baralho inicial a mão do começo da luta chega no máximo a 10 (só há um +), então
  a faixa de 12 a 24 só é alcançada depois que o jogador ganha cartas nas recompensas. É isso
  que obriga a montar o baralho durante a run. Os valores padrão da spec ficam como estão.

## D8. Cena principal como "raiz de composição": abre e fecha o conteúdo de cada casa

- **Decisão**: a cena principal `run/tela_run.tscn` guarda a `Run` e é a única que conhece as
  outras cenas. Ela tem fixos o mapa e a barra da run (ato, vida, cartas) e, a cada etapa,
  instancia a cena do conteúdo (luta, descanso, recompensa, aviso de vitória, fim de run),
  conecta o sinal dela, chama o método de entrada (`iniciar()` ou `mostrar()`) e, quando o
  sinal chega, repassa o resultado à `Run` e libera a cena com `queue_free()`. Enquanto um
  conteúdo está aberto, o mapa e a barra ficam escondidos com `hide()`, e o mapa não recebe
  clique (spec, casos-limite).
- **Motivo**: é o padrão da documentação de organização de cenas e da skill
  `scene-organization`: o pai chama métodos dos filhos e os filhos avisam por sinal, sem nenhum
  filho conhecer os irmãos. É também o que a `luta_avulsa` já faz com a tela da luta. Entre as
  estratégias da página "Change scenes manually", o conteúdo da casa usa "apagar a cena" (some
  da memória e para de processar; não há o que guardar nela, porque o resultado já foi para a
  `Run`) e o mapa usa "esconder a cena" (continua na memória e volta na hora, com a mesma
  disposição).
- **Alternativas**: `change_scene_to_file()` para cada tela (a documentação lembra que isso
  apaga a cena atual, então a `Run` teria que morar num autoload); barramento global de eventos
  (a skill o indica entre cenas irmãs sem pai comum; aqui o pai comum existe); `SubViewport`
  para cada tela (feito para mostrar várias telas ao mesmo tempo, o que o jogo não faz).
- **Documentação**:
  [Change scenes manually](https://docs.godotengine.org/en/4.7/tutorials/scripting/change_scenes_manually.html);
  [Scene organization](https://docs.godotengine.org/en/4.7/tutorials/best_practices/scene_organization.html)
  (já citada na 001, D6 e D14);
  [CanvasItem.hide()](https://docs.godotengine.org/en/4.7/classes/class_canvasitem.html#class-canvasitem-method-hide).

## D9. Mapa na tela: posições calculadas e ligações desenhadas com `_draw()`

- **Decisão**: `mapa/tela_mapa.tscn` é um `Control` de tela inteira. Cada casa é uma instância
  de `mapa/casa_mapa.tscn` (um `Button` de 32×32) posta numa posição calculada por uma função
  pura, `TelaMapa.posicao_da_casa(andar, indice, casas_no_andar, total_de_andares)`: andar 1
  embaixo e o chefe no topo, casas de um andar centradas e em `x` crescente com o `indice`. As
  ligações são desenhadas por baixo das casas no `_draw()` da própria `tela_mapa`, com
  `draw_line()` de largura 2 e sem suavização, ligando os centros calculados pela mesma função.
  A cada `mostrar()`, a cena recria as casas e chama `queue_redraw()`.
- **Motivo**: um mapa é um grafo; as linhas precisam sair e chegar exatamente no centro das
  casas. Com a posição vinda de uma função, o teste confere que o `x` cresce com o `indice` em
  todo andar (é o que faz "sem cruzamento nos dados" virar "sem cruzamento na tela") sem
  precisar esperar o desenho. A documentação explica que o `_draw()` roda uma vez e fica guardado
  até um `queue_redraw()`; que o desenho do pai sai antes dos filhos (as linhas ficam embaixo
  das casas); e que linhas de largura ímpar precisam ser deslocadas meio pixel, o que a largura
  2 evita. `draw_line()` tem a suavização desligada por padrão, o certo para pixel art.
- **Mouse nos filhos da casa** (**medido**): o `ColorRect` vem com `mouse_filter` `STOP` (valor
  0) e o `Label` com `IGNORE` (valor 2). Com `STOP`, o nó fica com o evento do mouse e ele não
  chega ao pai, então um `ColorRect` do tamanho do `Button` deixaria a casa sem clique e sem
  dica. Por isso o `ColorRect` da casa, a moldura e o marcador do Arthur usam `IGNORE`, como o
  fundo da `cartas/carta.tscn` da 001 (`mouse_filter = 2`). O teste confere esse valor: a
  simulação de clique com `push_input()` em modo headless não chegou nem a um `Button` sozinho
  nesta máquina, então não serve para provar o clique.
- **Exceção à regra de contêineres**: a 001 (D16) e a skill `godot-ui` pedem contêineres em
  vez de posições à mão. No mapa isso não serve: com uma `HBoxContainer` por andar, a posição de
  cada casa só existe depois que o contêiner arruma os filhos, e as linhas teriam que esperar
  esse momento. As outras telas da 002 (descanso, recompensa, aviso de vitória, fim de run,
  barra da run) usam contêineres, como a 001.
- **Alternativas**: um `Line2D` por ligação (um nó a mais por linha, para criar e apagar a cada
  atualização); `Node2D` para o mapa inteiro (perde o clique e o tema dos `Button`).
- **Documentação**:
  [Custom drawing in 2D](https://docs.godotengine.org/en/4.7/tutorials/2d/custom_drawing_in_2d.html)
  (seções "Updating" e "Coordinates and line width alignment");
  [CanvasItem.draw_line()](https://docs.godotengine.org/en/4.7/classes/class_canvasitem.html#class-canvasitem-method-draw-line);
  [Control.mouse_filter](https://docs.godotengine.org/en/4.7/classes/class_control.html#class-control-property-mouse-filter);
  [Using Containers](https://docs.godotengine.org/en/4.7/tutorials/ui/gui_containers.html) (já
  citada na 001, D16).

## D10. Descanso, recompensa, aviso de vitória e fim de run: cenas pequenas que avisam por sinal

- **Decisão**: quatro cenas pequenas, cada uma com um método `mostrar(...)` e um sinal no
  passado (orientação 4): `descanso/tela_descanso.tscn` (`continuou`),
  `recompensa/tela_recompensa.tscn` (`carta_escolhida(carta)` e `nenhuma_escolhida`),
  `run/vitoria_luta.tscn` (`continuou`) e `run/fim_de_run.tscn` (`jogar_de_novo`). A conta do
  descanso e o sorteio da oferta ficam na `Run`; as cenas só mostram e avisam. A recompensa
  mostra cada carta com a cena `cartas/carta.tscn` da 001, que já desenha símbolo, ataque, nome,
  efeito e a dica (FR-021: "cada uma como na luta"). Interfaces em
  [contracts/telas-run.md](contracts/telas-run.md).
- **Motivo**: princípio III e o padrão da 001 (D6): cada cena abre e é testada sozinha,
  recebendo números ou cartas. A regra na `Run` deixa a simulação de runs rodar sem tela.
- **Alternativas**: uma cena genérica de "aviso com botão" para descanso, vitória e fim de run
  (menos arquivos, mas mistura três textos e regras diferentes numa cena só e junta o trabalho
  de três pessoas no mesmo arquivo); a cura calculada na tela de descanso (a simulação não
  teria como descansar sem tela).
- **Documentação**: [Using signals](https://docs.godotengine.org/en/4.7/getting_started/step_by_step/signals.html)
  e Scene organization (já citadas na 001, D6).

## D11. Casa de chefe: etapa própria e um ponto de troca para a 003

- **Decisão**: a casa de chefe leva a `Run` para a etapa `CHEFE` (e não `LUTA`), e a cena
  principal abre essa etapa numa função própria, `TelaRun._abrir_chefe()`. Na 002 essa função
  só chama a mesma abertura de luta das outras casas, com o inimigo `chefe` do ato (FR-018). A
  `Run` trata o fim das duas etapas pelo mesmo `terminar_luta(resultado)`: no chefe, vitória
  abre a recompensa (atos 1 e 2) ou encerra a run com vitória (último ato).
- **O que a 003 troca** (orientação 5): para os chefes dos atos 1 e 2, só os valores e nomes de
  `chefe` em `dados/dificuldade.tres`; para a prova, só o corpo de `_abrir_chefe()`, que passa
  a abrir a cena da prova quando `run.ato` é o último. A única exigência é a cena da prova
  terminar com um `ResultadoLuta` (o sinal `luta_terminou` da 001), para a `Run` seguir igual.
  Mapa, casas, `Run` e as outras telas não mudam. Contrato em
  [contracts/run.md](contracts/run.md).
- **Alternativas**: `if casa.tipo == CHEFE` dentro da abertura de luta comum (o ponto de troca
  fica escondido no meio de outra função); uma classe ou cena "chefe" já agora (abstração sem
  uso na 002, contra o princípio I).
- **Documentação**: decisão de organização do código, sem página própria; segue a injeção de
  dependência de Scene organization (001, D14).

## D12. Testes e simulações

- **Áreas e testes**: cada pasta nova (`mapa/`, `run/`, `descanso/`, `recompensa/`) tem a sua
  `testes/`, como na 001. A lista de testes por arquivo está no [plan.md](plan.md) e os
  cenários no [quickstart.md](quickstart.md).
- **Simulação de 1.000 runs (SC-003), medida antes de decidir**: a simulação de 1.000 **lutas**
  da 001 leva cerca de 10 s nesta máquina (**medido**: `teste_simulacao.gd`, 2 testes, 10,1 s).
  1.000 runs com lutas de verdade seriam umas 10.000 lutas, mais de um minuto e meio só nesse
  teste. Por isso a simulação fica em duas partes:
  1. **1.000 runs com escolhas automáticas**: em cada casa de luta, o teste cria a `Batalha` real
     da 001 com o que a `Run` entrega e confere, no Arthur e na pilha de compra dessa `Batalha`
     (`baralho.compra`, onde estão todas as cartas antes de `iniciar()`), a vida e as cartas
     esperadas (SC-003), e que a luta começa sem escudo e com a mão vazia (FR-005). O resultado da luta é sorteado pelo teste (vitória com uma
     vida entre 1 e a atual, ou derrota), sem jogar as rodadas. É a `Run` que está sendo testada;
     a luta já tem a própria simulação na 001.
  2. **20 runs com lutas jogadas de verdade** pelo jogador automático da 001 (extraído para
     `batalha/testes/jogador_automatico.gd`, D1), do ato 1 até a vitória ou a derrota: em toda
     rodada, o alvo tem conta de exemplo e a mão tem o mínimo (FR-029), o baralho da run sai de
     cada luta igual ao que entrou (FR-004), e a mesma semente com as mesmas escolhas repete a
     run inteira (SC-002).
- **Sementes**: `hash(i)` (D3). **Tempo**: os testes contam avaliações e casas, nunca relógio,
  como na 001.
- **Testes de cena**: como na 001 (D17): a cena é instanciada, posta na árvore com
  `add_child_autofree()`, recebe os dados, e o teste aciona os botões e confere textos e sinais.
  Nos testes da cena principal, a dificuldade é trocada antes de pôr a cena na árvore por uma
  cópia com `tempo_resultado` de centésimos de segundo.
- **Cópia dos dados nos testes** (**medido** no Godot 4.7.2, num projeto de rascunho): o
  `duplicate(true)` de um recurso copia os sub-recursos salvos dentro do mesmo arquivo,
  inclusive os de dentro de listas, mas mantém o mesmo objeto para um recurso que é outro
  arquivo; mudar esse recurso na cópia mudou o arquivo carregado. Em `dificuldade.tres`, atos,
  inimigos e mapas são copiados, e `regras_base` e as cartas não. Como o motor carrega cada
  arquivo uma vez só (D5), mudar o `tempo_resultado` da cópia mudaria o `regras_batalha.tres`
  de todos os testes seguintes. Por isso o teste que muda `regras_base` faz
  `copia.regras_base = copia.regras_base.duplicate()` antes, como os testes da 001 já fazem com
  `REGRAS.duplicate()`. A alternativa `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` copia
  também as cartas, e os testes que comparam uma carta com o arquivo dela deixariam de achar o
  mesmo objeto.
- **Documentação**: a do GUT e a da linha de comando, já citadas na 001 (D17);
  [Resource.duplicate()](https://docs.godotengine.org/en/4.7/classes/class_resource.html#class-resource-method-duplicate)
  e
  [Resource.duplicate_deep()](https://docs.godotengine.org/en/4.7/classes/class_resource.html#class-resource-method-duplicate-deep).

## D13. Pixel art e placeholders

- **Decisão**: a mesma configuração da 001 (D3): base de 640×360, `viewport`, escala inteira,
  filtro `Nearest`, fonte de 10 px do `tema.tres`. Nenhum asset novo é criado (princípio IV).
  Placeholders: casa do mapa = `ColorRect` de 32×32 com a cor do tipo e uma letra (B, E, D, R,
  C) num `Label`, mais o nome do tipo na dica (`tooltip_text`); marcador do Arthur = `ColorRect`
  azul de 8×8, a mesma cor do Arthur na luta; ligações = linhas cinza (as do caminho percorrido,
  claras); fundo do mapa = cor de limpeza padrão; imagem do descanso = `ColorRect` de 96×96;
  inimigos = o mesmo `ColorRect` vermelho com o nome que a 001 já mostra no painel do inimigo.
  Tudo listado em `docs/assets-pendentes.md`, seção da 002, com tamanho, quadros, formato e
  onde é usado.
- **Troca pela arte final**: imagens que mudam por ato ou por tipo (fundo do mapa, ícone da
  casa, sprite do inimigo) vão precisar de um campo de textura nos dados quando chegarem (por
  exemplo `textura` em `DadosInimigo`). A 002 não cria esses campos agora: seria código para
  arquivos que ainda não existem (princípio I), e a 001 também deixou a frente das cartas para a
  troca. A tarefa de troca da arte (tarde de 29/11 no roteiro) faz isso.
- **Disposição da tela do mapa** (640×360): barra da run de 0 a 24; mapa de 32 a 360, chefe em
  `y = 48` e andar 1 em `y = 312` (5 andares a cada 66 px), casas a cada 96 px na horizontal;
  marcador do Arthur antes do primeiro andar em `y = 344`. Detalhes em
  [contracts/telas-run.md](contracts/telas-run.md).
- **Documentação**: a da 001 (D3, D15 e D18), sem página nova.

## Riscos que ficam para a implementação

- **Duração da run (SC-007)**: cada ato tem de 2 a 5 lutas no caminho do jogador (a do andar 1,
  a do chefe e de 0 a 3 nos andares 2 a 4, onde 4 das 8 casas são descanso ou recompensa), ou
  seja, de 6 a 15 lutas por run (cerca de 10 em média, D12). Com até 5 minutos por luta (meta da
  001), a run pode passar de 30 minutos. Só dá para saber jogando; a alavanca é o arquivo de
  dificuldade (vida dos inimigos e quantidade de batalhas por ato).
- **Pausa de até 0,1 s** no começo de rodadas raras dos atos 2 e 3 (D7).
- **Leitura do mapa** com letras no lugar dos ícones: só dá para julgar jogando; está no
  quickstart.
