extends GutTest
## Tela do descanso (FR-020): frases da cura e da vida, placeholder da imagem e o botão.

const CENA: PackedScene = preload("res://descanso/tela_descanso.tscn")

var _descanso: Control


func before_each() -> void:
	_descanso = add_child_autofree(CENA.instantiate())


func _texto(no: String) -> String:
	return _descanso.get_node("%" + no).text


func test_cura_12_com_32_de_40() -> void:
	_descanso.mostrar(12, 32, 40)
	assert_eq(_texto("Titulo"), "Descanso")
	assert_eq(_texto("Frase"), "Arthur descansou e recuperou 12 de vida.")
	assert_eq(_texto("Vida"), "Vida: 32/40")
	assert_eq(_texto("Botao"), "Continuar")


func test_cura_5_com_40_de_40() -> void:
	_descanso.mostrar(5, 40, 40)
	assert_eq(_texto("Frase"), "Arthur descansou e recuperou 5 de vida.")
	assert_eq(_texto("Vida"), "Vida: 40/40")


func test_cura_0_com_a_vida_cheia() -> void:
	_descanso.mostrar(0, 40, 40)
	assert_eq(_texto("Frase"), "Arthur descansou, mas a vida já estava cheia.")
	assert_eq(_texto("Vida"), "Vida: 40/40")


func test_placeholder_da_imagem_e_o_do_asset_34() -> void:
	var imagem := _descanso.get_node("%Imagem") as ColorRect
	assert_eq(imagem.size, Vector2(96, 96))
	assert_eq(imagem.color, Color(0.85, 0.5, 0.2))


func test_botao_emite_continuou_uma_vez() -> void:
	_descanso.mostrar(12, 32, 40)
	watch_signals(_descanso)
	(_descanso.get_node("%Botao") as Button).pressed.emit()
	assert_signal_emit_count(_descanso, "continuou", 1)
