extends GutTest


func _arthur(vida: int = 40) -> Combatente:
	return Combatente.new("Arthur", vida, 40, 0)


func test_comeca_com_os_valores_recebidos_e_sem_escudo() -> void:
	var inimigo := Combatente.new("Inimigo", 12, 12, 3)
	assert_eq(inimigo.nome, "Inimigo")
	assert_eq(inimigo.vida, 12)
	assert_eq(inimigo.vida_maxima, 12)
	assert_eq(inimigo.ataque, 3)
	assert_eq(inimigo.escudo, 0)


func test_vida_inicial_pode_ser_menor_que_a_maxima() -> void:
	var arthur := _arthur(25)
	assert_eq(arthur.vida, 25)
	assert_eq(arthur.vida_maxima, 40)


func test_dano_sem_escudo_sai_da_vida() -> void:
	var arthur := _arthur()
	assert_eq(arthur.receber_dano(3), 3)
	assert_eq(arthur.vida, 37)


func test_escudo_maior_que_o_dano_absorve_tudo() -> void:
	var arthur := _arthur()
	arthur.ganhar_escudo(5)
	assert_eq(arthur.receber_dano(3), 0)
	assert_eq(arthur.vida, 40)
	assert_eq(arthur.escudo, 2)


func test_escudo_menor_que_o_dano_absorve_so_uma_parte() -> void:
	var arthur := _arthur()
	arthur.ganhar_escudo(2)
	assert_eq(arthur.receber_dano(5), 3)
	assert_eq(arthur.vida, 37)
	assert_eq(arthur.escudo, 0)


func test_escudo_igual_ao_dano_absorve_tudo() -> void:
	var arthur := _arthur()
	arthur.ganhar_escudo(3)
	assert_eq(arthur.receber_dano(3), 0)
	assert_eq(arthur.vida, 40)
	assert_eq(arthur.escudo, 0)


func test_dano_maior_que_a_vida_para_em_zero() -> void:
	var arthur := _arthur(2)
	assert_eq(arthur.receber_dano(5), 2)
	assert_eq(arthur.vida, 0)
	assert_false(arthur.esta_vivo())


func test_cura_nao_passa_da_vida_maxima() -> void:
	var arthur := _arthur(39)
	assert_eq(arthur.curar(2), 1)
	assert_eq(arthur.vida, 40)


func test_cura_abaixo_do_maximo_cura_tudo() -> void:
	var arthur := _arthur(30)
	assert_eq(arthur.curar(2), 2)
	assert_eq(arthur.vida, 32)


func test_cura_com_vida_cheia_nao_cura_nada() -> void:
	var arthur := _arthur()
	assert_eq(arthur.curar(2), 0)
	assert_eq(arthur.vida, 40)


func test_escudo_se_acumula_e_zera() -> void:
	var arthur := _arthur()
	arthur.ganhar_escudo(5)
	arthur.ganhar_escudo(5)
	assert_eq(arthur.escudo, 10)
	arthur.zerar_escudo()
	assert_eq(arthur.escudo, 0)


func test_esta_vivo_enquanto_tem_vida() -> void:
	var arthur := _arthur(1)
	assert_true(arthur.esta_vivo())
	arthur.receber_dano(1)
	assert_false(arthur.esta_vivo())
