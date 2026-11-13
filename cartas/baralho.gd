class_name Baralho
extends RefCounted
## As quatro zonas das cartas durante a luta; cada carta está em exatamente uma.
## As cartas são movidas sempre por posição, nunca procuradas: cartas iguais são o mesmo
## objeto (os dois "3" apontam para o mesmo arquivo).

## Pilha de compra; o fim do array é o topo.
var compra: Array[DadosCarta] = []
var mao: Array[DadosCarta] = []
## Conta em montagem, na ordem escolhida.
var expressao: Array[DadosCarta] = []
## Cartas usadas; o início do array é a descartada há mais tempo.
var descarte: Array[DadosCarta] = []

var _rng: RandomNumberGenerator


## Copia a lista recebida para a pilha de compra e embaralha com o gerador da luta.
func _init(cartas: Array[DadosCarta], rng: RandomNumberGenerator) -> void:
	_rng = rng
	compra = cartas.duplicate()
	_embaralhar(compra)


## Do topo da pilha para a mão. Com a pilha vazia, o descarte vira a pilha (FR-005); sem
## cartas nas duas, para. Devolve quantas cartas comprou.
func comprar(quantidade: int) -> int:
	var compradas := 0
	while compradas < quantidade:
		if compra.is_empty():
			_refazer_compra()
		if compra.is_empty():
			break
		mao.append(compra.pop_back())
		compradas += 1
	return compradas


## Compra do início de rodada (FR-006, research D11). Cada uma das `quantidade` cartas é do
## tipo que falta na mão (número, depois soma, depois subtração), se houver; senão, é a do
## topo. Depois, compra cartas extras só enquanto faltar algum tipo que exista fora da mão.
## Nunca tira carta da mão. Recebe os mínimos, e não a RegrasBatalha, para a área cartas não
## depender da área batalha.
func comprar_com_minimo(quantidade: int, minimo_numeros: int, minimo_somas: int, minimo_subtracoes: int) -> void:
	var minimos := {
		DadosCarta.Tipo.NUMERO: minimo_numeros,
		DadosCarta.Tipo.SOMA: minimo_somas,
		DadosCarta.Tipo.SUBTRACAO: minimo_subtracoes,
	}
	for i in quantidade:
		if not _comprar_tipo_que_falta(minimos) and comprar(1) == 0:
			break
	while _comprar_tipo_que_falta(minimos):
		pass


## FR-008: a carta sai da mão e entra no fim da expressão.
func por_na_expressao(indice: int) -> void:
	if indice < 0 or indice >= mao.size():
		return
	expressao.append(mao.pop_at(indice))


## FR-009: a última carta da expressão volta para o fim da mão.
func desfazer() -> void:
	if not expressao.is_empty():
		mao.append(expressao.pop_back())


## FR-009: todas as cartas da expressão voltam para o fim da mão, na ordem.
func limpar() -> void:
	mao.append_array(expressao)
	expressao.clear()


## FR-004 e FR-019: a expressão inteira vai para o descarte.
func descartar_expressao() -> void:
	descarte.append_array(expressao)
	expressao.clear()


func total() -> int:
	return compra.size() + mao.size() + expressao.size() + descarte.size()


## Compra uma carta do primeiro tipo (na ordem do dicionário) que está abaixo do mínimo na mão
## e existe fora dela. Devolve false se nenhum tipo que falta pôde ser comprado.
func _comprar_tipo_que_falta(minimos: Dictionary) -> bool:
	for tipo: DadosCarta.Tipo in minimos:
		if _quantos_do_tipo(mao, tipo) < minimos[tipo] and _comprar_do_tipo(tipo):
			return true
	return false


## A carta do tipo mais perto do topo da pilha (com a pilha vazia, ela é refeita antes, FR-005)
## ou, se a pilha não tem nenhuma, a descartada há mais tempo.
func _comprar_do_tipo(tipo: DadosCarta.Tipo) -> bool:
	if compra.is_empty():
		_refazer_compra()
	for i in range(compra.size() - 1, -1, -1):
		if compra[i].tipo == tipo:
			mao.append(compra.pop_at(i))
			return true
	for i in descarte.size():
		if descarte[i].tipo == tipo:
			mao.append(descarte.pop_at(i))
			return true
	return false


func _quantos_do_tipo(cartas: Array[DadosCarta], tipo: DadosCarta.Tipo) -> int:
	var quantidade := 0
	for carta in cartas:
		if carta.tipo == tipo:
			quantidade += 1
	return quantidade


## FR-005: o descarte é embaralhado e vira a nova pilha de compra.
func _refazer_compra() -> void:
	compra.append_array(descarte)
	descarte.clear()
	_embaralhar(compra)


## Fisher–Yates com o gerador da luta, para a mesma semente dar a mesma ordem (research D8).
func _embaralhar(cartas: Array[DadosCarta]) -> void:
	for i in range(cartas.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var carta := cartas[i]
		cartas[i] = cartas[j]
		cartas[j] = carta
