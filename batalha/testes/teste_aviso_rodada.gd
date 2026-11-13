extends GutTest

const CENA_AVISO: PackedScene = preload("res://batalha/aviso_rodada.tscn")

var _aviso: Label


func before_each() -> void:
	_aviso = add_child_autofree(CENA_AVISO.instantiate())


func _resultado(tipo: ResultadoRodada.Tipo, alvo: int = 9) -> ResultadoRodada:
	var resultado := ResultadoRodada.new(tipo, alvo)
	resultado.inimigo_atacou = true
	resultado.dano_recebido = 3
	return resultado


func test_comeca_escondido() -> void:
	assert_false(_aviso.visible)


func test_acerto_mostra_o_dano_e_o_ataque_do_inimigo() -> void:
	var resultado := _resultado(ResultadoRodada.Tipo.ACERTO, 11)
	resultado.valor = 11
	resultado.dano_causado = 13
	_aviso.mostrar(resultado)
	assert_true(_aviso.visible)
	assert_eq(_aviso.text, "Acertou! 13 de dano.\nO inimigo tirou 3 de vida.")


func test_acerto_com_escudo_cura_e_compra() -> void:
	var resultado := _resultado(ResultadoRodada.Tipo.ACERTO)
	resultado.dano_causado = 9
	resultado.escudo_ganho = 5
	resultado.cura = 2
	resultado.cartas_compradas = 1
	resultado.dano_recebido = 0
	_aviso.mostrar(resultado)
	assert_eq(_aviso.text, "Acertou! 9 de dano. +5 de escudo. Curou 2. Comprou 1 carta.\nO escudo segurou o ataque.")


func test_acerto_final_nao_tem_a_linha_do_ataque() -> void:
	var resultado := ResultadoRodada.new(ResultadoRodada.Tipo.ACERTO, 11)
	resultado.dano_causado = 13
	resultado.luta_acabou = true
	_aviso.mostrar(resultado)
	assert_eq(_aviso.text, "Acertou! 13 de dano.")


func test_erro_mostra_o_valor_e_o_alvo() -> void:
	var resultado := _resultado(ResultadoRodada.Tipo.ERRO)
	resultado.valor = 7
	_aviso.mostrar(resultado)
	assert_eq(_aviso.text, "Errou: a conta deu 7, o alvo era 9.\nO inimigo tirou 3 de vida.")


func test_erro_com_valor_negativo() -> void:
	var resultado := _resultado(ResultadoRodada.Tipo.ERRO, 6)
	resultado.valor = -1
	_aviso.mostrar(resultado)
	assert_eq(_aviso.text, "Errou: a conta deu -1, o alvo era 6.\nO inimigo tirou 3 de vida.")


func test_conta_invalida_mostra_o_alvo() -> void:
	_aviso.mostrar(_resultado(ResultadoRodada.Tipo.INVALIDA))
	assert_eq(_aviso.text, "Conta inválida. O alvo era 9.\nO inimigo tirou 3 de vida.")


func test_pulo_com_uma_carta_comprada() -> void:
	var resultado := _resultado(ResultadoRodada.Tipo.PULO)
	resultado.cartas_compradas = 1
	_aviso.mostrar(resultado)
	assert_eq(_aviso.text, "Pulou a rodada. Comprou 1 carta.\nO inimigo tirou 3 de vida.")


func test_pulo_com_duas_cartas_usa_o_plural() -> void:
	var resultado := _resultado(ResultadoRodada.Tipo.PULO)
	resultado.cartas_compradas = 2
	_aviso.mostrar(resultado)
	assert_eq(_aviso.text, "Pulou a rodada. Comprou 2 cartas.\nO inimigo tirou 3 de vida.")


func test_pulo_sem_carta_comprada_nao_fala_em_compra() -> void:
	var resultado := _resultado(ResultadoRodada.Tipo.PULO)
	resultado.dano_recebido = 2
	resultado.luta_acabou = true
	_aviso.mostrar(resultado)
	assert_eq(_aviso.text, "Pulou a rodada.\nO inimigo tirou 2 de vida.")


func test_esconder() -> void:
	_aviso.mostrar(_resultado(ResultadoRodada.Tipo.INVALIDA))
	_aviso.esconder()
	assert_false(_aviso.visible)
