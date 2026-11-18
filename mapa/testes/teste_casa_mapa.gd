extends GutTest
## Uma casa do mapa: letra, cor e dica de cada tipo, os dois estados e o clique.

const CENA: PackedScene = preload("res://mapa/casa_mapa.tscn")

# tipo, letra, cor, dica (contracts/telas-run.md)
const TIPOS := [
	[Casa.Tipo.BATALHA, "B", Color(0.55, 0.3, 0.3), "Batalha"],
	[Casa.Tipo.ELITE, "E", Color(0.75, 0.2, 0.2), "Elite: inimigo mais forte, dá carta"],
	[Casa.Tipo.DESCANSO, "D", Color(0.3, 0.6, 0.35), "Descanso: cura parte da vida"],
	[Casa.Tipo.RECOMPENSA, "R", Color(0.75, 0.6, 0.25), "Recompensa: escolha uma carta"],
	[Casa.Tipo.CHEFE, "C", Color(0.5, 0.2, 0.55), "Chefe do ato"],
]


func _casa(tipo: Casa.Tipo, disponivel: bool) -> Button:
	var casa: Button = add_child_autofree(CENA.instantiate())
	casa.mostrar(tipo, disponivel)
	return casa


func test_cada_tipo_tem_letra_cor_e_dica(p = use_parameters(TIPOS)) -> void:
	var casa := _casa(p[0], true)
	assert_eq((casa.get_node("Letra") as Label).text, p[1])
	assert_eq((casa.get_node("Cor") as ColorRect).color, p[2])
	assert_eq(casa.tooltip_text, p[3])


func test_casa_mede_32_por_32() -> void:
	var casa := _casa(Casa.Tipo.BATALHA, true)
	assert_eq(casa.size, Vector2(32, 32))
	assert_eq((casa.get_node("Cor") as ColorRect).size, Vector2(32, 32))


func test_disponivel_tem_cor_cheia_e_moldura() -> void:
	var casa := _casa(Casa.Tipo.DESCANSO, true)
	assert_false(casa.disabled)
	assert_eq(casa.modulate, Color.WHITE)
	var moldura := casa.get_node("Moldura") as ReferenceRect
	assert_true(moldura.visible)
	assert_false(moldura.editor_only, "a moldura aparece fora do editor")
	assert_eq(moldura.border_width, 1.0)


func test_disponivel_emite_escolhida_ao_pressionar() -> void:
	var casa := _casa(Casa.Tipo.BATALHA, true)
	watch_signals(casa)
	casa.pressed.emit()
	assert_signal_emit_count(casa, "escolhida", 1)


func test_nao_disponivel_fica_desabilitada_e_escurecida() -> void:
	# Um Button desabilitado não emite pressed (BaseButton.disabled), então não emite escolhida.
	var casa := _casa(Casa.Tipo.ELITE, false)
	assert_true(casa.disabled)
	assert_eq(casa.modulate, Color(0.5, 0.5, 0.5))
	assert_false((casa.get_node("Moldura") as ReferenceRect).visible)


func test_mostrar_de_novo_troca_o_estado() -> void:
	var casa := _casa(Casa.Tipo.BATALHA, false)
	casa.mostrar(Casa.Tipo.CHEFE, true)
	assert_false(casa.disabled)
	assert_eq((casa.get_node("Letra") as Label).text, "C")
	casa.mostrar(Casa.Tipo.CHEFE, false)
	assert_true(casa.disabled)


func test_filhos_nao_pegam_o_mouse() -> void:
	# Com STOP (o padrão do ColorRect), o filho ficaria com o clique e a dica (research D9).
	var casa := _casa(Casa.Tipo.BATALHA, true)
	for no in ["Cor", "Moldura", "Letra"]:
		assert_eq((casa.get_node(no) as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE, no)
