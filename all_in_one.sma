#include <amxmodx>
#include <cstrike>
#include <fun>
#include <amxmisc>
#include <hamsandwich>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <geoip>



/* --== [ AMXX ACCESSES ] ==- */
#define ADMIN_ACCESS_IMMUNITY   (1<<0)      /* Flag a */
#define ADMIN_ACCESS_CHAT       (1<<1)      /* Flag b */
#define ADMIN_ACCESS_KICK       (1<<2)      /* Flag c */
#define ADMIN_ACCESS_SLAY       (1<<3)      /* Flag d */
#define ADMIN_ACCESS_TRANSFER   (1<<4)      /* Flag e */
#define ADMIN_ACCESS_MAP        (1<<5)      /* Flag f */
#define ADMIN_ACCESS_CVAR       (1<<6)      /* Flag g */
#define ADMIN_ACCESS_CHNG_NICK  (1<<7)      /* Flag h */
//#define ADMIN_ACCESS_LAST     (1<<8)    /* Flag i */
#define ADMIN_ACCESS_BAN        (1<<9)      /* Flag j */

/* --== [ CUSTOM ACCESSES ] ==- */
#define CUSTOM_SS_ACCESS        (1<<10)     /* Flag k */
//#define CUSTOM_GAG_ACCESS       (1<<11)     /* Flag l */


/* --== [ VIP ACCESSES ] ==-- */
#define VIP_ACCESS_VIP_LIST     (1<<15)     /* Flag p */
#define VIP_ACCESS_WPNS_MNU     (1<<16)     /* Flag q */
#define VIP_ACCESS_DMG_INFO     (1<<17)     /* Flag r */
#define VIP_ACCESS_MSG_INFO     (1<<18)     /* Flag s */
#define VIP_ACCESS_EXT_JUMP     (1<<19)     /* Flag t */
#define VIP_ACCESS_SPAWN_BNF    (1<<20)     /* Flag u */
#define VIP_ACCESS_KILL_GAIN    (1<<21)     /* Flag v */
#define VIP_ACCESS_RESET_DTH    (1<<22)     /* Flag w */


/* --== [ OTHER MACROS ] ==-- */
#define ROOT_ACCESS             (1<<24)     /* Flag y */
#define NULL_ACCESS             (1<<25)     /* Flag z */
#define MAX_FLAGS 20
#define TASKID 969696
//#define valid_ent(%0) (1 <= %0 <= g_iMaxPlayers)


/* --== [ Constants ] ==- */
new const PLUGIN_NAME[] = "AMXX ALL IN ONE"
new const VERSION[]     = "1.0"
new const AUTHOR[]      = "SenorAMXX"

static const g_szLocalFile[] = "addons/amxmodx/configs/aio_accesses.ini"
static const g_iFileX[]      = "addons/amxmodx/configs/vip_blocked_maps.ini";
static const g_iCfgFile[]    = "addons/amxmodx/configs/aio_cfg.cfg"

new g_CharToRemove[] = "/"
new const g_ChatCommands[][] =
{
    "/ss",
    "/map",
    "/kick",
    "/slay",
    "/slap",
    "/transfer",
    "/nick",
    "/cvar",
    "/say",
    "/psay"
}

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|
                                (1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|
                                (1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90);
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE);

new const TAG[] = "^4[AMXX]^1"


/* --== [ Global Variables ] ==- */
new g_get_password_field[65], g_user_password[65], g_get_flags[35],
    g_iMaxPlayers, g_iRSD[33], iRound, jumpnum[33] = 0, iSS, iMaxSS,
    copy_arg, FadeMSG

/* --== [ Global Booleans ] ==- */
new bool:g_bCheckForFlags[33]
new bool:g_bSetAccess[33]
new bool:g_bIsVipFree
new bool:dojump[33] = false
new bool:vip_blocked_map = false
new bool:is_SSed[33]
new bool:g_bIsGagged[33]

/* --== [ Enums ] ==-- */
enum _: PluginCvarInfos
{
    /* --== [ VIP PART ] ==-- */
    VIP_FREE_STATE, VIP_FREE_HOURS, VIP_FREE_FLAGS,
    VIP_EXTRA_JUMP,
    VIP_MAX_HP, VIP_MAX_AP,
    VIP_START_HP, VIP_START_AP,
    VIP_KILL_HP, VIP_KILL_AP,
    VIP_HS_HP, VIP_HS_AP,
    VIP_MAX_RSD,
    VIP_ROUND_ARME,

    /* --== [SS PART ] ==-- */
    MAX_SS, GREEN_SS
}
new getCvarInfo[PluginCvarInfos]

public plugin_init()
{
    register_plugin(PLUGIN_NAME, VERSION, AUTHOR)

    register_clcmd("say /rsd", "RSD_MAIN")
    register_clcmd("say /vips", "ShowVipList")

    register_clcmd("amx_ss", "screenShotMain")
    register_clcmd("amx_map", "cmd_map")
    register_clcmd("amx_kick", "cmd_kick")
    register_clcmd("amx_slay", "cmd_slay")
    register_clcmd("amx_ban", "cmd_ban")
    register_clcmd("amx_transfer", "cmd_transfer")
    register_clcmd("amx_slap", "cmd_slap")
    register_clcmd("amx_nick", "cmd_nick")
    register_clcmd("amx_cvar", "cmd_cvar")
    register_clcmd("amx_say", "cmd_say")
    register_clcmd("amx_psay", "cmd_psay")
    register_clcmd("amx_gag", "cmd_gag")
    register_clcmd("amx_ungag", "cmd_ungag")
    register_clcmd("say", "cmd_hud_say")
    register_clcmd("say_team", "cmd_admin_chat")

    RegisterHam(Ham_Spawn, "player", "ev_SpawnPost", 1)
    register_event("TextMsg", "round_rr_func", "a", "2=#Game_Commencing", "2=#Game_will_restart_in")
    register_logevent("ev_RoundStart", 2, "1=Round_Start")
    register_logevent("ev_RoundEnd", 2, "1=Round_End")
    RegisterHam(Ham_Killed, "player", "ham_PlayerKilled", 1)
    RegisterHam(Ham_TakeDamage, "player", "Damage", 1)

    getCvarInfo[VIP_EXTRA_JUMP] = register_cvar("vip_extra_jumps", "1")
    getCvarInfo[VIP_ROUND_ARME] = register_cvar("vip_round_arme", "3")
    getCvarInfo[VIP_MAX_HP]     = register_cvar("vip_max_hp", "120")
    getCvarInfo[VIP_MAX_AP]     = register_cvar("vip_max_ap", "120")
    getCvarInfo[VIP_START_HP]   = register_cvar("vip_start_hp", "120")
    getCvarInfo[VIP_START_AP]   = register_cvar("vip_start_ap", "100")
    getCvarInfo[VIP_KILL_HP]    = register_cvar("vip_hp_kill", "3")
    getCvarInfo[VIP_KILL_AP]    = register_cvar("vip_ap_kill", "5")
    getCvarInfo[VIP_HS_HP]      = register_cvar("vip_hs_hp", "5")
    getCvarInfo[VIP_HS_AP]      = register_cvar("vip_hs_ap", "8")
    getCvarInfo[VIP_MAX_RSD]    = register_cvar("vip_max_rsd", "3")
    getCvarInfo[MAX_SS]         = register_cvar("maxim_screenshots", "3")
    getCvarInfo[GREEN_SS]       = register_cvar("green_ss", "1")

    getCvarInfo[VIP_FREE_STATE] = register_cvar("vip_free_state", "1")
    getCvarInfo[VIP_FREE_HOURS] = register_cvar("vip_free_hours", "10-20")
    getCvarInfo[VIP_FREE_FLAGS] = register_cvar("vip_free_flags", "abcd")


    FadeMSG = get_user_msgid("ScreenFade")

    get_cvar_string("amx_password_field", g_get_password_field, charsmax(g_get_password_field))

    arrayset(g_bCheckForFlags, false, charsmax(g_bCheckForFlags))
    arrayset(g_bSetAccess, false, charsmax(g_bSetAccess))

    g_iMaxPlayers = get_maxplayers()


    CheckMap()
}

