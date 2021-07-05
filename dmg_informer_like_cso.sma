#include < amxmodx >
#include < cstrike >
#include < hamsandwich >

                          
public plugin_init() {
   register_plugin("[ZP] Damage Hud", "1.0", "BOSS_XD");
 
   RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage", 1);
}
                            
public fw_TakeDamage(iVictim, iInflictor, iAttacker, Float:damage) {
    if(iVictim == iAttacker || !is_user_alive(iAttacker) || !is_user_connected(iVictim))
        return;
    
    set_hudmessage(random[255], random[255], random[255], -1.0, 0.46, 0, 0.02, 0.05);
    show_hudmessage(iAttacker, "\     /^n^n/     \"); 
}                                   
