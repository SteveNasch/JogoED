class_name Run
extends RefCounted
## O estado e as regras de uma run inteira, do calabouço até a vitória ou a derrota (research
## D2). Não é nó: um teste cria e joga a run sem tela. A etapa só muda pelos métodos de
## transição, e cada um não faz nada fora da sua etapa. Interface em contracts/run.md.

enum Etapa { MAPA, LUTA, CHEFE, DESCANSO, RECOMPENSA, VITORIA, DERROTA }

## Semente da run (FR-006).
var semente: int
## Os dados conferidos no começo; a run nunca altera nada deles.
var dificuldade: DadosDificuldade
## De 1 até dificuldade.atos.size().
var ato: int = 1
## Um por ato, todos gerados na criação (research D3).
var mapas: Array[MapaAto] = []
## Onde o Arthur está; null antes do primeiro andar de cada ato.
var casa_atual: Casa
## Vida da run (FR-003), de 0 a vida_maxima.
var vida_arthur: int
var vida_maxima: int
## Cópia do baralho inicial mais as cartas escolhidas (FR-004).
var baralho: Array[DadosCarta] = []
var lutas_vencidas: int = 0
var etapa: Etapa = Etapa.MAPA
## Cartas da recompensa aberta; vazia fora da etapa RECOMPENSA.
var oferta: Array[DadosCarta] = []
## Quanto o último descanso curou de fato.
var cura: int = 0
## Sorteada ao entrar numa casa de luta ou de chefe.
var semente_da_luta: int

## Todo sorteio da run sai daqui: as sementes dos mapas, das lutas e as ofertas.
var _rng := RandomNumberGenerator.new()


## Pré-condição: dificuldade_da_run.erros() vazio (quem cria confere antes).
func _init(dificuldade_da_run: DadosDificuldade, semente_da_run: int) -> void:
	dificuldade = dificuldade_da_run
	semente = semente_da_run
	_rng.seed = semente
	for dados_ato in dificuldade.atos:
		mapas.append(GeradorMapa.gerar(dados_ato.mapa, _rng.randi()))
	vida_maxima = dificuldade.regras_base.vida_maxima_arthur
	vida_arthur = vida_maxima
	baralho = dificuldade.baralho_inicial.duplicate()


func mapa() -> MapaAto:
	return mapas[ato - 1]


func dados_do_ato() -> DadosAto:
	return dificuldade.atos[ato - 1]


func ultimo_ato() -> bool:
	return ato == dificuldade.atos.size()


## Vazia fora da etapa MAPA (FR-013).
func casas_disponiveis() -> Array[Casa]:
	if etapa != Etapa.MAPA:
		return []
	return mapa().disponiveis(casa_atual)


## Entra numa casa disponível. Devolve false, sem mudar nada, se a casa não vale agora.
func escolher_casa(casa: Casa) -> bool:
	if casa not in casas_disponiveis():
		return false
	var etapa_nova: Etapa
	match casa.tipo:
		Casa.Tipo.BATALHA, Casa.Tipo.ELITE:
			etapa_nova = Etapa.LUTA
		Casa.Tipo.CHEFE:
			etapa_nova = Etapa.CHEFE
		_:
			return false
	casa_atual = casa
	casa.visitada = true
	semente_da_luta = _rng.randi()
	etapa = etapa_nova
	return true


## O inimigo da casa atual, pelo ato e pelo andar dela (research D7).
func inimigo_da_luta() -> DadosInimigo:
	if casa_atual == null:
		return null
	return dados_do_ato().inimigo(casa_atual.tipo, casa_atual.andar)


## As regras da luta da 001 com a faixa do alvo do ato.
func regras_da_luta() -> RegrasBatalha:
	return dados_do_ato().regras_da_luta(dificuldade.regras_base)


## Andar da casa atual, ou 0 antes do primeiro andar (FR-024).
func andar_alcancado() -> int:
	if casa_atual == null:
		return 0
	return casa_atual.andar


## Leva o resultado da luta para a run. Só vale nas etapas LUTA e CHEFE.
func terminar_luta(resultado: ResultadoLuta) -> void:
	if etapa not in [Etapa.LUTA, Etapa.CHEFE] or not resultado.venceu:
		return
	vida_arthur = resultado.vida_arthur
	lutas_vencidas += 1
	etapa = Etapa.MAPA
