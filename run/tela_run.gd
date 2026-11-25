extends Control
## Cena principal da run (contracts/run.md, nível 2): guarda a Run e é a única que conhece as
## outras cenas. Mostra a barra e o mapa; a cada etapa abre a cena dela por cima, repassa o
## resultado à Run e fecha a cena (research D8).

const CENA_LUTA: PackedScene = preload("res://batalha/tela_batalha.tscn")
const CENA_VITORIA: PackedScene = preload("res://run/vitoria_luta.tscn")
const CENA_FIM: PackedScene = preload("res://run/fim_de_run.tscn")

## O arquivo de dificuldade (no editor: dados/dificuldade.tres). Nos testes, trocado antes de pôr
## a cena na árvore.
@export var dificuldade: DadosDificuldade

## A run em andamento.
var run: Run

@onready var _barra: HBoxContainer = %Barra
@onready var _ato: Label = %Ato
@onready var _vida: Label = %Vida
@onready var _baralho: Label = %Baralho
@onready var _mapa: TelaMapa = %Mapa


func _ready() -> void:
	_mapa.casa_escolhida.connect(_ao_escolher_casa)
	_comecar_run()


## Run nova com semente nova (FR-001, FR-006); é a única chamada solta de randi() da 002.
func _comecar_run() -> void:
	run = Run.new(dificuldade, randi())
	_mostrar_mapa()


## Barra da run (FR-015) e mapa do ato, visíveis só na etapa MAPA.
func _mostrar_mapa() -> void:
	_ato.text = "Ato %d: %s" % [run.ato, run.dados_do_ato().nome]
	_vida.text = "Vida %d/%d" % [run.vida_arthur, run.vida_maxima]
	_baralho.text = "Baralho: %d cartas" % run.baralho.size()
	_mapa.mostrar(run.mapa(), run.casa_atual)
	_barra.show()
	_mapa.show()


func _ao_escolher_casa(casa: Casa) -> void:
	if run.escolher_casa(casa):
		_abrir_etapa()


func _abrir_etapa() -> void:
	match run.etapa:
		Run.Etapa.MAPA:
			_mostrar_mapa()
		Run.Etapa.LUTA:
			_abrir_luta()
		Run.Etapa.CHEFE:
			_abrir_chefe()
		Run.Etapa.VITORIA, Run.Etapa.DERROTA:
			_abrir_fim()


func _abrir_luta() -> void:
	var luta: TelaBatalha = _abrir(CENA_LUTA)
	luta.luta_terminou.connect(_ao_terminar_luta.bind(luta))
	luta.iniciar(run.baralho, run.vida_arthur, run.inimigo_da_luta(), run.regras_da_luta(), run.semente_da_luta)


## Ponto de troca da 003: hoje o chefe é uma luta comum mais forte (FR-018).
func _abrir_chefe() -> void:
	_abrir_luta()


func _ao_terminar_luta(resultado: ResultadoLuta, luta: TelaBatalha) -> void:
	_fechar(luta)
	run.terminar_luta(resultado)
	if not resultado.venceu:
		_abrir_etapa()
		return
	var vitoria := _abrir(CENA_VITORIA)
	vitoria.continuou.connect(_ao_continuar.bind(vitoria))
	vitoria.mostrar(run.vida_arthur, run.vida_maxima)


## Fecha a cena e abre a etapa em que a Run já está.
func _ao_continuar(cena: Control) -> void:
	_fechar(cena)
	_abrir_etapa()


## Fim da run por vitória ou derrota (FR-024); "Começar de novo" cria outra run (SC-006).
func _abrir_fim() -> void:
	var fim := _abrir(CENA_FIM)
	fim.jogar_de_novo.connect(_ao_jogar_de_novo.bind(fim))
	fim.mostrar(run)


func _ao_jogar_de_novo(fim: Control) -> void:
	_fechar(fim)
	_comecar_run()


## Esconde a barra e o mapa e põe a cena da etapa por cima (o mapa não recebe clique).
func _abrir(cena: PackedScene) -> Control:
	_barra.hide()
	_mapa.hide()
	var no: Control = cena.instantiate()
	add_child(no)
	return no


## A cena sai da árvore na hora e é liberada no fim do quadro.
func _fechar(no: Control) -> void:
	remove_child(no)
	no.queue_free()
