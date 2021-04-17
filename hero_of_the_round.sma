/*
* PLUGIN MADE BY SENORAMXX FOR LALEAGANE.RO
* ChangeLog 17/04/2021 _:
{
	First Release
}

* Ce face pluginul ? :
-> Mai mult damage , mai putina gravitatie si mai mult speed la playerl ales

* Unde il putem folosi ? :
-> Pe clasic si CSDM (respawn)
*/

#include <amxmodx>
#include <cstrike>
#include <fun>
#include <hamsandwich>
#include <amxmisc>
#include <fakemeta>

#define IsPlayer(%0)	(1 <= %0 <= g_iMaxPlayers) 

#define CLASIC // daca vrei sa faceti pluginul pentru RESPAWN puneti // in fata la define ! Adica asa : //#define CLASIC

new bool: bBenefits[33]
enum _:Valori
{
	viteza,gravitatie,viata,armura,damage
}
new Val[Valori]
new g_iMaxPlayers

public plugin_init() 
{
	register_plugin("Random Powers", "1.0", "SenorAMXX")

	Val[viteza]		= register_cvar("hero_speed"	, 	"400.0	") // cata viteza sa aiba
	Val[gravitatie]	= register_cvar("hero_gravity"	, 	"400	") // cata gravitatie sa aiba
	Val[viata]		= register_cvar("hero_viata"	, 	"120	") // cata viata sa primeasca
	Val[armura]		= register_cvar("hero_armura"	, 	"120	") // cata armura sa primeasca
	Val[damage]		= register_cvar("hero_damage"	, 	"2		") // increment pentru damage ; adica : damage dat * valoare setata in cvar

	RegisterHam			(Ham_Spawn, "player", "spawn_check", true)
	RegisterHam			(Ham_TakeDamage, "player", "MoreDamage") 
	register_logevent	("ev_roundstart", 2, "1=Round_Start")
	register_event  	("CurWeapon", "Benefits", "be", "1=1")


	g_iMaxPlayers = get_maxplayers()

}

public ev_roundstart() 
{
	new players[32], player, pnum;
	get_players(players, pnum, "ach")
	for(new i = 0; i < pnum; i++)
	{
		player 					= players[i]
		bBenefits[player]		= true
	}
}

public spawn_check()
{
	new iPlayers[32], iNum, index, random_pick[33], iPlayer, random_recieved
 
	get_players(iPlayers, iNum)
	#if defined CLASIC
	for (new i = 0 ; i < iNum ; i++)
	{
		index = iPlayers[i];
		if ( cs_get_user_team(index) == CS_TEAM_T)
		{
			new name[33]
			get_user_name(index, name, charsmax(name))
			random_pick[random_recieved++] = index
			iPlayer = random_pick[random(random_recieved)]
			client_print(0,print_chat,"[LALEAGANE] %s a fost ales HERO al echipei T !", name)

			Benefits(iPlayer)
       }
		if (cs_get_user_team(index) == CS_TEAM_CT)
		{
			new name2[33]
			get_user_name(index, name2, charsmax(name2))
			random_pick[random_recieved++] = index
			iPlayer = random_pick[random(random_recieved)]
			client_print(0,print_chat,"[LALEAGANE] %s a fost ales HERO al echipei CT !", name2)
 
 			Benefits(iPlayer)
		}
	}
	#endif
	for (new i = 0 ; i < iNum ; i++)
	{
		index = iPlayers[i];
		new name[33]
		get_user_name(index, name, charsmax(name))
		random_pick[random_recieved++] = index
		iPlayer = random_pick[random(random_recieved)]
		client_print(0,print_chat,"[LALEAGANE] %s a fost ales HERO al rundei !", name)
 
 		Benefits(iPlayer)
	}
}

public Benefits(id)
{
	if(bBenefits[id] == true)
	set_pev(id, pev_maxspeed, get_pcvar_float(Val[viteza]))
	set_pev(id, pev_gravity, get_pcvar_float(Val[gravitatie]))
	set_user_health(id, get_pcvar_num(Val[viata]))
	cs_set_user_armor(id, get_pcvar_num(Val[armura]), CS_ARMOR_VESTHELM)

}

public MoreDamage(iVictim, iInflictor, iAttacker, Float:fDamage)
{
	if(iInflictor == iAttacker && IsPlayer(iAttacker)) 
	{
		new dmg = get_pcvar_num(Val[damage])
		SetHamParamFloat(4, fDamage * dmg)
		return HAM_HANDLED	
	}
	return HAM_IGNORED
	
}
