class_name Combatente
extends RefCounted
## O Arthur ou o inimigo durante a luta: vida, escudo e ataque.

var nome: String
## De 0 até vida_maxima.
var vida: int
## Teto da cura.
var vida_maxima: int
## Absorve dano antes da vida.
var escudo: int = 0
## Dano que causa por rodada (0 no Arthur).
var ataque: int


func _init(nome_inicial: String, vida_inicial: int, vida_maxima_inicial: int, ataque_inicial: int) -> void:
	nome = nome_inicial
	vida = vida_inicial
	vida_maxima = vida_maxima_inicial
	ataque = ataque_inicial


## Gasta o escudo primeiro e depois a vida, que não fica negativa. Devolve a vida perdida.
func receber_dano(quantidade: int) -> int:
	var absorvido := mini(escudo, quantidade)
	escudo -= absorvido
	var vida_perdida := mini(vida, quantidade - absorvido)
	vida -= vida_perdida
	return vida_perdida


## Não passa de vida_maxima. Devolve quanto curou de fato.
func curar(quantidade: int) -> int:
	var curado := clampi(vida_maxima - vida, 0, quantidade)
	vida += curado
	return curado


func ganhar_escudo(quantidade: int) -> void:
	escudo += quantidade


func zerar_escudo() -> void:
	escudo = 0


func esta_vivo() -> bool:
	return vida > 0
