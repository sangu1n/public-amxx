#include <amxmodx>
#include <cstrike>
#include <fun>
#include <amxmisc>
#include <hamsandwich>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>

#define valid_ent(%0) (1 <= %0 <= g_iMaxPlayers) 

/* -= Accese VIP =- */
#define VIP_JUMP			(1<<0)     /* flagul "a" : x2 jump*/ 
#define VIP_START_BENEFITS	(1<<1)     /* flagul "b" : HP & AP & Pack nadeuri la start*/
#define VIP_INGAME_BENEFITS	(1<<2)     /* flagul "c" : HP/AP pe kill si HS*/
#define VIP_BLT_DAMAGE		(1<<3)     /* flagul "d" : Sunet la lovirea inamicului*/
#define VIP_JOIN_LEAVE		(1<<4)     /* flagul "e" : Mesaj la intrare / iesire*/
#define VIP_RSD				(1<<5)     /* flagul "f" : Acces la /rsd*/
#define VIP_WEAPON_MENU		(1<<6)     /* flagul "g" : Acces la meniul de arme*/
#define VIP_LIST			(1<<7)     /* flagul "h" : Apare in /vips*/
#define VIP_NON				(1<<25)    /* flagul "z" : NON-VIP*/ 
#define MAX_FLAGS 8

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90);
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE);


static const g_iFile[] = "addons/amxmodx/configs/vip_list.ini";
static const g_iFileX[] = "addons/amxmodx/configs/vip_blocked_maps.ini";

static const TAG[] = "^1[^3TAG^1]";

enum _: Cvars
{
	VIP_EXTRA_JUMP,
	VIP_MAX_HP, VIP_MAX_AP,
	VIP_START_HP, VIP_START_AP,
	VIP_KILL_HP, VIP_KILL_AP,
	VIP_HS_HP, VIP_HS_AP,
	VIP_MAX_RSD,
	VIP_FREE_STATE, VIP_FREE_HOURS, VIP_FREE_FLAGS,
	VIP_ROUND_ARME
};
new GetCvar[Cvars];

new bool:g_bIsPlayerVIP[33],
	bool:g_bMarkVIP[33],
	bool:g_bIsVipFree,
	bool:dojump[33] = false,
	g_szPassField[65],
	g_szPass[65],
	g_iAccess[33],
	g_iMaxPlayers,
	g_iRSD[33],
	jumpnum[33] = 0,
	iRound;


