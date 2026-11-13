extends GutTest

const ARQUIVO_BARALHO := "res://dados/baralhos/baralho_luta_avulsa.tres"
# Faixa que o baralho da 001 não alcança: o maior valor possível é 7 x2 ^2 × 6 + 5 = 1.181.
const FAIXA_IMPOSSIVEL_MINIMO := 5000
const FAIXA_IMPOSSIVEL_MAXIMO := 6000

var baralho: Array[DadosCarta]


func before_all() -> void:
	baralho = load(ARQUIVO_BARALHO).cartas


func _carta(arquivo: String) -> DadosCarta:
	return load("res://dados/cartas/%s.tres" % arquivo)


## Mão sorteada sem repetição de posição a partir do baralho da 001.
func _mao_sorteada(rng: RandomNumberGenerator, tamanho: int) -> Array[DadosCarta]:
	var restantes := baralho.duplicate()
	var mao: Array[DadosCarta] = []
	for i in tamanho:
		mao.append(restantes.pop_at(rng.randi_range(0, restantes.size() - 1)))
	return mao


## Oráculo: todas as ordens de todos os subconjuntos da mão, avaliadas pelo motor.
func _valores_forca_bruta(mao: Array[DadosCarta]) -> Dictionary:
	var valores := {}
	_permutar(mao, [] as Array[DadosCarta], valores)
	return valores


func _permutar(restantes: Array[DadosCarta], conta: Array[DadosCarta], valores: Dictionary) -> void:
	if not conta.is_empty():
		var resultado := MotorContas.avaliar(conta)
		if resultado.valida:
			valores[resultado.valor] = true
	for i in restantes.size():
		var proximas := restantes.duplicate()
		var carta: DadosCarta = proximas.pop_at(i)
		conta.append(carta)
		_permutar(proximas, conta, valores)
		conta.pop_back()


func _quantos_numeros(conta: Array) -> int:
	return conta.filter(func(carta: DadosCarta) -> bool: return carta.eh_numero()).size()


## A conta usa só cartas da mão, cada uma no máximo quantas vezes aparece nela (cartas iguais
## são o mesmo objeto), e o motor confirma o valor.
func _conferir_conta_de_exemplo(mao: Array[DadosCarta], valor: int, conta: Array, descricao: String) -> void:
	for carta in conta:
		assert_lte(conta.count(carta), mao.count(carta), "%s: carta usada demais na conta de %d" % [descricao, valor])
	var resultado := MotorContas.avaliar(conta as Array[DadosCarta])
	assert_true(resultado.valida, "%s: conta de %d inválida" % [descricao, valor])
	assert_eq(resultado.valor, valor, "%s: conta de exemplo" % descricao)


func test_acha_os_mesmos_valores_que_a_forca_bruta() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var busca := BuscaAlvo.new(FAIXA_IMPOSSIVEL_MINIMO, FAIXA_IMPOSSIVEL_MAXIMO, 99, 1000000000)
	for i in 50:
		var mao := _mao_sorteada(rng, rng.randi_range(3, 6))
		var achados := busca.alcancaveis(mao)
		var esperados := _valores_forca_bruta(mao).keys()
		var obtidos := achados.keys()
		esperados.sort()
		obtidos.sort()
		var descricao := "mão %d: %s" % [i, ", ".join(mao.map(func(c: DadosCarta) -> String: return c.simbolo()))]
		assert_eq(obtidos, esperados, descricao)
		for valor in achados:
			_conferir_conta_de_exemplo(mao, valor, achados[valor], descricao)


func test_contas_de_exemplo_respeitam_o_maximo_de_numeros() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for maximo in [1, 2, 3]:
		var busca := BuscaAlvo.new(5, 12, maximo, 10000)
		for i in 20:
			var mao := _mao_sorteada(rng, rng.randi_range(5, 10))
			var achados := busca.alcancaveis(mao)
			for valor in achados:
				assert_lte(_quantos_numeros(achados[valor]), maximo, "máximo %d, valor %d" % [maximo, valor])
				_conferir_conta_de_exemplo(mao, valor, achados[valor], "máximo %d" % maximo)


func test_baralho_inteiro_com_faixa_impossivel_respeita_o_teto() -> void:
	var busca := BuscaAlvo.new(FAIXA_IMPOSSIVEL_MINIMO, FAIXA_IMPOSSIVEL_MAXIMO, 3, 10000)
	var achados := busca.alcancaveis(baralho)
	assert_lte(busca.avaliacoes, 10000)
	for valor in achados:
		assert_false(valor >= FAIXA_IMPOSSIVEL_MINIMO and valor <= FAIXA_IMPOSSIVEL_MAXIMO, "valor %d na faixa impossível" % valor)


