class_name DadosInimigo
extends Resource
## Um tipo de inimigo. Os arquivos ficam em dados/inimigos/.
## Convenção dos arquivos (conferida nos testes): vida >= 1 e ataque >= 1 (FR-001).

## Nome provisório mostrado na tela.
@export var nome: String = ""
## Vida máxima e inicial.
@export var vida: int = 1
## Dano por rodada.
@export var ataque: int = 1
