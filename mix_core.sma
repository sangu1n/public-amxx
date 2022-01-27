#include <amxmodx>
#include <cstrike>
#include <fun>
#include <amxmisc>
#include <hamsandwich>
#include <cs_teams_api>
#include <cromchat>
#include <time>

#define IsPlayer(%1) (1 <= %1 <= 32)

#define MAX_ROUNDS 15
#define MAX_ROUNDS_EXTRA 3
#define INTERVAL_MESAJE 90.0
#define TIMP_VOT_ECHIPE 10.0

#define CMDTARGET_OBEY_IMMUNITY (1<<0)
#define CMDTARGET_ALLOW_SELF	(1<<1)
#define CMDTARGET_ONLY_ALIVE	(1<<2)
#define CMDTARGET_NO_BOTS		(1<<3)

#define DEBUG

new const comenzi_start_mix[][] =
{
	"sv_restart 1",
	"mp_freezetime 10",
	"mp_buytime 0.25",
	"mp_startmoney 800",
	"mp_roundtime 1.75",
	"mp_forcecamera 2",
	"mp_friendlyfire 0",
	"mp_c4timer 35",
	"mp_flashlight 0"
}

new const comenzi_default[][] =
{
	"sv_restart 1",
	"mp_freezetime 1",
	"mp_buytime 0.25",
	"mp_startmoney 800",
	"mp_roundtime 2.00",
	"mp_forcecamera 2",
	"mp_friendlyfire 0",
	"mp_c4timer 35",
	"mp_flashlight 0"
}

new const comenzi_warmup[][] =
{
	"sv_restart 1",
	"mp_freezetime 0",
	"mp_buytime 9999.0",
	"mp_startmoney 16000",
	"mp_roundtime 8.75",
	"mp_forcecamera 2",
	"mp_friendlyfire 0",
	"mp_c4timer 35",
	"mp_flashlight 0"
}

new const comenzi_extra[][] =
{
	"sv_restart 1",
	"mp_freezetime 10",
	"mp_buytime 0.25",
	"mp_startmoney 10000",
	"mp_roundtime 1.75",
	"mp_forcecamera 2",
	"mp_friendlyfire 0",
	"mp_c4timer 35",
	"mp_flashlight 0"
}

new const comenzi_lame[][] =
{
	"sv_restart 1",
	"mp_freezetime 1",
	"mp_buytime 0.1",
	"mp_startmoney 69",
	"mp_roundtime 8.75",
	"mp_forcecamera 2",
	"mp_friendlyfire 0",
	"mp_c4timer 35",
	"mp_flashlight 0"
}

stock const Reclame[][] = 
{
	"Adresa de TeamSpeak: &x05TS.NUME.RO&x01.",
	"Mix-Core by &x05kidd0x &x01(&x05Discord: sangu1n#1886&x01).",
	"Pentru a scoate parola foloseste: &x05/nopass&x01."
}

const afk_task = 213213
new ultimele_pozitii[33][3]

enum _: Echipe
{
	CT,
	CTS,
	T,
	TS
}
new score[Echipe]

enum _: Bools
{
	mix_started,
	extra_started,
	end_round,
	second_part,
	runda_lame_echipa,
	runda_lame_normale,
	proces_votare,
	chat_stats,
	warmup,
	game_paused
}
new bool: g_Bool[Bools]

new bool: has_demo[33]

new hud_sync, count_timer

enum _: Cvars
{
	pause_time,
	afk_time,
	pause_info_mode,
	logs,
	auto_record,
	TAG[25]
}
new cvar[Cvars]

new g_Votes[2]


/******
 * &x07 = red
 * &x06 = blue
 * &x05 = white
 * &x04 = green
 * &x03 = team color
 * &x01 = normal*
 *******/

static const VERSION[] = "1.2-Beta"

