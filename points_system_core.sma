/* Sublime 4.0 AMXX-PAWN */

#include <amxmodx>
#include <sqlx>
#include <hamsandwich>
#include <fun>
#include <cstrike>
#include <amxmisc>

#define IsPlayer(%0)	(1 <= %0 <= MAX_PLAYERS)
#define MAX_NAME_LENGHT 33

#define PLUGIN  "PLUGIN"
#define VERSION "1.0"
#define AUTHOR  "AUTHOR"

enum(+=1234567890) {TASK_SENORAMXX, TASK_VEZI_PUNCTE}

enum _:DataBase
{
	szHost[64], szUser[64], szPassword[64], szDatabase[64], szTable[64]
}
new g_db[DataBase]

/*************************************************************************/

enum _:PlayersInfo
{
	szName[MAX_NAME_LENGHT], szSteamID[32], iPuncte
}
new g_pd[MAX_PLAYERS + 1][PlayersInfo]

enum _: Cvars
{
	kill, headshot, knife
}
new var[Cvars]

new Handle:g_szSqlTuple
new Handle:g_iSqlConnection
new g_iTry
new g_SqlError[512]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_event("DeathMsg", "ev_deathmsg", "a")

	new iVar
	iVar = create_cvar("kns_vers", VERSION, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY)

	iVar = create_cvar("plugin_db_host", "hostname")
	bind_pcvar_string(iVar, g_db[szHost], charsmax(g_db[szHost]))

	iVar = create_cvar("plugin_db_user", "user")
	bind_pcvar_string(iVar, g_db[szUser], charsmax(g_db[szUser]))

	iVar = create_cvar("plugin_db_password", "password")
	bind_pcvar_string(iVar, g_db[szPassword], charsmax(g_db[szPassword]))

	iVar = create_cvar("plugin_db_db", "database name")
	bind_pcvar_string(iVar, g_db[szDatabase], charsmax(g_db[szDatabase]))

	iVar = create_cvar("plugin_db_table", "table")
	bind_pcvar_string(iVar, g_db[szTable], charsmax(g_db[szTable]))

	iVar = create_cvar("plugin_kill_points", "5")
	bind_pcvar_string(iVar, var[kill], charsmax(var[kill]))

	iVar = create_cvar("plugin_hs_points", "10")
	bind_pcvar_string(iVar, var[headshot], charsmax(var[headshot]))

	iVar = create_cvar("plugin_knife_points", "15")
	bind_pcvar_string(iVar, var[knife], charsmax(var[knife]))


	AutoExecConfig()

	set_task(2.0, "connect_db")
}
public plugin_natives()
{
	register_native("get_points", "_get_user_points", 1)
}
public _get_user_points(id) return g_pd[id][iPuncte]

public plugin_end()
{
	SQL_FreeHandle(g_szSqlTuple)
	SQL_FreeHandle(g_iSqlConnection)
}

public connect_db()
{
	g_iTry += 1
	g_szSqlTuple = SQL_MakeDbTuple(g_db[szHost],g_db[szUser],g_db[szPassword],g_db[szDatabase], 10)

	new error
	g_iSqlConnection = SQL_Connect(g_szSqlTuple, error, g_SqlError, charsmax(g_SqlError))

	if(g_iSqlConnection == Empty_Handle)
	{
		log_amx("[%s] Incorect database settings!", PLUGIN)
		SQL_FreeHandle(g_iSqlConnection)

		if(g_iTry < 2)
		{
		connect_db()
		return
		}
	}	
	
	new szQueryData[600]
	formatex(szQueryData, charsmax(szQueryData),"CREATE TABLE IF NOT EXISTS `%s`\
	(`Name` VARCHAR(32) NOT NULL,\
	`SteamID` VARCHAR(32) NOT NULL,\
	`Puncte` INT NOT NULL\
	PRIMARY KEY(Name,SteamID))", g_db[szTable])

	new Handle:iQueries = SQL_PrepareQuery(g_iSqlConnection, szQueryData)

	if(!SQL_Execute(iQueries))
	{
		SQL_QueryError(iQueries, g_SqlError, charsmax(g_SqlError))
		log_amx(g_SqlError)
	}

	SQL_Execute(iQueries)
	SQL_FreeHandle(iQueries)
}
public client_putinserver(id)
{
	get_user_authid(id, g_pd[id][szSteamID], charsmax(g_pd[][szSteamID]))
	get_user_name(id, g_pd[id][szName], charsmax(g_pd[][szSteamID]))
	g_pd[id][iPuncte] = 0

	if(!is_user_bot(id) || !is_user_hltv(id))
	{
		set_task(2.0, "delay_loading_data", id + TASK_SENORAMXX)
	}
}
public delay_loading_data(id)
{
	id -= TASK_SENORAMXX
	LoadData(id)
}

