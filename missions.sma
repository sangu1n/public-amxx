#include <amxmodx>
#include <sqlx>
#include <amxmisc>
#include <cstrike>


/********** [ IDEI MISIUNI ] **********
* Bombe plantate
* Bombe dezamorsate
* Killuri
* Lame
* Conectari pe server
* Grenade aruncate
* Runde castigate
*********** [ IDEI MISIUNI ] **********/

enum MissionsData
{
	MissionID,
	MissionName[120],
	MissionInfo[50],
	MissionToDo
}

enum _: PlayerData
{
	NAME[MAX_NAME_LENGTH],
	STEAMID[MAX_AUTHID_LENGTH]
}
new g_ePlayerData[MAX_PLAYERS + 1][PlayerData]

new const MISSION_DATA[][MissionsData] = 
{/*
	{"id", Nume misiune", "Descriere Misiune", "Valoare ce trebuie indeplinita pentru misiune"}*/
	{1, "Al-Qaeda", "Planteaza 45 de bombe", 45},
	{2, "The Hero", "Dezamorseaza 30 de bombe", 30},
	{3, "Killer Machine", "Omoara 160 de persoane", 160},
	{4, "Samurai Jack", "Feliaza 40 de inamici", 40},
	{5, "Favorite Server", "Conecteaza-te de 20 de ori pe server", 20},
	{6, "Bomber Man", "Arunca 30 de grenade", 30},
	{7, "Winner Winner Chicken Dinner", "Castiga 300 de runde", 300}
}


new const g_szTablesInfo[][] =
{
	"( `id` INT(11) NOT NULL AUTO_INCREMENT ,\
	`name` VARCHAR(40) NOT NULL DEFAULT 'NONE' ,\
	`steamid` VARCHAR(40) NOT NULL DEFAULT 'NONE' ,\
	`is_user_registered` INT(2) NOT NULL DEFAULT 0 ,\
	`bombs_planted` INT(2) NOT NULL DEFAULT 0 ,\
	`bombs_defused` INT(2) NOT NULL DEFAULT 0 ,\
	`kills` INT(2) NOT NULL DEFAULT 0 ,\
	`knifes` INT(2) NOT NULL DEFAULT 0 ,\
	`connections` INT(2) NOT NULL DEFAULT 0 ,\
	`nades_thrown` INT(2) NOT NULL DEFAULT 0 ,\
	`rounds_won` INT(3) NOT NULL DEFAULT 0 ,\
	PRIMARY KEY (`id`))"
}

new const g_szTables[][] =
{
	"Missions_DB"
}
new Handle:g_SqlTuple
new g_Error[512]

enum _: ToCount
{
	iBOMBS_PLANTED,
	iBOMBS_DEFUSED,
	iKILLS,
	iKNIFES,
	iCONNECTIONS,
	iNADES_THROWN,
	iROUNDS_WON
}
new iCount[MAX_PLAYERS + 1][ToCount]

const keys = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0

new bool: g_bIsRegistered[MAX_PLAYERS + 1]

public plugin_init()
{
	register_plugin("[MISIUNI] Core", "1.0", "kidd0x")
	register_clcmd("say /misiuni", "func_open_missions_menu")
	register_clcmd("say /register", "func_reg")

	register_menu("MainMenu", keys, "handler_principal")
	register_menu("SecondMenu", (1<<0|1<<1|1<<9), "handler_secundar")

	MySql_Init()
}

public plugin_end()
{
	SQL_FreeHandle(g_SqlTuple)
}

public client_putinserver(id)
{
	set_task(5.0, "func_count_register", id + 12044)
}

public client_authorized(id)
{
	get_user_name(id, g_ePlayerData[id][NAME], charsmax(g_ePlayerData[][NAME]))
	mysql_escape_string(g_ePlayerData[id][NAME], charsmax(g_ePlayerData[][NAME]))
	get_user_authid(id, g_ePlayerData[id][STEAMID], charsmax(g_ePlayerData[][STEAMID]))
}

public MySql_Init()
{
	g_SqlTuple = SQL_MakeDbTuple("188.212.101.119", "u1200_kpE5Yi6XT9", "=o!vu3jJQmwqqA=1QmcmG@2R", "s1200_bb_xp")

	new szError
	new Handle: sql_con = SQL_Connect(g_SqlTuple, szError, g_Error, charsmax(g_Error))
	   
	if(sql_con == Empty_Handle)
	{
		set_fail_state(g_Error)
	}

	new Handle: intrari
	new data[2048]

	for(new i; i < sizeof g_szTables; i++)
	{
		formatex(data, charsmax(data), "CREATE TABLE IF NOT EXISTS %s %s", g_szTables[i], g_szTablesInfo[i])

		intrari = SQL_PrepareQuery(sql_con, data)

		if(!SQL_Execute(intrari))
		{
			SQL_QueryError(intrari, g_Error, charsmax(g_Error))
		}
	}

	SQL_FreeHandle(intrari)
	SQL_FreeHandle(sql_con)
}

public FreeHandle(FailState, Handle:Query, szError[], ErrorCode, szData[], iSize)
{
	if(FailState || ErrorCode)
	{
		log_amx("^nSQL ERROR: %s^n", szError)
	}

	SQL_FreeHandle(Query)
}