public plugin_init()
{
	register_plugin("[kidd0x] Mix Core", VERSION, "kidd0x")

	register_clcmd("say /start", "cmd_start")
	register_clcmd("say /live", "cmd_start")
	register_clcmd("say /stop", "cmd_stop")
	register_clcmd("say /warm", "cmd_warm")
	register_clcmd("say /lame", "cmd_lame")
	register_clcmd("say /knife", "cmd_lame")
	register_clcmd("say /restart", "cmd_restart")
	register_clcmd("say /rr", "cmd_restart")
	register_clcmd("say /specall", "cmd_spec_all")
	register_clcmd("say /pause", "cmd_pause")
	register_clcmd("say /unpause", "cmd_unpause")
	#if defined DEBUG
	register_clcmd("say +ct", "add_ct")
	register_clcmd("say +t", "add_t")
	register_clcmd("say debugx", "debugx")
	#endif
	register_clcmd("amx_t", "transfer_t")
	register_clcmd("amx_ct", "transfer_ct")
	register_clcmd("amx_spec", "transfer_spec")
	register_clcmd("say /on", "cmd_chat_on")
	register_clcmd("say /off", "cmd_chat_off")
	register_clcmd("say /score", "cmd_score")
	register_clcmd("say /mix", "cmd_mix_menu")
	register_clcmd("say /war", "cmd_mix_menu")
	register_clcmd("say /nopass", "cmd_remove_pass")
	register_clcmd("amx_pass", "cmd_add_pass")

	register_clcmd("say", "ClCmdSay")

	new pcvar = create_cvar("mix_core_author", "kidd0x", FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY, "Nu modifica!")

	pcvar = create_cvar("pause_time", "120", FCVAR_NONE, "Durata pentru ^"/pause^" ^nTrebuie setata in secunde!", true, 1.0)
	bind_pcvar_num(pcvar, cvar[pause_time])

	pcvar = create_cvar("afk_time_check", "40", FCVAR_NONE, "Durata pentru verificare AFK (Recomandat e sa fie lasata asa) ^nTrebuie setata in secunde!", true, 30.0)
	bind_pcvar_num(pcvar, cvar[afk_time])

	pcvar = create_cvar("pause_info", "1", FCVAR_NONE, "Metoda afisare timp pauza ^n1 - Mesaj HUD ^n2 - Mesaje PRINT_CENTER", true, 1.0, true, 2.0)
	bind_pcvar_num(pcvar, cvar[pause_info_mode])

	pcvar = create_cvar("create_logs", "1", FCVAR_NONE, "Activare / Dezactivare Loguri ^n0 - Fara loguri  ^n2 - Loguri", _, _, true, 1.0)
	bind_pcvar_num(pcvar, cvar[logs])

	pcvar = create_cvar("auto_start_demo", "1", FCVAR_NONE, "Activare / Dezactivare Demo Automat ^n0 - Nu incepe demo automat  ^n2 - Incepe demo automat", _, _, true, 1.0)
	bind_pcvar_num(pcvar, cvar[auto_record])

	pcvar = create_cvar("chat_messages_tag", "MIX", FCVAR_NONE, "Tagu-ul pentru mesajele in chat (MAXIM 20 CARACTERE & Fara Paranteze) ^nTagul pe chat este automat pus intre ^"[]^"")
	bind_pcvar_string(pcvar, cvar[TAG], charsmax(cvar[TAG]))


	register_cvar("mix_core_version", VERSION, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY)

	register_event("CurWeapon", "doar_cutit", "be", "1=1", "2!29")
	register_event("SendAudio", "EventTeroWin", "a", "2&%!MRAD_terwin")
	register_event("SendAudio", "EventCTWin", "a", "2&%!MRAD_ctwin")
	register_event("CurWeapon", "Hook_CurWeapon", "be", "1=1")

	register_logevent("LogEventRoundEnd", 2, "1=Round_End")
	register_logevent("LogEventRoundStart", 2, "1=Round_Start")

	RegisterHam(Ham_Spawn, "player", "PlayerSpawn", 1)

	set_task(INTERVAL_MESAJE, "display_mesaje", _, _, _,"b")

	hud_sync = CreateHudSyncObj()

	register_dictionary("time.txt")

	AutoExecConfig(true, "config_mix")

}
#if defined DEBUG
public add_t(id) score[T]++
public add_ct(id) score[CT]++
public debugx(id)
{
	client_cmd(id, "toggleconsole")
	client_cmd(id, "clear")
	console_print(id, "g_Bool[mix_started] %s", g_Bool[mix_started] ? "on" : "off")
	console_print(id, "g_Bool[extra_started] %s", g_Bool[extra_started] ? "on" : "off")
	console_print(id, "g_Bool[end_round] %s", g_Bool[end_round] ? "on" : "off")
	console_print(id, "g_Bool[second_part] %s", g_Bool[second_part] ? "on" : "off")
	console_print(id, "g_Bool[runda_lame_echipa] %s", g_Bool[runda_lame_echipa] ? "on" : "off")
	console_print(id, "g_Bool[runda_lame_normale] %s", g_Bool[runda_lame_normale] ? "on" : "off")
	console_print(id, "g_Bool[proces_votare] %s", g_Bool[proces_votare] ? "on" : "off")
	console_print(id, "g_Bool[chat_stats] %s", g_Bool[chat_stats] ? "on" : "off")
	console_print(id, "g_Bool[warmup] %s", g_Bool[warmup] ? "on" : "off")
	console_print(id, "g_Bool[game_paused] %s", g_Bool[game_paused] ? "on" : "off")

}
#endif

public Hook_CurWeapon(id)
{
	if(g_Bool[game_paused])
		set_user_maxspeed(id, 0.1)
}

public cmd_pause(id)
{
	if(!is_ok(id))
	{
		CC_SendMessage(id, "&x04[%s] &x01Nu ai acces la aceasta comanda!", cvar[TAG])
		return 1
	}

	if(!g_Bool[mix_started])
	{
		CC_SendMessage(id, "&x04[%s] &x01Mixul nu a inceput, nu poti folosi aceasta comanda acum!", cvar[TAG])
		return 1
	}

	if(g_Bool[game_paused])
	{
		CC_SendMessage(id, "&x04[%s] &x01Jocul este deja pe pauza!", cvar[TAG])
		return 1
	}

	g_Bool[game_paused] = true

	new iPlayers[32], iNum, id
	get_players(iPlayers, iNum, "ch")

	for(new i = 0; i < iNum; i++)
	{
		id = iPlayers[i]

		set_user_maxspeed(id, 0.1)
	}

	if(cvar[logs])
		CC_LogMessage(0, "mix_logs.txt", "&x04[%s] &x07%s &x01a pus pauza!", cvar[TAG], get_name(id))
	else
		CC_SendMessage(0, "&x04[%s] &x07%s &x01a pus pauza!", cvar[TAG], get_name(id))
	

	set_task(float(cvar[pause_time]), "StopPause", 123321)
	set_task(1.0, "ShowTimeRemaining", 13379501, _, _, "a", cvar[pause_time])
	
	client_cmd(0, "speak scientist/stop4.wav")
	
	return PLUGIN_CONTINUE
}

public ShowTimeRemaining()
{
	count_timer++

	new iTimer = cvar[pause_time] - count_timer

	new szTimeLenght[128]
	get_time_length(0, iTimer, timeunit_seconds, szTimeLenght, charsmax(szTimeLenght))

	set_hudmessage(42, 42, 255, -1.0, 0.87, 0, 6.0, 2.0)

	switch(cvar[pause_info_mode])
	{
		case 1: ShowSyncHudMsg(0, hud_sync, "Timp ramas pana ce expira pauza^n%s", szTimeLenght)
		case 2: client_print(0, print_center, "Timp ramas pana ce expira pauza^r%s", szTimeLenght)
	}

	if(iTimer <= 10)
	{
		new szNumToWord[20]
		num_to_word(iTimer, szNumToWord, charsmax(szNumToWord))
		
		client_cmd( 0, "speak ^"fvox/%s^"", szNumToWord)
	}
}

public StopPause()
{
	new iPlayers[32], iNum, id
	get_players(iPlayers, iNum, "ch")

	for(new i = 0; i < iNum; i++)
	{
		id = iPlayers[i]

		reset_client_maxspeed(id)
	}

	if(task_exists(13379501))
		remove_task(13379501)

	if(task_exists(123321))
		remove_task(123321)

	g_Bool[game_paused] = false
	count_timer = 0

	CC_SendMessage(0, "&x04[%s] &x01Timpul a expirat, pauza a fost oprita!", cvar[TAG])
	client_cmd(0, "speak barney/letsgo.wav")

}

