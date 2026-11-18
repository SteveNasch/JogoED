extends GutTest
## DadosDificuldade: uma frase de erros() para cada regra, com dados montados à mão (FR-028).

const REGRAS: RegrasBatalha = preload("res://dados/regras_batalha.tres")
const N1: DadosCarta = preload("res://dados/cartas/numero_1.tres")
const N6: DadosCarta = preload("res://dados/cartas/numero_6.tres")
const SOMA: DadosCarta = preload("res://dados/cartas/soma.tres")

var dados: DadosDificuldade


func _inimigo(vida: int, ataque: int) -> DadosInimigo:
	var inimigo := DadosInimigo.new()
	inimigo.vida = vida
	inimigo.ataque = ataque
	return inimigo


func _ato(nome: String) -> DadosAto:
	var ato := DadosAto.new()
	ato.nome = nome
	ato.alvo_minimo = 5
	ato.alvo_maximo = 12
	ato.comum = _inimigo(12, 3)
	ato.elite = _inimigo(18, 4)
	ato.chefe = _inimigo(26, 5)
	ato.vida_extra_por_andar = 1
	ato.mapa = DadosMapa.new()
	return ato


func before_each() -> void:
	dados = DadosDificuldade.new()
	dados.regras_base = REGRAS
	dados.baralho_inicial.assign([N1, N1, SOMA])
	dados.cartas_de_recompensa.assign([N6, SOMA])
	dados.cartas_por_recompensa = 3
	dados.cura_do_descanso = 30
	dados.atos.assign([_ato("Calabouço"), _ato("Salões")])


func _assert_erros(esperados: Array) -> void:
	var frases: Array[String] = []
	frases.assign(esperados)
	assert_eq(dados.erros(), frases)


func test_dados_validos_nao_tem_erros() -> void:
	_assert_erros([])


func test_regras_base_vazio() -> void:
	dados.regras_base = null
	_assert_erros(["regras_base está vazio."])


func test_atos_vazio() -> void:
	dados.atos.clear()
	_assert_erros(["atos está vazio."])


func test_atos_com_posicao_vazia() -> void:
	dados.atos[1] = null
	_assert_erros(["atos: a posição 1 está vazia."])


func test_baralho_inicial_sem_carta_de_numero() -> void:
	dados.baralho_inicial.assign([SOMA])
	_assert_erros(["baralho_inicial não tem nenhuma carta de número."])


func test_baralho_inicial_vazio_nao_tem_carta_de_numero() -> void:
	dados.baralho_inicial.clear()
	_assert_erros(["baralho_inicial não tem nenhuma carta de número."])


func test_baralho_inicial_com_posicao_vazia() -> void:
	dados.baralho_inicial[0] = null
	_assert_erros(["baralho_inicial: a posição 0 está vazia."])


func test_cartas_de_recompensa_com_posicao_vazia() -> void:
	dados.cartas_de_recompensa[1] = null
	_assert_erros(["cartas_de_recompensa: a posição 1 está vazia."])


func test_cartas_de_recompensa_vazio_nao_e_erro() -> void:
	# Spec, casos-limite: a recompensa avisa que não há cartas.
	dados.cartas_de_recompensa.clear()
	_assert_erros([])


func test_cartas_por_recompensa_menor_que_1() -> void:
	dados.cartas_por_recompensa = 0
	_assert_erros(["cartas_por_recompensa (0) é menor que 1."])


func test_cura_do_descanso_fora_de_0_a_100(p = use_parameters([-1, 101])) -> void:
	dados.cura_do_descanso = p
	_assert_erros(["cura_do_descanso (%d) precisa ficar entre 0 e 100." % p])


func test_cura_do_descanso_nos_limites_vale(p = use_parameters([0, 100])) -> void:
	dados.cura_do_descanso = p
	_assert_erros([])


func test_frases_do_ato_levam_o_numero_e_o_nome_dele() -> void:
	dados.atos[1].alvo_minimo = 13
	dados.atos[1].mapa.descansos = 0
	_assert_erros([
		"Ato 2 (Salões): alvo_minimo (13) é maior que alvo_maximo (12).",
		"Ato 2 (Salões): descansos (0) precisa ser pelo menos 1: o ato precisa de uma casa de descanso.",
	])
