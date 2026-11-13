extends GutTest

const CENA_FIM: PackedScene = preload("res://luta_avulsa/fim_de_luta.tscn")

var _fim: Control


func before_each() -> void:
	_fim = add_child_autofree(CENA_FIM.instantiate())


func _texto(no: String) -> String:
	return _fim.get_node("%" + no).text


func test_vitoria_mostra_a_vida_do_arthur_e_as_rodadas() -> void:
	_fim.mostrar(ResultadoLuta.new(true, 31, 0, 4))
	assert_eq(_texto("Titulo"), "Vitória!")
	assert_eq(_texto("LinhaVida"), "Vida do Arthur: 31")
	assert_eq(_texto("LinhaRodadas"), "Rodadas: 4")
	assert_eq(_texto("Botao"), "Lutar de novo")


func test_derrota_mostra_a_vida_do_inimigo_e_as_rodadas() -> void:
	_fim.mostrar(ResultadoLuta.new(false, 0, 5, 9))
	assert_eq(_texto("Titulo"), "Derrota")
	assert_eq(_texto("LinhaVida"), "Vida do inimigo: 5")
	assert_eq(_texto("LinhaRodadas"), "Rodadas: 9")
	assert_eq(_texto("Botao"), "Tentar de novo")


func test_botao_emite_jogar_de_novo() -> void:
	_fim.mostrar(ResultadoLuta.new(true, 31, 0, 4))
	watch_signals(_fim)
	(_fim.get_node("%Botao") as Button).pressed.emit()
	assert_signal_emit_count(_fim, "jogar_de_novo", 1)


func test_sem_audio_nada_toca_e_nada_da_erro() -> void:
	_fim.mostrar(ResultadoLuta.new(true, 31, 0, 4))
	_fim.mostrar(ResultadoLuta.new(false, 0, 5, 9))
	assert_false(_fim.get_node("SomVitoria").playing)
	assert_false(_fim.get_node("SomDerrota").playing)


func test_vitoria_toca_o_som_de_vitoria() -> void:
	var vitoria: AudioStreamPlayer = _fim.get_node("SomVitoria")
	var derrota: AudioStreamPlayer = _fim.get_node("SomDerrota")
	vitoria.stream = AudioStreamWAV.new()
	derrota.stream = AudioStreamWAV.new()
	_fim.mostrar(ResultadoLuta.new(true, 31, 0, 4))
	assert_true(vitoria.playing)
	assert_false(derrota.playing)


func test_derrota_toca_o_som_de_derrota() -> void:
	var vitoria: AudioStreamPlayer = _fim.get_node("SomVitoria")
	var derrota: AudioStreamPlayer = _fim.get_node("SomDerrota")
	vitoria.stream = AudioStreamWAV.new()
	derrota.stream = AudioStreamWAV.new()
	_fim.mostrar(ResultadoLuta.new(false, 0, 5, 9))
	assert_true(derrota.playing)
	assert_false(vitoria.playing)
