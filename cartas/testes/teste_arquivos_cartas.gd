extends GutTest
## Os arquivos de dados/cartas/ batem com a tabela de cartas da spec, e o baralho da luta
## avulsa tem as 21 cartas da FR-002.

const PASTA_CARTAS := "res://dados/cartas/"
const ARQUIVO_BARALHO := "res://dados/baralhos/baralho_luta_avulsa.tres"

# arquivo, nome, tipo, valor, ataque, efeito, intensidade (tabela da spec)
const TABELA := [
	["numero_1", "", DadosCarta.Tipo.NUMERO, 1, 1, DadosCarta.Efeito.NENHUM, 0],
	["numero_2", "", DadosCarta.Tipo.NUMERO, 2, 2, DadosCarta.Efeito.NENHUM, 0],
	["numero_3", "", DadosCarta.Tipo.NUMERO, 3, 3, DadosCarta.Efeito.NENHUM, 0],
	["numero_4", "", DadosCarta.Tipo.NUMERO, 4, 4, DadosCarta.Efeito.NENHUM, 0],
	["numero_5", "", DadosCarta.Tipo.NUMERO, 5, 5, DadosCarta.Efeito.NENHUM, 0],
	["soma", "", DadosCarta.Tipo.SOMA, 0, 1, DadosCarta.Efeito.NENHUM, 0],
	["subtracao", "", DadosCarta.Tipo.SUBTRACAO, 0, 1, DadosCarta.Efeito.NENHUM, 0],
	["multiplicacao", "", DadosCarta.Tipo.MULTIPLICACAO, 0, 3, DadosCarta.Efeito.NENHUM, 0],
	["divisao", "", DadosCarta.Tipo.DIVISAO, 0, 3, DadosCarta.Efeito.NENHUM, 0],
	["dobro", "", DadosCarta.Tipo.DOBRO, 0, 2, DadosCarta.Efeito.NENHUM, 0],
	["metade", "", DadosCarta.Tipo.METADE, 0, 3, DadosCarta.Efeito.NENHUM, 0],
	["quadrado", "", DadosCarta.Tipo.QUADRADO, 0, 4, DadosCarta.Efeito.NENHUM, 0],
	["chama", "Chama", DadosCarta.Tipo.NUMERO, 5, 5, DadosCarta.Efeito.DANO_EXTRA, 3],
	["foco", "Foco", DadosCarta.Tipo.NUMERO, 4, 1, DadosCarta.Efeito.COMPRAR, 1],
	["guarda", "Guarda", DadosCarta.Tipo.NUMERO, 6, 2, DadosCarta.Efeito.ESCUDO, 5],
	["vital", "Vital", DadosCarta.Tipo.NUMERO, 7, 3, DadosCarta.Efeito.CURA, 2],
]


func _carregar_carta(arquivo: String) -> DadosCarta:
	return load(PASTA_CARTAS + arquivo + ".tres") as DadosCarta


func test_carta_bate_com_a_tabela_da_spec(p = use_parameters(TABELA)) -> void:
	var carta := _carregar_carta(p[0])
	assert_not_null(carta, "%s.tres não carrega como DadosCarta" % p[0])
	if carta == null:
		return
	assert_eq(carta.nome, p[1], "nome")
	assert_eq(carta.tipo, p[2], "tipo")
	assert_eq(carta.valor, p[3], "valor")
	assert_eq(carta.ataque, p[4], "ataque")
	assert_eq(carta.efeito, p[5], "efeito")
	assert_eq(carta.intensidade, p[6], "intensidade")


func test_pasta_tem_so_as_cartas_da_tabela() -> void:
	var esperados: Array[String] = []
	for linha in TABELA:
		esperados.append(linha[0] + ".tres")
	esperados.sort()
	var achados := Array(DirAccess.get_files_at(PASTA_CARTAS))
	achados.sort()
	assert_eq(achados, esperados)


func test_todo_arquivo_de_carta_segue_as_regras_de_validacao() -> void:
	for arquivo in DirAccess.get_files_at(PASTA_CARTAS):
		var carta := load(PASTA_CARTAS + arquivo) as DadosCarta
		assert_not_null(carta, "%s não é um DadosCarta" % arquivo)
		if carta == null:
			continue
		if carta.eh_numero():
			assert_between(carta.valor, 1, 10, "%s: valor de número" % arquivo)
		else:
			assert_eq(carta.valor, 0, "%s: operador com valor" % arquivo)
			assert_eq(carta.efeito, DadosCarta.Efeito.NENHUM, "%s: operador com efeito" % arquivo)
		assert_gte(carta.ataque, 0, "%s: ataque" % arquivo)
		if carta.efeito != DadosCarta.Efeito.NENHUM:
			assert_gte(carta.intensidade, 1, "%s: intensidade do efeito" % arquivo)


func test_baralho_da_luta_avulsa_tem_as_21_cartas_da_fr_002() -> void:
	var baralho: DadosBaralho = load(ARQUIVO_BARALHO)
	assert_eq(baralho.cartas.size(), 21)
	var quantidades := {}
	for carta in baralho.cartas:
		var arquivo := carta.resource_path.get_file().get_basename()
		quantidades[arquivo] = quantidades.get(arquivo, 0) + 1
	var esperadas := {}
	for linha in TABELA:
		esperadas[linha[0]] = 2 if linha[0].begins_with("numero_") else 1
	assert_eq_deep(quantidades, esperadas)


func test_cartas_repetidas_do_baralho_sao_o_mesmo_objeto() -> void:
	var baralho: DadosBaralho = load(ARQUIVO_BARALHO)
	var tres := baralho.cartas.filter(func(carta: DadosCarta) -> bool: return carta.resource_path.ends_with("numero_3.tres"))
	assert_eq(tres.size(), 2)
	assert_same(tres[0], tres[1])
