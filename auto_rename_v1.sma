#include <amxmodx>

new const g_names[][] =
{
	"DldCS16[.]Com-Player",
    "(1)RCPlayer",
	"(2)RCPlayer",
	"(3)RCPlayer",
	"(4)RCPlayer",
	"(5)RCPlayer",
	"gametracker.rs Player",
	"RCPlayer-PRO",
	"<Warrior> Player",
	"www.",
	".com",
	".ro",
	".net",
        "cs-boost.com buy players",
        "(1)cs-boost.com buy players",
        "SM-Player",
        "(1)SM-Player",
        "(2)SM-Player",
	".info",
	":27",
  	"furien",
	"<warrior>",
   	"warrior",
	"warrior player",
	"watf",
	"pgl",
    "G a m e r C l u b . N e T",
    ")87",
    "87",
    ")178",
    "178",
    "ZP",
    "intrusii",
    "darkcs",
    "indungi",
    "CS0",
    "CSO"
      
}
new g_sizeof_names = sizeof g_names

new const g_names_new[][] =
{
	"ZE[.]LALEAGANE[.]RO",
	"ZE.LALEAGANE.RO"
}
new g_sizeof_names_new = sizeof g_names_new - 1

new g_filter_chars[29] = " ~`@#$%&*()-_=+\|[{]};',<>/?" //^"
//new g_sizeof_filter = sizeof g_filter_chars

new g_names_changed = 1

public client_connect(id)
	verify_name(id)

public client_infochanged(id)
{
	if (!is_user_connected(id))
		return;
	
	verify_name(id)
}

verify_name(id)
{
	static name[32]
	get_user_info(id, "name", name, 31)
	
	static i, ignore
	ignore = false
	
	for (i = 0; i <= g_sizeof_names_new; i++)
		if (containi(name, g_names_new[i]) != -1)
		{
			ignore = true
			break;
		}
	
	if (ignore)
		return;
	
	for (i = 0; i < 29; i++)
		replace_all(name, 31, g_filter_chars, "")
	
	for (i = 0; i < g_sizeof_names; i++)
		if (containi(name, g_names[i]) != -1)
		{
			formatex(name, 31, "%s [%d]", g_names_new[random_num(0, g_sizeof_names_new)], g_names_changed)
			set_user_info(id, "name", name)
			client_cmd(id, "name ^"%s^"", name)
			g_names_changed++
		}
}
