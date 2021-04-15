#include <amxmodx>
#include <cstrike>
#include <amxmisc>
#include <hamsandwich>
#include <engine>
#include <fun>
#include <csx>

#define RED Red
#define BLUE Blue
#define GREY Grey
#define ColorChat colorx

#define VIP_FLAG ADMIN_LEVEL_H

#define USE_HUD 

#define CHAT_PREFIX "^4[^3LALEAGANE.RO^4]"


#define DEAD (1<<0)
#define VIP (1<<2)

enum _: CVARS
{	
	EXTRA_JUMPS,
	MAXHP,
	MAXAP,
	KILLHP,
	KILLAP,
	KILLHP_HS,
	KILLAP_HS,
	SPAWNHP,
	SPAWNAP,
	RUNDA_ACCES,
	VIP_FREE_TURN,
	VIP_FREE_START,
	VIP_FREE_END,
	VIP_BULLET_DAMAGE,
}

enum
{
	Primary = 1,
	Secondary,
	Knife,
	Grenades,
	C4
}

enum {
	Grey = 33,
	Red,
	Blue
}

new const Float: g_flCoords[][] =
{
	{ 0.50, 0.40 },
	{ 0.56, 0.44 },	
	{ 0.60, 0.50 },
	{ 0.56, 0.56 },
	{ 0.50, 0.60 },
	{ 0.44, 0.56 },
	{ 0.40, 0.50 },
	{ 0.44, 0.44 }
}

new VAR[CVARS]
new iRound
new jumpnum[33] = 0
new bool:dojump[33] = false
new bool:bool_vip
new MaxPlayers
new g_iPosition[33]
new g_iSize


public plugin_init()
{
	register_plugin("VIP LLG", "1.0", "SenorAMXX")

	new pcvar

	pcvar = create_cvar("vip_extra_jumps", "2")
	bind_pcvar_num(pcvar, VAR[EXTRA_JUMPS])

	pcvar = create_cvar("vip_maxhp", "110")
	bind_pcvar_num(pcvar, VAR[MAXHP])

	pcvar = create_cvar("vip_maxap", "110")
	bind_pcvar_num(pcvar, VAR[MAXAP])

	pcvar = create_cvar("vip_killhp", "5")
	bind_pcvar_num(pcvar, VAR[KILLHP])

	pcvar = create_cvar("vip_killap", "8")
	bind_pcvar_num(pcvar, VAR[KILLAP])

	pcvar = create_cvar("vip_killhp_hs", "8")
	bind_pcvar_num(pcvar, VAR[KILLHP_HS])

	pcvar = create_cvar("vip_killap_hs", "10")
	bind_pcvar_num(pcvar, VAR[KILLAP_HS])

	pcvar = create_cvar("vip_spawn_hp", "105")
	bind_pcvar_num(pcvar, VAR[SPAWNHP])

	pcvar = create_cvar("vip_spawn_ap", "105")
	bind_pcvar_num(pcvar, VAR[SPAWNAP])

	pcvar = create_cvar("vip_menu_menu_shop", "2")
	bind_pcvar_num(pcvar, VAR[RUNDA_ACCES])

	pcvar = create_cvar("vip_free", "1")
	bind_pcvar_num(pcvar, VAR[VIP_FREE_TURN])

	pcvar = create_cvar("vip_free_start", "20")
	bind_pcvar_num(pcvar, VAR[VIP_FREE_START])

	pcvar = create_cvar("vip_free_end", "23")
	bind_pcvar_num(pcvar, VAR[VIP_FREE_END])

	pcvar = create_cvar("vip_bullet_damage", "1")
	bind_pcvar_num(pcvar, VAR[VIP_BULLET_DAMAGE])



	

	register_clcmd("say /vips", "ShowVipList")

	g_iSize = sizeof( g_flCoords )


	RegisterHam(Ham_Killed, "player", "ham_PlayerKilled", 1)
	RegisterHam(Ham_Spawn, "player", "SpawnCheck", 1)
	register_logevent("logev_Restart", 2, "1&Restart_Round", "1&Game_Commencing")
	register_event("HLTV", "ev_NewRound", "a", "1=0", "2=0")

	register_message(get_user_msgid("ScoreAttrib"), "VIP_IN_TAB")

	AutoExecConfig()

	MaxPlayers = get_maxplayers()

	new path[64];
	get_localinfo("amxx_configsdir", path, charsmax(path));
	formatex(path,charsmax(path), "%s/VIP_LLG/vip_blocked_maps.ini", path);
	
	new file = fopen(path, "r+");
	
	if(!file_exists(path))
	{
		write_file(path, "; VIP-UL ESTE DEZACTIVAT PE URMATOARELE HARTI: ");
		write_file(path, "; Exemplu de adaugare HARTA:^n; ^"harta^"^n^nfy_snow^nawp_bycastor");
		write_file(path, "; NOTA:^n Pentru a ignora anumite harti, adaugati ^";^" in fata hartii");
	}
	
	new mapname[32];
	get_mapname(mapname, charsmax(mapname));
	
	new text[121], maptext[32];
	while(!feof(file))
	{
		fgets(file, text, charsmax(text));
		trim(text);
		
		if(text[0] == ';' || !strlen(text))
		{
			continue; 
		}
		
		parse(text, maptext, charsmax(maptext));
		
		if(equal(maptext, mapname))
		{
			pause("a")
			break;
		}
	}
	fclose( file );
}


