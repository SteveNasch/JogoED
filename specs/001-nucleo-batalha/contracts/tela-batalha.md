# Contrato: as cenas da tela de luta

**Para quem**: quem for montar ou trocar o visual. Cada cena abaixo abre e funciona sozinha:
recebe dados por um método e avisa o pai por sinal. Nenhuma busca nós fora dela.
Resolução base 640×360 (ver [../research.md](../research.md), D3).

## Divisão da tela (640×360)

| Faixa (y) | Conteúdo | Requisito |
|---|---|---|
| 8 a 120 | Arthur à esquerda, alvo no centro (número grande), inimigo à direita | FR-023 |
| 128 a 200 | expressão em montagem (cartas 48×64) e, sobre ela, o aviso da rodada | FR-008, FR-025 |
| 208 a 232 | botões Desfazer, Limpar, Confirmar e Pular | FR-023 |
| 280 a 344 | mão (cartas 48×64, sobrepostas se não couberem em 600 px) | FR-023, FR-024 |

Margem de 8 px nas bordas. As posições saem de contêineres, não de coordenadas no código.

## Cenas

### `cartas/carta.tscn` (raiz: `Button`, 48×64)

```gdscript
signal clicada
func mostrar(dados: DadosCarta) -> void
```

Mostra o símbolo em destaque (`dados.simbolo()`), o ataque num canto e, nas especiais, o nome
(`dados.nome`) e o efeito (`dados.texto_efeito()`, por exemplo "+3 de dano"). O `tooltip_text`
junta os dois com a condição do efeito: "Chama: +3 de dano. Só vale quando a conta acerta o
alvo." (FR-024). Não há um segundo texto de efeito nos dados. O símbolo fica no canto superior
esquerdo, para continuar visível com as cartas sobrepostas.

### `cartas/fila_cartas.tscn` (raiz: `HBoxContainer`)

Usada duas vezes na tela: como **mão** (clicável) e como **expressão** (só leitura).

```gdscript
@export var clicavel: bool = true
signal carta_escolhida(indice: int)
func mostrar(cartas: Array[DadosCarta]) -> void
```

Recria as cartas na ordem do array. Se a largura passar de 600 px, reduz a separação até
caber. Com `clicavel = false`, as cartas não emitem nada.

### `combatentes/painel_combatente.tscn` (raiz: `VBoxContainer`)

```gdscript
func mostrar(combatente: Combatente) -> void
```

Mostra o placeholder do sprite (64×64), o nome, `vida / vida_maxima`, o escudo quando é
maior que 0 e o ataque quando é maior que 0. Com isso o mesmo painel serve ao Arthur (vida e
escudo) e ao inimigo (vida e ataque), sem parâmetro extra.

### `batalha/aviso_rodada.tscn` (raiz: `Label`)

```gdscript
func mostrar(resultado: ResultadoRodada) -> void
func esconder() -> void
```

Textos (FR-025):

| Tipo | Texto |
|---|---|
| `ACERTO` | "Acertou! 13 de dano." e, se houver, "+5 de escudo.", "Curou 2.", "Comprou 1 carta." (com o `cartas_compradas`) |
| `ERRO` | "Errou: a conta deu 7, o alvo era 9." |
| `INVALIDA` | "Conta inválida. O alvo era 9." |
| `PULO` | "Pulou a rodada." e, se `cartas_compradas` > 0, "Comprou 1 carta." ("Comprou 2 cartas." no plural) |
| em todos, se `inimigo_atacou` | segunda linha: "O inimigo tirou 3 de vida." (com o `dano_recebido`) ou, se `dano_recebido` for 0, "O escudo segurou o ataque." |

Como todo inimigo tem ataque de pelo menos 1 (FR-001), `dano_recebido` 0 depois de um ataque
só acontece quando o escudo segurou tudo. No `ACERTO`, o número de dano é o `dano_causado`,
que é o dano calculado e pode passar da vida que o inimigo ainda tinha (golpe final de 13 num
inimigo com 7 mostra "13 de dano").

### `batalha/sons_batalha.tscn` (raiz: `Node`)

