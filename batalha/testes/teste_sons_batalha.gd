extends GutTest

const CENA_SONS: PackedScene = preload("res://batalha/sons_batalha.tscn")
const TOCADORES_DE_EVENTO: Array[String] = ["Carta", "Acerto", "Erro", "Pulo", "DanoRecebido"]

var _sons: Node


func before_each() -> void:
	_sons = add_child_autofree(CENA_SONS.instantiate())


func _tocador(nome: String) -> AudioStreamPlayer:
	return _sons.get_node(nome)


## Áudio em memória em todos os tocadores de evento, para que "parado" signifique algo.
func _dar_audio_a_todos() -> void:
	for nome in TOCADORES_DE_EVENTO:
		_tocador(nome).stream = AudioStreamWAV.new()


func _tocando() -> Array[String]:
	var nomes: Array[String] = []
	for nome in TOCADORES_DE_EVENTO:
		if _tocador(nome).playing:
			nomes.append(nome)
	return nomes


func _rodada(tipo: ResultadoRodada.Tipo, dano_recebido: int) -> ResultadoRodada:
	var resultado := ResultadoRodada.new(tipo, 9)
	resultado.inimigo_atacou = true
	resultado.dano_recebido = dano_recebido
	return resultado


func test_sem_audio_nada_toca_e_nada_da_erro() -> void:
	_sons.tocar_carta()
	_sons.tocar_rodada(_rodada(ResultadoRodada.Tipo.ACERTO, 3))
	_sons.tocar_rodada(_rodada(ResultadoRodada.Tipo.ERRO, 3))
	_sons.tocar_rodada(_rodada(ResultadoRodada.Tipo.PULO, 3))
	assert_eq(_tocando(), [] as Array[String])


func test_carta_escolhida_toca_o_som_da_carta() -> void:
	_dar_audio_a_todos()
	_sons.tocar_carta()
	assert_eq(_tocando(), ["Carta"] as Array[String])


func test_acerto_com_dano_recebido_toca_acerto_e_dano() -> void:
	_dar_audio_a_todos()
	_sons.tocar_rodada(_rodada(ResultadoRodada.Tipo.ACERTO, 3))
	assert_eq(_tocando(), ["Acerto", "DanoRecebido"] as Array[String])


func test_acerto_sem_dano_recebido_toca_so_acerto() -> void:
	_dar_audio_a_todos()
	_sons.tocar_rodada(_rodada(ResultadoRodada.Tipo.ACERTO, 0))
	assert_eq(_tocando(), ["Acerto"] as Array[String])


func test_erro_toca_o_som_de_erro() -> void:
	_dar_audio_a_todos()
	_sons.tocar_rodada(_rodada(ResultadoRodada.Tipo.ERRO, 0))
	assert_eq(_tocando(), ["Erro"] as Array[String])


func test_conta_invalida_toca_o_som_de_erro() -> void:
	_dar_audio_a_todos()
	_sons.tocar_rodada(_rodada(ResultadoRodada.Tipo.INVALIDA, 3))
	assert_eq(_tocando(), ["Erro", "DanoRecebido"] as Array[String])


func test_pulo_toca_o_som_de_pulo() -> void:
	_dar_audio_a_todos()
	_sons.tocar_rodada(_rodada(ResultadoRodada.Tipo.PULO, 0))
	assert_eq(_tocando(), ["Pulo"] as Array[String])


func test_tocador_de_musica_existe_com_autoplay() -> void:
	var musica := _tocador("Musica")
	assert_not_null(musica)
	assert_true(musica.autoplay)
