extends Label
## O que aconteceu na rodada (FR-025), com os textos de contracts/tela-batalha.md: o
## resultado da conta ou do Pular na primeira linha e o ataque do inimigo na segunda.


func mostrar(resultado: ResultadoRodada) -> void:
	var linhas: Array[String] = [_texto_do_resultado(resultado)]
	if resultado.inimigo_atacou:
		linhas.append(_texto_do_ataque(resultado))
	text = "\n".join(linhas)
	show()


func esconder() -> void:
	hide()


func _texto_do_resultado(resultado: ResultadoRodada) -> String:
	var partes: Array[String] = []
	match resultado.tipo:
		ResultadoRodada.Tipo.ACERTO:
			partes.append("Acertou! %d de dano." % resultado.dano_causado)
			if resultado.escudo_ganho > 0:
				partes.append("+%d de escudo." % resultado.escudo_ganho)
			if resultado.cura > 0:
				partes.append("Curou %d." % resultado.cura)
		ResultadoRodada.Tipo.ERRO:
			partes.append("Errou: a conta deu %d, o alvo era %d." % [resultado.valor, resultado.alvo])
		ResultadoRodada.Tipo.INVALIDA:
			partes.append("Conta inválida. O alvo era %d." % resultado.alvo)
		ResultadoRodada.Tipo.PULO:
			partes.append("Pulou a rodada.")
	if resultado.cartas_compradas == 1:
		partes.append("Comprou 1 carta.")
	elif resultado.cartas_compradas > 1:
		partes.append("Comprou %d cartas." % resultado.cartas_compradas)
	return " ".join(partes)


## Todo inimigo tem ataque de pelo menos 1 (FR-001): dano 0 só acontece quando o escudo segurou.
func _texto_do_ataque(resultado: ResultadoRodada) -> String:
	if resultado.dano_recebido == 0:
		return "O escudo segurou o ataque."
	return "O inimigo tirou %d de vida." % resultado.dano_recebido
