extends Control
## Tela da recompensa (FR-021): as cartas da oferta, para escolher uma ou nenhuma. A oferta já
## foi sorteada pela Run; a tela só mostra e avisa a escolha. mostrar() só pode ser chamado
## depois que a tela entrou na árvore.

signal carta_escolhida(carta: DadosCarta)
signal nenhuma_escolhida

@onready var _titulo: Label = %Titulo
@onready var _cartas: HBoxContainer = %Cartas
@onready var _botao: Button = %Botao

var _oferta: Array[DadosCarta] = []


func _ready() -> void:
	_cartas.carta_escolhida.connect(_ao_escolher)
	_botao.pressed.connect(nenhuma_escolhida.emit)


func mostrar(oferta: Array[DadosCarta]) -> void:
	_oferta = oferta.duplicate()
	_cartas.mostrar(_oferta)
	_cartas.visible = not _oferta.is_empty()
	if _oferta.is_empty():
		_titulo.text = "Não há cartas para escolher."
		_botao.text = "Continuar"
	else:
		_titulo.text = "Escolha uma carta para o baralho"
		_botao.text = "Não pegar nenhuma"


func _ao_escolher(indice: int) -> void:
	carta_escolhida.emit(_oferta[indice])
