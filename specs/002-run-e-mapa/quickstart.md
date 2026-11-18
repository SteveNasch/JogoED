# Quickstart: Run e mapa (002)

Guia para rodar os testes e conferir, jogando, que a funcionalidade está pronta. Regras em
[spec.md](spec.md); interfaces em [contracts/](contracts/); dados em
[data-model.md](data-model.md).

## Pré-requisitos

Os mesmos da 001 (ver [quickstart da 001](../001-nucleo-batalha/quickstart.md)): Godot
4.7.2-stable, GUT 9.7.1 já no repositório e o apelido `godot` definido no terminal.

## Rodar a suíte inteira de testes

```bash
godot --headless --path . --import
godot --headless --path . -s addons/gut/gut_cmdln.gd
```

Rode o `--import` depois de criar as classes novas (`Run`, `Casa`, `MapaAto`, `GeradorMapa`,
`DadosMapa`, `DadosAto`, `DadosDificuldade`) e os arquivos de dados novos. **Esperado**:
`---- All tests passed! ----`, 0 falhando, código de saída 0.

Rodar só uma área:

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gselect=gerador_mapa
godot --headless --path . -s addons/gut/gut_cmdln.gd -gselect=simulacao_run
```

## Abrir o jogo

```bash
godot --path .
```

Ou, pelo editor, F5. A cena principal passa a ser `run/tela_run.tscn`. A luta solta da 001
continua existindo: abra `luta_avulsa/luta_avulsa.tscn` no editor e aperte F6.

**Dica para testar rápido**: para chegar aos atos 2 e 3 sem jogar até 15 lutas, mude por um momento
a vida dos inimigos em `dados/dificuldade.tres` para 1 e desfaça depois com
`git checkout dados/dificuldade.tres`.

## Cenários de validação

Marque cada um ao conferir. Os números entre parênteses são os da spec.

### 1. A suíte passa (SC-001 a SC-005)

A suíte precisa conter e passar, no mínimo:
- 1.000 mapas por ato com todas as regras de FR-008 a FR-011 conferidas uma a uma (SC-001) e a
  mesma semente dando o mesmo mapa (SC-002);
- a conferência dos dados padrão (SC-004) e uma frase de erro para cada valor impossível da
  FR-028;
- 1.000 runs com escolhas automáticas conferindo vida e baralho no começo de cada luta (SC-003)
  e 20 runs com lutas jogadas de verdade, com alvo alcançável e mão mínima em toda rodada
  (FR-029), o baralho da run igual depois de cada luta (FR-004) e a mesma semente repetindo a
  run (SC-002);
- os testes de cena: mapa, casa, descanso, recompensa, aviso de vitória, fim de run e a cena
  principal.

### 2. Atravessar o calabouço (história 1)

1. Abra o jogo. **Esperado**: o mapa do calabouço inteiro, do andar 1 (embaixo) ao chefe
   (topo), com as ligações; na barra, "Ato 1: Calabouço", "Vida 40/40" e "Baralho: 13 cartas";
   só as 2 ou 3 casas do andar 1 destacadas.
2. Clique numa casa que não está destacada. **Esperado**: nada acontece.
3. Clique numa casa de batalha do andar 1. **Esperado**: a luta começa com o Arthur com 40 de
   vida e um inimigo do calabouço com 12 de vida e 3 de ataque.
4. Vença a luta e anote a vida que sobrou. **Esperado**: aparece "Vitória!" com a vida; ao
   clicar em "Continuar", o mapa volta com o caminho percorrido em branco, o marcador do Arthur
   na casa, a mesma vida na barra e só as casas do andar 2 ligadas a ela destacadas.
5. Entre na luta seguinte. **Esperado**: ela começa com a vida anotada, e não com 40; o inimigo
   de um andar mais alto tem 1 de vida a mais.
6. Siga até o chefe e vença. **Esperado**: depois do aviso de vitória e da recompensa, aparece o
   mapa dos salões ("Ato 2: Salões"), com a mesma vida e o mesmo baralho e o Arthur antes do
   andar 1.

### 3. Perder e recomeçar (história 2)

1. Numa luta, use Pular até a vida do Arthur zerar. **Esperado**: sem aviso de vitória, aparece
   "Fim da run" com o ato e o andar em que ele caiu e quantas lutas venceu.
2. Clique em "Começar de novo". **Esperado**: o mapa do calabouço gerado de novo, quase sempre diferente do anterior (compare
   a posição das casas de descanso e de recompensa), "Vida 40/40" e "Baralho: 13 cartas"
   (SC-006: um clique só).

### 4. Descansar e ganhar cartas (história 3)

1. Entre num descanso com a vida baixa (por exemplo 20). **Esperado**: "Arthur descansou e
   recuperou 12 de vida." e "Vida: 32/40"; "Continuar" volta ao mapa com 32 na barra.
2. Entre num descanso com a vida em 35 ou mais. **Esperado**: a vida vai a 40 e a frase mostra só
   o que curou de fato; com 40, "a vida já estava cheia".
3. Entre numa recompensa. **Esperado**: 3 cartas diferentes, como na luta (símbolo, ataque e, nas
   especiais, nome e efeito), e o botão "Não pegar nenhuma".
4. Escolha uma carta. **Esperado**: a barra mostra "Baralho: 14 cartas", e a carta pode aparecer
   na mão da luta seguinte.
5. Em outra recompensa, clique em "Não pegar nenhuma". **Esperado**: o baralho não muda.
6. Vença uma elite. **Esperado**: depois do aviso de vitória abre uma recompensa. Vença uma
   batalha comum. **Esperado**: volta direto ao mapa.

### 5. Os três atos (história 4)

Com a dica de testar rápido (vida dos inimigos 1):
1. Passe do chefe do ato 1 e do ato 2. **Esperado**: "Ato 2: Salões" e depois "Ato 3: Torre",
   cada um com mapa próprio, vida e baralho mantidos.
2. Vença o chefe da torre. **Esperado**: o aviso de vitória e depois "Vitória!" no fim de run,
   sem recompensa, com "Começar de novo".
3. Desfaça a mudança (`git checkout dados/dificuldade.tres`).

### 6. Mudar o equilíbrio sem mexer em código (SC-005)

1. No editor, abra `dados/dificuldade.tres`, ato 1, `comum`, e mude a vida de 12 para 20. Salve.
2. Rode o jogo e entre numa batalha do andar 1. **Esperado**: o inimigo tem 20 de vida.
3. Desfaça a mudança.

### 7. Dado errado no arquivo (FR-028)

1. Em `dados/dificuldade.tres`, ato 1, mude `alvo_minimo` para 13 (maior que o máximo, 12).
2. Rode o jogo. **Esperado**: no lugar do mapa, o aviso "O arquivo de dificuldade tem valores
   errados. A run não começou." e a frase do ato 1 com `alvo_minimo` e `alvo_maximo`; a mesma
   frase aparece como erro na saída do editor.
3. Desfaça a mudança.

### 8. Pixel art e leitura do mapa (research D9 e D13)

1. Com a janela em 1280×720, veja as ligações e as casas. **Esperado**: linhas retas e nítidas,
   sem borrão, nenhuma ligação cruzando outra, as letras das casas legíveis.
2. Passe o mouse numa casa. **Esperado**: a dica com o tipo da casa.

### 9. Duração da run (SC-007)

Jogue pelo menos duas runs até o chefe da torre, sem a dica de vida 1, e cronometre do primeiro
clique ao chefe. **Esperado**: de 20 a 30 minutos. Anote os tempos no registro abaixo; fora da
meta, a correção é no arquivo de dificuldade (research, "Riscos").

### 10. Placeholders listados (SC-008)

Confira que cada retângulo, letra, linha e texto provisório novo tem uma linha em
`docs/assets-pendentes.md` (seção da 002) e que nenhum arquivo de imagem, som ou fonte foi criado
para o jogo (fora de `addons/gut/`).

### 11. A luta avulsa continua funcionando

Abra `luta_avulsa/luta_avulsa.tscn` e aperte F6. **Esperado**: a luta solta da 001, com as 21
cartas, como antes.

## Pelo MCP do Godot (para o Claude)

Como na 001: o Claude roda a suíte pela linha de comando, abre o jogo com `run_project` e lê a
saída com `get_debug_output` (cenários 1, 7 e 10, que não precisam de clique, e o carregamento
do jogo sem erro). Os cenários 2 a 6, 8, 9 e 11 são jogados por uma pessoa da equipe, que anota
o resultado abaixo.

## Registro da validação

(vazio; preenchido na implementação)
