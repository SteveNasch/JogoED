class_name Batalha
extends RefCounted
## As regras da luta, sem cena (contracts/batalha.md). Quem usa entrega o baralho, a vida do
## Arthur, o inimigo, as regras e a semente, e recebe o resultado por sinal. Os campos são
## públicos: a tela lê para desenhar e os testes escrevem para montar um cenário.

enum Estado { MONTANDO, MOSTRANDO_RESULTADO, TERMINADA }

## Algo visível mudou (mão, expressão, vidas, escudo, alvo): a tela se redesenha.
signal mudou
## A rodada foi resolvida; a tela mostra o resultado e depois chama avancar().
signal rodada_resolvida(resultado: ResultadoRodada)
## Alguém chegou a 0 de vida e avancar() foi chamado.
signal luta_terminou(resultado: ResultadoLuta)

var arthur: Combatente
var inimigo: Combatente
var baralho: Baralho
var alvo: int = 0
## Número da rodada, começando em 1.
var rodada: int = 0
var estado: Estado = Estado.MONTANDO
var regras: RegrasBatalha

var _rng := RandomNumberGenerator.new()
var _busca: BuscaAlvo


## Um só gerador de sorteio por luta, passado ao baralho e à busca do alvo, para a mesma
## semente dar a mesma luta (FR-029).
func _init(cartas: Array[DadosCarta], vida_arthur: int, dados_inimigo: DadosInimigo, regras_da_luta: RegrasBatalha, semente: int) -> void:
	regras = regras_da_luta
	_rng.seed = semente
	arthur = Combatente.new("Arthur", vida_arthur, regras.vida_maxima_arthur, 0)
	inimigo = Combatente.new(dados_inimigo.nome, dados_inimigo.vida, dados_inimigo.vida, dados_inimigo.ataque)
	baralho = Baralho.new(cartas, _rng)
	_busca = BuscaAlvo.new(regras.alvo_minimo, regras.alvo_maximo, regras.max_numeros_no_alvo, regras.limite_buscas_alvo)


## Começa a rodada 1.
func iniciar() -> void:
	_comecar_rodada(regras.cartas_iniciais)


## FR-008: a carta da mão vai para o fim da expressão.
func escolher_carta(indice_da_mao: int) -> void:
	if estado != Estado.MONTANDO or indice_da_mao < 0 or indice_da_mao >= baralho.mao.size():
		return
	baralho.por_na_expressao(indice_da_mao)
	mudou.emit()


## FR-011: não dá para confirmar uma expressão vazia.
func pode_confirmar() -> bool:
	return not baralho.expressao.is_empty()


## Julga a conta: acerto tira do inimigo a soma do ataque das cartas (FR-016); erro e conta
## inválida não causam dano (FR-019). Nos três casos as cartas vão para o descarte e o
## inimigo vivo ataca (FR-021).
func confirmar() -> void:
	if estado != Estado.MONTANDO or not pode_confirmar():
		return
	var conta := MotorContas.avaliar(baralho.expressao)
	var resultado: ResultadoRodada
	if not conta.valida:
		resultado = ResultadoRodada.new(ResultadoRodada.Tipo.INVALIDA, alvo)
	elif conta.valor != alvo:
		resultado = ResultadoRodada.new(ResultadoRodada.Tipo.ERRO, alvo)
		resultado.valor = conta.valor
	else:
		resultado = ResultadoRodada.new(ResultadoRodada.Tipo.ACERTO, alvo)
		resultado.valor = conta.valor
		resultado.dano_causado = _ataque_da_expressao()
		inimigo.receber_dano(resultado.dano_causado)
	baralho.descartar_expressao()
	_inimigo_ataca(resultado)
	_mostrar_resultado(resultado)


## Depois que a tela mostrou o resultado: começa a rodada seguinte.
func avancar() -> void:
	if estado != Estado.MOSTRANDO_RESULTADO:
		return
	_comecar_rodada(regras.cartas_por_rodada)


## Escudo zerado (FR-018), compra com o mínimo da mão (FR-006) e alvo sorteado com a mão já
## completa (FR-007).
func _comecar_rodada(cartas_a_comprar: int) -> void:
	rodada += 1
	arthur.zerar_escudo()
	baralho.comprar_com_minimo(cartas_a_comprar, regras.minimo_numeros, regras.minimo_somas, regras.minimo_subtracoes)
	alvo = _busca.sortear(baralho.mao, _rng)
	estado = Estado.MONTANDO
	mudou.emit()


func _ataque_da_expressao() -> int:
	var ataque := 0
	for carta in baralho.expressao:
		ataque += carta.ataque
	return ataque


## FR-021: o inimigo ataca no fim de toda rodada, menos quando caiu nela.
func _inimigo_ataca(resultado: ResultadoRodada) -> void:
	if not inimigo.esta_vivo():
		return
	resultado.inimigo_atacou = true
	resultado.dano_recebido = arthur.receber_dano(inimigo.ataque)


func _mostrar_resultado(resultado: ResultadoRodada) -> void:
	estado = Estado.MOSTRANDO_RESULTADO
	mudou.emit()
	rodada_resolvida.emit(resultado)