public client_damage(iAttacker, iVictim, iDamage)
{
	
	if(VAR[VIP_BULLET_DAMAGE] == 0
	|| is_user_bot(iAttacker)
	|| is_user_hltv(iAttacker)
	|| !is_user_alive(iAttacker)
	|| !is_user_gold_member(iAttacker))	return PLUGIN_HANDLED
	if(++g_iPosition[iAttacker] == g_iSize)	g_iPosition[iAttacker] = 0

	set_hudmessage(0, 40, 80, Float: g_flCoords[g_iPosition[iAttacker]][0], Float: g_flCoords[g_iPosition[iAttacker]][1], 0, 0.1, 2.5, 0.02, 0.02, -1)
	show_hudmessage(iAttacker, "%i", iDamage)
	return PLUGIN_CONTINUE
}

public client_putinserver(id)
{
	new name[33]
	get_user_name(id, name, charsmax(name))
	if(bool_vip) return PLUGIN_HANDLED

	if(is_user_gold_member(id))	colorx(0, id, "%s VIP ^3%s^1 s-a conectat pe server !",CHAT_PREFIX, name)
	return PLUGIN_HANDLED
}
public client_disconnected(id)
{
	new name[33]
	get_user_name(id, name, charsmax(name))
	if(bool_vip) return PLUGIN_HANDLED

	if(is_user_gold_member(id))	colorx(0, id, "%s VIP ^3%s^1 s-a deconectat pe server !",CHAT_PREFIX, name)
	return PLUGIN_HANDLED
}

public SpawnCheck(id)
{
	if(!is_user_alive(id) || is_user_bot(id) || is_user_hltv(id)) return PLUGIN_HANDLED

	if(is_user_gold_member(id))
	{
		set_user_health(id, VAR[SPAWNHP])
		cs_set_user_armor(id, VAR[SPAWNAP], CS_ARMOR_VESTHELM)
	}
	
	if(iRound >= VAR[RUNDA_ACCES])
	{
		meniu_vip(id)
	}

	return PLUGIN_HANDLED
}
public logev_Restart()	iRound = 0

public ev_NewRound()
{
	iRound++
	if(VAR[VIP_FREE_TURN] == 0)	return PLUGIN_CONTINUE

	if(is_vip_free(VAR[VIP_FREE_START], VAR[VIP_FREE_END]))	bool_vip = true
	else
    bool_vip = false	
	return PLUGIN_CONTINUE

}



