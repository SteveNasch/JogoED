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
	casa_atual = casa
	casa.visitada = true
	match casa.tipo:
		Casa.Tipo.BATALHA, Casa.Tipo.ELITE:
			semente_da_luta = _rng.randi()
			etapa = Etapa.LUTA
		Casa.Tipo.CHEFE:
			semente_da_luta = _rng.randi()
			etapa = Etapa.CHEFE
		Casa.Tipo.DESCANSO:
			_descansar()
			etapa = Etapa.DESCANSO
		Casa.Tipo.RECOMPENSA:
			_abrir_recompensa()
	return true


## Cura uma porcentagem da vida máxima, sem passar dela (FR-020), e guarda quanto curou de fato.
func _descansar() -> void:
	var vida_curada := mini(vida_maxima, vida_arthur + floori(vida_maxima * dificuldade.cura_do_descanso / 100.0))
	cura = vida_curada - vida_arthur
	vida_arthur = vida_curada


## Volta do descanso para o mapa. Só vale na etapa DESCANSO.
func sair_do_descanso() -> void:
	if etapa != Etapa.DESCANSO:
		return
	etapa = Etapa.MAPA


## Sorteia a oferta (FR-021): o conjunto sem cartas repetidas, sorteado sem repetição com o
## gerador da run, até cartas_por_recompensa cartas. Com o conjunto vazio, a oferta é vazia.
func _abrir_recompensa() -> void:
	var conjunto: Array[DadosCarta] = []
	for carta in dificuldade.cartas_de_recompensa:
		if carta not in conjunto:
			conjunto.append(carta)
	oferta = []
	while oferta.size() < dificuldade.cartas_por_recompensa and not conjunto.is_empty():
		oferta.append(conjunto.pop_at(_rng.randi_range(0, conjunto.size() - 1)))
	etapa = Etapa.RECOMPENSA


## Põe a carta escolhida no fim do baralho (null = não pegar nenhuma) e volta ao mapa; depois
## do chefe, já no ato seguinte, antes do primeiro andar (FR-023). Só vale na etapa RECOMPENSA,
## com uma carta da oferta ou null.
func escolher_recompensa(carta: DadosCarta) -> void:
	if etapa != Etapa.RECOMPENSA:
		return
	if carta != null and carta not in oferta:
		return
	if carta != null:
		baralho.append(carta)
	oferta = []
	if casa_atual.tipo == Casa.Tipo.CHEFE:
		ato += 1
		casa_atual = null
	etapa = Etapa.MAPA


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


## Leva o resultado da luta para a run. Só vale nas etapas LUTA e CHEFE. A derrota acaba a run
## (FR-024): em DERROTA nenhum método muda mais nada.
func terminar_luta(resultado: ResultadoLuta) -> void:
	if etapa not in [Etapa.LUTA, Etapa.CHEFE]:
		return
	if not resultado.venceu:
		vida_arthur = 0
		etapa = Etapa.DERROTA
		return
	vida_arthur = resultado.vida_arthur
	lutas_vencidas += 1
	match casa_atual.tipo:
		Casa.Tipo.CHEFE when ultimo_ato():
			etapa = Etapa.VITORIA
		Casa.Tipo.ELITE, Casa.Tipo.CHEFE:
			_abrir_recompensa()
		_:
			etapa = Etapa.MAPA
