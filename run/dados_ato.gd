class_name DadosAto
extends Resource
## Tudo o que muda de um ato para outro. Os atos ficam dentro de DadosDificuldade, em
## dados/dificuldade.tres. As funções nunca devolvem um objeto dos dados, sempre um novo, para
## ninguém alterar o arquivo carregado (research D5).

## Nome mostrado na barra da run.
@export var nome: String = ""
## Faixa do alvo das lutas do ato (FR-026).
@export var alvo_minimo: int
@export var alvo_maximo: int
## Inimigos no andar 1 do ato; o chefe é o provisório da FR-018.
@export var comum: DadosInimigo
@export var elite: DadosInimigo
@export var chefe: DadosInimigo
## Quanto a vida do comum e da elite sobe a cada andar.
@export var vida_extra_por_andar: int
## Tamanho e casas do mapa do ato.
@export var mapa: DadosMapa


## O inimigo de uma casa do ato (research D7). Descanso e recompensa não têm inimigo.
func inimigo(tipo: Casa.Tipo, andar: int) -> DadosInimigo:
	match tipo:
		Casa.Tipo.BATALHA:
			return _copia(comum, vida_extra_por_andar * (andar - 1))
		Casa.Tipo.ELITE:
			return _copia(elite, vida_extra_por_andar * (andar - 1))
		Casa.Tipo.CHEFE:
			return _copia(chefe, 0)
		_:
			return null


## As regras da luta da 001 com a faixa do alvo deste ato.
func regras_da_luta(base: RegrasBatalha) -> RegrasBatalha:
	var regras := base.duplicate() as RegrasBatalha
	regras.alvo_minimo = alvo_minimo
	regras.alvo_maximo = alvo_maximo
	return regras


## Uma frase por valor impossível (FR-028). O DadosDificuldade põe "Ato N (nome): " na frente.
func erros() -> Array[String]:
	var lista: Array[String] = []
	if alvo_minimo < 1:
		lista.append("alvo_minimo (%d) é menor que 1." % alvo_minimo)
	if alvo_minimo > alvo_maximo:
		lista.append("alvo_minimo (%d) é maior que alvo_maximo (%d)." % [alvo_minimo, alvo_maximo])
	for campo in ["comum", "elite", "chefe"]:
		lista.append_array(_erros_do_inimigo(campo, get(campo)))
	if vida_extra_por_andar < 0:
		lista.append("vida_extra_por_andar (%d) é negativo." % vida_extra_por_andar)
	if mapa == null:
		lista.append("mapa está vazio.")
	else:
		lista.append_array(mapa.erros())
	return lista


func _copia(original: DadosInimigo, vida_extra: int) -> DadosInimigo:
	var copia := DadosInimigo.new()
	copia.nome = original.nome
	copia.vida = original.vida + vida_extra
	copia.ataque = original.ataque
	return copia


func _erros_do_inimigo(campo: String, dados: DadosInimigo) -> Array[String]:
	var lista: Array[String] = []
	if dados == null:
		lista.append("%s está vazio." % campo)
		return lista
	if dados.vida < 1:
		lista.append("%s: vida (%d) é menor que 1." % [campo, dados.vida])
	if dados.ataque < 1:
		lista.append("%s: ataque (%d) é menor que 1." % [campo, dados.ataque])
	return lista