public client_disconnected(id)
{
	if(!is_user_bot(id) || !is_user_hltv(id))
	{
		SaveData(id)
	}
}

public ev_deathmsg()
{
	new iKiller = read_data(1)
	new iVictim = read_data(2)
	new iHeadShot = read_data(3)
	new iGun = get_user_weapon(iKiller)

	if(!IsPlayer(iVictim) || !IsPlayer(iKiller))	return PLUGIN_HANDLED

	if(iKiller == iVictim) return PLUGIN_HANDLED

	if(!iHeadShot || !(iGun == CSW_KNIFE))	g_pd[iKiller][iPuncte] += var[kill]
	else if(iHeadShot) g_pd[iKiller][iPuncte] += var[headshot]
	else if(iHeadShot && iGun == CSW_KNIFE) g_pd[iKiller][iPuncte] += (var[knife] + var[headshot])

	set_task(0.5, "vezi_puncte", iKiller + TASK_VEZI_PUNCTE)
	return PLUGIN_HANDLED
}

public vezi_puncte(id)
{
	id -=TASK_VEZI_PUNCTE
	set_hudmessage(255, 255, 255, -1.0, 0.2, 0, 6.0, 2.0)
	show_hudmessage(id, "Puncte : %d", g_pd[id][iPuncte])
}

public LoadData(id)
{
	new Handle:iQuery = SQL_PrepareQuery(g_iSqlConnection, "SELECT * FROM `%s` WHERE `SteamID` = '%s';", g_db[szTable], g_pd[id][szSteamID])

	if(!SQL_Execute(iQuery))
	{
		SQL_QueryError(iQuery, g_SqlError, charsmax(g_SqlError))
		log_amx(g_SqlError)
		SQL_FreeHandle(iQuery)
	}

	new szQuery[512]
	new bool:b_found = SQL_NumResults( iQuery ) > 0 ? false : true

	if(b_found)
	{
		formatex(szQuery, charsmax(szQuery), "INSERT INTO `%s`\
			(`Name`,\
			`SteamID`,\
			`Puncte`\
			) VALUES (^"%s^",'%s','0','0');", g_db[szTable], g_pd[id][szName], g_pd[id][szSteamID])
	}
	else
	{
		formatex(szQuery, charsmax(szQuery), "SELECT \
			`Name`,\
			`Puncte`\
			FROM `%s` WHERE `SteamID` = '%s';", g_db[szTable], g_pd[id][szSteamID])
	}

	iQuery = SQL_PrepareQuery(g_iSqlConnection, szQuery)

	if(!SQL_Execute(iQuery))
	{
		SQL_QueryError(iQuery, g_SqlError, charsmax(g_SqlError))
		log_amx(g_SqlError)
	}

	if(!b_found)
	{
		if(SQL_NumResults(iQuery) > 0)
		{
			g_pd[id][iPuncte] = SQL_ReadResult(iQuery, SQL_FieldNameToNum(iQuery, "Puncte"))
		}
	}

	SQL_FreeHandle(iQuery);
}

public SaveData(id)
{
	new szQuery[512]
	formatex(szQuery, charsmax(szQuery), "UPDATE `%s`\
	SET `Name`=^"%s^",\
	`Knife Kills`='%d\
	WHERE `SteamID`='%s';", g_db[szTable], g_pd[id][szName], g_pd[id][iPuncte],  g_pd[id][szSteamID])
	SQL_ThreadQuery(g_szSqlTuple, "QueryHandler", szQuery)
}

public QueryHandler(iFailState, Handle:iQuery, szError[], iErrorCode)
{
	switch(iFailState)
	{
		case TQUERY_CONNECT_FAILED: 
		{
			log_amx("[SQL Error] Connection failed (%i): %s", iErrorCode, szError);
		}
		case TQUERY_QUERY_FAILED:
		{
			log_amx("[SQL Error] Query failed (%i): %s", iErrorCode, szError);
		}
	}
}