public func_reg(id)
{
	func_check_db_for_account(id)
}

public func_check_db_for_account(id)
{
	new query[512], data[1]
	data[0] = id

	formatex(query, charsmax(query), "SELECT * FROM `%s` WHERE `steamid` = '%s'", g_szTables[0], g_ePlayerData[id][STEAMID])

	SQL_ThreadQuery(g_SqlTuple, "func_continue_to_reg", query, data, sizeof(data))
}

public func_continue_to_reg(failstate, Handle:query, error[], errorcode, data[], size)
{
	if(failstate || errorcode)
	{
		log_amx("^nSQL ERROR: %s^n", error)
	}

	new id = data[0]

	if(SQL_NumResults(query) > 0)
	{
		client_print_color(id, id, "^4[AMXX] ^1Contul este deja inregistrat!")
	}
	else
	{
		funct_register_account_to_db(id)
	}
}

public funct_register_account_to_db(id)
{
	new query[512]
	formatex(query, charsmax(query), "INSERT INTO `%s` (`name`, `steamid`, `is_user_registered`, `bombs_planted`, `bombs_defused`, `kills`, `knifes`, `connections`, `nades_thrown`, `rounds_won`)\
	VALUES\
	('%s', '%s', '1', '0', '0', '0', '0', '0', '0', '0')", g_szTables[0], g_ePlayerData[id][NAME], g_ePlayerData[id][STEAMID])

	SQL_ThreadQuery(g_SqlTuple, "FreeHandle", query)

	client_print_color(id, id, "^4[AMXX] ^1Contul a fost inregistrat! ^3(%s)", g_ePlayerData[id][STEAMID])
}

public func_count_register(id, Handle: Query)
{
	id -= 12044
	new is_registered = SQL_ReadResult(Query, 3)

	if(is_registered == 0)
	{
		client_print_color(id, id, "^4[AMXX] ^1Tasteaza /register pentru a putea realiza misiuni!")
		return PLUGIN_HANDLED
	}
	else
	{
		iCount[id][iCONNECTIONS]++
	}
	return PLUGIN_CONTINUE
}

public func_open_missions_menu(id, Handle:Query)
{

	new menu[512], iLen

	iLen += formatex(menu[iLen], charsmax(menu) - iLen, "[MISSIONS] Lista Misiuni:^n^n")

	for(new i; i < sizeof MISSION_DATA; i++)
	{
		iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[%d]\w. %s^n", i+1, MISSION_DATA[i][MissionName])
	}

	show_menu(id, keys, menu, -1, "MainMenu")
}

public handler_principal(id, key)
{
	if(!is_user_connected(id))
	{
		return
	}

	MissionPanel(id, key)
}

public MissionPanel(const id, const key)
{	
	new menu[512], iLen

	iLen += formatex(menu[iLen], charsmax(menu) - iLen, "Status Misiune:^n^n")

	iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\w[\y#\w] Nume Misiune: \r%s^n", MISSION_DATA[key][MissionName])
	iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\w[\y#\w] Info Misiune: \r%s^n", MISSION_DATA[key][MissionInfo])
	iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\w[\y#\w] Reward: \r$16.000^n")

	switch(MISSION_DATA[key][MissionID])
	{
		case 1: iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\w[\y#\w] Progres: \r%d\w/\r%d^n", iCount[id][iBOMBS_PLANTED], MISSION_DATA[key][MissionToDo])
		case 2: iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\w[\y#\w] Progres: \r%d\w/\r%d^n", iCount[id][iBOMBS_DEFUSED], MISSION_DATA[key][MissionToDo])
		case 3: iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\w[\y#\w] Progres: \r%d\w/\r%d^n", iCount[id][iKILLS], MISSION_DATA[key][MissionToDo])
		case 4: iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\w[\y#\w] Progres: \r%d\w/\r%d^n", iCount[id][iKNIFES], MISSION_DATA[key][MissionToDo])
		case 5: iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\w[\y#\w] Progres: \r%d\w/\r%d^n", iCount[id][iCONNECTIONS], MISSION_DATA[key][MissionToDo])
		case 6: iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\w[\y#\w] Progres: \r%d\w/\r%d^n", iCount[id][iNADES_THROWN], MISSION_DATA[key][MissionToDo])
		case 7: iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\w[\y#\w] Progres: \r%d\w/\r%d^n", iCount[id][iROUNDS_WON], MISSION_DATA[key][MissionToDo])
	}

	iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[0] \wExit", MISSION_DATA[key][MissionToDo])

	show_menu(id, (1<<9), menu, -1, "SecondMenu")
}

public handler_secundar(id, key)
{
	if(!is_user_connected(id))
	{
		return
	}
}




mysql_escape_string(dest[],len)
{
    replace_all(dest,len,"\\","\\\\");
    replace_all(dest,len,"\0","\\0");
    replace_all(dest,len,"\n","\\n");
    replace_all(dest,len,"\r","\\r");
    replace_all(dest,len,"\x1a","\Z");
    replace_all(dest,len,"'","\'");
    replace_all(dest,len,"^"","\^"");
}
