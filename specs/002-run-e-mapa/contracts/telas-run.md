# Contrato: as cenas da run

**Para quem**: quem for montar ou trocar o visual. Cada cena abaixo abre e funciona sozinha:
recebe dados por um método e avisa o pai por sinal. Nenhuma busca nós fora dela. Resolução base
640×360, fonte de 10 px do `tema.tres` (001, research D3 e D18).

## Cena principal: `run/tela_run.tscn` (raiz `Control`)

Interface e fluxo em [run.md](run.md). Por dentro tem, fixos:

| Nó | Tipo | Conteúdo |
|---|---|---|
| `Barra` | `HBoxContainer`, faixa de `y` 0 a 24, margem de 8 px | três `Label`: `Ato` ("Ato 1: Calabouço"), `Vida` ("Vida 31/40") e `Baralho` ("Baralho: 13 cartas") (FR-015) |
| `Mapa` | instância de `mapa/tela_mapa.tscn` | o mapa do ato atual |
| `ErroDados` | `Label` centrado, escondido | o aviso de dados errados |

A barra e o mapa aparecem juntos e somem juntos (research D8). As cenas das etapas entram como
filhas da raiz, por cima, e saem quando terminam.

Aviso de dados errados (FR-028), uma linha por frase de `erros()`:

```text
O arquivo de dificuldade tem valores errados. A run não começou.
- Ato 1 (Calabouço): alvo_minimo (13) é maior que alvo_maximo (12).
```

## `mapa/tela_mapa.tscn` (raiz `Control`, tela inteira)

```gdscript
signal casa_escolhida(casa: Casa)

## Recria as casas, posiciona o marcador do Arthur e redesenha as ligações.
func mostrar(mapa: MapaAto, casa_atual: Casa) -> void

## Centro da casa na tela; usada para pôr as casas e para desenhar as ligações (research D9).
static func posicao_da_casa(andar: int, indice: int, casas_no_andar: int, total_de_andares: int) -> Vector2
```

Disposição (640×360), com os 5 andares do padrão:

| Elemento | Posição |
|---|---|
| andar do chefe | `y = 48` |
| andar 1 | `y = 312` |
| outros andares | divididos por igual entre os dois (66 px com 5 andares) |
| casas de um andar | centradas em `x = 320`, a cada 96 px (3 casas: 224, 320, 416; 2 casas: 272, 368) |
| marcador do Arthur antes do primeiro andar | `x = 320`, `y = 344` |
| marcador do Arthur numa casa | canto de cima e da esquerda da casa |

Os valores são arredondados para o pixel inteiro. Com mais de 6 casas num andar a fileira passa
de 600 px; os dados padrão têm no máximo 3.

Comportamento:

- Uma `casa_mapa` por casa. Só as de `mapa.disponiveis(casa_atual)` ficam clicáveis (FR-013);
  clicar numa delas emite `casa_escolhida(casa)`. Clicar em qualquer outra coisa não faz nada.
- Ligações (no `_draw()`, por baixo das casas, largura 2, sem suavização):

  | Ligação | Cor do placeholder |
  |---|---|
  | comum | cinza, `Color(0.45, 0.45, 0.45)` |
  | já percorrida (as duas casas visitadas) | branca, `Color(0.95, 0.95, 0.95)` |
  | da casa atual para uma disponível | amarela, `Color(0.95, 0.8, 0.3)` |

- Marcador do Arthur: `ColorRect` 8×8 azul, `Color(0.25, 0.4, 0.8)` (a cor do Arthur na luta),
  com `mouse_filter = IGNORE`, para não tapar a dica da casa em que está (research D9).
- A cena não sabe de vida, baralho nem ato: isso fica na barra da cena principal.

## `mapa/casa_mapa.tscn` (raiz `Button`, 32×32)

```gdscript
signal escolhida

func mostrar(tipo: Casa.Tipo, disponivel: bool) -> void
```

