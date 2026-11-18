extends GutTest
## DadosDificuldade: uma frase de erros() para cada regra, com dados montados à mão (FR-028),
## e o arquivo padrão dados/dificuldade.tres conferido (SC-004).

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


# --- Arquivo padrão (dados/dificuldade.tres) ---

const ARQUIVO := "res://dados/dificuldade.tres"


func _nomes_dos_arquivos(cartas: Array[DadosCarta]) -> Array[String]:
	var nomes: Array[String] = []
	for carta in cartas:
		nomes.append(carta.resource_path.get_file().get_basename())
	return nomes


func test_arquivo_padrao_nao_tem_erros() -> void:
	var padrao: DadosDificuldade = load(ARQUIVO)
	assert_eq(padrao.erros(), [] as Array[String])


func test_arquivo_padrao_tem_os_valores_do_data_model() -> void:
	var padrao: DadosDificuldade = load(ARQUIVO)
	assert_eq(padrao.regras_base, REGRAS)
	assert_eq(padrao.cartas_por_recompensa, 3)
	assert_eq(padrao.cura_do_descanso, 30)
	# nome, alvo mínimo e máximo, comum, elite e chefe (vida e ataque), vida extra por andar
	var tabela := [
		["Calabouço", 5, 12, ["Inimigo do calabouço", 12, 3], ["Elite do calabouço", 18, 4], ["Chefe do calabouço", 26, 5]],
		["Salões", 8, 18, ["Inimigo dos salões", 18, 4], ["Elite dos salões", 26, 5], ["Chefe dos salões", 36, 6]],
		["Torre", 12, 24, ["Inimigo da torre", 24, 5], ["Elite da torre", 34, 6], ["Chefe da torre", 46, 7]],
	]
	assert_eq(padrao.atos.size(), tabela.size())
	for i in mini(padrao.atos.size(), tabela.size()):
		var ato := padrao.atos[i]
		var linha: Array = tabela[i]
		assert_eq([ato.nome, ato.alvo_minimo, ato.alvo_maximo], linha.slice(0, 3), "ato %d" % (i + 1))
		assert_eq([ato.comum.nome, ato.comum.vida, ato.comum.ataque], linha[3], "comum do ato %d" % (i + 1))
		assert_eq([ato.elite.nome, ato.elite.vida, ato.elite.ataque], linha[4], "elite do ato %d" % (i + 1))
		assert_eq([ato.chefe.nome, ato.chefe.vida, ato.chefe.ataque], linha[5], "chefe do ato %d" % (i + 1))
		assert_eq(ato.vida_extra_por_andar, 1, "ato %d" % (i + 1))
		assert_eq(ato.mapa.casas_acima_do_primeiro(), DadosMapa.new().casas_acima_do_primeiro(), "mapa do ato %d" % (i + 1))
		assert_eq(ato.mapa.andares_comuns, DadosMapa.new().andares_comuns, "mapa do ato %d" % (i + 1))


func test_baralho_inicial_e_o_da_fr_002() -> void:
	var padrao: DadosDificuldade = load(ARQUIVO)
	var quantidades := {}
	for nome in _nomes_dos_arquivos(padrao.baralho_inicial):
		quantidades[nome] = quantidades.get(nome, 0) + 1
	assert_eq_deep(quantidades, {
		"numero_1": 2, "numero_2": 2, "numero_3": 2, "numero_4": 2, "numero_5": 2,
		"soma": 1, "subtracao": 1, "multiplicacao": 1,
	})
	assert_eq(padrao.baralho_inicial.size(), 13)


func test_cartas_de_recompensa_sao_14_diferentes() -> void:
	var padrao: DadosDificuldade = load(ARQUIVO)
	var nomes := _nomes_dos_arquivos(padrao.cartas_de_recompensa)
	assert_eq(nomes.size(), 14)
	var sem_repetidas: Array[String] = []
	for nome in nomes:
		if not nome in sem_repetidas:
			sem_repetidas.append(nome)
	assert_eq(sem_repetidas, nomes)
	nomes.sort()
	var esperadas: Array[String] = ["chama", "divisao", "dobro", "foco", "guarda", "metade", "multiplicacao",
		"numero_10", "numero_6", "numero_7", "numero_8", "numero_9", "quadrado", "vital"]
	assert_eq(nomes, esperadas)


## SC-004: a dificuldade cresce com a profundidade (data-model, "Conferência dos dados padrão").
func test_dificuldade_cresce_com_a_profundidade() -> void:
	var padrao: DadosDificuldade = load(ARQUIVO)
	for i in padrao.atos.size():
		var ato := padrao.atos[i]
		var ultimo_andar := ato.mapa.andares_comuns
		var onde := "ato %d" % (i + 1)
		for andar in range(1, ultimo_andar + 1):
			var comum := ato.inimigo(Casa.Tipo.BATALHA, andar)
			var elite := ato.inimigo(Casa.Tipo.ELITE, andar)
			assert_gt(elite.vida, comum.vida, "%s, andar %d: vida da elite" % [onde, andar])
			assert_gt(elite.ataque, comum.ataque, "%s, andar %d: ataque da elite" % [onde, andar])
			if andar < ultimo_andar:
				for tipo in [Casa.Tipo.BATALHA, Casa.Tipo.ELITE]:
					var agora := ato.inimigo(tipo, andar)
					var depois := ato.inimigo(tipo, andar + 1)
					assert_gte(depois.vida, agora.vida, "%s, andar %d: vida diminuiu" % [onde, andar])
					assert_gte(depois.ataque, agora.ataque, "%s, andar %d: ataque diminuiu" % [onde, andar])
		var chefe := ato.inimigo(Casa.Tipo.CHEFE, ultimo_andar + 1)
		var elite_mais_funda := ato.inimigo(Casa.Tipo.ELITE, ultimo_andar)
		assert_gt(chefe.vida, elite_mais_funda.vida, "%s: vida do chefe" % onde)
		assert_gt(chefe.ataque, elite_mais_funda.ataque, "%s: ataque do chefe" % onde)
		if i + 1 < padrao.atos.size():
			_conferir_ato_seguinte(ato, padrao.atos[i + 1], onde)


func _conferir_ato_seguinte(ato: DadosAto, seguinte: DadosAto, onde: String) -> void:
	assert_gt(seguinte.alvo_minimo, ato.alvo_minimo, "%s: alvo mínimo do ato seguinte" % onde)
	assert_gt(seguinte.alvo_maximo, ato.alvo_maximo, "%s: alvo máximo do ato seguinte" % onde)
	for campo in ["comum", "elite", "chefe"]:
		var agora: DadosInimigo = ato.get(campo)
		var depois: DadosInimigo = seguinte.get(campo)
		assert_gt(depois.vida, agora.vida, "%s: vida do %s no ato seguinte" % [onde, campo])
		assert_gt(depois.ataque, agora.ataque, "%s: ataque do %s no ato seguinte" % [onde, campo])
	for tipo in [Casa.Tipo.BATALHA, Casa.Tipo.ELITE]:
		var mais_fundo := ato.inimigo(tipo, ato.mapa.andares_comuns)
		var primeiro := seguinte.inimigo(tipo, 1)
		assert_gte(primeiro.vida, mais_fundo.vida, "%s: andar 1 do ato seguinte mais fraco (tipo %d)" % [onde, tipo])
