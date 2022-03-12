#include <amxmodx>
#include <fun>
#include <cstrike>
#include <csx>

enum MEMBERS_DATA {
	title[32],
	health,
	armor,
	money,
	cost[32],
	flags[26]
};

// --------------------------------------------
//   ------------- DE EDITAT ---------------
// --------------------------------------------
new const MEMBERS[][MEMBERS_DATA] = {
	{ "Diamond Member", 		70, 70, 3000, "15 euro", "abcdefghijkl" },
	{ "Platinum Member", 		40, 40, 2000, "15 euro", "abcdefghijkl" },
	{ "Gold Member", 			30, 30, 1800, "15 euro", "abcdefghijkl" },
	{ "Silver Member", 		15, 15, 1200, "15 euro", "abcdefghijkl" },
	{ "Bronze Member", 		10, 10, 600, 	"15 euro", "abcdefghijkl" },
	{ "Steam VIP Member", 	1, 1, 100, 	"15 euro", "abcdefghijkl" },
	{ "Basic VIP Member", 	5, 5, 400, 	"15 euro", "abcdefghijkl" },
	{ "Clasic VIP Member", 	1, 1, 100, 	"15 euro", "abcdefghijkl" }
};
// --------------------------------------------
//   ------------- DE EDITAT ---------------
// --------------------------------------------

#define PLUGIN_NAME			"Beneficii"
#define PLUGIN_AUTHOR		"YONTU"
#define PLUGIN_VERSION		"1.0"

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	register_clcmd("say /vips", "ShowMembers");
}

stock isMember(const id, &accessId) {
	new i = 0, bool:found = false;
	for (i = 0; i < sizeof MEMBERS; i++) {
		if (get_user_flags(id) == read_flags(MEMBERS[i][flags])) {
			found = true;
			accessId = i;
			break;
		}
	}
	return found;
}

public client_death(killer, victim, wpnindex, hitplace, TK) {
	new accessId = -1;
	if (isMember(killer, accessId)) {
		if (killer == victim || !is_user_alive(killer))
			return;
		
		if (accessId != -1) {
			set_user_health(killer, min(get_user_health(killer) + MEMBERS[accessId][health], 100));
			set_user_armor(killer, min(get_user_armor(killer) + MEMBERS[accessId][armor], 100));
			cs_set_user_money(killer, min(cs_get_user_money(killer) + MEMBERS[accessId][money], 16000));
		}
	}
}

public ShowMembers(id) {
	new menu = menu_create("\wMembers", "MenuHandler");
	static text[128];
	for (new i = 0; i < sizeof MEMBERS; i++) {
		formatex(text, charsmax(text), "%s - \y%d HP\w &\y %d AP\w &\y %d$\w/kill (\r%s\w)", MEMBERS[i][title], MEMBERS[i][health], MEMBERS[i][armor], MEMBERS[i][money], MEMBERS[i][cost]);
		menu_additem(menu, text);
	}

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
	return PLUGIN_CONTINUE;
}

public MenuHandler(id, menu, item) {
	if (item == MENU_EXIT) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	DisplayMembers(id, item);
	
	menu_destroy(menu);
	return PLUGIN_CONTINUE;
}

public DisplayMembers(const id, const item) {
	new menu = menu_create("\wMembers^nChoose one and see who is online", "MenuMembersHandler");
	static name[32];
	new players[32], i, player, num, bool:found = false;
	get_players(players, num, "ch");

	for (i = 0; i < num; i++) {
		player = players[i];

		if (get_user_flags(player) == read_flags(MEMBERS[item][flags])) {
			found = true;
			get_user_name(player, name, charsmax(name));
			menu_additem(menu, name);
		}
	}

	if (!found)
		menu_additem(menu, "No one online...");

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
	return PLUGIN_CONTINUE;
}

public MenuMembersHandler(id, menu, item) {
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}
