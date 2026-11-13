extends GutTest
## Contas de referência do motor (SC-004). Cada conta é escrita como texto, com as cartas
## separadas por espaço, e vira uma lista de DadosCarta.

const TIPOS_POR_SIMBOLO := {
	"+": DadosCarta.Tipo.SOMA,
	"−": DadosCarta.Tipo.SUBTRACAO,
	"×": DadosCarta.Tipo.MULTIPLICACAO,
	"÷": DadosCarta.Tipo.DIVISAO,
	"x2": DadosCarta.Tipo.DOBRO,
	"/2": DadosCarta.Tipo.METADE,
	"^2": DadosCarta.Tipo.QUADRADO,
}

# conta, valor esperado
const CONTAS_VALIDAS := [
	["5", 5],
	["3 + 4 × 2", 11],
	["2 × 3 + 4", 10],
	["1 − 2 × 3", -5],
	["2 + 3 × 4 − 6 ÷ 3", 12],
	["6 ÷ 2 × 3 − 1", 8],
	["10 − 2 − 3", 5],
	["8 ÷ 2 ÷ 2", 2],
	["8 ÷ 4 × 2", 4],
	["1 + 1 + 1 + 1", 4],
	["3 ^2 x2", 18],
	["3 x2 ^2", 36],
	["4 ^2 ^2", 256],
	["9 /2 /2", 2],
	["3 /2 x2", 2],
	["3 x2 /2", 3],
	["2 × 3 ^2", 18],
	["3 + 5 x2", 13],
	["2 ^2 − 3 ^2", -5],
	["7 ÷ 2", 3],
	["5 ÷ 7", 0],
	["10 ÷ 3 + 10 ÷ 3", 6],
	["5 /2", 2],
	["1 /2", 0],
	["2 − 7 ÷ 2", -1],
	["1 − 7 /2", -2],
	["2 − 5 + 9", 6],
	["4 − 9", -5],
	["7 − 7", 0],
]

const CONTAS_INVALIDAS := [
	"",
	"3 4",
	"3 − 4 5",
	"+ 3",
	"x2",
	"5 ×",
	"3 + + 4",
	"3 4 +",
	"3 + x2",
	"^2 3",
	"4 ÷ 1 /2",
	"5 ÷ 3 ÷ 1 /2",
]


func _cartas(conta: String) -> Array[DadosCarta]:
	var cartas: Array[DadosCarta] = []
	for simbolo in conta.split(" ", false):
		var carta := DadosCarta.new()
		if simbolo.is_valid_int():
			carta.tipo = DadosCarta.Tipo.NUMERO
			carta.valor = simbolo.to_int()
		else:
			carta.tipo = TIPOS_POR_SIMBOLO[simbolo]
		cartas.append(carta)
	return cartas


func test_conta_valida_da_o_valor_certo(p = use_parameters(CONTAS_VALIDAS)) -> void:
	var resultado := MotorContas.avaliar(_cartas(p[0]))
	assert_true(resultado.valida, "%s deveria ser válida" % p[0])
	assert_eq(resultado.valor, p[1], p[0])


func test_conta_invalida_e_recusada(p = use_parameters(CONTAS_INVALIDAS)) -> void:
	var resultado := MotorContas.avaliar(_cartas(p))
	assert_false(resultado.valida, "\"%s\" deveria ser inválida" % p)


func test_avalia_as_cartas_dos_arquivos_de_dados() -> void:
	var cartas: Array[DadosCarta] = [
		load("res://dados/cartas/chama.tres"),
		load("res://dados/cartas/soma.tres"),
		load("res://dados/cartas/foco.tres"),
		load("res://dados/cartas/multiplicacao.tres"),
		load("res://dados/cartas/numero_2.tres"),
	]
	var resultado := MotorContas.avaliar(cartas)
	assert_true(resultado.valida)
	assert_eq(resultado.valor, 13, "Chama (5) + Foco (4) × 2")
