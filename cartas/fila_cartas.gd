extends HBoxContainer
## Uma fileira de cartas: serve de mão (clicável) e de expressão (só leitura). Quando as
## cartas não cabem na largura máxima, a separação diminui até elas se sobreporem (research
## D16), deixando à vista o canto com o símbolo de cada uma.

signal carta_escolhida(indice: int)

const CENA_CARTA: PackedScene = preload("res://cartas/carta.tscn")
## Largura da faixa da mão na tela (contracts/tela-batalha.md).
const LARGURA_MAXIMA := 600
const SEPARACAO_PADRAO := 4
const LARGURA_CARTA := 48

@export var clicavel: bool = true


## Recria as cartas na ordem do array.
func mostrar(cartas: Array[DadosCarta]) -> void:
	for carta in get_children():
		remove_child(carta)
		carta.queue_free()
	add_theme_constant_override("separation", _separacao(cartas.size()))
	for i in cartas.size():
		var carta: Button = CENA_CARTA.instantiate()
		add_child(carta)
		carta.mostrar(cartas[i])
		carta.clicada.connect(_ao_clicar.bind(i))


func _separacao(quantidade: int) -> int:
	if quantidade < 2:
		return SEPARACAO_PADRAO
	var sobra := LARGURA_MAXIMA - quantidade * LARGURA_CARTA
	return mini(SEPARACAO_PADRAO, floori(sobra / float(quantidade - 1)))


func _ao_clicar(indice: int) -> void:
	if clicavel:
		carta_escolhida.emit(indice)
