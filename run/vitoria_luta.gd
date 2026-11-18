extends Control
## Aviso de luta vencida na run (FR-019), antes de voltar ao mapa. mostrar() só pode ser chamado
## depois que a tela entrou na árvore.

signal continuou

@onready var _linha_vida: Label = %LinhaVida
@onready var _botao: Button = %Botao


func _ready() -> void:
	_botao.pressed.connect(continuou.emit)


func mostrar(vida: int, vida_maxima: int) -> void:
	_linha_vida.text = "Vida do Arthur: %d/%d" % [vida, vida_maxima]
