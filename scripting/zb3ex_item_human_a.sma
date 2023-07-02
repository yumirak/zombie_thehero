#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <zombie_thehero2>

#define PLUGIN "[Zombie: The Hero] Human Item"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define DELAY_TIME 2.0
#define ITEM_FILE "zombie_thehero_item.ini"

// Configs
const g_wb_cost = 2000
const Float:g_wb_gravity = 0.80

const g_dg_cost = 3000
const g_p30_cost = 3000
	
const g_sprint_cost = 5000
const Float:fastrun_time = 10.0
const Float:fastrun_speed = 340.0
const Float:slowrun_time = 5.0
const Float:slowrun_speed = 140.0
new const sound_fastrun_start[] = "zombie_thehero/speedup.wav"
new const sound_fastrun_heartbeat[] = "zombie_thehero/speedup_heartbeat.wav"
new const sound_breath_male[] = "zombie_thehero/human_breath_male.wav"
new const sound_breath_female[] = "zombie_thehero/human_breath_female.wav"

const g_deadlyshot_cost = 7000
const Float:g_deadlyshot_time = 5.0
new const g_deadlyshot_icon[] = "sprites/zombie_thehero/zb_skill_headshot.spr"
	
const g_bloodyblade_cost = 5000
const Float:g_bloodyblade_damage = 2.0	
const Float:g_bloodyblade_time = 5.0
new const g_bloodyblade_icon[] = "sprites/zombie_thehero/zb_meleeup.spr"
/// ===== Configs

new g_sync_hud1, g_sync_hud2
new Float:g_hud_delay[33]
new g_register, g_zombie_appear
new g_msgStatusIcon
// Wing Boot
new g_wing_boot, g_had_wing_boot[33]

// Double Grenade
new g_double_grenade, g_had_double_grenade[33], g_doubled_grenade[33]

// Sprint
new g_sprint
new g_had_sprint[33], g_can_use_sprint[33], g_using_sprint[33], g_sprint_status[33]

#define TASK_REMOVE_FASTRUN 59384543
#define TASK_REMOVE_SLOWRUN 5893485
#define TASK_HUMAN_SOUND 53450834

// +30% Damage
new g_p30_damage, g_had_p30_damage[33]

// Deadly Shot
new g_deadlyshot, g_had_deadlyshot[33], g_can_use_deadlyshot[33], g_using_deadlyshot[33]
new g_deadlyshot_icon_id

#define TASK_REMOVE_DEADLYSHOT 839483
#define TASK_DEADLYSHOT_ICON 534534

// Bloody Blade
new g_bloodyblade, g_had_bloodyblade[33], g_can_use_bloodyblade[33], g_using_bloodyblade[33]
new g_bloodyblade_icon_id

#define TASK_REMOVE_BLOODYBLADE 839485
#define TASK_BLOODYBLADE_ICON 535534

new g_Msg_ScreenFade

// NightVision
new g_nightvision, g_had_nvg[33]
const g_nightvision_cost = 2500

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	//g_sync_hud1 = zb3_get_synchud_id(SYNCHUD_HUMANZOMBIE_ITEM)
	g_sync_hud1 = zb3_get_synchud_id(SYNCHUD_ZBHM_SKILL1)
	
	RegisterHam(Ham_Item_AddToPlayer, "weapon_hegrenade", "fw_Add_Hegrenade_Post", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	
	g_Msg_ScreenFade = get_user_msgid("ScreenFade")
	g_msgStatusIcon = get_user_msgid("StatusIcon")
	
	register_clcmd("use_sprint", "do_fastrun")
	register_clcmd("use_deadlyshot", "do_deadlyshot")
	register_clcmd("use_bloodyblade", "do_bloodyblade")

	register_message(g_msgStatusIcon, "message_statusicon")
}

