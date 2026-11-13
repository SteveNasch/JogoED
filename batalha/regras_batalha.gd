class_name RegrasBatalha
extends Resource
## Todos os números da luta que não são de carta nem de inimigo (FR-028).
## Os valores ficam em dados/regras_batalha.tres, não aqui.
## Convenção do arquivo (conferida nos testes): alvo_minimo >= 1, alvo_minimo <= alvo_maximo,
## max_numeros_no_alvo >= 1 e os demais >= 0.

## FR-001
@export var vida_maxima_arthur: int
## FR-003: cartas na mão no início da luta.
@export var cartas_iniciais: int
## FR-003: cartas compradas a cada rodada nova.
@export var cartas_por_rodada: int
## FR-020
@export var cartas_por_pulo: int
## FR-006: mínimos da mão no início de cada rodada.
@export var minimo_numeros: int
@export var minimo_somas: int
@export var minimo_subtracoes: int
## FR-007: faixa do alvo.
@export var alvo_minimo: int
@export var alvo_maximo: int
## FR-007: o alvo nunca exige mais que esta quantidade de cartas de número (research D10).
@export var max_numeros_no_alvo: int
## Teto de contas avaliadas por busca do alvo (research D10).
@export var limite_buscas_alvo: int
## FR-025: segundos que o resultado da rodada fica na tela.
@export var tempo_resultado: float
