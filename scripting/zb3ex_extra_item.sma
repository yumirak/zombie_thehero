#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <zombie_thehero2>

#define PLUGIN "[Zombie: The Hero] Addon: Extra Item"
#define VERSION "2.0"
#define AUTHOR "Dias"

#define MAX_ITEM 20
#define MAX_FORWARD 2

enum
{
	FWD_ITEM_SELECTED_PRE = 0,
	FWD_ITEM_SELECTED_POST
}

new g_item_count, g_forward_dummy
new Array:item_name, Array:item_desc, Array:item_cost, Array:item_team, Array:item_permanent_buy
new g_bought_item[33][MAX_ITEM], g_item_forward[MAX_FORWARD]
new g_zombie_appear

public plugin_init()
{
	if(!g_item_count)
		set_fail_state("[ZB3] Error: No Item Loaded...")
		
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHam(Ham_Spawn, "player", "fw_Spawn_Post", 1)
	register_dictionary("zombie_thehero2.txt")
	
	g_item_forward[FWD_ITEM_SELECTED_PRE] = CreateMultiForward("zb3_item_selected_pre", ET_IGNORE, FP_CELL, FP_CELL)
	g_item_forward[FWD_ITEM_SELECTED_POST] = CreateMultiForward("zb3_item_selected_post", ET_IGNORE, FP_CELL, FP_CELL)
	
	register_clcmd("chooseteam", "cmd_openmenu")
	register_clcmd("jointeam", "cmd_openmenu")
	register_clcmd("joinclass", "cmd_openmenu")
}

public plugin_natives()
{
	register_native("zb3_register_item", "native_register_item", 1)
}

public plugin_precache()
{
	item_name = ArrayCreate(64, 1)
	item_desc = ArrayCreate(64, 1)
	item_cost = ArrayCreate(1, 1)
	item_team = ArrayCreate(1, 1)
	item_permanent_buy = ArrayCreate(1, 1)
}

public client_connect(id)
{
	reset_value_handle(id)
}

public client_disconnected(id)
{
	reset_value_handle(id)
}

public reset_value_handle(id)
{
	for(new i = 0; i < MAX_ITEM; i++)
		g_bought_item[id][i] = 0
}

public zb3_round_start_post() g_zombie_appear = 0
public zb3_random_zombie_post() g_zombie_appear = 1

public fw_Spawn_Post(id)
{
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(zb3_get_user_zombie(id))
		return HAM_IGNORED
		
	//client_printc(id, "!g[Zombie: The Hero]!n Bam !g(M)!n de mua Item")
	
	return HAM_HANDLED
}