public plugin_precache()
{
	precache_sound(sound_fastrun_start)
	precache_sound(sound_fastrun_heartbeat)
	precache_sound(sound_breath_male)
	precache_sound(sound_breath_female)
	
	g_deadlyshot_icon_id = precache_model(g_deadlyshot_icon)
	g_bloodyblade_icon_id = precache_model(g_bloodyblade_icon)
	
	g_wing_boot = zb3_register_item("Wing Boot", "More High Jump", g_wb_cost, TEAM2_HUMAN, 1)
	g_double_grenade = zb3_register_item("x2 HE Grenade", "+1 More HeGrenade", g_dg_cost, TEAM2_HUMAN, 1)
	g_p30_damage = zb3_register_item("Battle Veteran", "Start Damage is 130%", g_p30_cost, TEAM2_HUMAN, 1)
	g_sprint = zb3_register_item("Sprint", "FastRun (10 seconds)", g_sprint_cost, TEAM2_HUMAN, 1)
	g_deadlyshot = zb3_register_item("Deadly Shot", "Deal All Damage to the Head", g_deadlyshot_cost, TEAM2_HUMAN, 1)
	g_bloodyblade = zb3_register_item("Bloody Blade", "x2 Melee Damage", g_bloodyblade_cost, TEAM2_HUMAN, 1)
	g_nightvision = zb3_register_item("NightVision", "See in Dark", g_nightvision_cost, TEAM2_HUMAN, 1)
}

public client_connect(id)
{
	/*if(is_user_bot(id)) 
	{
		g_had_wing_boot[id] = 1
		g_had_double_grenade[id] = 1
		g_had_p30_damage[id] = random(1)
		g_had_sprint[id] = 1
		g_can_use_sprint[id] = 1
		g_using_sprint[id] = 0
		g_sprint_status[id] = 0
		g_had_deadlyshot[id] = 1
		g_can_use_deadlyshot[id] = 1
		g_using_deadlyshot[id] = 0
		//g_had_bloodyblade[id] = 1
		g_can_use_bloodyblade[id] = 1
		g_using_bloodyblade[id] = 0
		if(g_had_nvg[id])
			set_user_nightvision(id)
		return
	} else {
		*/
	g_had_wing_boot[id] = is_user_bot(id) == 0 ? 0 : 1
	g_had_double_grenade[id] = is_user_bot(id) == 0 ? 0 : 1
	g_had_p30_damage[id] = is_user_bot(id) == 0 ? 0 : random(1)
	g_had_sprint[id] = is_user_bot(id) == 0 ? 0 : 1
	g_can_use_sprint[id] = is_user_bot(id) == 0 ? 0 : 1
	g_using_sprint[id] = 0
	g_sprint_status[id] = 0
	g_had_deadlyshot[id] = is_user_bot(id) == 0 ? 0 : 1
	g_can_use_deadlyshot[id] = is_user_bot(id) == 0 ? 0 : 1
	g_using_deadlyshot[id] = 0
	g_had_bloodyblade[id] = is_user_bot(id) == 0 ? 0 : 1
	g_can_use_bloodyblade[id] = is_user_bot(id) == 0 ? 0 : 1
	g_using_bloodyblade[id] = 0
	g_had_nvg[id] = 0
	return
	//}
}

public client_putinserver(id)
{
	if(is_user_bot(id) && !g_register)
	{
		g_register = 1
		set_task(0.1, "do_register", id)
	}
}

public do_register(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
}

public zb3_item_selected_post(id, itemid)
{
	if(itemid == g_wing_boot)
	{
		g_had_wing_boot[id] = 1
		set_wing_boot(id)
	} else if(itemid == g_double_grenade) {
		g_had_double_grenade[id] = 1
		set_double_grenade(id)
	} else if(itemid == g_p30_damage) {
		g_had_p30_damage[id] = 1
		set_p30_damage(id)
		//zb3_set_user_maxlevel(id, 13)
	} else if(itemid == g_sprint) {
		g_had_sprint[id] = 1
		set_user_item_sprint(id)
	} else if(itemid == g_deadlyshot) {
		g_had_deadlyshot[id] = 1
		set_user_deadlyshot(id)
	} else if(itemid == g_bloodyblade) {
		g_had_bloodyblade[id] = 1
		set_user_bloodyblade(id)
	} else if(itemid == g_nightvision) {
		g_had_nvg[id] = 1
		zb3_set_user_nvg(id, 0, 0, 1, 0)
	}
}