public cmd_unpause(id)
{
	if(!is_ok(id))
	{
		CC_SendMessage(id, "&x04[%s] &x01Nu ai acces la aceasta comanda!", cvar[TAG])
		return 1
	}

	if(!g_Bool[game_paused])
	{
		CC_SendMessage(id, "&x04[%s] &x01Nu este pauza!", cvar[TAG])
		return 1
	}

	g_Bool[game_paused] = false
	count_timer = 0

	new iPlayers[32], iNum, id
	get_players(iPlayers, iNum, "ch")

	for(new i = 0; i < iNum; i++)
	{
		id = iPlayers[i]

		reset_client_maxspeed(id)
	}

	if(cvar[logs])
		CC_LogMessage(0, "mix_logs.txt", "&x04[%s] &x07%s &x01a anulat pauza!", cvar[TAG], get_name(id))
	else
		CC_SendMessage(0, "&x04[%s] &x07%s &x01a anulat pauza!", cvar[TAG], get_name(id))

	if(task_exists(13379501))
		remove_task(13379501)

	if(task_exists(123321))
		remove_task(123321)

	client_cmd(0, "speak barney/letsgo.wav")

	return PLUGIN_CONTINUE
}

public cmd_mix_menu(id)
{
	if(!is_ok(id))
	{
		CC_SendMessage(id, "&x04[%s] &x01Nu ai acces la aceasta comanda!", cvar[TAG])
		return 1
	}

	new menu = menu_create("\r[MIX] \wMeniu Administrare Mix", "mix_menu_handler")

	/*---------------------- [RUNDA LAME] ----------------------*/

	menu_additem(menu, "Runda Lame", "0", 0)

	/*---------------------- [RUNDA WARMUP] ----------------------*/

	menu_additem(menu, "Runda WarmUP", "1", 0)

	/*---------------------- [START JOC] ----------------------*/

	menu_additem(menu, "Start MIX", "2", 0)

	/*---------------------- [OPRESTE JOC] ----------------------*/

	menu_additem(menu, "Opreste MIX", "3", 0)

	/*---------------------- [RESTART JOC] ----------------------*/

	menu_additem(menu, "Restart", "4", 0)

	/*---------------------- [SPEC ALL] ----------------------*/

	menu_additem(menu, "Spec ALL", "5", 0)

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
 
	return PLUGIN_HANDLED
}
public mix_menu_handler(id, menu, item)
{
	if(!is_ok(id))
	{
		CC_SendMessage(id, "&x04[%s] &x01Nu ai acces la aceasta comanda!", cvar[TAG])
		return 1
	}

	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	switch(item)
	{
		case 0: cmd_lame(id)
		case 1: cmd_warm(id)	
		case 2: cmd_start(id)
		case 3: cmd_stop(id)
		case 4: cmd_restart(id)
		case 5: cmd_spec_all(id)
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED

}

/**********************[ COMENZI MIX ]**********************/
public doar_cutit(id)
{
	if(g_Bool[runda_lame_normale] || g_Bool[runda_lame_echipa])
		engclient_cmd(id, "weapon_knife")
}

public client_connect(id)
{
	has_demo[id] = false
}

public client_putinserver(id)
{
	remove_task(id, afk_task)
	set_task(float(cvar[afk_time]), "verifica_afk", id + afk_task)
}

public client_disconnected(id)
{
	remove_task(id + afk_task)
}

public PlayerSpawn(id)
{
	if(g_Bool[warmup] && !g_Bool[mix_started])
	{
		if(IsPlayer(id))
		{

				give_item(id, "weapon_ak47")
				give_item(id, "weapon_deagle")
				give
				cs_set_user_bpammo(id, CSW_AK47, 250)
				cs_set_user_bpammo(id, CSW_DEAGLE, 250)
				cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM)
				give_item(id, "weapon_m4a1")
				cs_set_user_bpammo(id, CSW_M4A1, 255)

		}
	}
}

public cmd_remove_pass(id)
{
	if(!is_ok(id))
	{
		CC_SendMessage(id, "&x04[%s] &x01Nu ai acces la aceasta comanda!", cvar[TAG])
		return 1
	}

	if(cvar[logs])
		CC_LogMessage(0, "mix_logs.txt", "&x04[%s] &x07%s &x01a scos parola de pe server!", TAG, get_name(id))
	else
		CC_SendMessage(0, "%s &x07%s &x01a scos parola de pe server!", cvar[TAG], get_name(id))

	server_cmd("sv_password ^"^"")

	return 1
}

public cmd_add_pass(id)
{
	if(!is_ok(id))
	{
		CC_SendMessage(id, "&x04[%s] &x01Nu ai acces la aceasta comanda!", cvar[TAG])
		return 1
	}

	new szArgs[32]
	read_argv(1, szArgs, charsmax(szArgs))

	if(equali(szArgs[0], ""))
	{
		console_print(id, "[*] Parola trebuie sa contina cel mult 1 caracter!", cvar[TAG])
		return 1
	}

	if(cvar[logs])
		CC_LogMessage(0, "mix_logs.txt", "&x04[%s] &x07%s &x01a setat parola serverului: &x07%s&x01!", cvar[TAG], get_name(id), szArgs)
	else
		CC_SendMessage(0, "&x04[%s] &x07%s &x01a setat parola serverului: &x07%s&x01!", cvar[TAG], get_name(id), szArgs)


	server_cmd("sv_password ^"%s^"", szArgs)

	return 1
}


public cmd_score(id)
{
	if(g_Bool[mix_started])
		CC_SendMessage(id, "&x04[%s] &x04Terrorists &x01[&x05%d&x01] - [&x05%d&x01] &x04Counter-Terrorists", cvar[TAG], score[T], score[CT])
	else
		CC_SendMessage(id, "&x04[%s] Meciul nu a inceput inca!", cvar[TAG])
}

