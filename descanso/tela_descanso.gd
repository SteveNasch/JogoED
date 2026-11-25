extends Control
## Tela do descanso (FR-020): quanto a cura deu e a vida do Arthur depois dela. A cura já foi
## feita pela Run; a tela só mostra. mostrar() só pode ser chamado depois que a tela entrou na
## árvore.

signal continuou

@onready var _frase: Label = %Frase
@onready var _vida: Label = %Vida
@onready var _botao: Button = %Botao


func _ready() -> void:
	_botao.pressed.connect(continuou.emit)


func mostrar(cura: int, vida: int, vida_maxima: int) -> void:
	if cura > 0:
		_frase.text = "Arthur descansou e recuperou %d de vida." % cura
	else:
		_frase.text = "Arthur descansou, mas a vida já estava cheia."
	_vida.text = "Vida: %d/%d" % [vida, vida_maxima]
