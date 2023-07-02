#include <amxmodx>
#include <fakemeta>
#include <cstrike>

#define PLUGIN "[Zombie: The Hero ] Addon: Information"
#define VERSION "2.0"
#define AUTHOR "Dias"

#define TASK_MSG 323422
#define MAX_MESSAGE 7
#define MESSAGE_SHOWTIME 4.0
#define MAX_HELP 20

new g_msg_num[33], sync_hud1, Motd[1028], Help_Number[10]
new message[MAX_MESSAGE][] = 
{
	"Chu Y !!!",
	"Chu Y !!!",
	"Thong bao tu Admin !!!",
	"Trong vong 3 ngay 23 den het 26",
	"tam thoi remove vu khi cua Human, de check vai thu",
	"Sau 3 ngay neu moi thu ok thi chuyen ve nhu cu~",
	"~ Dias"
}

new const help_name[MAX_HELP][] =
{
	"ZB3 co gi khac ZP ? (Phan 1)",
	"ZB3 co gi khac ZP ? (Phan 2)",
	"ZB3 co gi khac ZP ? (Phan 3)",
	"Hero la gi ? (Phan 1)",
	"Hero la gi ? (Phan 2)",
	"Attack Power la gi ?",
	"Evolution la gi ?",
	"Hom Tiep Te la gi ?",
	"Mau o Ti Le phan tram la gi ?",
	"He Thong Mau' co gi moi ?",
	"Do dai tay cua zombie la gi ?",
	"Pain Shock la gi ?",
	"He Thong class Zombie moi ?",
	"Gioi thieu cac loai zombie (Phan 1)",
	"Gioi thieu cac loai zombie (Phan 2)",
	"Gioi thieu cac loai zombie (Phan 3)",
	"Gioi thieu cac loai zombie (Phan 4)",
	"Gioi thieu cac loai zombie (Phan 5)",
	"He thong Unlock Class Zombie la gi ?",
	"Thong tin ve Tac Gia"
}

new const pipe_sound[] = "zombie_thehero/tutor_msg.wav"


public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "event_newround", "a", "1=0", "2=0")
	register_dictionary("zombie_thehero2.txt")
	
	register_clcmd("say /help", "cmd_help")
	register_clcmd("say /stop", "cmd_stop_notice")
	
	sync_hud1 = CreateHudSyncObj(8)
}

public plugin_precache()
{
	precache_sound(pipe_sound)
}

public client_putinserver(id)
{
	g_msg_num[id] = 0
	set_task(MESSAGE_SHOWTIME, "do_msg", id+TASK_MSG)
}

public event_newround()
{
	//set_task(1.0, "create_message")
}

public create_message()
{
	client_printc(0, "!g[Zombie: The Hero]!n Type /help to open Help Center (Vietnamese)")
}

public do_msg(id)
{
	id -= TASK_MSG
	if(is_user_connected(id) && (cs_get_user_team(id) == CS_TEAM_CT || cs_get_user_team(id) == CS_TEAM_T))
	{
		if(task_exists(id+TASK_MSG)) remove_task(id+TASK_MSG)
		set_task(MESSAGE_SHOWTIME, "do_msg", id+TASK_MSG)
	} else {
		return PLUGIN_HANDLED
	}
	
	if(g_msg_num[id] < MAX_MESSAGE)
	{
		client_cmd(id, "spk ^"%s^"", pipe_sound)
		
		set_hudmessage(0, 255, 0, -1.0, 0.65, 0, MESSAGE_SHOWTIME, MESSAGE_SHOWTIME)
		ShowSyncHudMsg(id, sync_hud1, message[g_msg_num[id]])
		
		g_msg_num[id]++
		
		set_task(MESSAGE_SHOWTIME, "do_msg", id+TASK_MSG)
	}
	
	return PLUGIN_CONTINUE
}

public cmd_stop_notice(id)
{
	remove_task(id+TASK_MSG)
	
	return PLUGIN_HANDLED
}

public cmd_help(id)
{
	set_pdata_int(id, 205, 0, 5)
	
	new mHandleID = menu_create("Help Center", "handle_select_help")
	
	for(new i = 0; i < MAX_HELP; i++)
	{
		static number[3]
		num_to_str(i, number, sizeof(number))
		
		menu_additem(mHandleID, help_name[i], number)
	}
	
	menu_display(id, mHandleID, 0)
}

public handle_select_help(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	static data[32], name[32], access
	menu_item_getinfo(menu, item, access, data, sizeof(data), name, sizeof(name), access)
	
	static number
	number = str_to_num(data)
	
	formatex(Help_Number, sizeof(Help_Number), "HELP_%i", number)
	formatex(Motd, sizeof(Motd), "%L", LANG_PLAYER, Help_Number)
	
	show_motd(id, Motd, help_name[number])
	
	return PLUGIN_HANDLED
}

// Colour Chat
stock client_printc(const id, const input[], any:...)
{
	new count = 1, players[32];
	static msg[191];
	vformat(msg, 190, input, 3);
	
	replace_all(msg, 190, "!g", "^x04"); // Green Color
	replace_all(msg, 190, "!n", "^x01"); // Default Color
	replace_all(msg, 190, "!t", "^x03"); // Team Color
	
	if (id) players[0] = id; else get_players(players, count, "ch");
	{
		for (new i = 0; i < count; i++)
		{
			if (is_user_connected(players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]);
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	}
}  
