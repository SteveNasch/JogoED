# Research: Núcleo da batalha (001)

**Data**: 2026-11-13 | **Plano**: [plan.md](plan.md) | **Spec**: [spec.md](spec.md)

Cada decisão traz o que foi escolhido, o motivo, as alternativas descartadas e a página da
documentação oficial do Godot 4.7 que a sustenta. As páginas foram lidas no ramo `4.7` do
repositório `godotengine/godot-docs` em 13/11/2026; os links apontam para a versão publicada
em `docs.godotengine.org/en/4.7/`. O que foi medido ou testado nesta máquina (Godot
4.7.2-stable, Linux) está marcado como **medido** ou **testado**.

Não ficou nenhum "NEEDS CLARIFICATION" do contexto técnico.

## D1. Linguagem: GDScript com tipagem estática

- **Decisão**: todo script usa tipos em variáveis, parâmetros e retornos (`var vida: int`,
  `func curar(quantidade: int) -> int`).
- **Motivo**: exigência da constituição (princípio I e Restrições Técnicas). A documentação
  aponta que os tipos permitem achar erros sem rodar o código e melhoram o autocompletar,
  o que ajuda uma equipe de cinco pessoas a usar o código uns dos outros.
- **Alternativas**: tipagem dinâmica (menos texto, mas erros só aparecem ao rodar).
- **Documentação**:
  [Static typing in GDScript](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/static_typing.html).

## D2. Renderizador: Compatibility

- **Decisão**: `rendering/renderer/rendering_method = "gl_compatibility"`.
- **Motivo**: a documentação recomenda o Compatibility para "jogo 2D", para "hardware mais
  antigo" e quando se quer "a maior variedade de hardware". O jogo é 2D simples e precisa
  rodar nos computadores do laboratório e dos colegas.
- **Alternativas**: Forward+ (padrão de projeto novo; pensado para 3D e recursos avançados
  que o jogo não usa) e Mobile.
