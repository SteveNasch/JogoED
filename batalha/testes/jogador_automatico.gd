extends RefCounted
## Jogador automático dos testes: a cada rodada alterna, em ciclo, entre acertar com a conta de
## exemplo da busca, errar de propósito e pular. Usado pela simulação de lutas da 001 e pela
## simulação de runs da 002. O nome não começa com "teste_" para o GUT não rodá-lo como teste.

enum Acao { ACERTAR, ERRAR, PULAR }

## As ações em ciclo, uma por rodada.
const CICLO: Array[Acao] = [Acao.ACERTAR, Acao.ERRAR, Acao.PULAR]


## Joga a rodada atual com a ação da vez no ciclo e devolve essa ação. A busca vem de fora
## porque a faixa do alvo muda de uma luta para outra (na run, a cada ato).
static func jogar_rodada(batalha: Batalha, busca: BuscaAlvo) -> Acao:
	var acao := CICLO[(batalha.rodada - 1) % CICLO.size()]
	match acao:
		Acao.ACERTAR:
			_montar(batalha, busca.alcancaveis(batalha.baralho.mao).get(batalha.alvo, []))
			batalha.confirmar()
		Acao.ERRAR:
			_montar(batalha, [_carta_errada(batalha)])
			batalha.confirmar()
		Acao.PULAR:
			batalha.pular()
	return acao


## A conta usa cada carta no máximo tantas vezes quanto ela aparece na mão.
static func usa_so_a_mao(conta: Array, mao: Array[DadosCarta]) -> bool:
	var sobra := mao.duplicate()
	for carta in conta:
		var i := sobra.find(carta)
		if i == -1:
			return false
		sobra.remove_at(i)
	return true


static func quantos_do_tipo(cartas: Array[DadosCarta], tipo: DadosCarta.Tipo) -> int:
	var quantidade := 0
	for carta in cartas:
		if carta.tipo == tipo:
			quantidade += 1
	return quantidade


static func simbolos(cartas: Array[DadosCarta]) -> Array[String]:
	var lista: Array[String] = []
	for carta in cartas:
		lista.append(carta.simbolo())
	return lista


## Para cada carta, acha o índice dela na mão atual (os índices mudam quando uma carta sai).
## Procurar por referência é seguro aqui porque cartas iguais são intercambiáveis; quem move a
## carta continua sendo o Baralho, por posição.
static func _montar(batalha: Batalha, conta: Array) -> void:
	for carta in conta:
		batalha.escolher_carta(batalha.baralho.mao.find(carta))


## Uma carta de número com valor diferente do alvo; se todas valem o alvo, o "+" sozinho
## (conta inválida).
static func _carta_errada(batalha: Batalha) -> DadosCarta:
	var soma: DadosCarta = null
	for carta in batalha.baralho.mao:
		if carta.eh_numero() and carta.valor != batalha.alvo:
			return carta
		if carta.tipo == DadosCarta.Tipo.SOMA:
			soma = carta
	return soma