func test_para_cedo_quando_acha_a_faixa_inteira() -> void:
	var mao: Array[DadosCarta] = [
		_carta("numero_1"), _carta("numero_2"), _carta("numero_3"), _carta("numero_4"),
		_carta("numero_5"), _carta("soma"), _carta("subtracao"), _carta("multiplicacao"),
	]
	var com_faixa_possivel := BuscaAlvo.new(5, 12, 3, 1000000)
	var achados := com_faixa_possivel.alcancaveis(mao)
	for valor in range(5, 13):
		assert_true(achados.has(valor), "valor %d" % valor)
	var sem_parada := BuscaAlvo.new(FAIXA_IMPOSSIVEL_MINIMO, FAIXA_IMPOSSIVEL_MAXIMO, 3, 1000000)
	sem_parada.alcancaveis(mao)
	assert_lt(com_faixa_possivel.avaliacoes, sem_parada.avaliacoes)


func test_cartas_de_mesma_chave_entram_como_cartas_diferentes_na_conta() -> void:
	var quatro := _carta("numero_4")
	var foco := _carta("foco")
	var mao: Array[DadosCarta] = [quatro, foco, _carta("soma")]
	var achados := BuscaAlvo.new(8, 8, 3, 10000).alcancaveis(mao)
	assert_true(achados.has(8))
	var conta: Array = achados[8]
	assert_true(conta.has(quatro) and conta.has(foco), "4 + Foco usa as duas cartas")


func test_valor_de_uma_carta_so_vale() -> void:
	var mao: Array[DadosCarta] = [_carta("numero_5"), _carta("soma"), _carta("subtracao")]
	var achados := BuscaAlvo.new(5, 5, 3, 10000).alcancaveis(mao)
	assert_true(achados.has(5))
	assert_eq(achados[5].size(), 1)


func test_mao_sem_numeros_nao_acha_nada() -> void:
	var mao: Array[DadosCarta] = [_carta("soma"), _carta("subtracao"), _carta("dobro")]
	var busca := BuscaAlvo.new(5, 12, 3, 10000)
	assert_eq(busca.alcancaveis(mao), {})
	assert_eq(busca.avaliacoes, 0)


# --- sortear e escolher_alvo ---


func _rng(semente: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return rng


## Os alvos que saem de escolher_alvo em 200 sementes, sem repetição.
func _alvos_em_varias_sementes(busca: BuscaAlvo, valores: Dictionary) -> Array:
	var alvos := []
	for semente in 200:
		var alvo := busca.escolher_alvo(valores, _rng(semente))
		if not alvo in alvos:
			alvos.append(alvo)
	alvos.sort()
	return alvos


func test_alvo_sempre_tem_conta_de_exemplo_e_fica_na_faixa_quando_possivel() -> void:
	var rng := _rng(31)
	var busca := BuscaAlvo.new(5, 12, 3, 10000)
	for i in 100:
		var mao := _mao_sorteada(rng, rng.randi_range(3, 8))
		var achados := busca.alcancaveis(mao)
		var alvo := busca.sortear(mao, rng)
		assert_true(achados.has(alvo), "mão %d: alvo %d sem conta de exemplo" % [i, alvo])
		var alguma_na_faixa := achados.keys().any(func(valor: int) -> bool: return valor >= 5 and valor <= 12)
		if alguma_na_faixa:
			assert_between(alvo, 5, 12, "mão %d" % i)


func test_sorteia_entre_todos_os_valores_da_faixa() -> void:
	var busca := BuscaAlvo.new(5, 12, 3, 10000)
	var valores := {2: [], 5: [], 9: [], 12: [], 13: []}
	assert_eq(_alvos_em_varias_sementes(busca, valores), [5, 9, 12])


func test_mao_que_nao_alcanca_a_faixa_fica_com_o_valor_mais_perto() -> void:
	var mao: Array[DadosCarta] = [_carta("numero_1"), _carta("numero_1"), _carta("numero_2"), _carta("soma"), _carta("subtracao")]
	var busca := BuscaAlvo.new(5, 12, 3, 10000)
	assert_eq(busca.sortear(mao, _rng(1)), 3, "com um só +, o maior valor possível é 2 + 1")


func test_empate_abaixo_e_acima_da_faixa_sorteia_entre_os_dois() -> void:
	var busca := BuscaAlvo.new(5, 12, 3, 10000)
	var valores := {3: [], 14: [], 1: [], 20: []}
	assert_eq(_alvos_em_varias_sementes(busca, valores), [3, 14])


func test_valores_zero_e_negativos_nunca_viram_alvo() -> void:
	var busca := BuscaAlvo.new(5, 12, 3, 10000)
	assert_eq(_alvos_em_varias_sementes(busca, {-4: [], 0: [], 2: []}), [2])


func test_sem_valor_positivo_o_alvo_e_o_minimo_da_faixa() -> void:
	var busca := BuscaAlvo.new(5, 12, 3, 10000)
	var mao: Array[DadosCarta] = [_carta("soma"), _carta("subtracao")]
	assert_eq(busca.sortear(mao, _rng(1)), 5)
	assert_eq(busca.escolher_alvo({0: [], -3: []}, _rng(1)), 5)


func test_mesma_semente_da_o_mesmo_alvo() -> void:
	var busca := BuscaAlvo.new(5, 12, 3, 10000)
	var mao := _mao_sorteada(_rng(8), 8)
	for semente in 20:
		assert_eq(busca.sortear(mao, _rng(semente)), busca.sortear(mao, _rng(semente)), "semente %d" % semente)
