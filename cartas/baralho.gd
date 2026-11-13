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