public zb3_game_start(start_type) 
{
	if(start_type == 0) g_zombie_appear = 0
	else if(start_type == 2) g_zombie_appear = 1
}

public client_PostThink(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return
		
	static Float:CurTime
	CurTime = get_gametime()
	
	if(CurTime - DELAY_TIME > g_hud_delay[id])
	{
		sync_hud1_handle(id)
		sync_hud2_handle(id)
		
		g_hud_delay[id] = CurTime
	}
	
	if(g_had_sprint[id] && g_using_sprint[id])
	{
		if(g_sprint_status[id] == 1)
		{
			if(pev(id, pev_maxspeed) != fastrun_speed) zb3_set_user_speed(id, floatround(fastrun_speed))
		} else if(g_sprint_status[id] == 2) {
			if(pev(id, pev_maxspeed) != slowrun_speed) zb3_set_user_speed(id, floatround(slowrun_speed))
		}
	}
}
public bot_use_item(id)
{
	if(!is_user_alive(id) && zb3_get_user_zombie(id) && !is_user_bot(id))
		return
	//set_task(float(random_num(50,150)),"bot_use_item",id)
	set_task(float(random(10)),"do_deadlyshot",id )
	set_task(float(random(20)),"do_fastrun",id )
	set_task(float(random(30)),"do_bloodyblade",id )
}
public sync_hud1_handle(id)
{
	if(is_user_bot(id))
		return

	static Temp_String[128], Temp_String2[128], Temp_String3[128]
	formatex(Temp_String, sizeof(Temp_String), "")
	
	
	if(g_had_double_grenade[id])
	{
		formatex(Temp_String2, sizeof(Temp_String2), " x2 HE", Temp_String)
		formatex(Temp_String3, sizeof(Temp_String3), "%s^n%s", Temp_String, Temp_String2)
		formatex(Temp_String, sizeof(Temp_String), "%s", Temp_String3)
	}
	if(g_had_p30_damage[id])
	{
		formatex(Temp_String2, sizeof(Temp_String2), " x1.3 DMG", Temp_String)
		formatex(Temp_String3, sizeof(Temp_String3), "%s^n%s", Temp_String, Temp_String2)
		formatex(Temp_String, sizeof(Temp_String), "%s", Temp_String3)
		ShowItemIcon(id, 4)
	}		
	if(g_had_nvg[id])
	{
		formatex(Temp_String2, sizeof(Temp_String2), " NVG", Temp_String)
		formatex(Temp_String3, sizeof(Temp_String3), "%s^n%s", Temp_String, Temp_String2)
		formatex(Temp_String, sizeof(Temp_String), "%s", Temp_String3)
	}		
	if(g_had_wing_boot[id])
	{
		formatex(Temp_String2, sizeof(Temp_String2), " BOOT", Temp_String)
		formatex(Temp_String3, sizeof(Temp_String3), "%s^n%s", Temp_String, Temp_String2)
		formatex(Temp_String, sizeof(Temp_String), "%s", Temp_String3)
		ShowItemIcon(id, 2) // BOOT
	}
	ShowItemIcon(id, 1) // AMMO
	//set_hudmessage(255, 100, 100, 0.015, 0.20, 0, 2.0, 2.0)
	//ShowSyncHudMsg(id, g_sync_hud1, Temp_String3)	
}

public sync_hud2_handle(id)
{
	if(is_user_bot(id))
		return

	static Temp_String_Sprint[128], Temp_String_DeadlyShot[128], Temp_String_BloodyBlade[128]
	static Temp_String_Hud[128]
	
	if(g_had_sprint[id] && g_can_use_sprint[id])
		formatex(Temp_String_Sprint, sizeof(Temp_String_Sprint), "Sprint")
	else 
		formatex(Temp_String_Sprint, sizeof(Temp_String_Sprint), "")
	
	if(g_had_deadlyshot[id] && g_can_use_deadlyshot[id])
		formatex(Temp_String_DeadlyShot, sizeof(Temp_String_DeadlyShot), "^nDeadly Shot")
	else 
		formatex(Temp_String_DeadlyShot, sizeof(Temp_String_DeadlyShot), "^n")
	
	if(g_had_bloodyblade[id] && g_can_use_bloodyblade[id])
		formatex(Temp_String_BloodyBlade, sizeof(Temp_String_BloodyBlade), "^nBloody Blade")
	else
		formatex(Temp_String_BloodyBlade, sizeof(Temp_String_BloodyBlade), "^n")
		
	formatex(Temp_String_Hud, sizeof(Temp_String_Hud), "%s%s%s", Temp_String_Sprint, Temp_String_DeadlyShot, Temp_String_BloodyBlade)
	
	set_hudmessage(255, 255, 255, -1.0, 0.10, 0, 0.0, 2.1)
	ShowSyncHudMsg(id, g_sync_hud1, Temp_String_Hud)
}