public cmd_restart(id)
{
	if(!is_ok(id))
	{
		CC_SendMessage(id, "&x04[%s] &x01Nu ai acces la aceasta comanda!", cvar[TAG])
		return 1
	}

	if(!g_Bool[mix_started] && !g_Bool[second_part] && !g_Bool[extra_started])
	{
		if(g_Bool[runda_lame_echipa] || g_Bool[proces_votare])
		{
			if(cvar[logs])
				CC_LogMessage(0, "mix_logs.txt", "&x04[%s] &x07%s &x01a dat restart la runda de alegeri!", cvar[TAG], get_name(id))
			else
				CC_SendMessage(0, "&x04[%s] &x07%s &x01a dat restart la runda de alegeri!", cvar[TAG], get_name(id))

			g_Bool[mix_started] = false
			g_Bool[runda_lame_echipa] = false
			g_Bool[proces_votare] = false
			g_Bool[chat_stats] = true

			cmd_start(id)
			carr()
			show_menu(id, 0, "^n", 1)
		}
		else
		{
			score[T] = 0
			score[CT] = 0

			g_Bool[runda_lame_normale] = false
			g_Bool[mix_started] = false
			g_Bool[second_part] = false
			g_Bool[warmup] = false
			g_Bool[chat_stats] = true

			if(cvar[logs])
				CC_LogMessage(0, "mix_logs.txt", "&x04[%s] &x07%s &x01a dat restart!", cvar[TAG], get_name(id))
			else
				CC_SendMessage(0, "&x04[%s] &x07%s &x01a dat restart!", cvar[TAG], get_name(id))
		
			_setari_default()

		}

	}
	else if(g_Bool[mix_started])
	{
		if(g_Bool[runda_lame_echipa] || g_Bool[proces_votare])
		{
			if(cvar[logs])
				CC_LogMessage(0, "mix_logs.txt", "&x04[%s] &x07%s &x01a dat restart la runda de alegeri!", cvar[TAG], get_name(id))
			else
				CC_SendMessage(0, "&x04[%s] &x07%s &x01a dat restart la runda de alegeri!", cvar[TAG], get_name(id))

			g_Bool[mix_started] = false
			g_Bool[runda_lame_echipa] = false
			g_Bool[proces_votare] = false
			g_Bool[chat_stats] = true

			cmd_start(id)
			carr()
			show_menu(id, 0, "^n", 1)
		}

		if(!g_Bool[second_part])
		{
			score[CT] = 0
			score[T] = 0
			score[CTS] = 0
			score[TS] = 0

			g_Bool[runda_lame_normale] = false
			g_Bool[mix_started] = true
			g_Bool[second_part] = false
			g_Bool[extra_started] = false
			g_Bool[chat_stats] = false
			g_Bool[game_paused] = false


			if(cvar[logs])
				CC_LogMessage(0, "mix_logs.txt", "&x04[%s] &x07%s &x01a repornit prima parte a meciului!", cvar[TAG], get_name(id))
			else
				CC_SendMessage(0, "&x04[%s] &x07%s &x01a repornit prima parte a meciului!", cvar[TAG], get_name(id))

			_setari_mix()

		}
		else if(g_Bool[second_part])
		{
			score[CT] = score[CTS]
			score[T] = score[TS]
			g_Bool[mix_started] = true
			g_Bool[extra_started] = false
			g_Bool[chat_stats] = false
			g_Bool[game_paused] = false

			if(cvar[logs])
				CC_LogMessage(0, "mix_logs.txt", "&x04[%s] &x07%s &x01a repornit a II a parte a meciului!", cvar[TAG], get_name(id))
			else
				CC_SendMessage(0, "&x04[%s] &x07%s &x01a repornit a II a parte a meciului!", cvar[TAG], get_name(id))

			_setari_mix()
		}
		else if(g_Bool[extra_started] && !g_Bool[second_part])
		{
			score[CT] = 0
			score[T] = 0
			score[CTS] = 0
			score[TS] = 0

			g_Bool[runda_lame_normale] = false
			g_Bool[extra_started] = true
			g_Bool[mix_started] = true
			g_Bool[second_part] = false
			g_Bool[chat_stats] = false
			g_Bool[game_paused] = false


			if(cvar[logs])
				CC_LogMessage(0, "mix_logs.txt", "&x04[%s] &x07%s &x01a repornit prima parte a rundelor extra!", cvar[TAG], get_name(id))
			else
				CC_SendMessage(0, "&x04[%s]  &x07%s &x01a repornit prima parte a rundelor extra!", cvar[TAG], get_name(id))

			_setari_extra()
		}
		else if(g_Bool[extra_started] && g_Bool[second_part])
		{
			score[CT] = score[CTS]
			score[T] = score[TS]

			g_Bool[runda_lame_normale] = false

			g_Bool[extra_started] = true
			g_Bool[mix_started] = true
			g_Bool[second_part] = true
			g_Bool[chat_stats] = false
			g_Bool[game_paused] = false


			if(cvar[logs])
				CC_LogMessage(0, "mix_logs.txt", "&x04[%s] &x07%s &x01a repornit a II a parte a rundelor extra!", cvar[TAG], get_name(id))
			else
				CC_SendMessage(0, "&x04[%s] &x07%s &x01a repornit a II a parte a rundelor extra!", cvar[TAG], get_name(id))

			_setari_extra()
		}
	}
	server_cmd("sv_restart 1")
	return 1
}

public cmd_lame(id)
{
	if(!is_ok(id))
	{
		CC_SendMessage(id, "&x04[%s] &x01Nu ai acces la aceasta comanda!", cvar[TAG])
		return 1
	}

	if(g_Bool[mix_started])
	{
		CC_SendMessage(id, "&x04[%s] &x01Nu poti porni runda de lame in timpul meciului!", cvar[TAG])
		return 1
	}

	if(g_Bool[runda_lame_echipa] || g_Bool[proces_votare])
	{
		CC_SendMessage(id, "&x04[%s] &x01Nu poti porni runda de lame in timpul alegerilor!", cvar[TAG])
		return 1
	}

	if(cvar[logs])
				CC_LogMessage(0, "mix_logs.txt", "&x04[%s] &x07%s &x01a pornit runda de lame!", cvar[TAG], get_name(id))
			else
				CC_SendMessage(0, "&x04[%s] &x07%s &x01a pornit runda de lame!", cvar[TAG], get_name(id))

	g_Bool[runda_lame_normale] = true
	_setari_lame()
	strip_user_weapons(id)

	return 1
}

public incepe_joc(id)
{
	if(!is_ok(id))
	{
		CC_SendMessage(id, "&x04[%s] &x01Nu ai acces la aceasta comanda!", cvar[TAG])
		return 1
	}

	if(!g_Bool[second_part])
	{
		if(g_Bool[mix_started])
		{
			CC_SendMessage(id, "&x04[%s] &x01Meciul este deja pornit!", cvar[TAG])
			return 1
		}
		score[CT] = 0
		score[CTS] = 0
		score[T] = 0
		score[TS] = 0
		g_Bool[runda_lame_normale] = false
		g_Bool[mix_started] = true
		g_Bool[extra_started] = false
		g_Bool[second_part] = false
		g_Bool[warmup] = false
		g_Bool[chat_stats] = false

		_setari_mix()

		CC_SendMessage(0, "&x06Prima parte a meciului a inceput!")
		CC_SendMessage(0, "&x07LIVE LIVE LIVE")
		CC_SendMessage(0, "&x07GOOD LUCK & HAVE FUN")

		if(cvar[auto_record])
			record_demo()
	}
	else if(g_Bool[second_part])
	{
		if(g_Bool[mix_started])
		{
			CC_SendMessage(id, "&x04[%s] &x01Meciul este deja pornit!", cvar[TAG])
			return 1
		}

		g_Bool[runda_lame_normale] = false
		g_Bool[mix_started] = true
		g_Bool[extra_started] = false
		g_Bool[second_part] = true
		g_Bool[warmup] = false
		g_Bool[chat_stats] = false


		_setari_mix()

		CC_SendMessage(0, "&x06A II a parte a meciului a inceput!")
		CC_SendMessage(0, "&x07LIVE LIVE LIVE")
		CC_SendMessage(0, "&x07GOOD LUCK & HAVE FUN")

	}
	return 1
}

