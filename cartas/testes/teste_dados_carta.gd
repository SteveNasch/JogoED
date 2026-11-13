extends GutTest

const OPERADORES := [
	[DadosCarta.Tipo.SOMA, "+", true],
	[DadosCarta.Tipo.SUBTRACAO, "−", true],
	[DadosCarta.Tipo.MULTIPLICACAO, "×", true],
	[DadosCarta.Tipo.DIVISAO, "÷", true],
	[DadosCarta.Tipo.DOBRO, "x2", false],
	[DadosCarta.Tipo.METADE, "/2", false],
	[DadosCarta.Tipo.QUADRADO, "^2", false],
]

const ESPECIAIS := [
	["Chama", 5, DadosCarta.Efeito.DANO_EXTRA, 3, "+3 de dano"],
	["Foco", 4, DadosCarta.Efeito.COMPRAR, 1, "compra 1"],
	["Guarda", 6, DadosCarta.Efeito.ESCUDO, 5, "+5 de escudo"],
	["Vital", 7, DadosCarta.Efeito.CURA, 2, "cura 2"],
]


func _numero(valor: int) -> DadosCarta:
	var carta := DadosCarta.new()
	carta.tipo = DadosCarta.Tipo.NUMERO
	carta.valor = valor
	carta.ataque = valor
	return carta


func _operador(tipo: DadosCarta.Tipo) -> DadosCarta:
	var carta := DadosCarta.new()
	carta.tipo = tipo
	carta.ataque = 1
	return carta


func _especial(nome: String, valor: int, efeito: DadosCarta.Efeito, intensidade: int) -> DadosCarta:
	var carta := _numero(valor)
	carta.nome = nome
	carta.efeito = efeito
	carta.intensidade = intensidade
	return carta


func test_numero_nao_e_operador() -> void:
	var carta := _numero(3)
	assert_true(carta.eh_numero())
	assert_false(carta.eh_binario())
	assert_false(carta.eh_unario())


func test_numero_mostra_o_proprio_valor() -> void:
	assert_eq(_numero(3).simbolo(), "3")
	assert_eq(_numero(10).simbolo(), "10")


func test_numero_comum_nao_tem_texto_de_efeito() -> void:
	assert_eq(_numero(3).texto_efeito(), "")


func test_operador_classificado_e_com_simbolo(p = use_parameters(OPERADORES)) -> void:
	var carta := _operador(p[0])
	var binario: bool = p[2]
	assert_false(carta.eh_numero())
	assert_eq(carta.eh_binario(), binario)
	assert_eq(carta.eh_unario(), not binario)
	assert_eq(carta.simbolo(), p[1])
	assert_eq(carta.texto_efeito(), "")


func test_especial_e_numero_com_texto_de_efeito(p = use_parameters(ESPECIAIS)) -> void:
	var carta := _especial(p[0], p[1], p[2], p[3])
	assert_true(carta.eh_numero())
	assert_false(carta.eh_binario())
	assert_false(carta.eh_unario())
	assert_eq(carta.simbolo(), str(p[1]))
	assert_eq(carta.texto_efeito(), p[4])


func test_texto_de_efeito_usa_a_intensidade() -> void:
	var carta := _especial("Guarda", 6, DadosCarta.Efeito.ESCUDO, 8)
	assert_eq(carta.texto_efeito(), "+8 de escudo")


func test_especial_tem_a_mesma_chave_do_numero_de_mesmo_valor() -> void:
	var foco := _especial("Foco", 4, DadosCarta.Efeito.COMPRAR, 1)
	assert_eq(foco.chave_conta(), _numero(4).chave_conta())


func test_numeros_diferentes_tem_chaves_diferentes() -> void:
	assert_ne(_numero(3).chave_conta(), _numero(4).chave_conta())


func test_operadores_iguais_tem_a_mesma_chave() -> void:
	var soma_a := _operador(DadosCarta.Tipo.SOMA)
	var soma_b := _operador(DadosCarta.Tipo.SOMA)
	assert_eq(soma_a.chave_conta(), soma_b.chave_conta())


func test_chave_de_operador_nunca_coincide_com_outra_carta() -> void:
	var chaves_numeros: Array[int] = []
	for valor in range(1, 11):
		chaves_numeros.append(_numero(valor).chave_conta())
	var chaves_operadores: Array[int] = []
	for linha in OPERADORES:
		var chave := _operador(linha[0]).chave_conta()
		assert_false(chave in chaves_numeros, "operador %s com chave de número" % linha[1])
		assert_false(chave in chaves_operadores, "operador %s com chave repetida" % linha[1])
		chaves_operadores.append(chave)
