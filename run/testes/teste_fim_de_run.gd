extends GutTest
## Fim de run (FR-024): os dois exemplos do contrato, montados numa Run de dados/dificuldade.tres
## pelos campos públicos, e o botão Começar de novo.

const CENA: PackedScene = preload("res://run/fim_de_run.tscn")
const DIFICULDADE: DadosDificuldade = preload("res://dados/dificuldade.tres")

var _fim: Control


func before_each() -> void:
	_fim = add_child_autofree(CENA.instantiate())


func _texto(no: String) -> String:
	return _fim.get_node("%" + no).text


## Run no `ato`, com o Arthur na casa de índice 0 do `andar`, na `etapa` e com `lutas` vencidas.
func _run(ato: int, andar: int, etapa: Run.Etapa, lutas: int) -> Run:
	var run := Run.new(DIFICULDADE, 1234)
	run.ato = ato
	run.casa_atual = run.mapa().casas_do_andar(andar)[0]
	run.etapa = etapa
	run.lutas_vencidas = lutas
	return run


func test_vitoria_mostra_o_chefe_da_torre_e_as_lutas() -> void:
	_fim.mostrar(_run(3, 5, Run.Etapa.VITORIA, 14))
	assert_eq(_texto("Titulo"), "Vitória!")
	assert_eq(_texto("Onde"), "Arthur venceu o chefe do ato 3 (Torre), andar 5.")
	assert_eq(_texto("Lutas"), "Lutas vencidas: 14")
	assert_eq(_texto("Botao"), "Começar de novo")


func test_derrota_mostra_onde_o_arthur_caiu_e_as_lutas() -> void:
	_fim.mostrar(_run(2, 3, Run.Etapa.DERROTA, 6))
	assert_eq(_texto("Titulo"), "Fim da run")
	assert_eq(_texto("Onde"), "Arthur caiu no ato 2 (Salões), andar 3.")
	assert_eq(_texto("Lutas"), "Lutas vencidas: 6")
	assert_eq(_texto("Botao"), "Começar de novo")


func test_botao_emite_jogar_de_novo_uma_vez() -> void:
	_fim.mostrar(_run(2, 3, Run.Etapa.DERROTA, 6))
	watch_signals(_fim)
	(_fim.get_node("%Botao") as Button).pressed.emit()
	assert_signal_emit_count(_fim, "jogar_de_novo", 1)