public cmd_warm(id)
{
	if(!is_ok(id))
	{
		CC_SendMessage(id, "&x04[%s] &x01Nu ai acces la aceasta comanda!", cvar[TAG])
		return 1
	}

	if(g_Bool[mix_started])	
	{
		CC_SendMessage(id, "&x04[%s] &x01Meciul este deja pornit!", cvar[TAG])
		return 1
	}

	if(g_Bool[runda_lame_echipa] || g_Bool[proces_votare])
	{
		CC_SendMessage(id, "&x04[%s] &x01Nu poti porni runda de warmup in timpul alegerilor!", cvar[TAG])
		return 1
	}

	score[T] = 0
	score[CT] = 0
	g_Bool[runda_lame_normale] = false

	g_Bool[mix_started] = false
	g_Bool[extra_started] = false
	g_Bool[second_part] = false
	g_Bool[warmup] = true
	g_Bool[chat_stats] = true

	if(cvar[logs])
		CC_LogMessage(0, "mix_logs.txt", "&x04[%s] &x07%s &x01a pornit runda de WarmUP!", cvar[TAG], get_name(id))
	else
		CC_SendMessage(0, "&x04[%s] &x07%s &x01a pornit runda de WarmUP!", cvar[TAG], get_name(id))


	_setari_warmup()

	return 1
}

public cmd_stop(id)
{
	if(!is_ok(id))
	{
		CC_SendMessage(id, "&x04[%s] &x01Nu ai acces la aceasta comanda!", cvar[TAG])
		return 1
	}

	if(!g_Bool[mix_started])	
	{
		if(g_Bool[runda_lame_echipa] || g_Bool[proces_votare])
		{
			if(cvar[logs])
				CC_LogMessage(0, "mix_logs.txt", "&x04[%s] &x07%s &x01a oprit runda de alegeri!", cvar[TAG], get_name(id))
			else
				CC_SendMessage(0, "&x04[%s] &x07%s &x01a oprit runda de alegeri!", cvar[TAG], get_name(id))

			server_cmd("sv_restart 1")
			g_Bool[runda_lame_echipa] = false
			g_Bool[proces_votare] = false

			carr()
			show_menu(id, 0, "^n", 1)
		}
		else
		{
			CC_SendMessage(id, "&x04[%s] &x01Meciul nu a inceput inca!", cvar[TAG])
			return 1
		}
		
	}
	else if(g_Bool[mix_started])
	{
		score[T] = 0
		score[TS] = 0
		score[CT] = 0
		score[CTS] = 0
		g_Bool[mix_started] = false
		g_Bool[extra_started] = false
		g_Bool[second_part] = false
		g_Bool[warmup] = false
		g_Bool[chat_stats] = true
		g_Bool[game_paused] = false

		if(cvar[logs])
			CC_LogMessage(0, "mix_logs.txt", "&x04[%s] &x07%s &x01a oprit meciul!", cvar[TAG], get_name(id))
		else
			CC_SendMessage(0, "&x04[%s] &x07%s &x01a oprit meciul!", cvar[TAG], get_name(id))

		carr()
		_setari_default()

		server_cmd("sv_password ^"^"")
		stop_demo()
	}
	
	return 1
}

public LogEventRoundStart()
{
	g_Bool[end_round] = false
}

public EventTeroWin()
{
	if(g_Bool[mix_started] && !g_Bool[end_round])
	{
		g_Bool[end_round] = true
		score[T]++
	}
}

public EventCTWin()
{
	if(g_Bool[mix_started] && !g_Bool[end_round])
	{
		g_Bool[end_round] = true
		score[CT]++
	}
}

