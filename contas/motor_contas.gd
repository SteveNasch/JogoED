class_name MotorContas
extends RefCounted
## Avalia uma sequência de cartas como conta (FR-012 a FR-015). É o mesmo motor que julga o
## jogador e que a busca do alvo usa, para os dois nunca discordarem.


## Três níveis: fator (número com os seus x2, /2 e ^2), termo (fatores ligados por × e ÷) e
## soma (termos ligados por + e −).
static func avaliar(cartas: Array[DadosCarta]) -> ResultadoConta:
	# 1ª passada: confere a ordem das cartas e aplica os unários ao número logo antes deles.
	var fatores: Array[int] = []
	var operadores: Array[DadosCarta.Tipo] = []
	var espera_numero := true
	for carta in cartas:
		if espera_numero:
			if not carta.eh_numero():
				return ResultadoConta.new(false)
			fatores.append(carta.valor)
			espera_numero = false
		elif carta.eh_unario():
			fatores[-1] = _aplicar_unario(carta.tipo, fatores[-1])
		elif carta.eh_binario():
			operadores.append(carta.tipo)
			espera_numero = true
		else:
			return ResultadoConta.new(false)
	if espera_numero:
		return ResultadoConta.new(false)

	# 2ª passada: × e ÷ juntam fatores no último termo; + e − abrem um termo novo. O sinal fica
	# à parte para a divisão agir só sobre o número (2 − 7 ÷ 2 é 2 − 3).
	var termos: Array[int] = [fatores[0]]
	var sinais: Array[int] = [1]
	for i in operadores.size():
		var proximo := fatores[i + 1]
		match operadores[i]:
			DadosCarta.Tipo.MULTIPLICACAO:
				termos[-1] *= proximo
			DadosCarta.Tipo.DIVISAO:
				if proximo == 0:
					return ResultadoConta.new(false)
				termos[-1] = floori(termos[-1] / float(proximo))
			DadosCarta.Tipo.SOMA:
				termos.append(proximo)
				sinais.append(1)
			DadosCarta.Tipo.SUBTRACAO:
				termos.append(proximo)
				sinais.append(-1)

	var total := 0
	for i in termos.size():
		total += sinais[i] * termos[i]
	return ResultadoConta.new(true, total)


static func _aplicar_unario(tipo: DadosCarta.Tipo, numero: int) -> int:
	if tipo == DadosCarta.Tipo.DOBRO:
		return numero * 2
	if tipo == DadosCarta.Tipo.METADE:
		return floori(numero / 2.0)
	return numero * numero  # QUADRADO, o único unário que sobra
