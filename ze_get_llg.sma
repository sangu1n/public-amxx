#include <amxmodx>
#include <amxmisc>

native crxranks_get_user_xp(id)
native crxranks_set_user_xp(id, amount)

native get_user_diamonds(id)
native set_user_diamonds(id, amount)

enum _: Timers
{
    START_TIME,
    END_TIME
}

new cvar[Timers]

enum _: Cvars
{
    GET_XP,
    GET_XP_NEG,
    GET_DIAMONDS,
    GET_DIAMONDS_NEG,
    HH_GET_XP,
    HH_GET_XP_NEG,
    HH_GET_DIAMONDS,
    HH_GET_DIAMONDS_NEG,
    RUNDA_ACCES
    
}

new xvar[Cvars]

new bool: g_bIsHappyHour, g_bAreDeja[33]

new bRound

public plugin_init()
{
    register_plugin("Get Mai smecher ca pe indungi", "1.0", "doza")
    
    register_clcmd("say /get", "func_get_main")
    
    set_task(10.0, "CheckTimeFunc", _, _, _, "b")
    
    register_logevent("abc", 2, "1=Round_Start")
    register_event( "TextMsg", "xyz", "a", "2=#Game_Commencing", "2=#Game_will_restart_in") 
    
    cvar[START_TIME] = register_cvar("get_bonus_start_hour", "20") // cand incepe happyhour
    cvar[END_TIME] = register_cvar("get_bonus_end_hour", "23") // cand se termina
    
    xvar[GET_XP] = register_cvar("get_xp_amount", "150") // cat xp sa primeasca pe +
    xvar[GET_XP_NEG] = register_cvar("get_xp_amount_negative", "200") // cat xp sa primeasca pe -
    xvar[GET_DIAMONDS] = register_cvar("get_diamonds_amount", "500") // cat diamonds sa primeasca pe +
    xvar[GET_DIAMONDS_NEG] = register_cvar("get_diamonds_amount_negative", "600")  // cat diamonds sa primeasca pe -
    /*===========*/
    xvar[HH_GET_XP] = register_cvar("happy_hour_get_xp_amount", "500") // cat xp sa primeasca pe + la happy hour
    xvar[HH_GET_XP_NEG] = register_cvar("happy_hour_get_xp_amount_negative", "200") // cat xp sa primeasca pe - la happy hour
    xvar[HH_GET_DIAMONDS] = register_cvar("happy_hour_get_diamonds", "1000") // cat diamonds sa primeasca pe + la happy hour
    xvar[HH_GET_DIAMONDS_NEG] = register_cvar("happy_hour_get_diamonds_negative", "200") // // cat diamonds sa primeasca pe - la happy hour
    
    xvar[RUNDA_ACCES] = register_cvar("get_round_acces", "2") // din ce runda se poate folosii /get
    
    
    for(new id = 0; id < get_maxplayers(); id++)
    {
        if(!is_user_connected(id) || !g_bAreDeja[id]) continue
        g_bAreDeja[id] = false
    }
}

public abc()    bRound++
public xyz()    bRound = 0

public CheckTimeFunc()
{
    new h
    time(h, _, _)
    
    if(h >= get_pcvar_num(cvar[START_TIME]) && h < get_pcvar_num(cvar[END_TIME]))
        g_bIsHappyHour = true
    else
        g_bIsHappyHour = false
    
}

public client_putinserver(id)
{
    if(g_bIsHappyHour)
        client_print(id, print_chat, "E happy hour saracule, ai mai multe rate la /get")
}

public func_get_main(id)
{
    new xp = random_num(0, get_pcvar_num(xvar[GET_XP]))
    new xp_neg = random_num(0, get_pcvar_num(xvar[GET_XP_NEG]))
    new diamonds = random_num(0, get_pcvar_num(xvar[GET_DIAMONDS]))
    new diamonds_neg = random_num(0, get_pcvar_num(xvar[GET_DIAMONDS_NEG]))
    /*========*/
    new hh_xp = random_num(0, get_pcvar_num(xvar[HH_GET_XP]))
    new hh_xp_neg = random_num(0, get_pcvar_num(xvar[HH_GET_XP_NEG]))
    new hh_diamonds = random_num(0, get_pcvar_num(xvar[HH_GET_DIAMONDS]))
    new hh_diamonds_neg = random_num(0, get_pcvar_num(xvar[HH_GET_DIAMONDS_NEG]))
    
    if(bRound < get_pcvar_num(xvar[RUNDA_ACCES])) 
    {
        client_print(id, print_chat, "Poti folosii /get din runda %d (Runde ramase pana la get: %d)", get_pcvar_num(xvar[RUNDA_ACCES]), get_pcvar_num(xvar[RUNDA_ACCES]) - bRound)
        return 1
    }
    
    if(!g_bAreDeja[id])
    {
        if(g_bIsHappyHour)
        {
            switch(random(4))
            {
                // xpul
                case 0:
                {
                    crxranks_set_user_xp(id, crxranks_get_user_xp(id) + hh_xp)
                    client_print(id, print_chat, "Ai primit +%i xp!")
                }
                case 1:
                {
                    crxranks_set_user_xp(id, crxranks_get_user_xp(id) - hh_xp_neg)
                    client_print(id, print_chat, "Ti-a fost luat -%i xp!")
                }
                // diamantele
                case 2:
                {
                    set_user_diamonds(id, get_user_diamonds(id) + hh_diamonds)
                    client_print(id, print_chat, "Ai primit +%i diamante!")
                }
                case 3:
                {
                    set_user_diamonds(id, get_user_diamonds(id) - hh_diamonds_neg)
                    client_print(id, print_chat, "Ti-au fost luate -%i diamante!")
                }
            }
        }
        else if(!g_bIsHappyHour)
        {
            switch(random(4))
            {
                // xpul
                case 0:
                {
                    crxranks_set_user_xp(id, crxranks_get_user_xp(id) + xp)
                    client_print(id, print_chat, "Ai primit +%i xp!")
                }
                case 1:
                {
                    crxranks_set_user_xp(id, crxranks_get_user_xp(id) - xp_neg)
                    client_print(id, print_chat, "Ti-a fost luat -%i xp!")
                }
                // diamantele
                case 2:
                {
                    set_user_diamonds(id, get_user_diamonds(id) + diamonds)
                    client_print(id, print_chat, "Ai primit +%i diamante!")
                }
                case 3:
                {
                    set_user_diamonds(id, get_user_diamonds(id) - diamonds_neg)
                    client_print(id, print_chat, "Ti-au fost luate -%i diamante!")
                }
            }
        }
        g_bAreDeja[id] = true
    }
    else
    {
        client_print(id, print_chat, "Poti primii pomana doar odata pe harta, ho!")
        return 1
    }
    
    return 1
}