public LogEventRoundEnd()
{
	if(g_Bool[mix_started])
	{
		if(!g_Bool[extra_started])
		{
			if(score[T] + score[CT] == MAX_ROUNDS)
			{
				SchimbaEchipe()
				_setari_mix()

				new alt = score[T]
				score[T] = score[CT]
				score[CT] = alt

				score[TS] = score[T]
				score[CTS] = score[CT]

				g_Bool[second_part] = true
				g_Bool[mix_started] = true
				g_Bool[extra_started] = false
				g_Bool[chat_stats] = false


				CC_SendMessage(0, "&x04[%s] &x01A pornit a II a parte a meciului!", cvar[TAG])

			}
		}

		if(score[T] >= MAX_ROUNDS + 1)
		{
			CC_SendMessage(0, "&x04[%s] &x01Echipa Terro a castigat meciul cu %d la %d", cvar[TAG], score[T], score[CT])

			_setari_default()
			server_cmd("sv_password ^"^"")

			score[T] = 0
			score[CT] = 0
			score[CTS] = 0
			score[TS] = 0

			g_Bool[second_part] = false
			g_Bool[mix_started] = false
			g_Bool[extra_started] = false
			g_Bool[chat_stats] = true

		}
		else if(score[CT] >= MAX_ROUNDS + 1)
		{
			CC_SendMessage(0, "&x04[%s] &x01Echipa CT a castigat meciul cu %d la %d", cvar[TAG], score[CT], score[T])

			_setari_default()
			server_cmd("sv_password ^"^"")

			score[T] = 0
			score[CT] = 0
			score[CTS] = 0
			score[TS] = 0

			g_Bool[second_part] = false
			g_Bool[mix_started] = false
			g_Bool[extra_started] = false
			g_Bool[chat_stats] = true

		}

		else if(score[T] == MAX_ROUNDS && score[CT] == MAX_ROUNDS)
		{
			SchimbaEchipe()

			CC_SendMessage(0, "&x04[%s] &x01Meciul s-a terminat egal!", cvar[TAG])
			CC_SendMessage(0, "&x04[%s] &x01Incep prelungirile!", cvar[TAG])

			score[T] = 0
			score[CT] = 0
			score[CTS] = 0
			score[TS] = 0
			g_Bool[runda_lame_normale] = false

			g_Bool[mix_started] = true
			g_Bool[extra_started] = true
			g_Bool[second_part] = false

			_setari_extra()

		}
		if(g_Bool[extra_started])
		{
			if(score[T] + score[CT] == MAX_ROUNDS_EXTRA)
			{
				SchimbaEchipe()

				CC_SendMessage(0, "&x04[%s] &x01Meciul s-a terminat egal!", cvar[TAG])
				CC_SendMessage(0, "&x04[%s] &x01Incep prelungirile!", cvar[TAG])

				_setari_extra()

				new altx = score[T]
				score[T] = score[CT]
				score[CT] = altx

				score[TS] = score[T]
				score[CTS] = score[CT]

				g_Bool[second_part] = true
				g_Bool[mix_started] = true
				g_Bool[extra_started] = true
				g_Bool[chat_stats] = false

			}
			if(score[T] >= MAX_ROUNDS_EXTRA + 1)
			{
				CC_SendMessage(0, "&x04[%s] &x01Echipa Terro a castigat meciul cu %d la %d", cvar[TAG], score[T], score[CT])

				_setari_default()
				server_cmd("sv_password ^"^"")
				stop_demo()

				score[T] = 0
				score[CT] = 0
				score[TS] = 0
				score[CTS] = 0

				g_Bool[mix_started] = false
				g_Bool[second_part] = false
				g_Bool[extra_started] = false
				g_Bool[chat_stats] = true


				return 1
			}
			else if(score[CT] >= MAX_ROUNDS_EXTRA + 1)
			{
				CC_SendMessage(0, "&x04[%s] &x01Echipa CT a castigat meciul cu %d la %d", cvar[TAG], score[CT], score[T])

				_setari_default()
				server_cmd("sv_password ^"^"")
				stop_demo()

				score[T] = 0
				score[CT] = 0
				score[TS] = 0
				score[CTS] = 0

				g_Bool[mix_started] = false
				g_Bool[second_part] = false
				g_Bool[extra_started] = false
				g_Bool[chat_stats] = true


				return 1

			}
			else if(score[T] == MAX_ROUNDS_EXTRA && score[CT] == MAX_ROUNDS_EXTRA)
			{
				SchimbaEchipe()

				CC_SendMessage(0, "&x04[%s] &x01relungirile s-au terminat egal!", cvar[TAG])
				CC_SendMessage(0, "&x04[%s] &x01Incep urmatoarele runde de prelungiri!", cvar[TAG])

				score[T] = 0
				score[CT] = 0
				score[TS] = 0
				score[CTS] = 0
				g_Bool[runda_lame_normale] = false

				g_Bool[mix_started] = true
				g_Bool[extra_started] = true
				g_Bool[second_part] = false
				g_Bool[chat_stats] = true

				_setari_extra()
			}
		}
		CC_SendMessage(0, "&x04[%s] &x04Terrorists &x01[&x05%d&x01] - [&x05%d&x01] &x04Counter-Terrorists", cvar[TAG], score[T], score[CT])
	}

	if(g_Bool[runda_lame_echipa])
	{
		new iPlayers[ 32 ], iNum;
		get_players(iPlayers, iNum, "ae", "TERRORIST")

		if(!iNum) 
		{
			CC_SendMessage(0, "&x04[%s] &x01Echipa CT a castigat runda de alegeri!", cvar[TAG])
			set_task(0.1, "vote_ct")
		}
		else
		{
			CC_SendMessage(0, "&x04[%s] &x01Echipa Terro a castigat runda de alegeri!", cvar[TAG])
			set_task(0.1, "vote_t")
		}
		g_Bool[runda_lame_echipa] = false
	}
	return 1
}

/*********************************************************
 *  			Runda Lame Alegeri Echipe
 *********************************************************/
public cmd_start(id)
{
	if(!is_ok(id))
	{
		CC_SendMessage(id, "&x04[%s] &x01Nu ai acces la aceasta comanda!", cvar[TAG])
		return 1
	}

	if(g_Bool[mix_started] || g_Bool[runda_lame_echipa] || g_Bool[proces_votare])
	{
		CC_SendMessage(id, "&x04[%s] &x01Meciul a inceput deja!", cvar[TAG])
		return 1
	}

	carr()
	alegere_echipe_ssd(id)
	set_task(0.1, "IncepeRundaDeAlegereEchipe", id)

	CC_SendMessage(0, "&x04[%s] &x01Runda pentru alegerea echipelor a inceput!", cvar[TAG])

	g_Bool[mix_started] = false
	g_Bool[extra_started] = false
	g_Bool[second_part] = false
	g_Bool[warmup] = false


	return PLUGIN_CONTINUE
}

public ShowMenu(id)
{
	g_Bool[proces_votare] = true

	carr()

	if(g_Bool[proces_votare])
	{
		new menu = menu_create("\r[MIX] \wSchimbi Echipa?", "show_menu_handler")

		menu_additem(menu, "\yDa", "", 0)
		menu_additem(menu, "\yNu", "", 0)

		menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
		menu_display(id, menu, 0)
	}
	return PLUGIN_HANDLED
}


public show_menu_handler(id, menu, item)
{
	if(!g_Bool[proces_votare]) return 1

	switch(item)
	{
		case 0:
		{
			g_Votes[0]++

			if(cs_get_user_team(id) == CS_TEAM_T)
				CC_GroupMessage("ae", "TERRORIST", "&x07%s &x01a ales sa schimbe echipa.", get_name(id))
			else if(cs_get_user_team(id) == CS_TEAM_CT)
				CC_GroupMessage("ae", "CT", "&x07%s &x01a ales sa schimbe echipa.", get_name(id))
		}
		case 1:
		{
			g_Votes[1]++
			
			if(cs_get_user_team(id) == CS_TEAM_T)
				CC_GroupMessage("ae", "TERRORIST", "&x07%s &x01a ales sa ramana.", get_name(id))
			else if(cs_get_user_team(id) == CS_TEAM_CT)
				CC_GroupMessage("ae", "CT", "&x07%s &x01a ales sa ramana.", get_name(id))
		}
	}
	return 1
}