public zb3_user_spawned(id)
{
	if(!is_user_connected(id))
		return HAM_IGNORED

	if(is_user_bot(id) && !zb3_get_user_zombie(id)) 
		set_task(float(random_num(20,150)),"bot_use_item",id)

	set_wing_boot(id)
	set_double_grenade(id)
	set_user_item_sprint(id)
	set_p30_damage(id)
	set_user_deadlyshot(id)
	set_user_bloodyblade(id)
	set_user_nightvision(id)
	
	return HAM_HANDLED
}

public zb3_user_infected(id)
{
	reset_all_item(id)
}

public reset_all_item(id)
{
	g_can_use_sprint[id] = 0
	g_using_sprint[id] = 0
	g_sprint_status[id] = 0
	g_can_use_deadlyshot[id] = 0
	g_using_deadlyshot[id] = 0	
	HideItemIcons(id)
	remove_deadlyshot_icon(id)
	remove_bloodblade_icon(id)
}
public zb3_user_dead(id)
{
	reset_all_item(id)
}

// =========== Item: Wing Boot
public set_wing_boot(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!g_had_wing_boot[id])
		return
		
	set_pev(id, pev_gravity, g_wb_gravity)
}

// =========== Item: Double Grenade
public fw_Add_Hegrenade_Post(ent, id)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(zb3_get_user_zombie(id))
		return HAM_IGNORED			
		
	if(!g_doubled_grenade[id])
		set_double_grenade(id)
		
	return HAM_HANDLED
}

public set_double_grenade(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return	
	if(!g_had_double_grenade[id])
		return
		
	g_doubled_grenade[id] = 1
	give_item(id, "weapon_hegrenade")
	
	cs_set_user_bpammo(id, CSW_HEGRENADE, 2)
}

// ============ Item: Sprint
public set_user_item_sprint(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!g_had_sprint[id])
		return	
		
	g_can_use_sprint[id] = 1
	g_using_sprint[id] = 0
	g_sprint_status[id] = 0
	
	client_cmd(id, "bind F1 fastrun")
}

