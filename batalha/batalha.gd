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


## Escudo zerado (FR-018), compra com o mínimo da mão (FR-006) e alvo sorteado com a mão já
## completa (FR-007).
func _comecar_rodada(cartas_a_comprar: int) -> void:
	rodada += 1
	arthur.zerar_escudo()
	baralho.comprar_com_minimo(cartas_a_comprar, regras.minimo_numeros, regras.minimo_somas, regras.minimo_subtracoes)
	alvo = _busca.sortear(baralho.mao, _rng)
	estado = Estado.MONTANDO
	mudou.emit()