public cmd_openmenu(id)
{
	if(!is_user_connected(id) || !is_user_alive(id))
		return PLUGIN_CONTINUE
	if(cs_get_user_team(id) == CS_TEAM_CT)
	{
		if(!g_zombie_appear)
		{
			open_menu_shop(id, TEAM2_HUMAN)	
			return PLUGIN_HANDLED
		} else {
			client_printc(id, "%L", LANG_PLAYER, "SHOP_BUY_START")
			return PLUGIN_HANDLED
		}
	} else if(cs_get_user_team(id) == CS_TEAM_T) {
		open_menu_shop(id, TEAM2_ZOMBIE)
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public open_menu_shop(id, team)
{
	new item_menu, temp_string[128], temp_string2[128], temp_int, temp_string3[128], 
	temp_string4[3], temp_int2, temp_string5[10]
	item_menu = menu_create("[Zombie: The Hero] Item Menu", "item_menu_handle")
	
	for(new i = 0; i < g_item_count; i++)
	{
		temp_int2 = ArrayGetCell(item_team, i)
		
		if(temp_int2 == team)
		{
			ArrayGetString(item_name, i, temp_string, sizeof(temp_string))
			ArrayGetString(item_desc, i, temp_string2, sizeof(temp_string2))
			temp_int = ArrayGetCell(item_cost, i)
			formatex(temp_string4, sizeof(temp_string4), "%i", i)
			
			if(ArrayGetCell(item_permanent_buy, i))
			{
				if(!g_bought_item[id][i])
				{
					formatex(temp_string5, sizeof(temp_string5), "%L", LANG_PLAYER, "SHOP_PERMANENT_ITEM")
					formatex(temp_string3, sizeof(temp_string3), "%s \y%s \r$%i (%s)", temp_string, temp_string2, temp_int, temp_string5)
				} else {
					formatex(temp_string3, sizeof(temp_string3), "\d%s (%L)", temp_string, LANG_PLAYER, "SHOP_BOUGHT")
				}
			} else {
				formatex(temp_string5, sizeof(temp_string5), "%L", LANG_PLAYER, "SHOP_ITEM_ONCETIME_USE")
				formatex(temp_string3, sizeof(temp_string3), "%s \y%s \r$%i (%s)", temp_string, temp_string2, temp_int, temp_string5)
			}
			
			menu_additem(item_menu, temp_string3, temp_string4)
		}
	}
	
	menu_setprop(item_menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, item_menu, 0)
}

public item_menu_handle(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	if(cs_get_user_team(id) == CS_TEAM_CT && g_zombie_appear)
	{
		client_printc(id, "%L", LANG_PLAYER, "SHOP_BUY_START")
		return PLUGIN_HANDLED
	}
	
	new data[6], szName[64], access, callback
	menu_item_getinfo(menu, item, access, data,charsmax(data), szName,charsmax(szName), callback)
	
	new item_id = str_to_num(data)

	ExecuteForward(g_item_forward[FWD_ITEM_SELECTED_PRE], g_forward_dummy, id, item_id)
	
	if(g_forward_dummy == PLUGIN_HANDLED)
		return PLUGIN_HANDLED
	
	static CurMoney, Cost, temp_string[128], temp_string2[128], temp_string3[10]
	
	CurMoney = cs_get_user_money(id)
	Cost = ArrayGetCell(item_cost, item_id)
	
	ArrayGetString(item_name, item_id, temp_string, sizeof(temp_string))
	
	if(!ArrayGetCell(item_permanent_buy, item_id))
	{
		if(CurMoney >= Cost)
		{
			ArrayGetString(item_desc, item_id, temp_string2, sizeof(temp_string2))
			cs_set_user_money(id, CurMoney - Cost)
			
			if(ArrayGetCell(item_permanent_buy, item_id))
				formatex(temp_string3, sizeof(temp_string3), "%L", LANG_PLAYER, "SHOP_PERMANENT_ITEM")
			else
				formatex(temp_string3, sizeof(temp_string3), "%L", LANG_PLAYER, "SHOP_ITEM_ONCETIME_USE")
			
			client_printc(id, "%L", LANG_PLAYER, "SHOP_BUY", temp_string, Cost, temp_string3)
			//client_printc(id, "%L", LANG_PLAYER, "SHOP_BUY_DESC", temp_string, temp_string2)
			
			ExecuteForward(g_item_forward[FWD_ITEM_SELECTED_POST], g_forward_dummy, id, item_id)
		} else {
			client_printc(id, "%L", LANG_PLAYER, "SHOP_NOT_ENOUGH_MONEY", temp_string, Cost)
		}
	} else if(ArrayGetCell(item_permanent_buy, item_id) && !g_bought_item[id][item_id]) {
		if(CurMoney >= Cost)
		{
			ArrayGetString(item_desc, item_id, temp_string2, sizeof(temp_string2))
			cs_set_user_money(id, CurMoney - Cost)
			
			if(ArrayGetCell(item_permanent_buy, item_id))
				formatex(temp_string3, sizeof(temp_string3), "%L", LANG_PLAYER, "SHOP_PERMANENT_ITEM")
			else
				formatex(temp_string3, sizeof(temp_string3), "%L", LANG_PLAYER, "SHOP_ITEM_ONCETIME_USE")
			
			client_printc(id, "%L", LANG_PLAYER, "SHOP_BUY", temp_string, Cost, temp_string3)
			//client_printc(id, "%L", LANG_PLAYER, "SHOP_BUY_DESC", temp_string, temp_string2)
			
			g_bought_item[id][item_id] = 1
			ExecuteForward(g_item_forward[FWD_ITEM_SELECTED_POST], g_forward_dummy, id, item_id)
		} else {
			client_printc(id, "%L", LANG_PLAYER, "SHOP_NOT_ENOUGH_MONEY", temp_string, Cost)
		}		
	} else if(ArrayGetCell(item_permanent_buy, item_id) && g_bought_item[id][item_id]) {
		client_printc(id, "%L", LANG_PLAYER, "SHOP_BUY_ONE_TIME", temp_string)
	}
	
	return PLUGIN_CONTINUE
}

public native_register_item(const name[], const desc[], cost, team, permanent_buy)
{
	param_convert(1)
	param_convert(2)
	
	ArrayPushString(item_name, name)
	ArrayPushString(item_desc, desc)
	ArrayPushCell(item_cost, cost)
	ArrayPushCell(item_team, team)
	ArrayPushCell(item_permanent_buy, permanent_buy)
	
	g_item_count++
	
	return (g_item_count - 1)
}

stock client_printc(index, const text[], any:...)
{
	new szMsg[128];
	vformat(szMsg, sizeof(szMsg) - 1, text, 3);

	replace_all(szMsg, sizeof(szMsg) - 1, "!g", "^x04");
	replace_all(szMsg, sizeof(szMsg) - 1, "!n", "^x01");
	replace_all(szMsg, sizeof(szMsg) - 1, "!t", "^x03");

	if(index == 0)
	{
		for(new i = 0; i < get_maxplayers(); i++)
		{
			if(is_user_connected(i))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, i);
				write_byte(i);
				write_string(szMsg);
				message_end();	
			}
		}		
	} else {
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, index);
		write_byte(index);
		write_string(szMsg);
		message_end();
	}
} 