public do_fastrun(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return	
	if(!g_zombie_appear)
		return
	
	if(g_can_use_sprint[id] && !g_using_sprint[id])
	{
		g_can_use_sprint[id] = 0
		g_using_sprint[id] = 1
		g_sprint_status[id] = 1
		
		message_begin(MSG_ONE_UNRELIABLE, g_Msg_ScreenFade, _, id)
		write_short(0) // duration
		write_short(0) // hold time
		write_short(0x0004) // fade type
		write_byte(255) // r
		write_byte(255) // g
		write_byte(255) // b
		write_byte(30) // alpha
		message_end()
		
		remove_task(id+TASK_REMOVE_FASTRUN)
		set_task(fastrun_time, "task_remove_fastrun", id+TASK_REMOVE_FASTRUN)
		
		zb3_set_user_speed(id, floatround(fastrun_speed))
		
		emit_sound(id, CHAN_AUTO, sound_fastrun_start, 1.0, ATTN_NORM, 0, PITCH_NORM)
		emit_sound(id, CHAN_AUTO, sound_fastrun_heartbeat, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		set_task(1.0, "task_human_sound", id+TASK_HUMAN_SOUND, _, _, "b")
	}
}

public task_human_sound(id)
{
	id -= TASK_HUMAN_SOUND
	
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
	{
		remove_task(id+TASK_HUMAN_SOUND)
		return			
	}
	if(!g_had_sprint[id])
	{
		remove_task(id+TASK_HUMAN_SOUND)
		return		
	}
	if(!g_using_sprint[id])
	{
		remove_task(id+TASK_HUMAN_SOUND)
		return
	}
	
	if (g_sprint_status[id] == 1)
	{
		emit_sound(id, CHAN_VOICE, sound_fastrun_heartbeat, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	else if (g_sprint_status[id] == 2)
	{
		static Sex
		Sex = zb3_get_user_sex(id)

		emit_sound(id, CHAN_VOICE, Sex == SEX_MALE ? sound_breath_male : sound_breath_female, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}

public task_remove_fastrun(id)
{
	id -= TASK_REMOVE_FASTRUN
	
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
	{
		remove_task(id+TASK_HUMAN_SOUND)
		return		
	}
	if(!g_had_sprint[id])
	{
		remove_task(id+TASK_HUMAN_SOUND)
		return		
	}
	if(!g_using_sprint[id])
	{
		remove_task(id+TASK_HUMAN_SOUND)
		return
	}	

	message_begin(MSG_ONE_UNRELIABLE, g_Msg_ScreenFade, _, id)
	write_short(0) // duration
	write_short(0) // hold time
	write_short(0x0004) // fade type
	write_byte(255) // r
	write_byte(255) // g
	write_byte(255) // b
	write_byte(0) // alpha
	message_end()
	
	g_sprint_status[id] = 2
	
	remove_task(id+TASK_REMOVE_SLOWRUN)
	set_task(slowrun_time, "task_remove_slowrun", id+TASK_REMOVE_SLOWRUN)
	
	zb3_reset_user_speed(id)
	zb3_set_user_speed(id, floatround(slowrun_speed))
}

public task_remove_slowrun(id)
{
	id -= TASK_REMOVE_SLOWRUN
	
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
	{
		remove_task(id+TASK_HUMAN_SOUND)
		return		
	}
	if(!g_had_sprint[id])
	{
		remove_task(id+TASK_HUMAN_SOUND)
		return		
	}
	if(!g_using_sprint[id])
	{
		remove_task(id+TASK_HUMAN_SOUND)
		return
	}	
	
	g_sprint_status[id] = 0
	g_using_sprint[id] = 0
	
	zb3_reset_user_speed(id)
}

// ============ Item: +30% Damage
public set_p30_damage(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!g_had_p30_damage[id])
		return	
		
	zb3_set_user_maxlevel(id, 13)
	zb3_set_user_level(id, zb3_get_user_level(id) + 3)
	
}

// =============== Item: Deadly Shot
public set_user_deadlyshot(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!g_had_deadlyshot[id])
		return	
		
	g_can_use_deadlyshot[id] = 1
	g_using_deadlyshot[id] = 0
	
	remove_deadlyshot_icon(id)
	client_cmd(id, "bind F2 use_deadlyshot")	
}

public do_deadlyshot(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return	
	if(!g_zombie_appear)
		return		
	
	if(g_can_use_deadlyshot[id] && !g_using_deadlyshot[id])
	{
		g_can_use_deadlyshot[id] = 0
		g_using_deadlyshot[id] = 1
		
		make_deadlyshoot_icon(id)
		emit_sound(id, CHAN_AUTO, sound_fastrun_start, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		if(!zb3_get_user_nvg(id))
		{
			message_begin(MSG_ONE_UNRELIABLE, g_Msg_ScreenFade, _, id)
			write_short(0) // duration
			write_short(0) // hold time
			write_short(0x0004) // fade type
			write_byte(255) // r
			write_byte(255) // g
			write_byte(255) // b
			write_byte(30) // alpha
			message_end()
		}
		
		remove_task(id+TASK_REMOVE_DEADLYSHOT)
		set_task(g_deadlyshot_time, "task_remove_headshot", id+TASK_REMOVE_DEADLYSHOT)
	}
}

public make_deadlyshoot_icon(id)
{
	if(!is_user_connected(id))
		return
		
	remove_deadlyshot_icon(id)
	set_task(0.1, "make_ds_spr", id+TASK_DEADLYSHOT_ICON)
}

public make_ds_spr(id)
{
	id -= TASK_DEADLYSHOT_ICON
	
	if(!is_user_connected(id))
		return
	if(!is_user_alive(id))
		return
	if(!g_using_deadlyshot[id])
		return
		
	static Float:Origin[3], Float:Add_Point
	pev(id, pev_origin, Origin)
	
	if(!(pev(id, pev_flags) & FL_DUCKING))
		Add_Point = 25.0
	else
		Add_Point = 17.0
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord,Origin[0])
	engfunc(EngFunc_WriteCoord,Origin[1])
	engfunc(EngFunc_WriteCoord,Origin[2] + Add_Point)
	write_short(g_deadlyshot_icon_id)
	write_byte(8)
	write_byte(255)
	message_end()	
		
	set_task(0.1, "make_ds_spr", id+TASK_DEADLYSHOT_ICON)
}

public remove_deadlyshot_icon(id)
{
	if(!is_user_connected(id))
		return
		
	remove_task(id+TASK_DEADLYSHOT_ICON)
}

public task_remove_headshot(id)
{
	id -= TASK_REMOVE_DEADLYSHOT
	
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!g_had_deadlyshot[id])
		return		
		
	if(!zb3_get_user_nvg(id))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_Msg_ScreenFade, _, id)
		write_short(0) // duration
		write_short(0) // hold time
		write_short(0x0004) // fade type
		write_byte(255) // r
		write_byte(255) // g
		write_byte(255) // b
		write_byte(0) // alpha
		message_end()
	}
	
	remove_deadlyshot_icon(id)
	
	g_can_use_deadlyshot[id] = 0
	g_using_deadlyshot[id] = 0
}

