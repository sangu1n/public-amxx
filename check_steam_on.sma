#include <amxmodx>
#include <hamsandwich>
#include <fun>
#include <cstrike>
#include <amxmisc>

#define HLDS
//#define REHLDS

#define CHAT_PREFIX "^4[^3LALEAGANE.RO^4]^1"

#define DEAD (1<<0)
#define VIP (1<<2)
#define RED Red
#define BLUE Blue
#define GREY Grey
#define ColorChat colorx

enum _: Cvars	{	runda, viata, armura	}
enum 			{	Grey = 33, Red, Blue    }

new Config[Cvars];

new iRound;
new MaxPlayers;

new const Comenzi[] =
{
	"say /steamon",
	"say /steam",
	"say /steams",
	"say_team /steamon",
	"say_team /steam",
	"say_team /steams"
};
new const _GetPointerMethod[] = 
{
	"CheckMethod1", 
	"CheckMethod2", 
	"CheckMethod3", 
	"CheckMethod4",
	"CheckMethod5", 
	"CheckMethod6",
	"CheckMethod7", 
	"CheckMethod8", 
	"CheckMethod9"
};


public plugin_init()
{
	register_plugin("STEAM BENEFITS", "1.0", "SenorAMXX");

	Config[viata]	= register_cvar("steam_hp_start", "105");
	Config[armura]	= register_cvar("steam_ap_start", "110");
	Config[runda]	= register_cvar("steam_deagle_round", "2");

	register_logevent("logev_Restart", 2, "1&Restart_Round", "1&Game_Commencing");
	register_event("HLTV", "ev_NewRound", "a", "1=0", "2=0");
	RegisterHam(Ham_Spawn, "player", "spawn_give", true);

	MaxPlayers = get_maxplayers();

	new text[200]; formatex(text, charsmax(text), "%s", Comenzi );
	for(new SenorAMXX; SenorAMXX < sizeof(Comenzi); SenorAMXX++) register_clcmd(text[SenorAMXX], "CheckSteam");
}

public reunion_check()
{
	static reunion_check, v;
	for(v = 0; v < sizeof(_GetPointerMethod); v++)
	{
		if(reunion_check || (reunion_check = get_cvar_pointer(_GetPointerMethod[v])))
		{
			return(get_cvar_pointer(_GetPointerMethod[v]) == 1) ? true : false;
		}
	}
	return false;
}

public logev_Restart()	iRound = 0;
public ev_NewRound()	iRound++;



public spawn_give(id)
{
	if(!is_user_alive(id) || is_user_bot(id) || is_user_hltv(id))	return;

	if(iRound >= get_pcvar_num(Config[runda]))
	set_user_health(id, get_pcvar_num(Config[viata]));
	cs_set_user_armor(id, get_pcvar_num(Config[armura]), CS_ARMOR_VESTHELM);
}

public CheckSteam(id) {
	new VipNames[33][32], Message[256], i, count, x, len;
	
	for (i = 1 ; i <= MaxPlayers; i ++)
	{
		if (is_user_connected(i) && is_user_steam(i))
		{
			get_user_name(i, VipNames [count ++], charsmax (VipNames []));
		}
	}
	
	len = format (Message, charsmax (Message), "%s^1 Steam ON:^4 ", CHAT_PREFIX);
	
	if (count > 0) 
	{
		for(x = 0 ; x < count ; x ++) 
		{
			len += format (Message [len], charsmax (Message) - len, "%s%s ", VipNames [x], x < (count-1) ? " | ":"");
			
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
		colorx(id, id, "%s^1 Nu sunt^4 jucatori cu steam^1-i online.", CHAT_PREFIX);
	} 
	
	return PLUGIN_CONTINUE;


}


#if defined HLDS
stock bool:is_user_steam(id)
{
    static dp_pointer;
    if(dp_pointer || (dp_pointer = get_cvar_pointer("dp_r_id_provider")))
    {
        server_cmd("dp_clientinfo %d", id);
        server_exec();
        return (get_pcvar_num(dp_pointer) == 2) ? true : false;
    }
    return false;
}
#endif

#if defined REHLDS
stock bool:is_user_steam(id)	reunion_check();
#endif

#if defined HLDS && defined REHLDS	
	set_fail_state("Ori HLDS ori REHLDS ... Hotaraste-te bro :D");
#endif











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
