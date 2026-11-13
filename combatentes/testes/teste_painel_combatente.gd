extends GutTest

const CENA_PAINEL: PackedScene = preload("res://combatentes/painel_combatente.tscn")


func _painel(combatente: Combatente) -> VBoxContainer:
	var painel: VBoxContainer = add_child_autofree(CENA_PAINEL.instantiate())
	painel.mostrar(combatente)
	return painel


func _label(painel: VBoxContainer, no: String) -> Label:
	return painel.get_node(no)


func test_arthur_sem_escudo_mostra_nome_e_vida() -> void:
	var painel := _painel(Combatente.new("Arthur", 31, 40, 0))
	assert_eq(_label(painel, "Nome").text, "Arthur")
	assert_eq(_label(painel, "Vida").text, "Vida: 31 / 40")
	assert_false(_label(painel, "Escudo").visible)
	assert_false(_label(painel, "Ataque").visible)


func test_arthur_com_escudo_mostra_o_escudo() -> void:
	var arthur := Combatente.new("Arthur", 40, 40, 0)
	arthur.ganhar_escudo(5)
	var painel := _painel(arthur)
	assert_true(_label(painel, "Escudo").visible)
	assert_eq(_label(painel, "Escudo").text, "Escudo: 5")
	assert_false(_label(painel, "Ataque").visible)


func test_escudo_some_quando_volta_a_zero() -> void:
	var arthur := Combatente.new("Arthur", 40, 40, 0)
	arthur.ganhar_escudo(5)
	var painel := _painel(arthur)
	arthur.zerar_escudo()
	painel.mostrar(arthur)
	assert_false(_label(painel, "Escudo").visible)


func test_inimigo_mostra_o_ataque() -> void:
	var painel := _painel(Combatente.new("Inimigo", 12, 12, 3))
	assert_eq(_label(painel, "Nome").text, "Inimigo")
	assert_eq(_label(painel, "Vida").text, "Vida: 12 / 12")
	assert_true(_label(painel, "Ataque").visible)
	assert_eq(_label(painel, "Ataque").text, "Ataque: 3")
	assert_false(_label(painel, "Escudo").visible)


func test_sprite_placeholder_tem_64_por_64() -> void:
	var painel := _painel(Combatente.new("Inimigo", 12, 12, 3))
	await wait_physics_frames(2)
	assert_eq((painel.get_node("Sprite") as ColorRect).size, Vector2(64, 64))
