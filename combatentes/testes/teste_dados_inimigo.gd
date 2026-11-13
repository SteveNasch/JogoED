extends GutTest

const PASTA_INIMIGOS := "res://dados/inimigos/"


func test_inimigo_padrao_tem_os_valores_da_spec() -> void:
	var inimigo: DadosInimigo = load(PASTA_INIMIGOS + "inimigo_padrao.tres")
	assert_eq(inimigo.nome, "Inimigo")
	assert_eq(inimigo.vida, 12)
	assert_eq(inimigo.ataque, 3)


func test_todo_inimigo_tem_vida_e_ataque_de_pelo_menos_1() -> void:
	var arquivos := DirAccess.get_files_at(PASTA_INIMIGOS)
	assert_gt(arquivos.size(), 0, "a pasta de inimigos está vazia")
	for arquivo in arquivos:
		var inimigo := load(PASTA_INIMIGOS + arquivo) as DadosInimigo
		assert_not_null(inimigo, "%s não é um DadosInimigo" % arquivo)
		if inimigo == null:
			continue
		assert_gte(inimigo.vida, 1, "%s: vida" % arquivo)
		assert_gte(inimigo.ataque, 1, "%s: ataque (FR-001: todo inimigo ataca)" % arquivo)
