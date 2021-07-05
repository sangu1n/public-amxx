#include <zombie_escape>

public plugin_init()
{
	register_plugin("DMG Control", "1.0", "SenorAMXX")
	RegisterHam(Ham_Touch, "trigger_hurt", "Fw_TouchTrigger_Post", 1)
}

public Fw_TouchTrigger_Post(iEnt, id)
{
	if(!is_user_alive(id) || !pev_valid(iEnt))
		return HAM_IGNORED
	
	
	if (pev(iEnt, pev_dmg) > 500)	user_silentkill(id, 0)
	
	return HAM_IGNORED
}
