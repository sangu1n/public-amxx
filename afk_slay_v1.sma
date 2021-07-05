#include <zombie_escape>

#define TIME 30.0
new Float:player_origin[33][3];
public plugin_init()
{
     register_plugin("afk slayer", "1.0", "senoramxx");
     RegisterHam(Ham_Spawn, "player", "e_Spawn", 1);
}
 
public e_Spawn(id)
{
     if(is_user_alive(id))
     {
           set_task(10.0, "get_spawn", id);
     }
     return HAM_IGNORED;
}

public get_spawn(id)
{
     pev(id, pev_origin, player_origin[id]);
     set_task(TIME, "check_afk", id);
}
 
public check_afk(id)
{
          if(same_origin(id))
          {
               user_kill(id);
               new name[33];
               get_user_name(id, name, charsmax(name));
               ze_colored_print(0, "!t%s !ywas killed for being afk", name);
          }
}
 
public same_origin(id)
{
       new Float:origin[3];
       pev(id, pev_origin, origin);
       for(new i = 0; i < 3; i++)
             if(origin[i] != player_origin[id][i])
                   return 0;
       return 1;
}