// NightVision
public set_user_nightvision(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!g_had_nvg[id])
		return	
	if(is_user_bot(id))	zb3_set_user_nvg(id, random(1), 1, 1, 0)
	else zb3_set_user_nvg(id, 0, 0, 1, 0)
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (victim == attacker || !is_user_alive(attacker) || !is_user_alive(victim))
		return HAM_IGNORED;
	if (cs_get_user_team(victim) == cs_get_user_team(attacker))
		return HAM_IGNORED
		
	if(g_using_bloodyblade[attacker] && get_user_weapon(attacker) == CSW_KNIFE)
		SetHamParamFloat(3, damage * g_bloodyblade_damage)
	if(g_using_deadlyshot[attacker])
		set_tr2(tracehandle, TR_iHitgroup, HIT_HEAD)
	
	return HAM_IGNORED
}

// ================ Skill: Bloody Blade
public set_user_bloodyblade(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!g_had_bloodyblade[id])
		return	
		
	g_can_use_bloodyblade[id] = 1
	g_using_bloodyblade[id] = 0
	
	client_cmd(id, "bind F3 use_bloodyblade")		
}

public do_bloodyblade(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return	
	if(!g_zombie_appear)
		return		
	
	if(g_can_use_bloodyblade[id] && !g_using_bloodyblade[id])
	{
		g_can_use_bloodyblade[id] = 0
		g_using_bloodyblade[id] = 1
		make_bloodblade_icon(id)
		
		emit_sound(id, CHAN_AUTO, sound_fastrun_start, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		if(!zb3_get_user_nvg(id))
		{
			message_begin(MSG_ONE_UNRELIABLE, g_Msg_ScreenFade, _, id)
			write_short(0) // duration
			write_short(0) // hold time
			write_short(0x0004) // fade type
			write_byte(255) // r
			write_byte(255) // g
			write_byte(255) // b
			write_byte(30) // alpha
			message_end()
		}
		
		remove_task(id+TASK_REMOVE_BLOODYBLADE)
		set_task(g_bloodyblade_time, "task_remove_bloodyblade", id+TASK_REMOVE_BLOODYBLADE)
	}
}

public task_remove_bloodyblade(id)
{
	id -= TASK_REMOVE_BLOODYBLADE
	
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!g_had_bloodyblade[id])
		return		
		
	if(!zb3_get_user_nvg(id))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_Msg_ScreenFade, _, id)
		write_short(0) // duration
		write_short(0) // hold time
		write_short(0x0004) // fade type
		write_byte(255) // r
		write_byte(255) // g
		write_byte(255) // b
		write_byte(0) // alpha
		message_end()
	}
	
	remove_bloodblade_icon(id)
	g_can_use_bloodyblade[id] = 0
	g_using_bloodyblade[id] = 0
}

