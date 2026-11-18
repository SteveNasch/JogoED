extends GutTest
## Aviso de luta vencida (FR-019): textos e o botão Continuar.

const CENA: PackedScene = preload("res://run/vitoria_luta.tscn")

var _vitoria: Control


func before_each() -> void:
	_vitoria = add_child_autofree(CENA.instantiate())


func _texto(no: String) -> String:
	return _vitoria.get_node("%" + no).text


func test_mostra_a_vitoria_e_a_vida_do_arthur() -> void:
	_vitoria.mostrar(24, 40)
	assert_eq(_texto("Titulo"), "Vitória!")
	assert_eq(_texto("LinhaVida"), "Vida do Arthur: 24/40")
	assert_eq(_texto("Botao"), "Continuar")


func test_mostra_a_vida_com_1() -> void:
	_vitoria.mostrar(1, 40)
	assert_eq(_texto("LinhaVida"), "Vida do Arthur: 1/40")


func test_botao_emite_continuou_uma_vez() -> void:
	_vitoria.mostrar(24, 40)
	watch_signals(_vitoria)
	(_vitoria.get_node("%Botao") as Button).pressed.emit()
	assert_signal_emit_count(_vitoria, "continuou", 1)