public plugin_cfg()
{
    if(file_exists(g_iCfgFile))
    {
        server_cmd("exec %s", g_iCfgFile)
        server_print("FISIERUL SPECIAL ESTE EXECUTAT")
        server_cmd("exec banned.cfg")
        server_cmd("exec listip.cfg")
    }
    else
    {
        new iFileHandler = fopen(g_iCfgFile, "wt");
       
        fputs(iFileHandler, "; --== [ Super AMXMODX CFG File ] ==--^n^n");
        fputs(iFileHandler, "vip_extra_jumps ^"1^"^n");
        fputs(iFileHandler, "vip_round_arme ^"3^"^n");
        fputs(iFileHandler, "vip_max_hp ^"120^"^n");
        fputs(iFileHandler, "vip_max_ap ^"120^"^n");
        fputs(iFileHandler, "vip_start_hp ^"120^"^n");
        fputs(iFileHandler, "vip_start_ap ^"120^"^n");
        fputs(iFileHandler, "vip_hp_kill ^"3^"^n");
        fputs(iFileHandler, "vip_ap_kill ^"5^"^n");
        fputs(iFileHandler, "vip_hs_hp ^"5^"^n");
        fputs(iFileHandler, "vip_hs_ap ^"8^"^n");
        fputs(iFileHandler, "vip_max_rsd ^"3^"^n");
        fputs(iFileHandler, "maxim_screenshots ^"3^"^n");
        fputs(iFileHandler, "green_ss ^"1^"^n");
        fputs(iFileHandler, "vip_free_state ^"1^"^n");
        fputs(iFileHandler, "vip_free_hours ^"23-09^"^n");
        fputs(iFileHandler, "vip_free_flags ^"pqrstuvw^"^n");

        fclose(iFileHandler);
    }
}

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
            if(strlen(szLineToRead) == 0 || szLineToRead[0] == ';' || (szLineToRead[0] == '/' && szLineToRead[1] == '/'))    continue;
            parse(szLineToRead, szParse[0], charsmax(szParse[]));
            remove_quotes(szParse[0]);

            if(equali(mapname, szParse[0]))    vip_blocked_map = true
        }
    }
    else
    {
        new iFileHandler = fopen(g_iFileX, "wt");
       
        fputs(iFileHandler, ";  --== [ Super AMXMODX VIP Blocked Maps File ] ==--^n^n");
        fputs(iFileHandler, "bb_castle_final^n");
        fputs(iFileHandler, "fy_snow^n");

        fclose(iFileHandler);
    }
}
public round_rr_func()
{
    remove_task(67543)
    iRound = 0
}
public Damage(id, idinflictor, iAttacker, Float:damage, damagebits)
{
    if(damage <= 0 || !(function_get_flags(iAttacker) & VIP_ACCESS_DMG_INFO || function_get_flags(iAttacker) & ROOT_ACCESS))    return;
   
    client_cmd(iAttacker, "spk fvox/bell") ;
}

public ev_RoundStart()
{
    iRound++
}

public ev_RoundEnd()
{
    for(new i = 0; i < g_iMaxPlayers; i++)
    {
        g_bSetAccess[i] = false
    }
    remove_task(67543)
}    

public ev_SpawnPost(id)
{
    if (!is_user_alive(id) && !is_user_bot(id)) return
    
    VIP_FREE()
    
    if(g_bIsVipFree == true && get_pcvar_num(getCvarInfo[VIP_FREE_STATE]) != 0)
    {
        new szFlags[MAX_FLAGS]
        get_pcvar_string(getCvarInfo[VIP_FREE_FLAGS], szFlags, charsmax(szFlags))
        function_set_flags(id, read_flags(szFlags))
    }
    new szPassword[65]
    get_user_info(id, g_get_password_field, szPassword, charsmax(szPassword))
    
    function_get_flags(id)
    
    if(g_bCheckForFlags[id])
    {
        if(!equal(szPassword, g_user_password))
        server_cmd("kick #%d ^"Invalid Password^"", get_user_userid(id))
    }

    if(function_get_flags(id) & VIP_ACCESS_SPAWN_BNF || function_get_flags(id) & ROOT_ACCESS && !vip_blocked_map)
    {
        set_user_health(id, get_pcvar_num(getCvarInfo[VIP_START_HP]));
        cs_set_user_armor(id, get_pcvar_num(getCvarInfo[VIP_START_AP]), CS_ARMOR_VESTHELM);
        give_item(id, "weapon_hegrenade");
        if(get_user_team(id) == 2) cs_set_user_defuse(id, 1);
        for(new i; i < 2; i++){give_item(id, "weapon_flashbang");}
    }

    if((function_get_flags(id) & VIP_ACCESS_WPNS_MNU || function_get_flags(id) & ROOT_ACCESS) && !vip_blocked_map) ShowPistolsMenu(id);
}

public client_putinserver(id)
{   
    new szPlayerName[33]
    get_user_name(id, szPlayerName, charsmax(szPlayerName))

    if(function_get_flags(id) & VIP_ACCESS_MSG_INFO || function_get_flags(id) & ROOT_ACCESS)
    {
        client_print_color(0, 0,"%s ^3VIP-ul ^4%s^3 s-a conectat pe server!",TAG, szPlayerName)
    }
    
    is_SSed[id] = false
}
public client_disconnected(id)
{
    new szPlayerName[33], szPlayerIP[22], szPlayerSteamID[33]

    get_user_name(id, szPlayerName, charsmax(szPlayerName))

    if(function_get_flags(id) & VIP_ACCESS_MSG_INFO || function_get_flags(id) & ROOT_ACCESS)
    {
        client_print_color(0, 0,"%s ^3VIP-ul ^4%s^3 s-a deconectat de pe server!",TAG, szPlayerName)
    }

    get_user_name(copy_arg, szPlayerName, charsmax(szPlayerName))
    get_user_ip(copy_arg, szPlayerIP, charsmax(szPlayerIP), 1)
    get_user_authid(copy_arg, szPlayerSteamID, charsmax(szPlayerSteamID))

    if(is_SSed[copy_arg])
    {
        client_print_color(0, 0, "%s %s (^3%s ^4| ^3%s^1) a dat drop cand i s-au cerut poze !",TAG, szPlayerName, szPlayerIP, szPlayerSteamID)
        is_SSed[copy_arg] = false
    }
    
}

