class_name TelaBatalha
extends Control
## A luta com tela (contracts/batalha.md, nível 1). Junta as cenas pequenas, repassa os
## cliques à Batalha e redesenha a cada mudança. Quem conta o tempo do aviso é o Timer
## (research D12). Não mostra o valor da conta em montagem nem se ela é válida (FR-010).

## Emitido uma vez, depois que o resultado da última rodada saiu da tela.
signal luta_terminou(resultado: ResultadoLuta)

## A lógica da luta em andamento (criada por iniciar()). Quem usa a cena só lê; os testes de
## cena escrevem nela para montar um cenário e depois emitem batalha.mudou.
var batalha: Batalha

@onready var _painel_arthur: VBoxContainer = %PainelArthur
@onready var _painel_inimigo: VBoxContainer = %PainelInimigo
@onready var _alvo: Label = %Alvo
@onready var _expressao: HBoxContainer = %Expressao
@onready var _aviso: Label = %Aviso
@onready var _confirmar: Button = %Confirmar
@onready var _mao: HBoxContainer = %Mao
@onready var _sons: Node = %Sons
@onready var _timer: Timer = %Timer


func _ready() -> void:
	_mao.carta_escolhida.connect(_ao_escolher_carta)
	_confirmar.pressed.connect(_ao_confirmar)
	_timer.timeout.connect(_ao_acabar_o_aviso)


## Começa a luta. Chamar depois de pôr a cena na árvore.
func iniciar(cartas: Array[DadosCarta], vida_arthur: int, dados_inimigo: DadosInimigo, regras: RegrasBatalha, semente: int) -> void:
	batalha = Batalha.new(cartas, vida_arthur, dados_inimigo, regras, semente)
	batalha.mudou.connect(_redesenhar)
	batalha.rodada_resolvida.connect(_ao_resolver_rodada)
	batalha.luta_terminou.connect(luta_terminou.emit)
	batalha.iniciar()


## As ações só valem montando a conta; durante o aviso e depois do fim ficam desligadas.
func _redesenhar() -> void:
	_painel_arthur.mostrar(batalha.arthur)
	_painel_inimigo.mostrar(batalha.inimigo)
	_alvo.text = str(batalha.alvo)
	_expressao.mostrar(batalha.baralho.expressao)
	_mao.mostrar(batalha.baralho.mao)
	var montando := batalha.estado == Batalha.Estado.MONTANDO
	_mao.clicavel = montando
	_confirmar.disabled = not (montando and batalha.pode_confirmar())


func _ao_escolher_carta(indice: int) -> void:
	batalha.escolher_carta(indice)
	_sons.tocar_carta()


func _ao_confirmar() -> void:
	batalha.confirmar()


func _ao_resolver_rodada(resultado: ResultadoRodada) -> void:
	_aviso.mostrar(resultado)
	_sons.tocar_rodada(resultado)
	_timer.start(batalha.regras.tempo_resultado)


func _ao_acabar_o_aviso() -> void:
	_aviso.esconder()
	batalha.avancar()