public client_PreThink(id)
{
	if(!is_user_alive(id))	return PLUGIN_HANDLED
	
	new nbut = get_user_button(id)
	new obut = get_user_oldbutton(id)
	
	if((nbut & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(obut & IN_JUMP))
	{
		if(is_user_gold_member(id))
		{
			if(jumpnum[id] < VAR[EXTRA_JUMPS])
			{
				dojump[id] = true
				jumpnum[id]++
				return PLUGIN_CONTINUE
			}
		}
	}
	
	if((nbut & IN_JUMP) && (get_entity_flags(id) & FL_ONGROUND))
	{
		jumpnum[id] = 0
		return PLUGIN_CONTINUE
	}
	
	return PLUGIN_CONTINUE
}

public client_PostThink(id)
{
	if(bool_vip)
    {

        set_user_flags(id, VIP_FLAG)
        #if defined USE_HUD
        set_hudmessage(255, 0, 0, 0.27, 0.0, 0, 6.0, 12.0)
        show_hudmessage(id, "FREE VIP ON!")
        #endif
    }

	if(!is_user_alive(id))
	{
		return PLUGIN_CONTINUE
	}
	
	if(is_user_gold_member(id))
	{
		if(dojump[id] == true)
		{
			new Float:velocity[3]
			entity_get_vector(id,EV_VEC_velocity, velocity)
			velocity[2] = random_float(265.0,285.0)
			entity_set_vector(id,EV_VEC_velocity, velocity)
			dojump[id] = false
			return PLUGIN_CONTINUE
		}
	}
	
	return PLUGIN_CONTINUE;
}

public VIP_IN_TAB() 
{
	new id = get_msg_arg_int(1);
	if(is_user_gold_member(id))
	{
		if(is_user_connected(id))
			set_msg_arg_int(2, ARG_BYTE, is_user_alive(id) ? VIP : DEAD)
	}
}

public ham_PlayerKilled(iVictim, iAttacker)
{
	if(!iVictim || !iAttacker || !is_user_alive(iAttacker))
		return HAM_IGNORED;
		
	if(is_user_gold_member(iAttacker))
	{
		new g_iIsHeadshot	= read_data (3)
		new g_iHealth		= get_user_health(iAttacker)
		new g_iArmor 		= get_user_armor(iAttacker)
		new g_iHealthAdd	= VAR[KILLHP]
		new g_iHealthHSAdd	= VAR[KILLHP_HS]
		new g_iArmorAdd		= VAR[KILLAP]
		new g_iArmorHSAdd	= VAR[KILLAP_HS]
		new g_iMaxHP		= VAR[MAXHP]
		new g_iMaxAP		= VAR[MAXAP]
		
		if( g_iIsHeadshot )
		{
			if( g_iHealth >= g_iMaxHP || g_iArmor >= g_iMaxAP )
			{
				set_user_health(iAttacker, g_iMaxHP)
				set_user_armor(iAttacker, g_iMaxAP)
			}
			else
			{
				set_user_health(iAttacker, g_iHealth + g_iHealthHSAdd)
				set_user_armor(iAttacker, g_iHealth + g_iArmorHSAdd)
			}
		}
		else
		{
			if(g_iHealth >= g_iMaxHP || g_iArmor >= g_iMaxAP)
			{
				set_user_health(iAttacker, g_iMaxHP)
				set_user_armor(iAttacker, g_iMaxAP)
			}
			else
			{
				set_user_health(iAttacker, g_iHealth + g_iHealthAdd)
				set_user_armor(iAttacker, g_iHealth + g_iArmorAdd)
			}
		}
	}
	return PLUGIN_HANDLED
}

public meniu_vip(id)
{
	if(!is_user_gold_member(id)) return
	new menu = menu_create("VIP MENU","VMH")

	menu_additem(menu, "AK47 + DEAGLE", "", 0)
	menu_additem(menu, "M4A1 + DEAGLE", "", 0)
	menu_additem(menu, "AWP + DEAGLE" , "", 0)

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
}

public VMH(id,menu,item)
{
	if(item==MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	switch(item)
	{
		case 0: 
		{
			give_item(id, "weapon_ak47")
			give_item(id, "weapon_deagle")
			cs_set_user_bpammo(id, CSW_AK47, 90)
			cs_set_user_bpammo(id, CSW_DEAGLE, 35)
			client_print(id, print_center, "**Ai primit AK47 + DEAGLE**")
		}
		case 1: 
		{
			give_item(id, "weapon_m4a1")
			give_item(id, "weapon_deagle")
			cs_set_user_bpammo(id, CSW_M4A1, 90)
			cs_set_user_bpammo(id, CSW_DEAGLE, 35)
			client_print(id, print_center, "**Ai primit M4A1 + DEAGLE**")
		}
		case 2: 
		{
			give_item(id, "weapon_awp")
			give_item(id, "weapon_deagle")
			cs_set_user_bpammo(id, CSW_AWP, 30)
			cs_set_user_bpammo(id, CSW_DEAGLE, 35)
			client_print(id, print_center, "**Ai primit AWP + DEAGLE**")
		}
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED

}

public ShowVipList(id) {
	new VipNames[33][32], Message[256], i, count, x, len;
	if(bool_vip)
	{
		colorx(id, id, "%s^1 Toti jucatorii au VIP pentru ca este event :D", CHAT_PREFIX)
		return PLUGIN_HANDLED
	}
	
	for (i = 1 ; i <= MaxPlayers; i ++)
	{
		if (is_user_connected(i) && is_user_gold_member(i))
		{
			get_user_name(i, VipNames [count ++], charsmax (VipNames []));
		}
	}
	
	len = format (Message, charsmax (Message), "%s^1 VIP-ii online sunt:^4 ", CHAT_PREFIX);
	
	if (count > 0) 
	{
		for(x = 0 ; x < count ; x ++) 
		{
			len += format (Message [len], charsmax (Message) - len, "%s%s ", VipNames [x], x < (count-1) ? ", ":"");
			
			if (len > 96) 
			{
				colorx(id, id, Message);
				
				len = format(Message, 255, " ");
			}
		}
		
		colorx(id, id, Message);
	}
	else 
	{
		colorx(id, id, "%s^1 Nu sunt^4 VIP^1-i online.", CHAT_PREFIX);
	} 
	
	return PLUGIN_CONTINUE;
}


stock bool:is_user_gold_member(id)
{
	if(get_user_flags(id) & VIP_FLAG) return true;
	return false;
}
bool:is_vip_free(start, end)
{
    new iHour; time( iHour )
    return bool:( start < end ? ( start <= iHour < end ) : ( start <= iHour || iHour < end ) )
} 

stock colorx(id, sender, const fmt[], any:...) {
	// check if id is different from 0
	if( id && !is_user_connected(id) )
	{
		return 0;
	}
	
	static const szTeamName[][] =  {
		"",
		"TERRORIST",
		"CT"
	};
	
	new szMessage[192];
	
	new iParams = numargs();
	// Specific player code
	if( id )
	{
		if( iParams == 3 )
		{
			copy(szMessage, charsmax(szMessage), fmt); // copy so message length doesn't exceed critical 192 value
		}
		else
		{
			vformat(szMessage, charsmax(szMessage), fmt, 4);
		}
		
		if( sender > Grey )
		{
			if( sender > Blue )
			{
				sender = id;
			}
			else
			{
				_CC_TeamInfo(id, sender, szTeamName[sender-Grey]);
			}
		}
		_CC_SayText(id, sender, szMessage);
	} 
	
	// Send message to all players
	else
	{
		// Figure out if at least 1 player is connected
		// so we don't execute useless useless code if not
		new iPlayers[32], iNum;
		get_players(iPlayers, iNum, "ch");
		if( !iNum )
		{
			return 0;
		}
		
		new iMlNumber, i, j;
		new Array:aStoreML = ArrayCreate();
		if( iParams >= 5 ) // ML can be used
		{
			for(j=3; j<iParams; j++)
			{
				// retrieve original param value and check if it's LANG_PLAYER value
				if( getarg(j) == LANG_PLAYER )
				{
					i=0;
					// as LANG_PLAYER == -1, check if next parm string is a registered language translation
					while( ( szMessage[ i ] = getarg( j + 1, i++ ) ) ) {}
					if( GetLangTransKey(szMessage) != TransKey_Bad )
					{
						// Store that arg as LANG_PLAYER so we can alter it later
						ArrayPushCell(aStoreML, j++);
						
						// Update ML array saire so we'll know 1st if ML is used,
						// 2nd how many args we have to alterate
						iMlNumber++;
					}
				}
			}
		}
		
		// If arraysize == 0, ML is not used
		// we can only send 1 MSG_ALL message if sender != 0
		if( !iMlNumber ) {
			
			if( iParams == 3 )
			{	
				copy(szMessage, charsmax(szMessage), fmt);
			}
			else
			{
				vformat(szMessage, charsmax(szMessage), fmt, 4);
			}
			if( 0 < sender < Blue ) // if 0 is passed, need to loop
			{
				if( sender > Grey )
				{
					_CC_TeamInfo(0, sender, szTeamName[sender-Grey]);
				}
				_CC_SayText(0, sender, szMessage);
				return 1;
			}
		}
		
		if( sender > Blue )
		{
			sender = 0; // use receiver index
		}
		
		for(--iNum; iNum>=0; iNum--)
		{
			id = iPlayers[iNum];
			
			if( iMlNumber )
			{
				for(j=0; j<iMlNumber; j++)
				{
					// Set all LANG_PLAYER args to player index ( = id )
					// so we can format the text for that specific player
					setarg(ArrayGetCell(aStoreML, j), _, id);
				}
				
				// format string for specific player
				vformat(szMessage, charsmax(szMessage), fmt, 4);
			}
			
			if( sender > Grey ) {
				_CC_TeamInfo(id, sender, szTeamName[sender-Grey]);
			}
			_CC_SayText(id, sender, szMessage);
		}
		
		ArrayDestroy(aStoreML);
	}
	return 1;
}

stock _CC_TeamInfo(iReceiver, iSender, szTeam[])	{
	static iTeamInfo = 0;
	if( !iTeamInfo ) 
	{
		iTeamInfo = get_user_msgid("TeamInfo");
	}
	message_begin(iReceiver ? MSG_ONE : MSG_ALL, iTeamInfo, _, iReceiver);
	write_byte(iSender);
	write_string(szTeam);
	message_end();
}

stock _CC_SayText(iReceiver, iSender, szMessage[]) {
	static iSayText = 0;
	if( !iSayText ) {
		iSayText = get_user_msgid("SayText");
	}
	message_begin(iReceiver ? MSG_ONE : MSG_ALL, iSayText, _, iReceiver);
	write_byte(iSender ? iSender : iReceiver);
	write_string(szMessage);
	message_end();
}

stock register_dictionary_colored(const filename[]) {
	if( !register_dictionary(filename) )
	{
		return 0;
	}
	
	new szFileName[256];
	get_localinfo("amxx_datadir", szFileName, charsmax(szFileName));
	format(szFileName, charsmax(szFileName), "%s/lang/%s", szFileName, filename);
	new fp = fopen(szFileName, "rt");
	if( !fp )
	{
		log_amx("Failed to open %s", szFileName);
		return 0;
	}
	
	new szBuffer[512], szLang[3], szKey[64], szTranslation[256], TransKey:iKey;
	
	while( !feof(fp) ) {
		fgets(fp, szBuffer, charsmax(szBuffer));
		trim(szBuffer);
		
		if( szBuffer[0] == '[' )
		{
			strtok(szBuffer[1], szLang, charsmax(szLang), szBuffer, 1, ']');
		}
		else if( szBuffer[0] )
		{
			strbreak(szBuffer, szKey, charsmax(szKey), szTranslation, charsmax(szTranslation));
			iKey = GetLangTransKey(szKey);
			if( iKey != TransKey_Bad )
			{
				replace_all(szTranslation, charsmax(szTranslation), "!g", "^4");
				replace_all(szTranslation, charsmax(szTranslation), "!t", "^3");
				replace_all(szTranslation, charsmax(szTranslation), "!n", "^1");
				AddTranslation(szLang, iKey, szTranslation[2]);
			}
		}
	}
	
	fclose(fp);
	return 1;
} 