public screenShotMain(id)
{
    if(!(function_get_flags(id) & CUSTOM_SS_ACCESS || function_get_flags(id) & ROOT_ACCESS))
    {
        client_print_color(id, id, "%s Nu ai acces la comanda.", TAG)
        console_print(id, "%s Nu ai acces la comanda.", TAG)
        return PLUGIN_HANDLED
    }

    new szArg[33], szPlayerName[33], szPlayerSteamID[32], szPlayerIP[22], szAdminName[33]
    read_argv(1, szArg, charsmax(szArg))

    if(equali(szArg[id], "") || equali(szArg[id], " "))
    {
        client_print_color(id, id, "%s Format corect: ^3/ss ^"nume player^"", TAG)
        console_print(id, "%s Format corect: amx_ss ^"nume jucator^".", TAG)
        return PLUGIN_HANDLED
    }
    

    new iPlayer = cmd_target(id, szArg)

    if(!iPlayer) return PLUGIN_HANDLED

    if(function_get_flags(iPlayer) & ADMIN_ACCESS_IMMUNITY || function_get_flags(iPlayer) & ROOT_ACCESS)    
    {
        client_print_color(id, id, "%s Acces protejat.", TAG)
        console_print(id, "%s Acces protejat.", TAG)
        return PLUGIN_HANDLED
    }

    if(!is_user_alive(iPlayer)
    ||is_user_bot(iPlayer)
    ||is_user_hltv(iPlayer)) return PLUGIN_HANDLED

    iSS = 0
    iMaxSS = get_pcvar_num(getCvarInfo[MAX_SS])

    get_user_name(iPlayer, szPlayerName, charsmax(szPlayerName))
    get_user_authid(iPlayer, szPlayerSteamID, charsmax(szPlayerSteamID))
    get_user_ip(iPlayer, szPlayerIP, charsmax(szPlayerIP), 1)

    client_print_color(id, id,"%s I-ai facut ^4%d ^1poze lui [^3%s / %s / %s^1]", TAG, iMaxSS, szPlayerName, szPlayerSteamID, szPlayerIP)

    for(new spam = 0; spam < 3; spam++)    client_cmd(id,"say_team @ I-am facut poze lui %s", szPlayerName)

    is_SSed[iPlayer] = true

    new szHostName[64], szGetTime[32]

    get_user_name(id, szAdminName, charsmax(szAdminName))
    get_cvar_string("hostname", szHostName, charsmax(szHostName))
    get_time("%d/%m/%Y - %H:%M:%S", szGetTime, charsmax(szGetTime))

    client_print(iPlayer, print_center, "[STAMPILA]^r** [POZA : #%d] **", iSS + 1)

    client_print_color(iPlayer, iPlayer, "^1----------------------[%s]----------------------", TAG)
    client_print_color(iPlayer, iPlayer, "^3[*]^1 ADMIN NAME : ^3%s", szAdminName)
    client_print_color(iPlayer, iPlayer, "^3[*]^1 YOUR STATS : ^3%s ^4&^3 %s ^4&^3 %s", szPlayerName, szPlayerSteamID, szPlayerIP)
    client_print_color(iPlayer, iPlayer, "^3[*]^1 TIME STAMP : ^3%s", szGetTime)
    client_print_color(iPlayer, iPlayer, "^1----------------------[%s]----------------------", TAG)

    client_cmd(iPlayer, "snapshot")

    copy_arg = iPlayer

    iSS++
    set_task(1.0, "special_ss", TASKID, _, _, "b")
    return PLUGIN_HANDLED

}

public special_ss(id)
{
    new green = get_pcvar_num(getCvarInfo[MAX_SS]) - get_pcvar_num(getCvarInfo[GREEN_SS])
    if(iSS < iMaxSS)
    {
        if(iSS >= green)
        {
            message_begin(MSG_ONE, FadeMSG, {0,0,0}, copy_arg)
            write_short(14<<7)
            write_short(58<<6)
            write_short(1<<0)
            write_byte(5)
            write_byte(255)
            write_byte(0)
            write_byte(255)
            message_end()
        }

        new szGetTime[32]
        get_time("%d/%m/%Y - %H:%M:%S", szGetTime, charsmax(szGetTime))

        new szPlayerName[33], szPlayerSteamID[32], szPlayerIP[22]

        get_user_name(copy_arg, szPlayerName, charsmax(szPlayerName))
        get_user_authid(copy_arg, szPlayerSteamID, charsmax(szPlayerSteamID))
        get_user_ip(copy_arg, szPlayerIP, charsmax(szPlayerIP), 1)

        client_print(copy_arg, print_center, "[STAMPILA]^r** [POZA : #%d] **", iSS + 1)

        client_print_color(copy_arg, copy_arg, "^1----------------------[%s]----------------------", TAG)
        client_print_color(copy_arg, copy_arg, "^3[*]^1 YOUR STATS : ^3%s ^4&^3 %s ^4&^3 %s", szPlayerName, szPlayerSteamID, szPlayerIP)
        client_print_color(copy_arg, copy_arg, "^3[*]^1 TIME STAMP : ^3%s", szGetTime)
        client_print_color(copy_arg, copy_arg, "^1----------------------[%s]----------------------", TAG)

        client_cmd(copy_arg, "snapshot")
        iSS++
    }
        
        else
        {
            user_silentkill(copy_arg, 1)
            cs_set_user_team(copy_arg, CS_TEAM_SPECTATOR)
            remove_task(TASKID)
            
        }
    return PLUGIN_HANDLED
}

