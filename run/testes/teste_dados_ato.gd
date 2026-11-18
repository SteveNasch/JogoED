extends GutTest
## DadosAto com um ato montado à mão com os números do ato 1 (data-model): o inimigo de cada
## casa, as regras da luta e uma frase de erros() para cada regra (FR-028).

const REGRAS: RegrasBatalha = preload("res://dados/regras_batalha.tres")

var ato: DadosAto


func _inimigo(nome: String, vida: int, ataque: int) -> DadosInimigo:
	var dados := DadosInimigo.new()
	dados.nome = nome
	dados.vida = vida
	dados.ataque = ataque
	return dados


func before_each() -> void:
	ato = DadosAto.new()
	ato.nome = "Calabouço"
	ato.alvo_minimo = 5
	ato.alvo_maximo = 12
	ato.comum = _inimigo("Inimigo do calabouço", 12, 3)
	ato.elite = _inimigo("Elite do calabouço", 18, 4)
	ato.chefe = _inimigo("Chefe do calabouço", 26, 5)
	ato.vida_extra_por_andar = 1
	ato.mapa = DadosMapa.new()


func test_batalha_ganha_vida_a_cada_andar() -> void:
	var inimigo := ato.inimigo(Casa.Tipo.BATALHA, 3)
	assert_eq(inimigo.nome, "Inimigo do calabouço")
	assert_eq(inimigo.vida, 14)
	assert_eq(inimigo.ataque, 3)
	assert_eq(ato.inimigo(Casa.Tipo.BATALHA, 1).vida, 12)


func test_elite_ganha_vida_a_cada_andar() -> void:
	var inimigo := ato.inimigo(Casa.Tipo.ELITE, 4)
	assert_eq(inimigo.nome, "Elite do calabouço")
	assert_eq(inimigo.vida, 21)
	assert_eq(inimigo.ataque, 4)


func test_chefe_nao_ganha_vida_pelo_andar() -> void:
	var inimigo := ato.inimigo(Casa.Tipo.CHEFE, 5)
	assert_eq(inimigo.nome, "Chefe do calabouço")
	assert_eq(inimigo.vida, 26)
	assert_eq(inimigo.ataque, 5)


func test_descanso_e_recompensa_nao_tem_inimigo() -> void:
	assert_null(ato.inimigo(Casa.Tipo.DESCANSO, 4))
	assert_null(ato.inimigo(Casa.Tipo.RECOMPENSA, 3))


func test_mudar_o_inimigo_devolvido_nao_muda_os_dados() -> void:
	for tipo in [Casa.Tipo.BATALHA, Casa.Tipo.ELITE, Casa.Tipo.CHEFE]:
		var inimigo := ato.inimigo(tipo, 1)
		inimigo.vida = 99
		inimigo.ataque = 99
	assert_eq(ato.comum.vida, 12)
	assert_eq(ato.comum.ataque, 3)
	assert_eq(ato.elite.vida, 18)
	assert_eq(ato.chefe.vida, 26)
	assert_eq(ato.chefe.ataque, 5)


func test_regras_da_luta_tem_a_faixa_do_ato_e_a_base_fica_intacta() -> void:
	var base := REGRAS.duplicate() as RegrasBatalha
	base.alvo_minimo = 1
	base.alvo_maximo = 2
	var regras := ato.regras_da_luta(base)
	assert_ne(regras, base)
	assert_eq(regras.alvo_minimo, 5)
	assert_eq(regras.alvo_maximo, 12)
	assert_eq(regras.vida_maxima_arthur, base.vida_maxima_arthur)
	assert_eq(regras.cartas_iniciais, base.cartas_iniciais)
	assert_eq(base.alvo_minimo, 1)
	assert_eq(base.alvo_maximo, 2)


func test_ato_valido_nao_tem_erros() -> void:
	assert_eq(ato.erros(), [] as Array[String])


func test_faixa_invertida() -> void:
	ato.alvo_minimo = 13
	assert_eq(ato.erros(), ["alvo_minimo (13) é maior que alvo_maximo (12)."] as Array[String])


func test_alvo_minimo_menor_que_1() -> void:
	ato.alvo_minimo = 0
	assert_eq(ato.erros(), ["alvo_minimo (0) é menor que 1."] as Array[String])


func test_inimigo_vazio(p = use_parameters(["comum", "elite", "chefe"])) -> void:
	ato.set(p, null)
	assert_eq(ato.erros(), ["%s está vazio." % p] as Array[String])


func test_vida_menor_que_1(p = use_parameters(["comum", "elite", "chefe"])) -> void:
	(ato.get(p) as DadosInimigo).vida = 0
	assert_eq(ato.erros(), ["%s: vida (0) é menor que 1." % p] as Array[String])


func test_ataque_menor_que_1(p = use_parameters(["comum", "elite", "chefe"])) -> void:
	(ato.get(p) as DadosInimigo).ataque = 0
	assert_eq(ato.erros(), ["%s: ataque (0) é menor que 1." % p] as Array[String])


func test_vida_extra_por_andar_negativa() -> void:
	ato.vida_extra_por_andar = -1
	assert_eq(ato.erros(), ["vida_extra_por_andar (-1) é negativo."] as Array[String])


func test_mapa_vazio() -> void:
	ato.mapa = null
	assert_eq(ato.erros(), ["mapa está vazio."] as Array[String])


func test_frases_do_mapa_sao_repassadas() -> void:
	ato.mapa.descansos = 0
	assert_eq(ato.erros(), ato.mapa.erros())
	assert_eq(ato.erros().size(), 1)
