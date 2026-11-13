extends Button
## Uma carta na tela (FR-024). O símbolo fica no canto superior esquerdo para continuar
## visível com as cartas sobrepostas na mão. O fundo é placeholder (assets 8 a 10).
## mostrar() só pode ser chamado depois que a carta entrou na árvore.

signal clicada

@onready var _simbolo: Label = $Simbolo
@onready var _nome: Label = $Nome
@onready var _efeito: Label = $Efeito
@onready var _ataque: Label = $Ataque


func _ready() -> void:
	pressed.connect(clicada.emit)


func mostrar(dados: DadosCarta) -> void:
	_simbolo.text = dados.simbolo()
	_ataque.text = str(dados.ataque)
	_nome.text = dados.nome
	_efeito.text = dados.texto_efeito()
	tooltip_text = ""
	if dados.efeito != DadosCarta.Efeito.NENHUM:
		tooltip_text = "%s: %s. Só vale quando a conta acerta o alvo." % [dados.nome, dados.texto_efeito()]