public FinishVote()
{
	if(!g_Bool[proces_votare]) return 1

	server_cmd("sv_restart 1")
	
	if(g_Votes[0] > g_Votes[1])
	{
		CC_SendMessage(0, "&x04[%s] &x01Echipele au fost schimbate! Meciul incepe in 5 secunde!", cvar[TAG])
		SchimbaEchipe()
	}
	else
	{
		CC_SendMessage(0, "&x04[%s] &x01Echipele nu au fost schimbate! Meciul incepe in 5 secunde!", cvar[TAG])
	}

	carr()


	g_Bool[proces_votare] = false
	g_Bool[runda_lame_echipa] = false

	set_task(5.0, "incepe_joc")
	return 1
}

public carr() arrayset(g_Votes, 0, charsmax(g_Votes))

public alegere_echipe_ssd(id)
{
	server_cmd("sv_restart 1")
	g_Bool[mix_started] = false
	g_Bool[second_part] = false
	g_Bool[extra_started] = false
	g_Bool[runda_lame_echipa] = false
}

public IncepeRundaDeAlegereEchipe()
{
	g_Bool[runda_lame_echipa] = true
	g_Bool[proces_votare] = false

	new iPlayers[32], iNum, id
	get_players(iPlayers, iNum)
	{
		for(new i = 0; i < iNum; i++)
		{
			id = iPlayers[i]
			doar_cutit(id)
		}
	}
}

public SchimbaEchipe()
{
	new iPlayers[32], iNum, id
	get_players(iPlayers, iNum, "h")

	for(new i = 0; i < iNum; i++)
	{
		id = iPlayers[i]

		if(cs_get_user_team(id) == CS_TEAM_T)
			cs_set_player_team(id, CS_TEAM_CT)
		else if(cs_get_user_team(id) == CS_TEAM_CT)
			cs_set_player_team(id, CS_TEAM_T)
	}
}

public vote_t()
{
	for(new i = 1; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_T)
		{
			ShowMenu(i)
		}
	}
	set_task(TIMP_VOT_ECHIPE, "FinishVote")
}
public vote_ct()
{
	for(new i = 1; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_CT)
		{
			ShowMenu(i)
		}
	}
	set_task(TIMP_VOT_ECHIPE, "FinishVote")
}

public display_mesaje()
{
	new Buff[256]
	formatex(Buff, charsmax(Buff), "%s", Reclame[random(sizeof Reclame)])

	CC_SendMessage(0, "&x04[%s] &x01%s", cvar[TAG], Buff)
}