```gdscript
func tocar_carta() -> void
func tocar_rodada(resultado: ResultadoRodada) -> void
```

Um `AudioStreamPlayer` por evento, sem áudio atribuído (placeholder). Só toca se houver
áudio. Eventos: carta escolhida, acerto, erro, pulo, dano recebido.

O que `tocar_rodada(resultado)` toca:

| `resultado` | Tocador |
|---|---|
| `ACERTO` | acerto |
| `ERRO` ou `INVALIDA` | erro |
| `PULO` | pulo |
| e, em qualquer tipo, `dano_recebido > 0` | dano recebido, junto com o de cima |
 Mais um tocador para a
música da luta, com `autoplay = true` e sem script: começa quando a cena entra na árvore e
para quando ela sai (o loop é configurado na importação do arquivo Ogg). Lista completa de
sons pedidos em `docs/assets-pendentes.md`.

### `batalha/tela_batalha.tscn` (raiz: `Control`)

Interface pública em [batalha.md](batalha.md). Por dentro, junta as cenas acima, os quatro
botões, o `Label` do alvo e um `Timer` de disparo único.

Comportamento:
- A cada `carta_escolhida(i)` da mão: chama `batalha.escolher_carta(i)` e
  `sons_batalha.tocar_carta()` (asset 15).
- A cada `mudou` da lógica: atualiza os dois painéis, o alvo, a mão e a expressão;
  Confirmar fica desabilitado se `pode_confirmar()` for falso (FR-011).
- A cada `rodada_resolvida`: mostra o aviso, toca o som, desabilita mão e botões e liga o
  `Timer` com `regras.tempo_resultado` (FR-025).
- Quando o `Timer` dispara: esconde o aviso, chama `avancar()` e reabilita as ações.
- Não mostra o valor da conta em montagem nem se ela é válida (FR-010).
- Repassa o `luta_terminou` da lógica.

### `luta_avulsa/fim_de_luta.tscn` (raiz: `Control`)

```gdscript
signal jogar_de_novo
func mostrar(resultado: ResultadoLuta) -> void
```

| | Vitória (FR-026) | Derrota (FR-027) |
|---|---|---|
| Título | "Vitória!" | "Derrota" |
| Linha 1 | "Vida do Arthur: 31" | "Vida do inimigo: 5" |
| Linha 2 | "Rodadas: 4" | "Rodadas: 9" |
| Botão | "Lutar de novo" | "Tentar de novo" |
| Som | tocador de vitória | tocador de derrota |

Os dois tocadores são `AudioStreamPlayer` sem áudio (placeholder); `mostrar()` toca o certo
só se ele tiver áudio, como em `sons_batalha`.

### `luta_avulsa/luta_avulsa.tscn` (raiz: `Control`, cena principal do projeto na 001)

```gdscript
@export var baralho: DadosBaralho
@export var inimigo: DadosInimigo
@export var regras: RegrasBatalha

## A tela da luta em andamento; null enquanto o fim de luta está na tela.
var tela: TelaBatalha
```

Os três campos são preenchidos no editor com os arquivos de `dados/`. Ao abrir, cria a
`TelaBatalha` e chama `iniciar()`. No `luta_terminou`, remove a tela da luta e mostra o
`fim_de_luta`. No `jogar_de_novo`, começa outra luta do zero, com semente nova (FR-026,
FR-027). Na 002, o mapa substitui esta cena.

Nos testes, os três campos podem ser trocados antes de pôr a cena na árvore (por exemplo,
regras com `tempo_resultado` de centésimos de segundo), e o cenário de vitória ou derrota é
montado por `tela.batalha` (ver [batalha.md](batalha.md)).

## Placeholders (princípio IV)

Tudo que é visual ou sonoro nestas cenas é placeholder do próprio Godot (`ColorRect`,
`Panel`, `Label`, fonte padrão, `AudioStreamPlayer` vazio) e está listado em
`docs/assets-pendentes.md`. Trocar um placeholder pelo asset final é mexer só na cena
(`.tscn`), no editor: atribuir o áudio ao tocador ou trocar o `ColorRect` por um nó de
textura. Nenhum script muda.
