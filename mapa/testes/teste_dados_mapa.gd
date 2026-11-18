extends GutTest
## DadosMapa: os padrões e uma frase de erros() para cada regra do data-model (FR-028).

# mudanças nos padrões, frases esperadas (todas, na ordem)
const CASOS := [
	# regra 1, "mapa sem andares"
	[{"andares_comuns": 1}, ["andares_comuns (1) é menor que 2."]],
	# regra 2
	[{"casas_minimas_por_andar": 0}, ["casas_minimas_por_andar (0) é menor que 1."]],
	# regra 3 (a 4 também falha, porque o andar 1 fica sem tamanho possível)
	[{"casas_minimas_por_andar": 4}, [
		"casas_minimas_por_andar (4) é maior que casas_maximas_por_andar (3).",
		"batalhas_primeiro_andar (3) precisa ficar entre 4 e 3.",
	]],
	# regra 4, abaixo de 2 e acima do máximo
	[{"batalhas_primeiro_andar": 1}, ["batalhas_primeiro_andar (1) precisa ficar entre 2 e 3."]],
	[{"batalhas_primeiro_andar": 4}, ["batalhas_primeiro_andar (4) precisa ficar entre 2 e 3."]],
	# regra 5
	[{"batalhas": -1}, ["batalhas (-1) é negativo."]],
	[{"elites": -1}, ["elites (-1) é negativo."]],
	[{"descansos": -1}, ["descansos (-1) é negativo."]],
	[{"recompensas": -1}, ["recompensas (-1) é negativo."]],
	# regra 6, "ato sem casa de descanso"
	[{"descansos": 0}, ["descansos (0) precisa ser pelo menos 1: o ato precisa de uma casa de descanso."]],
	# regra 7, "mais casas de um tipo do que o ato comporta" e menos do que o mínimo
	[{"descansos": 10}, ["batalhas + elites + descansos + recompensas (16) precisa ficar entre 6 e 9 para caber nos andares 2 a 4."]],
	[{"batalhas": 0, "recompensas": 0}, ["batalhas + elites + descansos + recompensas (3) precisa ficar entre 6 e 9 para caber nos andares 2 a 4."]],
	# regra 8, "elite sem andar acima do 2" (a 7 também falha: 8 casas não cabem num andar)
	[{"andares_comuns": 2, "elites": 1}, [
		"batalhas + elites + descansos + recompensas (8) precisa ficar entre 2 e 3 para caber nos andares 2 a 2.",
		"elites (1) precisa de um andar acima do 2, mas andares_comuns é 2.",
	]],
	# regra 9: 5 casas em 2 andares; com o andar 2 cheio (3), o andar 3 tem 2 vagas, uma delas
	# do descanso reservado, e sobra 1 vaga para 2 elites. As regras 1 a 8 passam.
	[{"andares_comuns": 3, "batalhas_primeiro_andar": 2, "batalhas": 2, "elites": 2, "descansos": 1, "recompensas": 0},
		["elites (2) é maior que as vagas do andar 3 em diante com o andar 2 cheio (1)."]],
	# regras 10 e 11, "mapa que não cabe na tela" (na 11, as batalhas fazem a regra 7 passar)
	[{"casas_maximas_por_andar": 8}, ["casas_maximas_por_andar (8) é maior que 7, o máximo que cabe na tela."]],
	[{"andares_comuns": 9, "batalhas": 16}, ["andares_comuns (9) é maior que 8, o máximo que cabe na tela."]],
]


func _mapa_com(mudancas: Dictionary) -> DadosMapa:
	var mapa := DadosMapa.new()
	for campo: String in mudancas:
		mapa.set(campo, mudancas[campo])
	return mapa


func test_padroes_nao_tem_erros() -> void:
	var mapa := DadosMapa.new()
	assert_eq(mapa.erros(), [] as Array[String])
	assert_eq(mapa.casas_acima_do_primeiro(), 8)


func test_cada_regra_quebrada_da_a_frase_dela(p = use_parameters(CASOS)) -> void:
	var frases: Array[String] = []
	frases.assign(p[1])
	assert_eq(_mapa_com(p[0]).erros(), frases, str(p[0]))


func test_elites_que_cabem_com_o_andar_2_cheio_nao_sao_erro() -> void:
	# O caso da regra 9 com uma elite a menos: sobra 1 vaga para 1 elite.
	var mapa := _mapa_com({"andares_comuns": 3, "batalhas_primeiro_andar": 2, "batalhas": 2, "elites": 1, "descansos": 1, "recompensas": 0})
	assert_eq(mapa.erros(), [] as Array[String])


func test_limites_da_tela_sao_aceitos() -> void:
	var mapa := _mapa_com({"casas_maximas_por_andar": DadosMapa.MAXIMO_CASAS_POR_ANDAR})
	assert_eq(mapa.erros(), [] as Array[String])
	# 14 casas, o mínimo para 7 andares de 2 casas.
	mapa = _mapa_com({"andares_comuns": DadosMapa.MAXIMO_ANDARES_COMUNS, "batalhas": 9})
	assert_eq(mapa.erros(), [] as Array[String])


func test_regra_1_quebrada_nao_gera_as_frases_de_7_a_9() -> void:
	# Com 1 andar comum, a 7 (8 casas em 0 andares) e a 8 (elite) também falhariam.
	var mapa := _mapa_com({"andares_comuns": 1})
	assert_eq(mapa.erros().size(), 1)
	assert_string_starts_with(mapa.erros()[0], "andares_comuns (1)")


func test_dois_andares_comuns_sem_elite_valem() -> void:
	# Sem andar 3 não há vaga de elite, e sem elite isso não é erro (research D4).
	var mapa := _mapa_com({"andares_comuns": 2, "elites": 0, "batalhas": 1, "descansos": 1, "recompensas": 1})
	assert_eq(mapa.erros(), [] as Array[String])
