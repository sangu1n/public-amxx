#include <amxmodx>
#include <cstrike>

new const szFile[] = "Linkuri.cfg"

public plugin_init()
{
    register_clcmd("say", "rc_say")
    register_clcmd("say_team", "rc_say")
}

public rc_say(id)
{
    new arg[32], szName[32]
    read_argv(1, arg, charsmax(arg))
    remove_quotes(arg)
    
    new szDate[32], szTime[32]
    
    get_time("%d/%m/%Y", szDate, charsmax(szDate))
    get_time("%H:%M:%S", szTime, charsmax(szTime))
    
    
    if(!arg[id]) return
     
    if(equali(arg[id], "https") || equali(arg[id], "imgur") || equali(arg[id], "http"))
        log_to_file(szFile, "%s a scris linkul ^"%s^" pe chat. [%s-%s]", szName, arg, szDate, szTime)
}