public ClCmdSay(id)
{
	if(!(get_user_flags(id) & ADMIN_KICK) && !g_Bool[chat_stats])
	{
		static szArgs[192]
		read_args(szArgs, charsmax(szArgs))

		if(!szArgs[0])
			return PLUGIN_CONTINUE

		if(!g_Bool[chat_stats])
			CC_SendMessage(id, "&x04[%s] &x01Chat-ul a fost blocat! Folositi functia say_team!", cvar[TAG])

		return g_Bool[chat_stats] ? PLUGIN_CONTINUE : PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public cmd_chat_on(id)
{
	if(!is_ok(id))
	{
		CC_SendMessage(id, "&x04[%s] &x01Nu ai acces la aceasta comanda!", cvar[TAG])
		return 1
	}

	if(g_Bool[chat_stats])
	{
		CC_SendMessage(id, "&x04[%s] &x01Chat-ul este deja deblocat!", cvar[TAG])
		return 1
	}

	if(cvar[logs])
		CC_LogMessage(0, "mix_logs.txt", "&x04[%s] &x07%s &x01a deblocat chatul!", cvar[TAG], get_name(id))
	else
		CC_SendMessage(0, "&x04[%s] &x07%s &x01a deblocat chatul!", cvar[TAG], get_name(id))

	g_Bool[chat_stats] = true

	return PLUGIN_CONTINUE
}

public cmd_chat_off(id)
{
	if(!is_ok(id))
	{
		CC_SendMessage(id, "&x04[%s] &x01Nu ai acces la aceasta comanda!", cvar[TAG])
		return 1
	}

	if(!g_Bool[chat_stats])
	{
		CC_SendMessage(id, "&x04[%s] &x01Chat-ul este deja blocat!", cvar[TAG])
		return 1
	}

	if(cvar[logs])
		CC_LogMessage(0, "mix_logs.txt", "&x04[%s] &x07%s &x01a blocat chatul!", cvar[TAG], get_name(id))
	else
		CC_SendMessage(0, "&x04[%s] &x07%s &x01a blocat chatul!", cvar[TAG], get_name(id))

	g_Bool[chat_stats] = false

	return PLUGIN_CONTINUE
}

public record_demo()
{
	new iPlayers[32], iNum, id
	get_players(iPlayers, iNum, "h")

	new time[32]
	new map[32]
	new demo[256]

	get_mapname(map, charsmax(map))
	get_time("%d-%m-%Y_%H-%M", time, charsmax(time))

	for(new i = 0; i < iNum; i++)
	{
		id = iPlayers[i]

		if(is_user_connected(id))
		{
			if(cs_get_user_team(id) != CS_TEAM_SPECTATOR)
			{
				formatex(demo, sizeof(demo), "CT_vs_T_%s_%s", time, map)

				client_cmd(id, "stop; record ^"%s^"", demo)
			}
		}
	}
	CC_SendMessage(0, "&x04[%s] &x01Inregistrare demo: &x05%s &x01.", cvar[TAG], demo)

}

public stop_demo()
{
	new iPlayers[32], iNum, id
	get_players(iPlayers, iNum, "h")

	for(new i = 0; i < iNum; i++)
	{
		id = iPlayers[i]
		if(is_user_connected(id))
			client_cmd(id, "stop")
	}
}

public cmd_spec_all(id)
{
	if(!is_ok(id))
	{
		CC_SendMessage(id, "&x04[%s] &x01Nu ai acces la aceasta comanda!", cvar[TAG])
		return 1
	}

	if(g_Bool[mix_started] || g_Bool[runda_lame_echipa] || g_Bool[proces_votare])
	{
		CC_SendMessage(id, "&x04[%s] &x01Nu poti pune jucatorii la Specator in timpul meciului!", cvar[TAG])
		return 1
	}

	new iPlayers[32], iNum, id

	get_players(iPlayers, iNum, "h")

	for(new i = 0; i < iNum; i++)
	{
		id = iPlayers[i]

		user_kill(id, 0)
		cs_set_player_team(id, CS_TEAM_SPECTATOR)
	}

	if(cvar[logs])
		CC_LogMessage(0, "mix_logs.txt", "&x04[%s] &x07%s &x01a mutat toti jucatorii la Spectator!", cvar[TAG], get_name(id))
	else
		CC_SendMessage(0, "&x04[%s] &x07%s &x01a mutat toti jucatorii la Spectator!", cvar[TAG], get_name(id))

	return 1
}

public transfer_t(id)
{
	if(!is_ok(id))
	{
		console_print(id, "&x04[%s] &x01Nu ai acces la aceasta comanda!", cvar[TAG])
		return 1
	}

	new argument[32]
	read_argv(1, argument, charsmax(argument))

	new player = cmd_target(id, argument, CMDTARGET_NO_BOTS | CMDTARGET_ALLOW_SELF)

	if(!player) 
		return 1

	if(cs_get_user_team(player) == CS_TEAM_T)
	{
		CC_SendMessage(id, "&x04[%s] &x01Jucatorul &x07%s &x01este deja la Terro!", cvar[TAG], get_name(player))
		return 1
	}

	cs_set_player_team(player, CS_TEAM_T)

	user_silentkill(player)

	CC_SendMessage(0, "&x04[%s] &x07%s &x01l-a mutat pe &x07%s &x01la Terro!", cvar[TAG], get_name(id), get_name(player))

	return 1


}

public transfer_ct(id)
{
	if(!is_ok(id))
	{
		console_print(id, "&x04[%s] &x01Nu ai acces la aceasta comanda!", cvar[TAG])
		return 1
	}

	new argument[32]
	read_argv(1, argument, charsmax(argument))

	new player = cmd_target(id, argument, CMDTARGET_NO_BOTS | CMDTARGET_ALLOW_SELF)

	if(!player) 
		return 1

	if(cs_get_user_team(player) == CS_TEAM_CT)
	{
		CC_SendMessage(id, "&x04[%s] &x01Jucatorul &x07%s &x01este deja la CT!", cvar[TAG], get_name(player))
		return 1
	}

	cs_set_player_team(player, CS_TEAM_CT)

	user_silentkill(player)

	CC_SendMessage(0, "&x04[%s] &x07%s &x01l-a mutat pe &x07%s &x01la CT!", cvar[TAG], get_name(id), get_name(player))

	return 1

}

public transfer_spec(id)
{
	if(!is_ok(id))
	{
		console_print(id, "&x04[%s] &x01 Nu ai acces la aceasta comanda!", cvar[TAG])
		return 1
	}

	new argument[32]
	read_argv(1, argument, charsmax(argument))

	new player = cmd_target(id, argument, CMDTARGET_NO_BOTS | CMDTARGET_ALLOW_SELF)

	if(!player) 
		return 1

	if(cs_get_user_team(player) == CS_TEAM_SPECTATOR)
	{
		CC_SendMessage(id, "&x04[%s] &x01Jucatorul &x07%s &x01este deja la Spectatori!", cvar[TAG], get_name(player))
		return 1
	}

	cs_set_player_team(player, CS_TEAM_SPECTATOR)

	user_silentkill(player)

	CC_SendMessage(0, "&x04[%s] &x07%s &x01l-a mutat pe &x07%s &x01la Spectatori!", cvar[TAG], get_name(id), get_name(player))

	return 1

}

public verifica_afk(TaskID)
{
	new id = TaskID - afk_task

	if(!is_user_alive(id))
	{
		set_task(float(cvar[afk_time]), "verifica_afk", TaskID)
		return
	}

	new origine[3]
	get_user_origin(id, origine)

	if(origine[0] == ultimele_pozitii[id][0] && 
	   origine[1] == ultimele_pozitii[id][1] && 
	   origine[2] == ultimele_pozitii[id][2])
	{
		CC_SendMessage(0, "&x04[%s] &x07%s &x01a fost detectat ca fiind AFK!", cvar[TAG], get_name(id))
	}

	ultimele_pozitii[id][0] = origine[0]
	ultimele_pozitii[id][1] = origine[1]
	ultimele_pozitii[id][2] = origine[2]

	set_task(float(cvar[afk_time]), "verifica_afk", TaskID)

}

/**********************[ STOCK-URI ]**********************/

stock bool: is_ok(id)
{
	if(get_user_flags(id) & ADMIN_KICK)
		return true
	return false
}

//-------------------------------------------------------------------
public _setari_mix()
{
	for(new i = 0; i < sizeof(comenzi_start_mix); i++)
		server_cmd(comenzi_start_mix[i])

	set_cvar_string("mp_forcerespawn", "0")
}
//-------------------------------------------------------------------
public _setari_default()
{
	for(new i = 0; i < sizeof(comenzi_default); i++)
		server_cmd(comenzi_default[i])

	set_cvar_string("mp_forcerespawn", "0")
}
//-------------------------------------------------------------------
public _setari_warmup()
{
	for(new i = 0; i < sizeof(comenzi_warmup); i++)
		server_cmd(comenzi_warmup[i])

	set_cvar_string("mp_forcerespawn", "1")
}
//-------------------------------------------------------------------
public _setari_extra()
{
	for(new i = 0; i < sizeof(comenzi_extra); i++)
		server_cmd(comenzi_extra[i])

	set_cvar_string("mp_forcerespawn", "0")
}
//-------------------------------------------------------------------
public _setari_lame()
{
	for(new i = 0; i < sizeof(comenzi_lame); i++)
		server_cmd(comenzi_lame[i])

	set_cvar_string("mp_forcerespawn", "1")
}
//-------------------------------------------------------------------
stock get_name(id)
{
	new szName[32]
	get_user_name(id, szName, charsmax(szName))

	return szName
}
//-------------------------------------------------------------------
stock reset_client_maxspeed(id) 
{ 
	new Float:flMaxSpeed

	switch(get_user_weapon(id)) 
    	{ 
       		case CSW_SG550, CSW_AWP, CSW_G3SG1: flMaxSpeed = 210.0;
        	case CSW_M249: flMaxSpeed = 220.0 
        	case CSW_AK47: flMaxSpeed = 221.0
        	case CSW_M3, CSW_M4A1: flMaxSpeed = 230.0
        	case CSW_SG552: flMaxSpeed = 235.0 
        	case CSW_XM1014, CSW_AUG, CSW_GALIL, CSW_FAMAS: flMaxSpeed = 240.0 
        	case CSW_P90 : flMaxSpeed = 245.0 
        	case CSW_SCOUT: flMaxSpeed = 260.0 
        	default: flMaxSpeed = 250.0 
	} 

    	engfunc(EngFunc_SetClientMaxspeed, id, flMaxSpeed)
    	set_pev(id, pev_maxspeed, flMaxSpeed)
}
//-------------------------------------------------------------------

//-------------------------------------------------------------------
