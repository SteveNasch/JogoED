class_name DadosDificuldade
extends Resource
## O arquivo único de equilíbrio da run (FR-027), dados/dificuldade.tres. Os atos, os inimigos e
## os mapas ficam dentro dele; as cartas e as regras da luta são arquivos da 001 apontados por
## ele. erros() é conferido ao abrir o jogo, antes da run (FR-028).

## As regras da luta da 001; a faixa do alvo vem de cada ato.
@export var regras_base: RegrasBatalha
## Baralho do começo de toda run (FR-002).
@export var baralho_inicial: Array[DadosCarta] = []
## Conjunto de onde saem as ofertas de recompensa (FR-021). Vazio vale.
@export var cartas_de_recompensa: Array[DadosCarta] = []
## Cartas em cada oferta.
@export var cartas_por_recompensa: int
## Porcentagem da vida máxima que o descanso cura (FR-020).
@export var cura_do_descanso: int
## Na ordem da run; o último é o que termina a run.
@export var atos: Array[DadosAto] = []


## Uma frase por valor impossível, com o nome do campo como aparece no Inspector. As posições
## das listas são contadas a partir de 0, como no Inspector.
func erros() -> Array[String]:
	var lista: Array[String] = []
	if regras_base == null:
		lista.append("regras_base está vazio.")
	lista.append_array(_erros_dos_atos())
	lista.append_array(_posicoes_vazias("baralho_inicial", baralho_inicial))
	if not baralho_inicial.any(func(carta: DadosCarta) -> bool: return carta != null and carta.eh_numero()):
		lista.append("baralho_inicial não tem nenhuma carta de número.")
	lista.append_array(_posicoes_vazias("cartas_de_recompensa", cartas_de_recompensa))
	if cartas_por_recompensa < 1:
		lista.append("cartas_por_recompensa (%d) é menor que 1." % cartas_por_recompensa)
	if cura_do_descanso < 0 or cura_do_descanso > 100:
		lista.append("cura_do_descanso (%d) precisa ficar entre 0 e 100." % cura_do_descanso)
	return lista


func _erros_dos_atos() -> Array[String]:
	var lista: Array[String] = []
	if atos.is_empty():
		lista.append("atos está vazio.")
	lista.append_array(_posicoes_vazias("atos", atos))
	for i in atos.size():
		var ato := atos[i]
		if ato == null:
			continue
		for frase in ato.erros():
			lista.append("Ato %d (%s): %s" % [i + 1, ato.nome, frase])
	return lista


func _posicoes_vazias(campo: String, itens: Array) -> Array[String]:
	var lista: Array[String] = []
	for i in itens.size():
		if itens[i] == null:
			lista.append("%s: a posição %d está vazia." % [campo, i])
	return lista