| Tipo | Letra | Cor do placeholder (`ColorRect` 32×32) | Dica (`tooltip_text`) |
|---|---|---|---|
| `BATALHA` | B | `Color(0.55, 0.3, 0.3)` | "Batalha" |
| `ELITE` | E | `Color(0.75, 0.2, 0.2)` | "Elite: inimigo mais forte, dá carta" |
| `DESCANSO` | D | `Color(0.3, 0.6, 0.35)` | "Descanso: cura parte da vida" |
| `RECOMPENSA` | R | `Color(0.75, 0.6, 0.25)` | "Recompensa: escolha 1 entre 3 cartas" |
| `CHEFE` | C | `Color(0.5, 0.2, 0.55)` | "Chefe do ato" |

Estados (FR-012):

| Estado | `disabled` | Aparência |
|---|---|---|
| disponível | `false` | cor cheia e moldura de 1 px clara em volta (destaque) |
| não disponível (visitada ou não) | `true` | cor escurecida (`modulate` 0,5) |

A casa não recebe se foi visitada: o que separa a visitada das demais é o caminho branco das
ligações e o marcador do Arthur, desenhados pela `tela_mapa` (FR-012).

Mouse: o `ColorRect` e a moldura (se ela for um nó) usam `mouse_filter = IGNORE`; o `Label` já
vem assim. O `ColorRect` vem com `STOP` e, cobrindo o botão inteiro, ficaria com o clique e com a
dica (research D9). É o mesmo cuidado do fundo da `cartas/carta.tscn` da 001.

## `descanso/tela_descanso.tscn` (raiz `Control`, tela inteira)

```gdscript
signal continuou

func mostrar(cura: int, vida: int, vida_maxima: int) -> void
```

Centrado na tela (`CenterContainer` com `VBoxContainer`): título "Descanso", placeholder da
imagem (`ColorRect` 96×96, `Color(0.85, 0.5, 0.2)`), a frase da cura, a vida e o botão
"Continuar".

| Caso | Frase |
|---|---|
| `cura` > 0 | "Arthur descansou e recuperou 12 de vida." |
| `cura` = 0 | "Arthur descansou, mas a vida já estava cheia." |
| sempre | "Vida: 32/40" |

## `recompensa/tela_recompensa.tscn` (raiz `Control`, tela inteira)

```gdscript
signal carta_escolhida(carta: DadosCarta)
signal nenhuma_escolhida

func mostrar(oferta: Array[DadosCarta]) -> void
```

Centrado na tela: título "Escolha uma carta para o baralho", uma fileira (`HBoxContainer`) com
uma `cartas/carta.tscn` da 001 por carta da oferta (até 3, com símbolo, ataque e, nas especiais,
nome, efeito e a dica da 001; FR-021) e o botão "Não pegar nenhuma". Clicar numa carta emite
`carta_escolhida(carta)`; o botão emite `nenhuma_escolhida`.

Com a oferta vazia (conjunto de recompensas vazio nos dados): a fileira some, o título vira
"Não há cartas para escolher." e o botão vira "Continuar", emitindo `nenhuma_escolhida`.

## `run/vitoria_luta.tscn` (raiz `Control`, tela inteira)

```gdscript
signal continuou

func mostrar(vida: int, vida_maxima: int) -> void
```

Centrado: "Vitória!", "Vida do Arthur: 24/40" e o botão "Continuar" (FR-019).

## `run/fim_de_run.tscn` (raiz `Control`, tela inteira)

```gdscript
signal jogar_de_novo

func mostrar(run: Run) -> void
```

| | Vitória (etapa `VITORIA`) | Derrota (etapa `DERROTA`) |
|---|---|---|
| Título | "Vitória!" | "Fim da run" |
| Linha 1 | "Arthur venceu o chefe do ato 3 (Torre), andar 5." | "Arthur caiu no ato 2 (Salões), andar 3." |
| Linha 2 | "Lutas vencidas: 14" | "Lutas vencidas: 6" |
| Botão | "Começar de novo" | "Começar de novo" |

Ato, nome e andar vêm da `Run` (`ato`, `dados_do_ato().nome`, `andar_alcancado()`; FR-024). Um
clique no botão começa a run nova (SC-006).

## Placeholders (princípio IV)

Tudo que é visual nestas cenas é placeholder do próprio Godot (`ColorRect`, `Button`, `Label`,
linhas do `_draw()`, fonte padrão) e está listado em `docs/assets-pendentes.md`, seção da 002.
Nenhuma cena da 002 tem som: a música e os sons da luta continuam os da 001, e o mapa fica em
silêncio até a 004.
