extends GutTest

const ARQUIVO_REGRAS := "res://dados/regras_batalha.tres"

var regras: RegrasBatalha


func before_each() -> void:
	regras = load(ARQUIVO_REGRAS)


func test_arquivo_tem_os_valores_padrao() -> void:
	assert_eq(regras.vida_maxima_arthur, 40)
	assert_eq(regras.cartas_iniciais, 5)
	assert_eq(regras.cartas_por_rodada, 1)
	assert_eq(regras.cartas_por_pulo, 1)
	assert_eq(regras.minimo_numeros, 3)
	assert_eq(regras.minimo_somas, 1)
	assert_eq(regras.minimo_subtracoes, 1)
	assert_eq(regras.alvo_minimo, 5)
	assert_eq(regras.alvo_maximo, 12)
	assert_eq(regras.max_numeros_no_alvo, 3)
	assert_eq(regras.limite_buscas_alvo, 10000)
	assert_almost_eq(regras.tempo_resultado, 1.5, 0.0001)


func test_faixa_do_alvo_e_valida() -> void:
	assert_gte(regras.alvo_minimo, 1)
	assert_lte(regras.alvo_minimo, regras.alvo_maximo)


func test_busca_aceita_pelo_menos_um_numero() -> void:
	assert_gte(regras.max_numeros_no_alvo, 1)


func test_demais_valores_nao_sao_negativos() -> void:
	assert_gte(regras.vida_maxima_arthur, 0)
	assert_gte(regras.cartas_iniciais, 0)
	assert_gte(regras.cartas_por_rodada, 0)
	assert_gte(regras.cartas_por_pulo, 0)
	assert_gte(regras.minimo_numeros, 0)
	assert_gte(regras.minimo_somas, 0)
	assert_gte(regras.minimo_subtracoes, 0)
	assert_gte(regras.limite_buscas_alvo, 0)
	assert_gte(regras.tempo_resultado, 0.0)
