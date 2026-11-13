class_name ResultadoLuta
extends RefCounted
## O que a luta devolve a quem a chamou (na 001, a luta_avulsa; na 002, o mapa).

## true = o inimigo chegou a 0.
var venceu: bool
## Vida restante do Arthur (0 na derrota); é a vida a levar para a próxima luta.
var vida_arthur: int
## Vida restante do inimigo (0 na vitória).
var vida_inimigo: int
## Quantas rodadas a luta durou.
var rodadas: int


func _init(venceu_inicial: bool, vida_arthur_inicial: int, vida_inimigo_inicial: int, rodadas_inicial: int) -> void:
	venceu = venceu_inicial
	vida_arthur = vida_arthur_inicial
	vida_inimigo = vida_inimigo_inicial
	rodadas = rodadas_inicial
