extends VBoxContainer
## Sprite, nome, vida, escudo e ataque de um combatente (FR-023). O escudo e o ataque só
## aparecem quando são maiores que 0; assim o mesmo painel serve ao Arthur (vida e escudo) e
## ao inimigo (vida e ataque). O sprite é placeholder (assets 1 e 4); a cor de cada um é
## definida na tela da luta. mostrar() só pode ser chamado depois que o painel entrou na árvore.

@onready var _nome: Label = $Nome
@onready var _vida: Label = $Vida
@onready var _escudo: Label = $Escudo
@onready var _ataque: Label = $Ataque


func mostrar(combatente: Combatente) -> void:
	_nome.text = combatente.nome
	_vida.text = "Vida: %d / %d" % [combatente.vida, combatente.vida_maxima]
	_escudo.text = "Escudo: %d" % combatente.escudo
	_escudo.visible = combatente.escudo > 0
	_ataque.text = "Ataque: %d" % combatente.ataque
	_ataque.visible = combatente.ataque > 0