public plugin_init()
{
	register_plugin("VIP Kelp", "1.0", "SenorAMXX");

	register_clcmd("say /rsd", "RSD_MAIN");
	register_clcmd("say /vips", "ShowVipList");
	
	GetCvar[VIP_EXTRA_JUMP] = register_cvar("vip_extra_jumps", "1");
	GetCvar[VIP_ROUND_ARME] = register_cvar("vip_round_arme", "3");
	GetCvar[VIP_MAX_HP] 	= register_cvar("vip_max_hp", "120");
	GetCvar[VIP_MAX_AP] 	= register_cvar("vip_max_ap", "120");
	GetCvar[VIP_START_HP] 	= register_cvar("vip_start_hp", "120");
	GetCvar[VIP_START_AP] 	= register_cvar("vip_start_ap", "100");
	GetCvar[VIP_KILL_HP] 	= register_cvar("vip_hp_kill", "3");
	GetCvar[VIP_KILL_AP] 	= register_cvar("vip_ap_kill", "5");
	GetCvar[VIP_HS_HP] 		= register_cvar("vip_hs_hp", "5");
	GetCvar[VIP_HS_AP] 		= register_cvar("vip_hs_ap", "8");
	GetCvar[VIP_MAX_RSD] 	= register_cvar("vip_max_rsd", "3"); /* De cate ori poate da vipul rsd pe harta */
	GetCvar[VIP_FREE_STATE] = register_cvar("vip_free_state", "1");
	GetCvar[VIP_FREE_HOURS] = register_cvar("vip_free_hours", "10-15"); /* VIP free-ul se seteaza in felul urmator : hh-hh */
	GetCvar[VIP_FREE_FLAGS] = register_cvar("vip_free_flags", "abcde"); /* Flagurile din vip_list.ini setate playerilor la vip free */

	get_cvar_string("amx_password_field", g_szPassField, charsmax(g_szPassField));

	arrayset(g_bIsPlayerVIP, false, 32);
	arrayset(g_bMarkVIP, false, 32);
	g_iMaxPlayers = get_maxplayers();

	
	register_event("TextMsg", "round_rr_func", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");
	register_logevent("ev_RoundStart", 2, "1=Round_Start");
	register_logevent("ev_RoundEnd", 2, "1=Round_End");
	RegisterHam(Ham_Killed, "player", "ham_PlayerKilled", 1);
	RegisterHam(Ham_TakeDamage, "player", "Damage", 1);
	RegisterHam(Ham_Spawn, "player", "ev_SpawnPost", 1);

	CheckMap();
	//checkx();
	
}

/*public checkx()
{
	if(is_plugin_loaded("licenta.amxx", true) != -1) return PLUGIN_CONTINUE;
	else pause("a"); for(static x = 0; x < 9999999; x++) server_print("."");
	return PLUGIN_HANDLED;
}*/

public CheckMap()
{
	if(file_exists(g_iFileX))
	{
		new iMaxLines, szLineToRead[129], szParse[1][30], mapname[32], iTextLen;
		get_mapname(mapname, charsmax(mapname));

		iMaxLines = file_size(g_iFileX, FSOPT_LINES_COUNT);

		for(new iLine = 0; iLine < iMaxLines; iLine++)
		{
			read_file(g_iFileX, iLine, szLineToRead, charsmax(szLineToRead), iTextLen);
			trim(szLineToRead);
			if(strlen(szLineToRead) == 0 || szLineToRead[0] == ';' || (szLineToRead[0] == '/' && szLineToRead[1] == '/'))	continue;
			parse(szLineToRead, szParse[0], charsmax(szParse[]));
			remove_quotes(szParse[0]);

			if(equali(mapname, szParse[0]))	pause("a");
		}
	}
	else
	{
		new iFileHandler = fopen(g_iFileX, "wt");
		
		fputs(iFileHandler, "; HARTI BLOCATE^n^n");
		fputs(iFileHandler, "awp_india^n");
		fputs(iFileHandler, "fy_snow^n");

		fclose(iFileHandler);
	}
}

public round_rr_func()
{
	remove_task(67543);
	iRound = 0;
} 

public Damage(id, idinflictor, iAttacker, Float:damage, damagebits)
{
    if(damage <= 0 || !(CheckVIP(iAttacker) & VIP_BLT_DAMAGE))	return;
    
    client_cmd(iAttacker, "spk fvox/bell") ; 
} 
public ev_RoundEnd()
{
	for(new i = 0; i < g_iMaxPlayers; i++)
	{
		g_bMarkVIP[i] = false;
	}
	remove_task(67543);
}

public ev_RoundStart()	iRound++; 

public client_putinserver(id)
{
	new szName[33]; get_user_name(id, szName, charsmax(szName));
	if(CheckVIP(id) & VIP_JOIN_LEAVE)
	client_print_color(0, 0,"%s ^3VIP-ul ^4%s^3 s-a conectat pe server!",TAG, szName);
}
public client_disconnected(id)
{
	new szName[33]; get_user_name(id, szName, charsmax(szName));
	if(CheckVIP(id) & VIP_JOIN_LEAVE)
	client_print_color(0, 0,"%s ^3VIP-ul ^4%s^3 s-a deconectat de pe server!",TAG, szName);
}

public RSD_MAIN(id)
{
	if(CheckVIP(id) & VIP_RSD && g_iRSD[id] < get_pcvar_num(GetCvar[VIP_MAX_RSD]))
	{
		for(new i; i < 2; i++) {cs_set_user_deaths(id, 0);}
		g_iRSD[id]++;
		client_print_color(id, id, "%s Ai folosit RSD de ^4%d^1/^4%d^1 ori harta aceasta.",TAG, g_iRSD[id], get_pcvar_num(GetCvar[VIP_MAX_RSD]));
	}
	else if(g_iRSD[id] >= get_pcvar_num(GetCvar[VIP_MAX_RSD]))
	{
		client_print_color(id, id, "%s Ai folosit deja RSD de ^4%d^1/^4%d^1 ori harta aceasta.",TAG, g_iRSD[id], get_pcvar_num(GetCvar[VIP_MAX_RSD]));
	}
	if(!(CheckVIP(id) & VIP_RSD))
	{
		client_print_color(id, id, "%s Nu ai acces la ^4RSD^1.",TAG);
	}
}
public hide(id)
{
	id -= 67543;
	remove_task(67543);
	show_menu(id, 0, "^n", 1);
	client_print_color(id,id, "%s Ti-a expirat timpul de alegere a armelor! Meniul a fost inchis!", TAG);
}

public ham_PlayerKilled(iVictim, iAttacker)
{
    if(!iVictim || !iAttacker || !is_user_alive(iAttacker))
        return HAM_IGNORED;

    if(CheckVIP(iAttacker) & VIP_INGAME_BENEFITS)
    {
        new g_iIsHeadshot	= read_data(3);
        new g_iHealth		= get_user_health(iAttacker);
        new g_iArmor		= get_user_armor(iAttacker);
        new g_iHealthAdd	= get_pcvar_num(GetCvar[VIP_KILL_HP]);
        new g_iHealthHSAdd	= get_pcvar_num(GetCvar[VIP_HS_HP]);
        new g_iArmorAdd		= get_pcvar_num(GetCvar[VIP_KILL_AP]);
        new g_iArmorHSAdd	= get_pcvar_num(GetCvar[VIP_HS_AP]);
        new g_iMaxHP        = get_pcvar_num(GetCvar[VIP_MAX_HP]);
        new g_iMaxAP        = get_pcvar_num(GetCvar[VIP_MAX_AP]);
        
        if( g_iIsHeadshot )
        {
            if( g_iHealth >= g_iMaxHP || g_iArmor >= g_iMaxAP )
            {
                set_user_health(iAttacker, g_iMaxHP);
                set_user_armor(iAttacker, g_iMaxAP);
            }
            else
            {
                set_user_health(iAttacker, g_iHealth + g_iHealthHSAdd);
                set_user_armor(iAttacker, g_iHealth + g_iArmorHSAdd);
            }
        }
        else
        {
            if(g_iHealth >= g_iMaxHP || g_iArmor >= g_iMaxAP)
            {
                set_user_health(iAttacker, g_iMaxHP);
                set_user_armor(iAttacker, g_iMaxAP);
            }
            else
            {
                set_user_health(iAttacker, g_iHealth + g_iHealthAdd);
                set_user_armor(iAttacker, g_iHealth + g_iArmorAdd);
            }
        }
    }
    return PLUGIN_HANDLED;
}

public client_PreThink(id)
{
    if(!is_user_alive(id))    return PLUGIN_HANDLED;
    
    new nbut = get_user_button(id);
    new obut = get_user_oldbutton(id);
    
    if((nbut & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(obut & IN_JUMP))
    {
        if(CheckVIP(id) & VIP_JUMP)
        {
            if(jumpnum[id] < get_pcvar_num(GetCvar[VIP_EXTRA_JUMP]))
            {
                dojump[id] = true;
                jumpnum[id]++;
                return PLUGIN_CONTINUE;
            }
        }
    }
    
    if((nbut & IN_JUMP) && (get_entity_flags(id) & FL_ONGROUND))
    {
        jumpnum[id] = 0;
        return PLUGIN_CONTINUE;
    }
    
    return PLUGIN_CONTINUE;
}

public client_PostThink(id)
{
    if(!is_user_alive(id)) return PLUGIN_CONTINUE;
    
    if(CheckVIP(id) & VIP_JUMP)
    {
        if(dojump[id] == true)
        {
            new Float:velocity[3];
            entity_get_vector(id,EV_VEC_velocity, velocity);
            velocity[2] = random_float(265.0,285.0);
            entity_set_vector(id,EV_VEC_velocity, velocity);
            dojump[id] = false;
            return PLUGIN_CONTINUE;
        }
    }
    
    return PLUGIN_CONTINUE;
}

public client_authorized(id)
{
	new get_pass[65];
	get_user_info(id, g_szPassField, get_pass, charsmax(g_szPassField));

	CheckVIP(id);

	if(g_bIsPlayerVIP[id])
	{
		if(!equal(get_pass, g_szPass))
			server_cmd("kick #%d ^"Invalid vip password^"", get_user_userid(id));
	}
}
public ev_SpawnPost(id)
{
	if(!is_user_alive(id) || is_user_bot(id)) return;

	VIP_FREE();

	if (g_bIsVipFree == true && get_pcvar_num(GetCvar[VIP_FREE_STATE]) != 0)
	{
		new szFlags[MAX_FLAGS];
		get_pcvar_string(GetCvar[VIP_FREE_FLAGS], szFlags, charsmax(szFlags));
		SetVIP(id, read_flags(szFlags));
	}

	if(CheckVIP(id) & VIP_START_BENEFITS)
	{
		set_user_health(id, get_pcvar_num(GetCvar[VIP_START_HP]));
		cs_set_user_armor(id, get_pcvar_num(GetCvar[VIP_START_AP]), CS_ARMOR_VESTHELM);
		give_item(id, "weapon_hegrenade");
		if(get_user_team(id) == 2) cs_set_user_defuse(id, 1);
		for(new i; i < 2; i++){give_item(id, "weapon_flashbang");}
	}

	if(CheckVIP(id) & VIP_WEAPON_MENU) ShowPistolsMenu(id);
}


public ShowPistolsMenu(id)
{
	set_task(10.0, "hide", 67543, _, _,"b", 0);
	new menu = menu_create("\yChoose your Secondary Gun:", "PistolsGiver");
		
	menu_additem(menu, "Deagle", "", 0);
	menu_additem(menu, "USP", "", 0);
	menu_additem(menu, "Five-Seven", "", 0);

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);

}

public ShowRifelsMenu(id)
{

	new menu = menu_create("\yChoose your Primary Gun:", "WeaponsGiver");
		
	menu_additem(menu, "AK47", "", 0);
	menu_additem(menu, "M4A1", "", 0);
	menu_additem(menu, "AWP", "", 0);

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
}

public PistolsGiver(id,menu,item)
{
	if(item == MENU_EXIT) {menu_destroy(menu); return PLUGIN_HANDLED;}

	switch(item)
	{
		case 0:
		{
			arunca_armele(id,2);
			give_item(id, "weapon_deagle");
			cs_set_user_bpammo(id, CSW_DEAGLE, 35);
			if(iRound >= get_pcvar_num(GetCvar[VIP_ROUND_ARME])) ShowRifelsMenu(id);
		}
		case 1:
		{
			arunca_armele(id,2);
			give_item(id, "weapon_usp");
			cs_set_user_bpammo(id, CSW_USP, 120);
			if(iRound >= get_pcvar_num(GetCvar[VIP_ROUND_ARME])) ShowRifelsMenu(id);
		}
		case 2:
		{
			arunca_armele(id,2);
			give_item(id, "weapon_fiveseven");
			cs_set_user_bpammo(id, CSW_FIVESEVEN, 50);
			if(iRound >= get_pcvar_num(GetCvar[VIP_ROUND_ARME])) ShowRifelsMenu(id);
		}
	}
	

	return PLUGIN_HANDLED;

}

public WeaponsGiver(id,menu,item)
{
	if(item == MENU_EXIT) {menu_destroy(menu); return PLUGIN_HANDLED;}
	
	switch(item)
	{
		case 0:
		{
			arunca_armele(id,1);
			give_item(id, "weapon_ak47");
			cs_set_user_bpammo(id, CSW_AK47, 90);
		}
		case 1:
		{
			arunca_armele(id,1);
			give_item(id, "weapon_m4a1");
			cs_set_user_bpammo(id, CSW_M4A1, 90);
		}
		case 2:
		{
			arunca_armele(id,1);
			give_item(id, "weapon_awp");
			cs_set_user_bpammo(id, CSW_AWP, 30);
		}
	}

	return PLUGIN_HANDLED;

}

public ShowVipList(id) 
{
    new VipNames[33][32], Message[256], i, count, x, len;
    
    for (i = 1 ; i <= g_iMaxPlayers; i ++)
    {
        if (is_user_connected(i) && (CheckVIP(i) & VIP_LIST))
        {
            get_user_name(i, VipNames [count ++], charsmax (VipNames []));
        }
    }
    
    len = format (Message, charsmax (Message), "%s^1 VIP-ii online sunt:^4 ", TAG);
    
    if (count > 0) 
    {
        for(x = 0 ; x < count ; x ++) 
        {
            len += format(Message [len], charsmax (Message) - len, "%s%s ", VipNames [x], x < (count-1) ? ", ":"");
            
            if (len > 96) 
            {
                client_print_color(id, id, Message);
                
                len = format(Message, 255, " ");
            }
        }
        
        client_print_color(id, id, Message);
    }
    else 
    {
        client_print_color(id, id, "%s^1 Nu sunt^4 VIP^1-i online.", TAG);
    } 
    
    return PLUGIN_CONTINUE;
}

public SetVIP(id, Flags)
{
	g_bMarkVIP[id] = true;
	g_iAccess[id] = Flags;
	CheckVIP(id);
}

public CheckVIP(id)
{
	if(file_exists(g_iFile))
	{
		new iMaxLines, szLineToRead[129], szParse[4][65], szName[32], szSteamID[36], iTextLen;
		
		iMaxLines = file_size(g_iFile, FSOPT_LINES_COUNT);
		
		get_user_authid(id, szSteamID, charsmax(szSteamID));
		get_user_name(id, szName, charsmax(szName));

		for(new iLine = 0; iLine < iMaxLines; iLine++)
		{
			read_file(g_iFile, iLine, szLineToRead, charsmax(szLineToRead), iTextLen);
			trim(szLineToRead);

			if (strlen(szLineToRead) == 0 || szLineToRead[0] == ';' || (szLineToRead[0] == '/' && szLineToRead[1] == '/'))
				continue;

			parse(szLineToRead, szParse[0], charsmax(szParse[]), szParse[1], charsmax(szParse[]), szParse[2], charsmax(szParse[]), szParse[3], charsmax(szParse[]));
			
			remove_quotes(szParse[0]);
			remove_quotes(szParse[1]);
			remove_quotes(szParse[2]);
			remove_quotes(szParse[3]);
			
			get_time_x(szParse[3], szParse[0]);

			if(equali(szSteamID, szParse[0]) || equali(szName, szParse[0]))
			{
				g_bIsPlayerVIP[id] = true;
				copy(g_szPass, charsmax(g_szPass), szParse[1]);
				
				return read_flags(szParse[2]);
			}
		}
	}
	else
	{

		new iFileHandler = fopen(g_iFile, "wt");
		
		fputs(iFileHandler, "; VIPS LIST ^n^n");
		fputs(iFileHandler, "; ACCESE:^n^n");
		fputs(iFileHandler, "; a - Extra Jump^n");
		fputs(iFileHandler, "; b - HP/AP la start^n");
		fputs(iFileHandler, "; c - HP/AP KILL si pe HS^n");
		fputs(iFileHandler, "; d - Sunet la lovirea inamicului.^n");
		fputs(iFileHandler, "; e - Mesaj intrare / iesire de pe server^n");
		fputs(iFileHandler, "; f - Acces la /rsd^n");
		fputs(iFileHandler, "; g - Acces la meniul de Arme^n");
		fputs(iFileHandler, "; h - Apare in /vips (nu functioneaza la vip free)^n^n");
		fputs(iFileHandler, "; Model adaugare VIP:^n^n");
		fputs(iFileHandler, "; ^"SteamID sau Nume^" ^"Parola^" ^"Flagurile^" ^"Data expirare vip^"");

		fclose(iFileHandler);
	}
	
	g_bIsPlayerVIP[id] = false;
	
	if(g_bMarkVIP[id] == true)	{return g_iAccess[id];}	else {return VIP_NON;}
}

stock get_time_x(const szEndDate[], const szKey[])
{
	new szCurrentDate[64],
		szFormatedEndDate[64],
		szCurrentDay[32],
		szCurrentMonth[32],
		szCurrentYear[32],
		szEndDay[32],
		szEndMonth[32],
		szEndYear[32];
		
	copy(szFormatedEndDate, charsmax(szFormatedEndDate), szEndDate);
	get_time("%d-%m-%Y", szCurrentDate, charsmax(szCurrentDate));
	
	for(new ch = 0; ch <= charsmax(szFormatedEndDate); ch++)
	{
		if(szFormatedEndDate[ch] == '-')
			szFormatedEndDate[ch] = ' ';
	}
	
	for (new ch = 0; ch <= charsmax(szCurrentDate); ch++)
	{
		if(szCurrentDate[ch] == '-')
			szCurrentDate[ch] = ' ';
	}

	parse(szCurrentDate, szCurrentDay, charsmax(szCurrentDay), szCurrentMonth, charsmax(szCurrentMonth), szCurrentYear, charsmax(szCurrentYear));
	parse(szFormatedEndDate, szEndDay, charsmax(szEndDay), szEndMonth, charsmax(szEndMonth), szEndYear, charsmax(szEndYear));
	
	if (str_to_num(szFormatedEndDate) == 0)
		return;
	
	new iCurrentDay,
		iCurrentMonth,
		iCurrentYear,
		iEndDay,
		iEndMonth,
		iEndYear;
	
	iCurrentDay   = str_to_num(szCurrentDay);
	iCurrentMonth = str_to_num(szCurrentMonth);
	iCurrentYear  = str_to_num(szCurrentYear);
	
	iEndDay   = str_to_num(szEndDay);
	iEndMonth = str_to_num(szEndMonth);
	iEndYear  = str_to_num(szEndYear);
	
	if ((!iCurrentDay && !iCurrentMonth && !iCurrentYear) || (!iEndDay && !iEndMonth && !iEndYear))
		return;

	if (iEndYear < iCurrentYear)
	{
		line_erase(g_iFile, szKey);
	}
	else if (iEndYear == iCurrentYear)
	{
		if (iEndMonth < iCurrentMonth)
		{
			line_erase(g_iFile, szKey);
		}
		else if (iEndMonth == iCurrentMonth)
		{
			if (iEndDay < iCurrentDay)
			{
				line_erase(g_iFile, szKey);
			}
		}
	}
}

stock line_erase(const szFile[], const szKey[])
{
	if(file_exists(szFile))
	{
		new iMaxLines = file_size(szFile, FSOPT_LINES_COUNT);
		new Array:szFileLines, szLineToRead[400], iTextLen, szParse[4][65];
		szFileLines = ArrayCreate(400);
		for(new iLine = 0; iLine < iMaxLines; iLine++)
		{
			read_file(szFile, iLine, szLineToRead, charsmax(szLineToRead), iTextLen);
			parse(szLineToRead, szParse[0], charsmax(szParse[]), szParse[1], charsmax(szParse[]), szParse[2], charsmax(szParse[]), szParse[3], charsmax(szParse[]));
			remove_quotes(szParse[0]);
			remove_quotes(szParse[1]);
			remove_quotes(szParse[2]);
			remove_quotes(szParse[3]);
		
			if(equal(szParse[0], szKey))	continue;
			ArrayPushString(szFileLines, szLineToRead);
		}
		delete_file(szFile);
	
		for(new iLine = 0; iLine < ArraySize(szFileLines); iLine++)
		{
			ArrayGetString(szFileLines, iLine, szLineToRead, charsmax(szLineToRead));
			write_file(szFile, szLineToRead);
		}
		ArrayDestroy(szFileLines);
	}
}

stock VIP_FREE()
{
	new szTime[3], szHappyHours[32], szHappyHours_Start[32], szHappyHours_End[32];
	get_time("%H", szTime, charsmax(szTime));
	
	get_pcvar_string(GetCvar[VIP_FREE_HOURS], szHappyHours, charsmax(szHappyHours));
	
	for(new ch = 0; ch <= charsmax(szHappyHours); ch++)
	{
		if (szHappyHours[ch] == '-')
			szHappyHours[ch] = ' ';
	}
	
	parse(szHappyHours, szHappyHours_Start, charsmax(szHappyHours_Start), szHappyHours_End, charsmax(szHappyHours_End));
	
	new iTime, iHappyHourStart, iHappyHourEnd;
	
	iTime = str_to_num(szTime);
	iHappyHourStart = str_to_num(szHappyHours_Start);
	iHappyHourEnd = str_to_num(szHappyHours_End);
	
	if(iHappyHourEnd > iTime >= iHappyHourStart)
	{
        g_bIsVipFree = true;
	}
	else
	{
		g_bIsVipFree = false;
	}
}

stock arunca_armele(id, tip_arma)
{
	static Weapons[32], Num, i, WeaponID;
	Num = 0;
	get_user_weapons(id, Weapons, Num);
	for(i = 0; i < Num; i ++)
	{
		WeaponID = Weapons[i];
		if((tip_arma == 1 && ((1 << WeaponID) & PRIMARY_WEAPONS_BIT_SUM)) || (tip_arma == 2 && ((1 << WeaponID) & SECONDARY_WEAPONS_BIT_SUM )))
		{
			static DropName[32], WeaponEntity;
			get_weaponname(WeaponID, DropName, charsmax(DropName));
			WeaponEntity = fm_find_ent_by_owner(-1, DropName, id);
			set_pev(WeaponEntity, pev_iuser1, cs_get_user_bpammo (id, WeaponID));
			engclient_cmd(id, "drop", DropName);
			cs_set_user_bpammo(id, WeaponID, 0);
		}
	}
}