- **Documentação**:
  [Renderers](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html)
  (seção "Choosing a renderer") e
  [ProjectSettings: rendering/renderer/rendering_method](https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html#class-projectsettings-property-rendering-renderer-rendering-method).

## D3. Pixel art: resolução base e configurações do projeto

- **Decisão**:

  | Configuração (Project Settings) | Valor | Para quê |
  |---|---|---|
  | `display/window/size/viewport_width` × `viewport_height` | 640 × 360 | resolução base do jogo |
  | `display/window/size/window_width_override` × `window_height_override` | 1280 × 720 | a janela abre em 2× no PC |
  | `display/window/stretch/mode` | `viewport` | desenha em 640×360 e depois amplia a imagem pronta |
  | `display/window/stretch/aspect` | `keep` | mantém 16:9, com barras pretas se a tela for diferente |
  | `display/window/stretch/scale_mode` | `integer` | só amplia 1×, 2×, 3×… (pixels sempre quadrados e iguais) |
  | `rendering/textures/canvas_textures/default_texture_filter` | `Nearest` (0) | sem suavização nas texturas |
  | `rendering/2d/snap/snap_2d_transforms_to_pixel` | `true` | posições arredondadas para o pixel inteiro |

- **Motivo**: é a configuração que a documentação recomenda para jogo de PC em pixel art:
  base 640×360 ("boa referência, porque escala para 1280×720, 1920×1080, 2560×1440 e
  3840×2160 sem barras pretas com escala inteira"), modo `viewport`, aspecto `keep` e escala
  `integer`. Em 640×360 cabem a mão, a expressão, os dois combatentes e os botões com cartas
  de 48×64 px (ver [contracts/tela-batalha.md](contracts/tela-batalha.md)); em 320×180 o
  texto das cartas (nome e efeito das especiais) não caberia legível.
- **Atenção**: projetos criados no Godot 4.7 já vêm com `stretch/mode = canvas_items`
  (a própria referência de `ProjectSettings` avisa). É preciso trocar para `viewport`.
- **Fonte**: a fonte final precisa ser de pixel art (asset pendente). Pela documentação, esse
  tipo de fonte pede filtro `Nearest` (já é o padrão do projeto), posicionamento de subpixel
  **desativado** na importação e tamanho múltiplo inteiro do tamanho de desenho da fonte.
  Até a fonte chegar, o placeholder é a fonte padrão do Godot; a leitura do texto nesse
  estado é conferida no [quickstart.md](quickstart.md) (cenário 6).
- **Tela cheia**: se a equipe quiser tela cheia depois (funcionalidade 004), usar
  "Exclusive Fullscreen": a documentação avisa que o modo "Fullscreen" comum perde 1 pixel de
  altura e pode derrubar a escala inteira para um fator menor.
- **Alternativas**: `canvas_items` com escala inteira (texto mais nítido, porque é desenhado
  na resolução final, mas os sprites podem parar em posições de meio pixel e a grade de pixels
  deixa de ser única; a documentação o indica para quem aceita movimento em subpixel);
  320×180 (pequena demais para o texto das cartas); 480×270 (escala exato só para 1920×1080;
  em 1280×720 e 2560×1440 sobra borda, e a mão grande fica mais apertada).
- **Documentação**:
  [Multiple resolutions](https://docs.godotengine.org/en/4.7/tutorials/rendering/multiple_resolutions.html)
  (seções "Stretch Mode", "Stretch Scale Mode" e "Common use case scenarios > Desktop game >
  Pixel art");
  [ProjectSettings](https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html)
  (`display/window/stretch/mode`, `display/window/stretch/scale_mode`,
  `display/window/size/window_width_override`,
  `rendering/textures/canvas_textures/default_texture_filter`,
  `rendering/2d/snap/snap_2d_transforms_to_pixel`);
  [Using Fonts](https://docs.godotengine.org/en/4.7/tutorials/ui/gui_using_fonts.html)
  (avisos sobre fontes de pixel art).

## D4. Regra separada da tela: lógica em `RefCounted`

- **Decisão**: motor das contas, baralho, combatente, busca do alvo e regras da rodada são
  classes que estendem `RefCounted` (ou só têm funções estáticas). Nenhuma delas é nó, usa
  `get_node` ou depende da árvore de cenas. As cenas guardam uma `Batalha`, mostram o estado
  dela e repassam os cliques.
- **Motivo**: a documentação indica `RefCounted` "na maioria dos casos em que se precisa de
  dados numa classe própria", por ser mais leve que nó e liberar a memória sozinho. Sem
  árvore de cenas, os testes do GUT criam os objetos com `.new()` e conferem o resultado na
  hora, sem abrir tela nem esperar quadros.
- **Alternativas**: lógica dentro do script da cena de batalha (mais rápido de escrever, mas
  cada teste teria que instanciar a tela, e a 002 não conseguiria simular lutas); autoload
  com o estado da luta (estado global dificulta teste e reinício).
- **Documentação**:
  [When and how to avoid using nodes for everything](https://docs.godotengine.org/en/4.7/tutorials/best_practices/node_alternatives.html);
  [RefCounted](https://docs.godotengine.org/en/4.7/classes/class_refcounted.html).

## D5. Dados fora do código: `Resource` em arquivos `.tres`

- **Decisão**: três tipos de dado, cada um um script que estende `Resource` com campos
  `@export`: `DadosCarta` (uma por tipo de carta), `DadosInimigo` e `RegrasBatalha` (todos os
  números da luta: vida, mão, mínimos, faixa do alvo, limites da busca, tempo do resultado).
  O baralho da luta é um `DadosBaralho` (lista de cartas). Os arquivos ficam em `dados/`.
  O código não tem número de equilíbrio solto: lê tudo desses objetos.
- **Motivo**: a documentação descreve `Resource` como "contêiner de dados" que o Inspector
  já sabe mostrar e editar e que é salvo em texto (`.tres`), bom para o git. A equipe muda o
  equilíbrio pelo editor, sem tocar em código (FR-028, SC-007).
- **Preparado para a 002**: a luta recebe `RegrasBatalha` e `DadosInimigo` por parâmetro e
  não sabe de onde vieram. O arquivo único de dificuldade da 002 pode guardar esses objetos
  como sub-recursos (um `.tres` pode conter outros recursos dentro dele) e entregar o da
  profundidade certa, sem mudar a batalha. Nada disso é implementado agora.
- **Alternativas**: JSON (precisa de código de leitura e validação e não aparece no
  Inspector); constantes no script (proibido pela FR-028); `Dictionary` exportado (sem tipos).
- **Documentação**:
  [Resources](https://docs.godotengine.org/en/4.7/tutorials/scripting/resources.html)
  (seção "Creating your own resources").

## D6. Cenas pequenas que conversam por sinais

- **Decisão**: oito cenas pequenas (lista no [plan.md](plan.md)). Cada uma recebe os dados
  por um método chamado pelo pai (`mostrar(...)`, `iniciar(...)`) e avisa o pai por sinal com
  nome no passado (`carta_escolhida`, `luta_terminou`). Nenhuma cena busca nós de outra cena
  por caminho.
- **Motivo**: é o que a documentação recomenda: cenas "sem dependências", com o pai
  fornecendo o que a filha precisa (injeção de dependência) e a filha respondendo por sinal;
  por convenção os sinais têm nome de verbo no passado. Atende ao princípio III da
  constituição (cena abre e é testada sozinha).
- **Alternativas**: uma cena única de batalha com tudo dentro (menos arquivos, mas contraria
  o princípio III e gera conflito de merge entre os cinco); barramento global de eventos
  (desnecessário para uma tela só).
- **Documentação**:
  [Scene organization](https://docs.godotengine.org/en/4.7/tutorials/best_practices/scene_organization.html)
  (seção "How to build relationships effectively");
  [Using signals](https://docs.godotengine.org/en/4.7/getting_started/step_by_step/signals.html).

## D7. Pastas por área do jogo

- **Decisão**: uma pasta por área na raiz (`cartas/`, `contas/`, `combatentes/`, `batalha/`,
  `luta_avulsa/`), cada uma com suas cenas, scripts e uma subpasta `testes/`; dados em
  `dados/`; terceiros em `addons/`. Nomes de pastas e arquivos em `snake_case`, nós em
  `PascalCase`. Arquivo vazio `.gdignore` em `docs/` e em `specs/`, para o Godot não importar
  nem mostrar a documentação no painel de arquivos.
- **Motivo**: a documentação recomenda agrupar os arquivos "o mais perto possível das
  cenas", `snake_case` para pastas e arquivos (evita erro de maiúsculas ao exportar no
  Windows), terceiros em `addons/` e `.gdignore` para pastas que não são do jogo. A
  constituição (III) pede cena, script e testes da área juntos.
- **Alternativas**: pastas por tipo de arquivo (`scripts/`, `scenes/`, `tests/`), como no
  jogo antigo (espalha uma mesma área em três lugares).
- **Documentação**:
  [Project organization](https://docs.godotengine.org/en/4.7/tutorials/best_practices/project_organization.html);
  [GDScript style guide](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/gdscript_styleguide.html).

## D8. Sorteio controlável por semente

- **Decisão**: a `Batalha` cria **um** `RandomNumberGenerator`, define `seed` com a semente
  recebida de fora e passa esse mesmo objeto ao baralho (embaralhar) e à busca do alvo
  (sortear). O embaralhamento é um Fisher–Yates escrito à mão com `rng.randi_range()`.
  Fica proibido no código da luta: `Array.shuffle()`, `Array.pick_random()`, `randi()` e
  `randf()` soltos.
- **Motivo**: a documentação diz que `shuffle()` e as funções globais usam "uma semente
  global comum", o que deixaria um teste interferir no outro. Já a classe
  `RandomNumberGenerator` permite "várias instâncias, cada uma com a sua semente e estado".
  Mesma semente e mesmas ações resultam na mesma luta (FR-029, SC-008).
- **Alternativas**: `seed()` global antes de cada luta (qualquer outro código que sorteie
  algo muda a sequência); um gerador por classe (três sementes para controlar em vez de uma).
- **Documentação**:
  [Random number generation](https://docs.godotengine.org/en/4.7/tutorials/math/random_number_generation.html)
  (seções "Global scope versus RandomNumberGenerator class" e "Random seed and internal
  state");
  [Array.shuffle()](https://docs.godotengine.org/en/4.7/classes/class_array.html#class-array-method-shuffle);
  [RandomNumberGenerator](https://docs.godotengine.org/en/4.7/classes/class_randomnumbergenerator.html).

## D9. Motor das contas e divisão para baixo

- **Decisão**: `MotorContas.avaliar(cartas)` percorre as cartas uma vez, em três níveis:
  **fator** (número seguido dos seus x2, /2 e ^2, na ordem), **termo** (fatores ligados por
  × e ÷, da esquerda para a direita) e **soma** (termos ligados por + e −). Devolve um
  `ResultadoConta` com `valida` e `valor`. A divisão e a metade usam
  `floori(a / float(b))`.
- **Motivo**: os três níveis são a própria regra de precedência da FR-013, sem montar árvore
  nem classe de parser. Sobre a divisão: no GDScript, `int / int` **trunca** (descarta a
  parte decimal, arredondando para zero), enquanto `floori()` arredonda "para baixo (em
  direção ao infinito negativo)", e a documentação avisa que os dois são diferentes. No jogo
  eles dão o mesmo resultado, porque não há sinal de negativo isolado e × e ÷ vêm antes de
  + e −: a divisão só recebe números positivos ou zero. O motor usa `floori()` mesmo assim,
  para seguir a FR-014 ao pé da letra sem depender desse detalhe.
- **Alternativas**: classe `Expression` do Godot (não conhece x2, /2 e ^2 como sufixos, usa
  divisão própria e aceitaria textos que a regra do jogo proíbe); parser recursivo com
  classes (o do jogo antigo: funciona, mas é mais código que o necessário).
- **Documentação**:
  [int: operator /](https://docs.godotengine.org/en/4.7/classes/class_int.html#class-int-operator-div-int);
  [@GlobalScope.floori()](https://docs.godotengine.org/en/4.7/classes/class_%40globalscope.html#class-globalscope-method-floori).

## D10. Alvo sempre alcançável: algoritmo, custo e testes

### O problema

A cada rodada o jogo precisa sortear um alvo da faixa (padrão 5 a 12) que o jogador consiga
montar com a mão atual, usando cada carta no máximo uma vez (FR-007). O jogo antigo sorteava
qualquer número da faixa, sem conferir.

### O algoritmo

`BuscaAlvo` monta, por busca em profundidade, todas as contas **válidas** possíveis com a mão
e anota o valor de cada uma:

1. As cartas da mão são agrupadas por tipo de conta (dois "3" são o mesmo tipo; o Foco, que
   vale 4, é o mesmo tipo que um "4"). Assim a busca não repete contas iguais.
2. A busca constrói a conta carta por carta, só por caminhos que a gramática permite
   (FR-012): começa por número; depois de um número pode vir um unário (x2, /2, ^2), um
   binário (+, −, ×, ÷) ou o fim; depois de um binário tem que vir número.
3. Toda vez que a conta está num ponto em que poderia terminar, ela é avaliada pelo
   **mesmo** `MotorContas.avaliar()` que julga a jogada do jogador. O valor entra num
   dicionário `valor → conta de exemplo` (só a primeira conta achada para cada valor).
4. A busca é repetida com limite crescente de cartas de número: primeiro contas de 1 número,
   depois de até 2, depois de até `max_numeros_no_alvo` (padrão 3).
5. **Parada antecipada**: assim que todos os valores da faixa já foram achados, a busca para.
   Isso não muda o resultado (a faixa inteira já é alcançável), só poupa tempo.
6. **Teto de segurança**: a busca também para ao atingir `limite_buscas_alvo` avaliações
   (padrão 10.000). Os valores achados até ali continuam valendo.
7. **Sorteio**: se algum valor da faixa foi achado, o alvo é sorteado entre eles, em ordem
   crescente, com o gerador da luta. Se nenhum foi achado, o alvo é o valor positivo achado
   mais próximo da faixa (FR-007); se um valor abaixo e um acima estão à mesma distância, o
   gerador sorteia entre os dois (decisão do Estêvão no analyze). Se a mão não tem nenhum
   número, o alvo é o mínimo da faixa e resta ao jogador o Pular. Isso só acontece com um
   baralho sem cartas de número, que o contrato da luta proíbe
   ([contracts/batalha.md](contracts/batalha.md), pré-condição); o caso fica tratado para a
   busca não quebrar se a pré-condição for violada.

### Por que o alvo é sempre alcançável

O alvo só sai do dicionário, e todo valor do dicionário entrou junto com uma conta de exemplo
feita só com cartas da mão e aprovada pelo motor que julga o jogador. Não existe caminho em
que o alvo seja escolhido sem essa conta. Como a busca e o julgamento usam a mesma função,
os dois nunca discordam sobre precedência, divisão ou validade.

### Quanto custa (medido)

Protótipo com a mesma estrutura, rodado no Godot 4.7.2 em modo headless nesta máquina
(melhor de 5 execuções). Cada avaliação custa cerca de 3,5 microssegundos.

**Faixa padrão (5 a 12), até 3 números:** o caso real da 001.

| Mão | Cartas | Avaliações | Tempo |
|---|---|---|---|
| Mínima ruim (1, 1, 2, +, −) | 5 | 24 | 0,09 ms |
| Inicial típica (2, 3, 5, +, −) | 5 | 45 | 0,17 ms |
| Mista | 8 | 63 | 0,20 ms |
| Mista | 12 | 91 | 0,25 ms |
| O baralho inteiro na mão | 21 | 243 | 0,78 ms |

Mão grande é **barata**, porque com muitas cartas a faixa inteira aparece cedo e a busca
para. Um quadro a 60 fps tem 16,7 ms; a busca usa menos de 1 ms.

**Faixas maiores (como as que a 002 vai usar), até 3 números:**

| Mão | Faixa | Avaliações | Tempo |
|---|---|---|---|
| 12 cartas | 16 a 30 | 1.743 | 4,5 ms |
| Baralho inteiro (21) | 16 a 30 | 3.031 | 8,4 ms |
| Baralho inteiro (21) | 30 a 60 | 5.765 | 16,0 ms |

**Pior caso (faixa impossível, a busca vai até o fim, sem teto):**

| Mão | Até 2 números | Até 3 números | Até 4 números |
|---|---|---|---|
| 8 cartas | 0,3 ms | 2,4 ms | 7,5 ms |
| 12 cartas | 0,9 ms | 21 ms | 251 ms |
| Baralho inteiro (21) | 26 ms | 1.424 ms | 37.947 ms |

O pior caso cresce muito rápido com o número de tipos diferentes na mão e com o limite de
números, porque a quantidade de contas possíveis é combinatória. Por isso existem os dois
freios, ambos nos dados:

- `max_numeros_no_alvo = 3`: o alvo nunca exige mais de 3 números, o que também é uma
  decisão de dificuldade (a 002 pode aumentar com a profundidade, olhando esta tabela);
- `limite_buscas_alvo = 10.000`: garante no máximo cerca de 35 ms nesta máquina, mesmo no
  pior caso, e esse instante fica escondido atrás do aviso de resultado da rodada.

Quando o teto corta a busca, o alvo continua alcançável (só sai do que foi achado). O que se
perde é a certeza de ter visto **todos** os valores possíveis. Na 001 isso não acontece: o
teste de simulação abaixo confere que nenhuma rodada chega ao teto
(`avaliacoes < limite_buscas_alvo` em toda rodada).

### Como é testado

- **Contra a força bruta** (oráculo independente): para dezenas de mãos pequenas sorteadas
  com semente (3 a 6 cartas), o conjunto de valores da `BuscaAlvo` (sem limite de números)
  tem que ser igual ao conjunto obtido testando **todas as ordens de todos os subconjuntos**
  da mão no `MotorContas`. No protótipo: 60 mãos, 60 conjuntos iguais.
- **Conta de exemplo**: para cada valor achado, a conta guardada usa só cartas da mão (cada
  uma no máximo uma vez) e o motor confirma que ela dá aquele valor.
- **Sorteio**: o alvo sempre pertence aos valores achados; fica na faixa quando há algum
  valor da faixa; cai no mais próximo quando não há (mão 1, 1, 2, +, − → alvo 3: os valores
  possíveis são −1, 0, 1, 2 e 3, porque só há um `+`).
- **Freios**: com o baralho inteiro na mão e uma faixa impossível (5.000 a 6.000; o maior
  valor possível com o baralho da 001 é `7 x2 ^2 × 6 + 5` = 1.181), a busca termina e o número
  de avaliações não passa de `limite_buscas_alvo`; nenhuma conta de exemplo tem mais números
  que `max_numeros_no_alvo`.
- **Simulação** (SC-002): 1.000 lutas com sementes diferentes, jogadas por um "jogador
  automático" simples; em toda rodada o alvo tem conta de exemplo válida, e toda busca
  termina antes do teto (`avaliacoes < limite_buscas_alvo`). Conferir só que não passou do
  teto não provaria nada, porque o teto já impede isso.
- Os testes conferem **contagem de avaliações**, não tempo de relógio, para não falharem
  por causa da velocidade do computador de quem roda.

- **Alternativas**: sortear o alvo e torcer (jogo antigo: alvo impossível acontece); montar
  uma conta aleatória e usar o valor dela como alvo (alcançável, mas não sabe dizer se a
  faixa tem outro valor possível e distorce o sorteio); programação dinâmica por conjuntos de
  valores (mais rápida no pior caso, porém bem mais difícil de ler e sem reaproveitar o motor
  que julga o jogador).
- **Documentação**:
  [RandomNumberGenerator.randi_range()](https://docs.godotengine.org/en/4.7/classes/class_randomnumbergenerator.html#class-randomnumbergenerator-method-randi-range)
  (sorteio do alvo);
  [Time.get_ticks_usec()](https://docs.godotengine.org/en/4.7/classes/class_time.html#class-time-method-get-ticks-usec)
  (usado na medição). O algoritmo em si é do projeto, não da documentação.

## D11. Garantia de mão mínima: compra dirigida

- **Decisão** (resposta do Estêvão em 13/11): o jogo **nunca tira** cartas da mão. No início
  da rodada, enquanto faltar número, soma ou subtração na mão (atendidos nessa ordem), a
  carta comprada é a daquele tipo mais perto do topo da pilha de compra ou, se a pilha não
  tiver, a descartada há mais tempo (decisão do Estêvão no analyze). Com a pilha vazia, vale
  a FR-005 antes de tudo: o descarte é embaralhado e vira a pilha, e a busca é feita nela
  (segunda decisão do Estêvão no analyze). A ordem entre os tipos
  não muda a mão final, porque cada tipo pega a própria carta; ela só deixa o código
  determinístico. Primeiro saem as
  cartas normais da rodada (5 na primeira, 1 nas outras); se ainda faltar algo, o jogo compra
  cartas extras do tipo que falta. Sem falta nenhuma, compra o topo da pilha.
- **Consequência**: a mão inicial é sempre 3 números, + e −. As compras do Pular e do Foco
  são comuns (topo da pilha), porque a garantia vale no início da rodada (FR-006).
- **Motivo**: trocar cartas "que sobram" tiraria da mão cartas que o jogador guarda de
  propósito. A compra dirigida é também mais simples de programar e de testar que a troca.
- **Alternativas**: trocar excedentes (texto antigo da FR-006, do jogo antigo); repor a mão
  até 5 toda rodada (muda a ideia de mão persistente).
- **Documentação**: regra de jogo, sem página do Godot; usa só `Array` tipado
  ([Array](https://docs.godotengine.org/en/4.7/classes/class_array.html)).

## D12. Pausa de 1,5 s do resultado

- **Decisão**: a `Batalha` resolve a rodada na hora (dano, efeitos, ataque do inimigo),
  entra no estado `MOSTRANDO_RESULTADO`, em que recusa qualquer ação, e emite
  `rodada_resolvida`. Quem conta o tempo é a tela: um nó `Timer` de disparo único com
  `wait_time = regras.tempo_resultado`; ao disparar, a tela chama `batalha.avancar()`.
- **Motivo**: o tempo é apresentação, não regra. Nos testes de lógica o teste chama
  `avancar()` direto, sem esperar. Nos testes de cena as regras usam um tempo de centésimos
  de segundo. O nó `Timer` é, segundo a documentação, "a forma mais simples" de lidar com
  tempo e some junto com a cena, o que evita o erro de um `await` terminar depois que a tela
  foi fechada (por exemplo ao reiniciar a luta).
- **Alternativas**: `await get_tree().create_timer(1.5).timeout` (o temporizador é da árvore
  e continua vivo se a cena for removida); pausa dentro da lógica (os testes ficariam lentos
  ou precisariam de simulação de tempo).
- **Documentação**:
  [Timer](https://docs.godotengine.org/en/4.7/classes/class_timer.html);
  [SceneTree.create_timer()](https://docs.godotengine.org/en/4.7/classes/class_scenetree.html#class-scenetree-method-create-timer).

## D13. Efeitos das cartas especiais com alvo certo

- **Decisão**: `DadosCarta` tem `efeito` (enum `NENHUM`, `DANO_EXTRA`, `COMPRAR`, `ESCUDO`,
  `CURA`) e `intensidade`. A `Batalha` aplica com um `match` numa função só: `DANO_EXTRA` →
  `inimigo.receber_dano()`; `COMPRAR` → `baralho.comprar()`; `ESCUDO` →
  `arthur.ganhar_escudo()`; `CURA` → `arthur.curar()`. Quem recebe está escrito ao lado do
  efeito, não é passado por parâmetro.
- **Motivo**: no jogo antigo, um registro genérico recebia um "alvo" e a batalha passava
  sempre o inimigo, então Guarda e Vital protegiam e curavam o inimigo. Com o destinatário
  fixo por efeito, o erro não tem onde acontecer, e são 4 casos, que não justificam registro
  nem classes de efeito (princípio I).
- **Ordem**: dano das cartas, efeitos na ordem da conta (valem mesmo no golpe final),
  expressão para o descarte e, por último, o ataque do inimigo se ele ainda está vivo
  (FR-016). Os efeitos vêm antes do descarte para o Foco não comprar cartas da própria conta.
- **Testes obrigatórios**: para cada efeito, conferir **os dois lados**: Guarda dá 5 de
  escudo ao Arthur e o escudo do inimigo continua 0; Vital aumenta a vida do Arthur e a do
  inimigo só cai pelo dano das cartas; Chama tira vida do inimigo e não mexe no Arthur; Foco
  aumenta a mão em 1. E nenhum efeito acontece em conta errada.
- **Alternativas**: registro de efeitos por nome com `Callable` (jogo antigo); um `Resource`
  por efeito com método `aplicar()` (extensível, mas é abstração sem necessidade agora).
- **Documentação**:
  [GDScript reference](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/gdscript_basics.html)
  (seções "Enums" e "match").

## D14. Interface da luta pensada para a 002

- **Decisão**: a cena `tela_batalha.tscn` tem um método
  `iniciar(cartas, vida_arthur, dados_inimigo, regras, semente)` e um sinal
  `luta_terminou(resultado)`, em que `resultado` traz `venceu`, `vida_arthur`,
  `vida_inimigo` e `rodadas`. Ela não conhece o baralho padrão, não mostra tela de vitória ou
  derrota e não reinicia nada. Na 001, quem a usa é a cena `luta_avulsa`, que carrega os
  dados padrão, mostra `fim_de_luta` e recomeça. Na 002, o mapa ocupa o lugar da
  `luta_avulsa`. Detalhes em [contracts/batalha.md](contracts/batalha.md).
- **Motivo**: é a injeção de dependência da documentação: quem está acima fornece os dados
  e reage ao sinal. Com a tela de fim fora da batalha, o mapa da 002 decide o que vem depois
  (recompensa, próxima casa, fim da run) sem alterar a batalha.
- **Alternativas**: a batalha carregar sozinha o baralho e a vida (a 002 teria que
  reescrevê-la); autoload com o estado da run (é assunto da 002, não desta funcionalidade).
- **Documentação**:
  [Scene organization](https://docs.godotengine.org/en/4.7/tutorials/best_practices/scene_organization.html).

## D15. Placeholders e lista de pendências

- **Decisão**: nenhum arquivo de arte ou som é criado. Sprites são `ColorRect` de cor chapada
  no tamanho final do asset, com um `Label` de nome por cima; cartas são `Panel` + `Label`;
  o fundo é a cor de limpeza padrão do projeto; a fonte é a padrão do Godot; o projeto não
  tem ícone próprio (sem `application/config/icon` e sem `icon.svg`), então a janela usa o
  ícone padrão do Godot, listado como pendência como os demais. Sons: a cena `sons_batalha` tem um
  `AudioStreamPlayer` por evento, **sem áudio atribuído**, e só toca se houver áudio
  (`if tocador.stream != null`); a música da luta é mais um tocador ali, com `autoplay`; os
  sons de vitória e derrota são dois tocadores da cena `fim_de_luta`. Quando a equipe entregar um arquivo, ele é atribuído no
  editor, sem mexer no código. Tudo fica listado em `docs/assets-pendentes.md` (tipo,
  tamanho, quadros, formato e onde é usado).
- **Motivo**: princípio IV da constituição e FR-030. `ColorRect` é o nó da documentação para
  "um retângulo de cor única". `PlaceholderTexture2D`, apesar do nome, foi descartado: a
  documentação diz que ele "não foi feito para ser usado como textura de verdade".
- **Formatos pedidos à equipe**: imagens em PNG com fundo transparente; efeitos sonoros
  curtos em WAV e música em Ogg Vorbis, como a documentação sugere.
- **Alternativas**: gerar sprites provisórios (proibido sem autorização); deixar os sons para
  depois, sem pontos de encaixe (a troca exigiria mexer em código).
- **Documentação**:
  [ColorRect](https://docs.godotengine.org/en/4.7/classes/class_colorrect.html);
  [PlaceholderTexture2D](https://docs.godotengine.org/en/4.7/classes/class_placeholdertexture2d.html);
  [Importing audio samples](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_audio_samples.html);
  [AudioStreamPlayer](https://docs.godotengine.org/en/4.7/classes/class_audiostreamplayer.html).

## D16. Interface com nós `Control`

- **Decisão**: a tela é feita de nós `Control` dentro de contêineres (`HBoxContainer`,
  `VBoxContainer`, `MarginContainer`), sem posições calculadas à mão. A fila de cartas diminui
  a separação entre as cartas (até sobrepor) quando a mão não cabe em 600 px, deixando o canto
  de cada carta, com o símbolo, visível e clicável. O efeito de uma carta especial aparece
  também em `tooltip_text`, com o nome e a condição ("Chama: +3 de dano. Só vale quando a
  conta acerta o alvo."). Os textos ficam direto em português no código e
  nas cenas, sem sistema de tradução (o jogo é só em português).
- **Motivo**: contêineres organizam os filhos sozinhos e continuam certos quando a mão muda
  de tamanho; a mão não tem limite (pode chegar a 21 cartas), então a sobreposição é
  necessária em 640 px de largura.
- **Alternativas**: `Node2D` com posições manuais (mais código e conta de layout à mão);
  rolagem horizontal da mão (esconde cartas do jogador).
- **Documentação**:
  [Using Containers](https://docs.godotengine.org/en/4.7/tutorials/ui/gui_containers.html);
  [Control.tooltip_text](https://docs.godotengine.org/en/4.7/classes/class_control.html#class-control-property-tooltip-text).

## D17. Testes: GUT 9.7.1 pela linha de comando

- **Decisão**: GUT **9.7.1** copiado para `addons/gut/` e versionado no git, plugin ativado
  no projeto. Arquivos de teste em `<area>/testes/teste_*.gd`; as pastas e o prefixo
  `teste_` ficam no `.gutconfig.json` da raiz. Comando da suíte inteira (detalhes no
  [quickstart.md](quickstart.md)):

  ```bash
  godot --headless --path . --import          # só na primeira vez ou após criar classes
  godot --headless --path . -s addons/gut/gut_cmdln.gd
  ```

- **Motivo**: a tabela do README do GUT indica a 9.7.1 (ramo `godot_4_7`) para o Godot 4.7.x;
  o ramo principal ainda é o do 4.6. O `--import` é necessário porque as classes com
  `class_name` só são reconhecidas depois que o projeto é importado uma vez; segundo a
  documentação do Godot, ele "abre o editor, espera a importação e sai". `--headless` roda
  sem janela e `-s` executa um script.
- **Testado**: num projeto de rascunho com o GUT 9.7.1 e o Godot 4.7.2 desta máquina, os dois
  comandos acima rodaram um teste de classe e um teste com `await wait_seconds()` e nó na
  árvore: 2 de 2 passando, em modo headless.
- **Exceção ao português**: o GUT exige que as funções de teste comecem com `test_` e que o
  script estenda `GutTest`. Esses nomes são da ferramenta, como os da API do Godot
  (princípio V); o resto do nome fica em português (`test_soma_vem_depois_da_multiplicacao`).
- **Testes de cena**: a cena é instanciada, posta na árvore com `add_child_autofree()`,
  recebe os dados, e o teste aciona os sinais dos botões e confere os textos e os sinais
  emitidos (`watch_signals`, `assert_signal_emitted`), com `tempo_resultado` de centésimos de
  segundo.
- **Código de saída**: pela documentação do GUT, o comando devolve 0 se tudo passa e 1 se
  algum teste falha.
- **MCP do Godot**: serve para abrir o jogo e ver a saída de depuração durante a
  implementação (`run_project`, `get_debug_output`); a suíte de testes roda pelo comando
  acima, que não abre janela.
- **Alternativas**: gdUnit4 (descartado na constituição); GUT pelo ramo principal (é o do
  Godot 4.6); instalar pela Asset Library (lá só há a versão do 4.6, segundo o README).
- **Documentação**:
  [Command line tutorial](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
  (`--headless`, `--path`, `--import`, `-s`). Do GUT (não é documentação do Godot):
  [README com a tabela de versões](https://github.com/bitwes/Gut/tree/godot_4_7),
  [Command Line](https://gut.readthedocs.io/en/v9.7.1/Command-Line.html),
  [Creating Tests](https://gut.readthedocs.io/en/v9.7.1/Creating-Tests.html) e
  [Awaiting](https://gut.readthedocs.io/en/v9.7.1/Awaiting.html).

## Riscos que ficam para a implementação

- **Leitura do texto em 640×360 com a fonte padrão**: só dá para julgar com o jogo aberto.
  Está no quickstart (cenário 6). Se ficar ruim antes de a fonte de pixel art chegar, a saída
  é aumentar o tamanho da fonte placeholder, não mudar a resolução.
- **Equilíbrio**: com 21 cartas e alvos de 5 a 12, um acerto de 3 cartas tira de 5 a 9 de
  vida; o inimigo padrão (12 de vida) deve cair em 2 ou 3 acertos. Os números são do jogo
  antigo e ficam nos dados para a equipe ajustar jogando.
- **Cartas iguais são o mesmo objeto**: os dois "3" do baralho apontam para o mesmo
  `numero_3.tres`. O código do baralho move cartas sempre por **posição**, nunca procurando
  pela carta, para não confundir uma com a outra.