public RSD_MAIN(id)
{
    if((function_get_flags(id) & VIP_ACCESS_RESET_DTH) || (function_get_flags(id) & ROOT_ACCESS) && g_iRSD[id] < get_pcvar_num(getCvarInfo[VIP_MAX_RSD]))
    {
        for(new i; i < 2; i++) {cs_set_user_deaths(id, 0);}
        g_iRSD[id]++;
        client_print_color(id, id, "%s Ai folosit RSD de ^4%d^1/^4%d^1 ori harta aceasta.",TAG, g_iRSD[id], get_pcvar_num(getCvarInfo[VIP_MAX_RSD]));
    }
    else if(g_iRSD[id] >= get_pcvar_num(getCvarInfo[VIP_MAX_RSD]))
    {
        client_print_color(id, id, "%s Ai folosit deja RSD de ^4%d^1/^4%d^1 ori harta aceasta.",TAG, g_iRSD[id], get_pcvar_num(getCvarInfo[VIP_MAX_RSD]));
    }
    if(!(function_get_flags(id) & VIP_ACCESS_RESET_DTH || function_get_flags(id) & ROOT_ACCESS))
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

    if((function_get_flags(iAttacker) & VIP_ACCESS_KILL_GAIN || function_get_flags(iAttacker) & ROOT_ACCESS) && !vip_blocked_map)
    {
        new g_iIsHeadshot    = read_data(3);
        new g_iHealth        = get_user_health(iAttacker);
        new g_iArmor        = get_user_armor(iAttacker);
        new g_iHealthAdd    = get_pcvar_num(getCvarInfo[VIP_KILL_HP]);
        new g_iHealthHSAdd    = get_pcvar_num(getCvarInfo[VIP_HS_HP]);
        new g_iArmorAdd        = get_pcvar_num(getCvarInfo[VIP_KILL_AP]);
        new g_iArmorHSAdd    = get_pcvar_num(getCvarInfo[VIP_HS_AP]);
        new g_iMaxHP        = get_pcvar_num(getCvarInfo[VIP_MAX_HP]);
        new g_iMaxAP        = get_pcvar_num(getCvarInfo[VIP_MAX_AP]);
       
        if(g_iIsHeadshot)
        {
            if(g_iHealth >= g_iMaxHP || g_iArmor >= g_iMaxAP)
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
    if(!is_user_alive(id) && vip_blocked_map)    return PLUGIN_HANDLED;
   
    new nbut = get_user_button(id);
    new obut = get_user_oldbutton(id);
   
    if((nbut & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(obut & IN_JUMP))
    {
        if(function_get_flags(id) & VIP_ACCESS_EXT_JUMP || function_get_flags(id) & ROOT_ACCESS)
        {
            if(jumpnum[id] < get_pcvar_num(getCvarInfo[VIP_EXTRA_JUMP]))
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
    if(vip_blocked_map) return PLUGIN_HANDLED
    if(!is_user_alive(id)) return PLUGIN_CONTINUE;
   
    if(function_get_flags(id) & VIP_ACCESS_EXT_JUMP || function_get_flags(id) & ROOT_ACCESS)
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
            if(iRound >= get_pcvar_num(getCvarInfo[VIP_ROUND_ARME])) ShowRifelsMenu(id);
        }
        case 1:
        {
            arunca_armele(id,2);
            give_item(id, "weapon_usp");
            cs_set_user_bpammo(id, CSW_USP, 120);
            if(iRound >= get_pcvar_num(getCvarInfo[VIP_ROUND_ARME])) ShowRifelsMenu(id);
        }
        case 2:
        {
            arunca_armele(id,2);
            give_item(id, "weapon_fiveseven");
            cs_set_user_bpammo(id, CSW_FIVESEVEN, 50);
            if(iRound >= get_pcvar_num(getCvarInfo[VIP_ROUND_ARME])) ShowRifelsMenu(id);
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
        if (is_user_connected(i) && (function_get_flags(i) & VIP_ACCESS_VIP_LIST || function_get_flags(id) & ROOT_ACCESS))
        {
            get_user_name(i, VipNames [count ++], charsmax (VipNames []));
        }
    }
   
    len = formatex(Message, charsmax (Message), "%s^1 VIP-ii online sunt:^4 ", TAG);
   
    if (count > 0)
    {
        for(x = 0 ; x < count ; x ++)
        {
            len += formatex(Message [len], charsmax (Message) - len, "%s%s ", VipNames [x], x < (count-1) ? ", ":"");
           
            if (len > 96)
            {
                client_print_color(id, id, Message);
               
                len = formatex(Message, 255, " ");
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

public cmd_map(id)
{
    new szAdminName[33]
    get_user_name(id, szAdminName, charsmax(szAdminName))

    if(function_get_flags(id) & ADMIN_ACCESS_MAP || function_get_flags(id) & ROOT_ACCESS)
    {
        new szArg[32]
        new szArgLen = read_argv(1, szArg, charsmax(szArg))
    
        if (!is_map_valid(szArg) || contain(szArg, "..") != -1)
        {
            console_print(id, "%s Harta este invalida.", TAG)
            client_print_color(id, id, "%s Harta este invalida.", TAG)
            return PLUGIN_HANDLED
        }
        client_print_color(0, 0, "%s Admin-ul %s a schimbat harta in %s.", TAG, szAdminName, szArg)        
        set_task(2.0, "chMap", 0, szArg, szArgLen + 1)
    }
    else
    {
        client_print_color(id, id, "%s Nu ai acces la comanda.", TAG)
        console_print(id, "%s Nu ai acces la comanda.", TAG)
        return PLUGIN_HANDLED
    }
    return PLUGIN_HANDLED
}

public chMap(map[]) engine_changelevel(map);

public cmd_kick(id)
{
    new szArg[32], szArg2[33]
    read_argv(1, szArg, charsmax(szArg))
    read_argv(2, szArg2, charsmax(szArg2))
    remove_quotes(szArg2)
    new iPlayer = cmd_target(id, szArg)
    if(!iPlayer) return PLUGIN_HANDLED


    new szPlayerName[33], szAdminName[33]
    get_user_name(id, szAdminName, charsmax(szAdminName))
    get_user_name(iPlayer, szPlayerName, charsmax(szPlayerName))

    

    if(function_get_flags(id) & ADMIN_ACCESS_KICK || function_get_flags(id) & ROOT_ACCESS)
    {
        if(equali(szArg[id], "") || equali(szArg[id], " "))
        {
            client_print_color(id, id, "%s Format corect: ^3/kick ^"nume player^" ^"motiv^"", TAG)
            console_print(id, "%s Format corect: amx_kick ^"nume player^" ^"motiv^"", TAG)
            return PLUGIN_HANDLED
        }

        if(function_get_flags(iPlayer) & ADMIN_ACCESS_IMMUNITY || function_get_flags(iPlayer) & ROOT_ACCESS)    
        {
            client_print_color(id, id, "%s Acces protejat.", TAG)
            console_print(id, "%s Acces protejat.", TAG)
            return PLUGIN_HANDLED
        }

        new szUserID = get_user_userid(iPlayer)

        if(is_user_bot(iPlayer))
        {
            server_cmd("kick #%d", szUserID)
        }
        else
        {
            if(equali(szArg2[id], "") || equali(szArg2[id], " "))
            {
                server_cmd("kick #%d", szUserID)
                client_print_color(0, 0, "%s Admin %s i-a dat kick lui %s fara motiv!", TAG, szAdminName, szPlayerName)
                server_print("kick fara rason")
            }
            else
            {
                server_cmd("kick #%d ^"%s^"", szUserID, szArg2)
                client_print_color(0, 0, "%s Admin %s i-a dat kick lui %s cu motivul %s!", TAG, szAdminName, szPlayerName, szArg2)
                server_print("Kick szReason : %s", szArg2)
            }
        }
    }
    else
    {
        client_print_color(id, id, "%s Nu ai acces la comanda.", TAG)
        console_print(id, "%s Nu ai acces la comanda.", TAG)
        return PLUGIN_HANDLED
    }
    return PLUGIN_HANDLED
}

public cmd_slay(id)
{
    new szArg[32], szArg2[33]
    read_argv(1, szArg, charsmax(szArg))
    read_argv(2, szArg2, charsmax(szArg2))
    remove_quotes(szArg2)
    new iPlayer = cmd_target(id, szArg)
    if(!iPlayer) return PLUGIN_HANDLED

    new szPlayerName[33], szAdminName[33]

    get_user_name(id, szAdminName, charsmax(szAdminName))
    get_user_name(iPlayer, szPlayerName, charsmax(szPlayerName))

    if(function_get_flags(id) & ADMIN_ACCESS_SLAY || function_get_flags(id) & ROOT_ACCESS)
    {
        if(equali(szArg[id], "") || equali(szArg[id], " "))
        {
            client_print_color(id, id, "%s Format corect: ^3/slay ^"nume player^" ^"motiv^"", TAG)
            console_print(id, "%s Format corect: amx_slay ^"nume player^" ^"motiv^"", TAG)
            return PLUGIN_HANDLED
        }

        if(function_get_flags(iPlayer) & ADMIN_ACCESS_IMMUNITY || function_get_flags(iPlayer) & ROOT_ACCESS)    
        {
            client_print_color(id, id, "%s Acces protejat.", TAG)
            console_print(id, "%s Acces protejat.", TAG)
            return PLUGIN_HANDLED
        }

        if(equali(szArg2[id], "") || equali(szArg2[id], " "))
        {
            user_silentkill(iPlayer)
            client_print_color(0, 0, "%s Admin %s i-a dat slay lui %s fara motiv!", TAG, szAdminName, szPlayerName)
        }
        else
        {
            user_silentkill(iPlayer)
            client_print_color(0, 0, "%s Admin %s i-a dat slay lui %s cu motivul %s!", TAG, szAdminName, szPlayerName, szArg2)
        }
    }
    else
    {
        client_print_color(id, id, "%s Nu ai acces la comanda.", TAG)
        console_print(id, "%s Nu ai acces la comanda.", TAG)
        return PLUGIN_HANDLED
    }
    return PLUGIN_HANDLED
}

public cmd_slap(id)
{
    new szArg[32], szArg2[33]
    read_argv(1, szArg, charsmax(szArg))
    read_argv(2, szArg2, charsmax(szArg2))
    remove_quotes(szArg2)

    new szDamage = clamp(str_to_num(szArg2))
    new szDamageX = random_num(0, 99)
    new iPlayer = cmd_target(id, szArg)
    if(!iPlayer) return PLUGIN_HANDLED

    
    new szPlayerName[33], szAdminName[33]

    get_user_name(id, szAdminName, charsmax(szAdminName))
    get_user_name(iPlayer, szPlayerName, charsmax(szPlayerName))

    if(function_get_flags(id) & ADMIN_ACCESS_SLAY || function_get_flags(id) & ROOT_ACCESS)
    {
        if(equali(szArg[id], "") || equali(szArg[id], " "))
        {
            client_print_color(id, id, "%s Format corect: ^3/slap ^"nume player^" ^"power^"", TAG)
            console_print(id, "%s Format corect: amx_slap ^"nume player^" ^"power^"", TAG)
            return PLUGIN_HANDLED
        }

        if(function_get_flags(iPlayer) & ADMIN_ACCESS_IMMUNITY || function_get_flags(iPlayer) & ROOT_ACCESS)    
        {
            client_print_color(id, id, "%s Acces protejat.", TAG)
            console_print(id, "%s Acces protejat.", TAG)
            return PLUGIN_HANDLED
        }

        if(equali(szArg2[id], "") || equali(szArg2[id], " "))
        {
            user_slap(iPlayer, szDamageX)
            client_print_color(0, 0, "%s Adminul %s i-a dat slap lui %s cu %d power.", TAG, szAdminName, szPlayerName, szDamageX)
        }
        else
        {
            client_print_color(0, 0, "%s Adminul %s i-a dat slap lui %s cu %d power.", TAG, szAdminName, szPlayerName, szDamage)
            user_slap(iPlayer, szDamage)
        }
    }
    else
    {
        client_print_color(id, id, "%s Nu ai acces la comanda.", TAG)
        console_print(id, "%s Nu ai acces la comanda.", TAG)
        return PLUGIN_HANDLED
    }
    return PLUGIN_HANDLED
}

public cmd_transfer(id)
{
    new szArg[32], szArg2[33]
    read_argv(1, szArg, charsmax(szArg))
    read_argv(2, szArg2, charsmax(szArg2))
    remove_quotes(szArg2)
    new iPlayer = cmd_target(id, szArg)
    if(!iPlayer) return PLUGIN_HANDLED

    new szPlayerName[33], szAdminName[33]

    get_user_name(id, szAdminName, charsmax(szAdminName))
    get_user_name(iPlayer, szPlayerName, charsmax(szPlayerName))

    if(function_get_flags(id) & ADMIN_ACCESS_TRANSFER || function_get_flags(id) & ROOT_ACCESS)
    {
        if(equali(szArg[id], "") || equali(szArg[id], " "))
        {
            client_print_color(id, id, "%s Format corect: ^3/transfer ^"nume player^" ^"@T/@CT/@SPEC^"", TAG)
            console_print(id, "%s Format corect: amx_transfer ^"nume player^" ^"@T/@CT/@SPEC^"", TAG)
            return PLUGIN_HANDLED
        }

        if(szArg2[0] == '@')
        {
            if(equali(szArg2[1], "T") || equali(szArg2[1], "t"))
            {
                if(cs_get_user_team(iPlayer) == CS_TEAM_T)
                {
                    client_print_color(id, id, "%s Jucatorul %s este deja Terro.", TAG, szPlayerName)
                    return PLUGIN_HANDLED
                }
                else 
                {
                    client_print_color(id, id, "%s Ai mutat jucatorul %s la Terro.", TAG, szPlayerName)
                    client_print_color(iPlayer, iPlayer, "%s Ai fost mutat la Terro de adminul %s.", TAG, szAdminName)

                    user_silentkill(iPlayer)
                    cs_set_user_team(iPlayer, CS_TEAM_T)
                }
            }
            else if(equali(szArg2[1], "CT") || equali(szArg2[1], "ct"))
            {
                if(cs_get_user_team(iPlayer) == CS_TEAM_CT)
                {
                    client_print_color(id, id, "%s Jucatorul %s este deja Anti-Terro.", TAG, szPlayerName)
                    return PLUGIN_HANDLED
                }
                else 
                {
                    client_print_color(id, id, "%s Ai mutat jucatorul %s la Anti-Terro.", TAG, szPlayerName)
                    client_print_color(iPlayer, iPlayer, "%s Ai fost mutat la Anti-Terro de adminul %s.", TAG, szAdminName)

                    user_silentkill(iPlayer)
                    cs_set_user_team(iPlayer, CS_TEAM_CT)
                }
            }
            else if(equali(szArg2[1], "SPEC") || equali(szArg2[1], "spec"))
            {
                if(cs_get_user_team(iPlayer) == CS_TEAM_SPECTATOR)
                {
                    client_print_color(id, id, "%s Jucatorul %s este deja Spectator.", TAG, szPlayerName)
                    return PLUGIN_HANDLED
                }
                else 
                {
                    client_print_color(id, id, "%s Ai mutat jucatorul %s la Spectatori.", TAG, szPlayerName)
                    client_print_color(iPlayer, iPlayer, "%s Ai fost mutat la Spectatori de adminul %s.", TAG, szAdminName)

                    user_silentkill(iPlayer)
                    cs_set_user_team(iPlayer, CS_TEAM_SPECTATOR)
                }
            }
            
        }
    }
    else
    {
        client_print_color(id, id, "%s Nu ai acces la comanda.", TAG)
        console_print(id, "%s Nu ai acces la comanda.", TAG)
        return PLUGIN_HANDLED
    }
    return PLUGIN_HANDLED
}


public cmd_nick(id)
{
    new szArg[32], szArg2[33]
    read_argv(1, szArg, charsmax(szArg))
    read_argv(2, szArg2, charsmax(szArg2))
    remove_quotes(szArg2)
    new iPlayer = cmd_target(id, szArg)

    if(!iPlayer) return PLUGIN_HANDLED

    new szPlayerName[33], szAdminName[33]

    get_user_name(id, szAdminName, charsmax(szAdminName))
    get_user_name(iPlayer, szPlayerName, charsmax(szPlayerName))

    if(function_get_flags(id) & ADMIN_ACCESS_CHNG_NICK || function_get_flags(id) & ROOT_ACCESS)
    {
        if(id != iPlayer)
        {
            set_user_info(iPlayer, "name", szArg2)
            client_print_color(0, 0, "%s Admin-ul %s i-a schimbat numele lui %s in %s.", TAG, szAdminName, szPlayerName, szArg2)    
        }
        else
        {
            set_user_info(id, "name", szArg2)
            client_print_color(0, 0, "%s Admin-ul %s si-a schimbat numele in %s.", TAG, szAdminName, szArg2)    
        }
    }
    else
    {
        client_print_color(id, id, "%s Nu ai acces la comanda.", TAG)
        console_print(id, "%s Nu ai acces la comanda.", TAG)
        return PLUGIN_HANDLED
    }
    return PLUGIN_HANDLED
}

public cmd_cvar(id)
{
    new szArg[32], szArg2[33], szPointer
    read_argv(1, szArg, charsmax(szArg))
    read_argv(2, szArg2, charsmax(szArg2))

    new szAdminName[33]

    get_user_name(id, szAdminName, charsmax(szAdminName))

    if(function_get_flags(id) & ADMIN_ACCESS_CVAR || function_get_flags(id) & ROOT_ACCESS)
    {
        if(equal(szArg, "add"))
        {
            if((szPointer = get_cvar_pointer(szArg2)) != 0)
            {
                new szFlags = get_pcvar_flags(szPointer)

                if(!(szFlags & FCVAR_PROTECTED))
                {
                    set_pcvar_flags(szPointer, szFlags | FCVAR_PROTECTED)
                }
            }
            return PLUGIN_HANDLED
        }
        trim(szArg)

        if((szPointer = get_cvar_pointer(szArg)) == 0)
        {
            console_print(id, "%s Cvar invalid.", TAG)
            client_print_color(id, id, "%s Cvar invalid.", TAG)
            return PLUGIN_HANDLED
        }

        if(read_argc() < 3)
        {
            get_pcvar_string(szPointer, szArg2, charsmax(szArg2))
            console_print(id, "%s Valoarea cvarului %s este %s", TAG, szArg, szArg2)
            client_print_color(id, id, "%s Valoarea cvarului %s este %s", TAG, szArg, szArg2)
            return PLUGIN_HANDLED
        }
        set_pcvar_string(szPointer, szArg2)

        client_print_color(0, 0, "%s Adminul %s a setat valoare cvarului %s pe %s", TAG, szAdminName, szArg, szArg2) 
    }
    else
    {
        client_print_color(id, id, "%s Nu ai acces la comanda.", TAG)
        console_print(id, "%s Nu ai acces la comanda.", TAG)
        return PLUGIN_HANDLED
    }
    return PLUGIN_HANDLED
}

public cmd_say(id)
{
    new szText[192]
    read_args(szText, charsmax(szText))
    remove_quotes(szText)
    

    if(function_get_flags(id) & ADMIN_ACCESS_CHAT || function_get_flags(id) & ROOT_ACCESS)
    {
        if(!szText[0])  return PLUGIN_HANDLED
        client_print_color(0, 0, "%s Anunt Admin : %s", TAG, szText)
    }
    else
    {
        client_print_color(id, id, "%s Nu ai acces la comanda.", TAG)
        console_print(id, "%s Nu ai acces la comanda.", TAG)
        return PLUGIN_HANDLED
    }
    return PLUGIN_HANDLED
}

public cmd_hud_say(id)
{

    new szArg[6], szText[192], szCommand[192]
    read_argv(1, szArg, charsmax(szArg))
    read_args(szText, charsmax(szText))
    remove_quotes(szText)
    
    new szPlayerName[33], szAdminName[33]

    get_user_name(id, szAdminName, charsmax(szAdminName))
    get_user_name(id, szPlayerName, charsmax(szPlayerName))

    if(g_bIsGagged[id])
    {
        client_print_color(id, id, "%s Ai primit gag, inca nu poti scrie.", TAG)
        return PLUGIN_HANDLED
    }

    for(new i; i < sizeof g_ChatCommands; i++)
    {
        if(equal(szText, g_ChatCommands[i], strlen(g_ChatCommands[i])))
        {
            if(function_get_flags(id))
            {
                replace(szText, charsmax(szText), g_CharToRemove, "")
                formatex(szCommand, charsmax(szCommand), "amx_%s", szText)
                client_cmd(id, szCommand)
            }
            break
        }
    }


    if((function_get_flags(id) & ADMIN_ACCESS_CHAT || function_get_flags(id) & ROOT_ACCESS) && szArg[0] == '@')
    {
        const MAX_LINES_SHIFTING = 6
        static iLine = 0
        new szTag[MAX_LINES_SHIFTING]
            
        if(iLine > 0 )
        {
            for(new i=0; i < iLine; i++) szTag[i] = '^n'
        }
            
        iLine = ++iLine % MAX_LINES_SHIFTING
        set_hudmessage(144, 144, 144, 0.05, 0.5, 0, 6.0, 6.0, 0.5, 0.15, -1)
        show_hudmessage(0, "%s%s: %s", szTag, szAdminName, szText[1])
    }
    else if((function_get_flags(id) & ADMIN_ACCESS_CHAT || function_get_flags(id) & ROOT_ACCESS) && szArg[0] != '@') return PLUGIN_CONTINUE
    else if(!(function_get_flags(id) & ADMIN_ACCESS_CHAT || function_get_flags(id) & ROOT_ACCESS) && szArg[0] != '@') return PLUGIN_CONTINUE
    else if(!(function_get_flags(id) & ADMIN_ACCESS_CHAT || function_get_flags(id) & ROOT_ACCESS) && szArg[0] == '@')
    {
        client_print_color(id, id, "%s Nu ai acces la comanda.", TAG)
        console_print(id, "%s Nu ai acces la comanda.", TAG)
        return PLUGIN_HANDLED
    }
    
    return PLUGIN_HANDLED
}         

public cmd_admin_chat(id)
{
    new szArg[2], szText[192], iPlayers[32], iNum, iPlayer, szPlayerName[33]
    read_args(szText, charsmax(szText))
    read_argv(1, szArg, charsmax(szArg))
    remove_quotes(szText)
    get_players(iPlayers, iNum, "ch")

    if(szArg[0] != '@') return PLUGIN_CONTINUE

    get_user_name(id, szPlayerName, charsmax(szPlayerName))

    for (new bool:is_sender_admin = funcion_is_user(id) != 0, i = 0; i < iNum; ++i)
    {
        iPlayer = iPlayers[i]

        if (iPlayer == id || (function_get_flags(iPlayer) & ADMIN_ACCESS_CHAT || function_get_flags(iPlayer) & ROOT_ACCESS))
        {
            client_print_color(iPlayer, iPlayer, "^4[^3%s^4] ^1%s :  %s", is_sender_admin ? "STAFF" : "JUCATOR", szPlayerName, szText[1])
        }
    }

    return PLUGIN_HANDLED
}

public cmd_psay(id)
{   
    new szText[192], szPlayerName[33], szAdminName[33]
    read_args(szText, charsmax(szText))
    remove_quotes(szText)
    read_argv(1, szPlayerName, charsmax(szPlayerName))
    
    new iPlayer = cmd_target(id, szPlayerName, 0)
    if(!iPlayer) return PLUGIN_HANDLED

    

    get_user_name(id, szAdminName, charsmax(szAdminName))
    get_user_name(iPlayer, szPlayerName, charsmax(szPlayerName))

    new iLenght = strlen(szPlayerName) + 1

    if(szText[0] = '"' && szText[iLenght] == '"')
    {
        szText[0] = ' '
        szText[iLenght] = ' '
        iLenght += 2
    }

    if(function_get_flags(id) & ADMIN_ACCESS_CHAT || function_get_flags(id) & ROOT_ACCESS)
    {
        if(id && id != iPlayer)
        {
            client_print_color(id, id, "^4[^3PM ^1to: ^3%s^4] %s", szPlayerName, szText[iLenght])
            client_print_color(iPlayer, iPlayer, "^4[^3PM ^1from: ^3%s^4] %s", szAdminName, szText[iLenght])
        }
    }
    else
    {
        client_print_color(id, id, "%s Nu ai acces la comanda.", TAG)
        console_print(id, "%s Nu ai acces la comanda.", TAG)
        return PLUGIN_HANDLED
    }
    return PLUGIN_HANDLED
}

/*public cmd_gag(id)
{
    if(function_get_flags(id) & CUSTOM_GAG_ACCESS || function_get_flags(id) & ROOT_ACCESS)
    {
        new szArg[32], szReason[32]
        read_argv(1, szArg, charsmax(szArg))
        read_argv(2, szReason, charsmax(szReason))

        new iPlayer = cmd_target(id, szArg)
        if(!iPlayer) return PLUGIN_HANDLED

        new szPlayerName[32], szAdminName[32]
        get_user_name(id, szAdminName, charsmax(szAdminName))
        get_user_name(iPlayer, szPlayerName, charsmax(szPlayerName))

        if(!szArg[id]) return PLUGIN_HANDLED

        if(g_bIsGagged[iPlayer])
        {
            client_print_color(id, id, "%s Jucatorul %s are deja gag.", TAG, szPlayerName)
            return PLUGIN_HANDLED
        }

        if(szReason[0])
        {
            client_print_color(0, 0, "%s Admin-ul %s i-a interzis accesul la chat lui %s. Motiv: %s", TAG, szAdminName, szPlayerName, szReason)
            g_bIsGagged[iPlayer] = true
        }
        else
        {
            client_print_color(0, 0, "%s Admin-ul %s i-a interzis accesul la chat lui %s", TAG, szAdminName, szPlayerName)
            g_bIsGagged[iPlayer] = true
        }
        
    }

    else
    {
        client_print_color(id, id, "%s Nu ai acces la comanda.", TAG)
        console_print(id, "%s Nu ai acces la comanda.", TAG)
        return PLUGIN_HANDLED
    }
     
    return PLUGIN_HANDLED
}

public cmd_ungag(id)
{
    if(function_get_flags(id) & CUSTOM_GAG_ACCESS || function_get_flags(id) & ROOT_ACCESS)
    {
        new szArg[32]
        read_argv(1, szArg, charsmax(szArg))

        new iPlayer = cmd_target(id, szArg)
        if(!iPlayer) return PLUGIN_HANDLED

        if(!szArg[id]) return PLUGIN_HANDLED


        new szPlayerName[32], szAdminName[32]
        get_user_name(id, szAdminName, charsmax(szAdminName))
        get_user_name(iPlayer, szPlayerName, charsmax(szPlayerName))

        if(g_bIsGagged[iPlayer])
        {
            client_print_color(0, 0, "%s Admin-ul %s i-a redat accesul la chat lui %s.", TAG, szAdminName, szPlayerName)
            g_bIsGagged[iPlayer] = false
            return PLUGIN_HANDLED
        }
        else
        {
            client_print_color(id, id, "%s Jucatorul %s nu are gag.", TAG, szPlayerName)
            return PLUGIN_HANDLED
        }
    }
    else
    {
        client_print_color(id, id, "%s Nu ai acces la comanda.", TAG)
        console_print(id, "%s Nu ai acces la comanda.", TAG)
        return PLUGIN_HANDLED
    }

}*/


public cmd_ban(id)
{
    if(function_get_flags(id) & ADMIN_ACCESS_CHAT || function_get_flags(id) & ROOT_ACCESS)
    {
        new szTarget[32], szMinutes[32], szReason[32]
        read_argv(1, szTarget, charsmax(szTarget))
        read_argv(2, szMinutes, charsmax(szMinutes))
        read_argv(3, szReason, charsmax(szReason))

        if(!is_str_num(szMinutes))
        {
            console_print(id,"%s Format incorect.", TAG)
            return PLUGIN_HANDLED
        }
    
        new iPlayer = cmd_target(id, szTarget, 9)
    
        if(!iPlayer)    return PLUGIN_HANDLED

        if(equali(szTarget, "STEAM_ID_PENDING") ||
        equali(szTarget, "STEAM_ID_LAN") ||
        equali(szTarget, "HLTV") ||
        equali(szTarget, "4294967295") ||
        equali(szTarget, "VALVE_ID_LAN") ||
        equali(szTarget, "VALVE_ID_PENDING") ||
        equali(szTarget, "PENDING") ||
        equali(szTarget, "VALVE") ||
        equali(szTarget, "STEAM"))
        {
            console_print(id, "%s Nu poti interzice accesul userului '%s'.", TAG, szTarget);
            return PLUGIN_HANDLED;
        }

        if(str_to_num(szMinutes) < 0)   client_print(id, print_console, "%s Valoarea este mai mica decat 0.", TAG)
    
        new szPlayerSteamID[32], szPlayerName[32], szAdminName[32], szPlayerIP[32]
        
        new szPlayerID = get_user_userid(iPlayer)

        new nNum = str_to_num(szMinutes)
    
        get_user_authid(iPlayer, szPlayerSteamID, charsmax(szPlayerSteamID))
        get_user_name(iPlayer, szPlayerName, charsmax(szPlayerName))
        get_user_ip(iPlayer, szPlayerIP, charsmax(szPlayerIP), 1)
        get_user_name(id, szAdminName, charsmax(szAdminName))

        console_print(iPlayer, "^n^n^n[==================================]")
        console_print(iPlayer, "[         (Ban Informations)            ]")
        console_print(iPlayer, "[==================================]^n")
        console_print(iPlayer, ">> Admin Name : %s", szAdminName)
        console_print(iPlayer, ">> Your Name  : %s", szPlayerName)
        console_print(iPlayer, ">> Your IP      : %s", szPlayerIP)
        console_print(iPlayer, ">> Your Steam : %s", szPlayerSteamID)
        if(!nNum)       console_print(iPlayer, ">> Ban Lenght : Permanent Ban")
        else            console_print(iPlayer, ">> Ban Lenght : %s minutes", szMinutes)
        if(szReason[0]) console_print(iPlayer, ">> Ban Reason : %s", szReason)
        else            console_print(iPlayer, ">> Ban Reason : No specified reason")
        console_print(iPlayer, "[==================================]")
        console_print(iPlayer, "[         (Ban Informations)            ]")
        console_print(iPlayer, "[==================================]^n^n^n")
        if(szReason[0])
        {
            if(nNum)
            {
                client_print_color(0, 0, "%s Admin-ul %s i-a dat ban jucatorului %s pentru %s minut(e). Motiv: %s", TAG, szAdminName, szPlayerName, szMinutes, szReason)
            }
            else
            {
                client_print_color(0, 0, "%s Admin-ul %s i-a dat ban permanent jucatorului %s. Motiv: %s", TAG, szAdminName, szPlayerName, szReason)
            }

        }
        else
        {
            if(nNum)
            {
                client_print_color(0, 0, "%s Admin-ul %s i-a dat ban jucatorului %s pentru %s minut(e). Motiv nespecificat", TAG, szAdminName, szPlayerName, szMinutes)
            }
            else
            {
                client_print_color(0, 0, "%s Admin-ul %s i-a dat ban permanent jucatorului %s. Motiv nespecificat", TAG, szAdminName, szPlayerName)
            }
        }
        
        server_cmd("kick #%d Ai primit ban. Verifica-ti consola.", szPlayerID)
        server_cmd("wait; addip ^"%s^" ^"%s^"; wait; writeip", szMinutes, szPlayerIP)
    
    }
    else
    {
        client_print_color(id, id, "%s Nu ai acces la comanda.", TAG)
        console_print(id, "%s Nu ai acces la comanda.", TAG)
        return PLUGIN_HANDLED
    }
    return PLUGIN_HANDLED
}


public client_authorized(id)
{
    new szPassword[65]
    get_user_info(id, g_get_password_field, szPassword, charsmax(szPassword))
    
    function_get_flags(id)
    
    if(g_bCheckForFlags[id])
    {
        if(!equal(szPassword, g_user_password))
        server_cmd("kick #%d ^"Invalid Password^"", get_user_userid(id))
    }

    /*new szInfo[32]
    get_user_info(id, "r_banned", szInfo, charsmax(szInfo))

    if(strlen(szInfo) > 0)
    {
        if(get_systime() < str_to_num(szInfo))
        server_cmd("kick #%d ^"Ai fost banat pe acest server.^"", get_user_userid(id))
        return
    }*/
}

public function_get_flags(id)
{
    if(file_exists(g_szLocalFile))
    {
        new szPlayerName[33], szPlayerSteamID[33]
        new iMaxLines, szLineToRead[129], szParse[4][65],iTextLen
        
        iMaxLines = file_size(g_szLocalFile, FSOPT_LINES_COUNT)
        
        get_user_authid(id, szPlayerSteamID, charsmax(szPlayerSteamID))
        get_user_name(id, szPlayerName, charsmax(szPlayerName))
        
        for(new iLine = 0; iLine < iMaxLines; iLine++)
        {
            read_file(g_szLocalFile, iLine, szLineToRead, charsmax(szLineToRead), iTextLen)
            
            trim(szLineToRead)
            
            if (strlen(szLineToRead) == 0 || szLineToRead[0] == ';' || (szLineToRead[0] == '/' && szLineToRead[1] == '/'))
                continue
            
            parse(szLineToRead, szParse[0], charsmax(szParse[]), szParse[1], charsmax(szParse[]), szParse[2], charsmax(szParse[]), szParse[3], charsmax(szParse[]))
            
            remove_quotes(szParse[0])
            remove_quotes(szParse[1])
            remove_quotes(szParse[2])
            remove_quotes(szParse[3])
            
            VerificareData(szParse[3], szParse[0])
            
            if(equali(szPlayerSteamID, szParse[0]) || equali(szPlayerName, szParse[0]))
            {
                g_bCheckForFlags[id] = true
                copy(g_user_password, charsmax(g_user_password), szParse[1])
                
                return read_flags(szParse[2])
            }
        }
    }
    else
    {
        new iFileHandler = fopen(g_szLocalFile, "wt")
        
        fputs(iFileHandler, "; --== [ Super AMXMODX Accesses File ] ==-- ^n^n")
        fputs(iFileHandler, "; --== [ AMXX COMMANDS ACCESSES ] ==-- ^n^n")
        fputs(iFileHandler, "; a - Admin Immunity ^n")
        fputs(iFileHandler, "; b - Chat Commands Access ^n")
        fputs(iFileHandler, "; c - Kick Access ^n")
        fputs(iFileHandler, "; d - Slay Access ^n")
        fputs(iFileHandler, "; e - Transfer Access ^n")
        fputs(iFileHandler, "; f - Map Access ^n")
        fputs(iFileHandler, "; g - Cvar Access ^n")
        fputs(iFileHandler, "; h - Change Nick Access ^n")
        fputs(iFileHandler, "; j - Ban Access ^n^n")
        fputs(iFileHandler, "; --== [ SPECIAL ACCESSES ] ==-- ^n^n")
        fputs(iFileHandler, "; k - ScreenShot Command Access^^nn")
        fputs(iFileHandler, "; --== [ VIP ACCESSES ] ==-- ^n^n")
        fputs(iFileHandler, "; p - Vip List Access ^n")
        fputs(iFileHandler, "; q - Vip Weapons Menu Access ^n")
        fputs(iFileHandler, "; r - Vip Damage Info Access ^n")
        fputs(iFileHandler, "; s - Vip Join/Leave Access ^n")
        fputs(iFileHandler, "; t - Vip Extra Jump Access ^n")
        fputs(iFileHandler, "; u - Vip Spawn HP/AP ^n")
        fputs(iFileHandler, "; v - Vip Kill HP/AP ^n")
        fputs(iFileHandler, "; w - Vip Reset Deaths Access ^n")
        fputs(iFileHandler, "; y - Full Access ^n")
        fputs(iFileHandler, "; z - Default Access ^n")
        fputs(iFileHandler, "; ^"Steam/Nick^" ^"Password^" ^"Flags^" ^"Data Exprirare^"") // data de expirare format : zz-mm-yyyy ; 0 = permanent

        fclose(iFileHandler)
    }
    
    g_bCheckForFlags[id] = false
    
    if (g_bSetAccess[id] == true)
    {
        return g_get_flags[id]
    }
    else
    {
        return NULL_ACCESS
    }
}

public function_set_flags(id, Flags)
{
    g_bSetAccess[id] = true
    g_get_flags[id] = Flags
    function_get_flags(id)
}

public funcion_is_user(id)
{
    if(function_get_flags(id) & NULL_ACCESS)
        return false
    
    return true
}

stock VerificareData(const szEndDate[], const szKey[])
{
    new szCurrentDate[64],
        szFormatedEndDate[64],
        szCurrentDay[32],
        szCurrentMonth[32],
        szCurrentYear[32],
        szEndDay[32],
        szEndMonth[32],
        szEndYear[32]
        
    copy(szFormatedEndDate, charsmax(szFormatedEndDate), szEndDate)
    get_time("%d-%m-%Y", szCurrentDate, charsmax(szCurrentDate))
    
    for(new ch = 0; ch <= charsmax(szFormatedEndDate); ch++)
    {
        if (szFormatedEndDate[ch] == '-')
            szFormatedEndDate[ch] = ' '
    }
    
    for(new ch = 0; ch <= charsmax(szCurrentDate); ch++)
    {
        if(szCurrentDate[ch] == '-')
            szCurrentDate[ch] = ' '
    }

    parse(szCurrentDate, szCurrentDay, charsmax(szCurrentDay), szCurrentMonth, charsmax(szCurrentMonth), szCurrentYear, charsmax(szCurrentYear))
    parse(szFormatedEndDate, szEndDay, charsmax(szEndDay), szEndMonth, charsmax(szEndMonth), szEndYear, charsmax(szEndYear))
    
    if(str_to_num(szFormatedEndDate) == 0)
        return
    
    new iCurrentDay,
        iCurrentMonth,
        iCurrentYear,
        iEndDay,
        iEndMonth,
        iEndYear
    
    iCurrentDay   = str_to_num(szCurrentDay)
    iCurrentMonth = str_to_num(szCurrentMonth)
    iCurrentYear  = str_to_num(szCurrentYear)
    
    iEndDay   = str_to_num(szEndDay)
    iEndMonth = str_to_num(szEndMonth)
    iEndYear  = str_to_num(szEndYear)
    
    if((!iCurrentDay && !iCurrentMonth && !iCurrentYear) || (!iEndDay && !iEndMonth && !iEndYear))
        return
    
    
    
    if(iEndYear < iCurrentYear)
    {
        RemoveLineX(g_szLocalFile, szKey)
    }
    else if(iEndYear == iCurrentYear)
    {
        if(iEndMonth < iCurrentMonth)
        {
            RemoveLineX(g_szLocalFile, szKey)
        }
        else if(iEndMonth == iCurrentMonth)
        {
            if(iEndDay < iCurrentDay)
            {
                RemoveLineX(g_szLocalFile, szKey)
            }
        }
    }
}


stock RemoveLineX(const szFile[], const szKey[])
{
    if(file_exists(szFile))
    {
        new iMaxLines = file_size(szFile, FSOPT_LINES_COUNT)
        new Array:szFileLines, szLineToRead[400], iTextLen, szParse[4][65]

        szFileLines = ArrayCreate(400)
        
        for(new iLine = 0; iLine < iMaxLines; iLine++)
        {
           
            read_file(szFile, iLine, szLineToRead, charsmax(szLineToRead), iTextLen)
            
    
            parse(szLineToRead, szParse[0], charsmax(szParse[]), szParse[1], charsmax(szParse[]), szParse[2], charsmax(szParse[]), szParse[3], charsmax(szParse[]))
            
            
            remove_quotes(szParse[0])
            remove_quotes(szParse[1])
            remove_quotes(szParse[2])
            remove_quotes(szParse[3])
            
            if (equal(szParse[0], szKey))
                continue
            
            ArrayPushString(szFileLines, szLineToRead)
        }
        
        delete_file(szFile)
        
        for(new iLine = 0; iLine < ArraySize(szFileLines); iLine++)
        {
            ArrayGetString(szFileLines, iLine, szLineToRead, charsmax(szLineToRead))
            write_file(szFile, szLineToRead)
        }
        ArrayDestroy(szFileLines)
    }
}

stock VIP_FREE()
{
    new szTime[3], szHappyHours[32], szHappyHours_Start[32], szHappyHours_End[32]
    get_time("%H", szTime, charsmax(szTime))

    get_pcvar_string(getCvarInfo[VIP_FREE_HOURS], szHappyHours, charsmax(szHappyHours))
    
    for (new ch = 0; ch <= charsmax(szHappyHours); ch++)
    {
        if (szHappyHours[ch] == '-')
            szHappyHours[ch] = ' '
    }
    
    parse(szHappyHours, szHappyHours_Start, charsmax(szHappyHours_Start), szHappyHours_End, charsmax(szHappyHours_End))
    
    new iTime, iHappyHourStart, iHappyHourEnd
    
    iTime = str_to_num(szTime)
    iHappyHourStart = str_to_num(szHappyHours_Start)
    iHappyHourEnd = str_to_num(szHappyHours_End)
    
    if(iHappyHourEnd > iTime >= iHappyHourStart)
    {
        set_hudmessage(140, 140, 140, 0.02, 0.2, 1, _, 59.0, _, _, -1)
        show_hudmessage(0, "VIP FREE EVENT ACTIVE")
        g_bIsVipFree = true
    }
    else
    {
        g_bIsVipFree = false
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