public make_bloodblade_icon(id)
{
	if(!is_user_connected(id))
		return	
	
	remove_bloodblade_icon(id)
	set_task(0.1, "make_bb_spr", id+TASK_BLOODYBLADE_ICON)
	
}	

public make_bb_spr(id)
{
	id -= TASK_BLOODYBLADE_ICON
	
	if(!is_user_connected(id))
		return
	if(!is_user_alive(id))
		return
	if(!g_using_bloodyblade[id])
		return
		
	static Float:Origin[3], Float:Add_Point
	pev(id, pev_origin, Origin)
	
	if(!(pev(id, pev_flags) & FL_DUCKING))
		Add_Point = 25.0
	else
		Add_Point = 17.0
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord,Origin[0])
	engfunc(EngFunc_WriteCoord,Origin[1])
	engfunc(EngFunc_WriteCoord,Origin[2] + Add_Point)
	write_short(g_bloodyblade_icon_id)
	write_byte(8)
	write_byte(255)
	message_end()	
		
	set_task(0.1, "make_bb_spr", id+TASK_BLOODYBLADE_ICON)
}

public remove_bloodblade_icon(id)
{
	if(!is_user_connected(id))
		return
	
	remove_task(id+TASK_BLOODYBLADE_ICON)
}
// StatusIcon
stock ShowItemIcon(id, idspr)
{	
	StatusIcon(id, GetItemIconName(idspr), 1)
}
stock HideItemIcon(id, idspr)
{	
	StatusIcon(id, GetItemIconName(idspr), 0)
}
stock HideItemIcons(id)
{	
	for (new i = 0; i <= 7; i++)
	{
		StatusIcon(id, GetItemIconName(i + 1), 0)
		//StatusIcon(id, GetItemIconName(i, 2), 0)
	}

}
stock StatusIcon(id, sprite_name[], run)
{	
	message_begin(MSG_ONE, g_msgStatusIcon, {0,0,0}, id);
	write_byte(run); // status (0=hide, 1=show, 2=flash)
	write_string(sprite_name); // sprite name
	write_byte(200) //R
	write_byte(150) //G
	write_byte(100) //B
	message_end();

}
stock GetItemIconName(item)
{
	new item_name[64]
	switch (item)
	{
		/*
		case 1: item_name = "zombiACT" // AMMO 1.5
		case 2: item_name = "zombiBCT" // BOOT
		case 3: item_name = "zombiCCT" // VOODOO
		case 4: item_name = "zombiECT" // TRAP
		case 5: item_name = "zombiFCT" // SPRINT VERT
		case 6: item_name = "zombiICT" // DEADLY
		case 7: item_name = "zombiJCT" // BLOODY

		
		case 1: item_name = "zombiATER" // HP+ AP UP
		case 2: item_name = "zombiBTER" // ZB 100% HP
		case 3: item_name = "zombiCTER" // Psycho zb
		case 4: item_name = "zombiDTER" // light zb
		case 5: item_name = "zombiETER" // heavy
		case 6: item_name = "zombiFTER" // psycho
		case 7: item_name = "zombiGTER" // voodoo
		case 8: item_name = "zombiHTER" // 0 res
		case 9: item_name = "zombiITER" // deimos
		case 10: item_name = "zombiJTER" // metus
		*/
		case 1: item_name = "zombiACT" // AMMO 1.5
		case 2: item_name = "zombiBCT" // BOOT
		case 3: item_name = "zombiATER"// HP + AP UP
		case 4: item_name = "zombiHCT" // 30 UP
		case 5: item_name = "zombiFCT" // SPRINT
		case 6: item_name = "zombiICT" // DEADLY
		case 7: item_name = "zombiJCT" // BLOODY
		default: item_name = ""
	}
	return item_name
}
public message_statusicon()
{
	return PLUGIN_HANDLED;
}	