#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <zombie_thehero2>

#define PLUGIN "[ZB3] Zombie Class: Regular"
#define VERSION "2.0"
#define AUTHOR "Dias"

new const LANG_FILE[] = "zombie_thehero2.txt"

// Zombie Configs
new const zclass_name[] = "Heavy"
new const zclass_desc[] = "Trap"
new const zclass_sex = SEX_MALE
new const zclass_lockcost = 0
new const zclass_hostmodel[] = "heavy_zombi_host"
new const zclass_originmodel[] = "heavy_zombi_origin"
new const zclass_clawsmodelhost[] = "v_knife_heavy_zombi.mdl"
new const zclass_clawsmodelorigin[] = "v_knife_heavy_zombi.mdl"
new const zombiegrenade_modelhost[] = "models/zombie_thehero/v_zgren_heavy_zombi.mdl"
new const zombiegrenade_modelorigin[] = "models/zombie_thehero/v_zgren_heavy_zombi.mdl"
new const Float:zclass_gravity = 0.8
new const Float:zclass_speedhost = 270.0
new const Float:zclass_speedorigin = 270.0
new const Float:zclass_knockback = 0.3
new const Float:zclass_painshock = 0.5
new const Float:zclass_dmgmulti = 0.8

new const DeathSound[2][] = 
{
	"zombie_thehero/zombi_death_heavy_1.wav",
	"zombie_thehero/zombi_death_heavy_2.wav"
}

new const HurtSound[2][] = {
	"zombie_thehero/zombi_hurt_heavy_1.wav",
	"zombie_thehero/zombi_hurt_heavy_2.wav"
}

new const HealSound[] = "zombie_thehero/zombi_heal_heavy.wav"
new const EvolSound[] = "zombie_thehero/zombi_evolution.wav"
new const Float:ClawsDistance1 = 1.0
new const Float:ClawsDistance2 = 1.1

new g_zombie_classid, g_can_set_trap[33], g_current_time[33]
new const berserk_sound[2][] =
{
	"zombie_thehero/zombi_pre_idle_1.wav",
	"zombie_thehero/zombi_pre_idle_2.wav"
}

#define LANG_OFFICIAL LANG_PLAYER

#define TRAP_SKILL_TIME_HOST 10
#define TRAP_SKILL_TIME_ORIGIN 15
#define TRAP_SKILL_COOLDOWN_HOST (10 + TRAP_SKILL_TIME_HOST)
#define TRAP_SKILL_COOLDOWN_ORIGIN (5 + TRAP_SKILL_TIME_ORIGIN)

#define TASK_COOLDOWN 12001
#define TASK_BERSERK_SOUND 12002

const MAX_TRAP = 30
new const trap_classname[] = "nst_zb_trap"

new const model_trap[] = "models/zombie_thehero/zombitrap.mdl"
new const sound_trapsetup[] = "zombie_thehero/zombi_trapsetup.wav"
new const sound_trapped[] = "zombie_thehero/zombi_trapped.wav"
// Vars
new g_total_traps[33], g_msgScreenShake, g_trapping[33], g_player_trapped[33]
new g_waitsetup[33], TrapOrigins[33][MAX_TRAP][4]
// Task offsets
enum (+= 100)
{
	TASK_TRAPSETUP = 2000,
	TASK_REMOVETRAP,
	TASK_REMOVE_TIMEWAIT,
	TASK_BOT_USE_SKILL
}
// IDs inside tasks
#define ID_TRAPSETUP (taskid - TASK_TRAPSETUP)
#define ID_REMOVETRAP (taskid - TASK_REMOVETRAP)
#define ID_REMOVE_TIMEWAIT (taskid - TASK_REMOVE_TIMEWAIT)
#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)
#define TRAP_TOTAL 3
#define TRAP_TIMEWAIT 10.0
#define TRAP_TIMESETUP 1.0
#define TRAP_INVISIBLE 100
#define TRAP_TIME_EFFECT 8.0
new g_synchud1

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_dictionary(LANG_FILE)
	register_clcmd("drop", "cmd_drop")
	// Msg
	g_msgScreenShake = get_user_msgid("ScreenShake")
	
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	
	//g_Msg_Fov = get_user_msgid("SetFOV")
	g_synchud1 = zb3_get_synchud_id(SYNCHUD_ZBHM_SKILL1)
}

public plugin_precache()
{
	// Register Zombie Class
	g_zombie_classid = zb3_register_zombie_class(zclass_name, zclass_desc, zclass_sex, zclass_lockcost, 
	zclass_gravity, zclass_speedhost, zclass_speedorigin, zclass_knockback, zclass_painshock, zclass_dmgmulti,
	ClawsDistance1, ClawsDistance2)
	
	zb3_set_zombie_class_data(zclass_hostmodel, zclass_originmodel, zclass_clawsmodelhost, zclass_clawsmodelorigin, 
	DeathSound[0], DeathSound[1], HurtSound[0], HurtSound[1], HealSound, EvolSound)
	
	zb3_register_zbgre_model(zombiegrenade_modelhost, zombiegrenade_modelorigin)
	
	// Precache Class Resource
	engfunc(EngFunc_PrecacheModel, model_trap)
	engfunc(EngFunc_PrecacheSound, sound_trapsetup)
	engfunc(EngFunc_PrecacheSound, sound_trapped)
	for(new i = 0; i < sizeof(berserk_sound); i++)
		engfunc(EngFunc_PrecacheSound, berserk_sound[i])
}

public zb3_user_infected(id, infector)
{
	if(zb3_get_user_zombie_class(id) == g_zombie_classid)
	{
		if(is_user_bot(id))
			bot_use_skill(id)
		reset_skill(id)
		
		g_can_set_trap[id] = 1
		g_current_time[id] = zb3_get_user_level(id) > 1 ? (TRAP_SKILL_COOLDOWN_ORIGIN) : (TRAP_SKILL_COOLDOWN_HOST)
	}
}

public reset_skill(id)
{
	if (task_exists(id+TASK_TRAPSETUP)) remove_task(id+TASK_TRAPSETUP)
	if (task_exists(id+TASK_REMOVETRAP)) remove_task(id+TASK_REMOVETRAP)
	if (task_exists(id+TASK_REMOVE_TIMEWAIT)) remove_task(id+TASK_REMOVE_TIMEWAIT)
	if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)
	
	g_total_traps[id] = 0
	g_trapping[id] = 0
	g_player_trapped[id] = 0
	
	remove_traps_player(id)
	remove_traps()
}

public zb3_user_spawned(id) 
{
	if(!zb3_get_user_zombie(id)) set_task(0.1, "reset_skill", id)
}

public zb3_user_dead(id) reset_skill(id)
public bot_use_skill(id)
{
	if(!is_user_alive(id) || !zb3_get_user_zombie(id))
		return PLUGIN_CONTINUE
		
	cmd_drop(id)
	set_task(zb3_get_user_level(id) > 1 ? float(TRAP_SKILL_COOLDOWN_ORIGIN) : float(TRAP_SKILL_COOLDOWN_HOST),"bot_use_skill",id)
	return PLUGIN_HANDLED
}
public cmd_drop(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
	if(!zb3_get_user_zombie(id))
		return PLUGIN_CONTINUE
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return PLUGIN_CONTINUE
	if(!g_can_set_trap[id])
		return PLUGIN_HANDLED
		
	Do_Trap(id)

	return PLUGIN_HANDLED
}

public Do_Trap(id)
{
	if (!is_user_alive(id)) return PLUGIN_CONTINUE

	// check setupping
	if (g_trapping[id] || g_waitsetup[id]) return PLUGIN_HANDLED
	
	g_can_set_trap[id] = 0
	g_current_time[id] = 0
	g_can_set_trap[id] = 0
	
	// check total trap
	new level = zb3_get_user_level(id)
	new max_traps = TRAP_TOTAL
	if (level==1) max_traps = max_traps/2
	/*
	if (g_total_traps[id]>=max_traps)
	{
		new message[100]
		format(message, charsmax(message), "^x04[Zombie United]^x01 %L", LANG_PLAYER, "CLASS_NOTICE_MAXTRAP", max_traps)
		print_client(id, message)
		return PLUGIN_HANDLED
	}*/
	 
	// set trapping
	g_trapping[id] = 1
	//bartime(id, FloatToNum(get_pcvar_float(trap_timesetup)))
		
	// set task
	if (task_exists(id+TASK_TRAPSETUP)) remove_task(id+TASK_TRAPSETUP)
	set_task(TRAP_TIMESETUP, "TrapSetup", id+TASK_TRAPSETUP)
	
	//client_print(id, print_chat, "[%i]", fnFloatToNum(time_invi))
	//static Float:SkillTime
	//SkillTime = zb3_get_user_level(id) > 1 ? float(BERSERK_TIME_ORIGIN) : float(BERSERK_TIME_HOST)
		
	//set_task(SkillTime, "Remove_Berserk", id+TASK_BERSERKING)
	return PLUGIN_HANDLED

}
/*
public Remove_Berserk(id)
{
	id -= TASK_BERSERKING

	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 

	// Set Vars
	g_can_set_trap[id] = 0	
	
	// Reset Rendering
	zb3_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 0)
	
	// Reset FOV
	set_fov(id)
	
	// Reset Speed
	static Float:DefaultSpeed
	DefaultSpeed = zb3_get_user_level(id) > 1 ? zclass_speedorigin : zclass_speedhost
	
	zb3_set_user_speed(id, floatround(DefaultSpeed))
}
*/
public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id)) return;
	
	// icon help
	/*
	if (zb3_get_user_zombie(id) && zb3_get_user_zombie_class(id) == g_zombie_classid)
	{
		// check trapping
		if (g_trapping[id])
		{
			// remove setup trap if player move
			static Float:velocity[3]
			pev(id, pev_velocity, velocity)
			if (velocity[0] || velocity[1] || velocity[2])
			{
				remove_setuptrap(id)
			}
		}

	}*/
	
	// player pickup trap
	new ent_trap = g_player_trapped[id]
	if (ent_trap && pev_valid(ent_trap))
	{
		// sequence of trap model
		static classname[32]
		pev(ent_trap, pev_classname, classname, charsmax(classname))
		if (equal(classname, classname))
		{
			if (pev(ent_trap, pev_sequence) != 1)
			{
				set_pev(ent_trap, pev_sequence, 1)
				set_pev(ent_trap, pev_frame, 0.0)
			}
			else
			{
				if (pev(ent_trap, pev_frame) > 230)
					set_pev(ent_trap, pev_frame, 20.0)
				else
					set_pev(ent_trap, pev_frame, pev(ent_trap, pev_frame) + 1.0)
			}
			//client_print(0, print_chat, "[%i][%i]", pev(ent_trap, pev_sequence), pev(ent_trap, pev_frame))
		}
		//client_print(0, print_chat, "[%s]", classname)
	}
	
	return;
}
// don't move when traped
public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id)) return;
	
	new ent_trap = g_player_trapped[id]
	if (ent_trap && pev_valid(ent_trap) && !zb3_get_user_zombie(id))
	{	
		set_pev(id, pev_maxspeed, 0.01)
	}
}
// trapped
public pfn_touch(ptr, ptd)
{
	if(pev_valid(ptr))
	{
		new classname[32]
		pev(ptr, pev_classname, classname, charsmax(classname))
		//client_print(ptd, print_chat, "[%s][%i]", classname, ptr)
		
		if(equal(classname, trap_classname))
		{
			new victim = ptd
			new attacker = pev(ptr, pev_owner)
			if (is_user_alive(victim) && (get_user_team(attacker) != get_user_team(victim)) && victim != attacker && !g_player_trapped[victim])
			//if (is_user_alive(victim) && !nst_zb_get_user_zombie(victim) && g_player_trapped[victim] != ptr)
			{
				Trapped(victim, ptr)
			}
		}
	}
}
// #################### TRAP PUBLIC ####################

public TrapSetup(taskid)
{
	new id = ID_TRAPSETUP
	
	// remove setup trap
	remove_setuptrap(id)

	// create model trap
	create_w_class(id)

	// play sound
	PlayEmitSound(id, sound_trapsetup)
	
	// remove task TrapSetup
	if (task_exists(taskid)) remove_task(taskid)

	// set wait time
	g_waitsetup[id] = 1
	if (task_exists(id+TASK_REMOVE_TIMEWAIT)) remove_task(id+TASK_REMOVE_TIMEWAIT)
	set_task(TRAP_TIMEWAIT, "RemoveTimeWait", id+TASK_REMOVE_TIMEWAIT)
}
public RemoveTimeWait(taskid)
{
	new id = ID_REMOVE_TIMEWAIT
	g_waitsetup[id] = 0
	if (task_exists(taskid)) remove_task(taskid)
}
remove_setuptrap(id)
{
	g_trapping[id] = 0
	if (task_exists(id+TASK_TRAPSETUP)) remove_task(id+TASK_TRAPSETUP)
}
Trapped(id, ent_trap)
{
	// check trapped
	for (new i=1; i<33; i++)
	{
		if (is_user_connected(i) && g_player_trapped[i]==ent_trap) return;
	}
	
	// set ent trapped of player
	g_player_trapped[id] = ent_trap
	
	// set screen shake
	user_screen_shake(id, 4, 2, 5)

	// stop move
	//if (!(user_flags & FL_FROZEN)) set_pev(id, pev_flags, (user_flags | FL_FROZEN))
			
	// play sound
	PlayEmitSound(id, sound_trapped)
	
	// reset invisible model trapped
	fm_set_rendering(ent_trap)

	// set task remove trap
	if (task_exists(id+TASK_REMOVETRAP)) remove_task(id+TASK_REMOVETRAP)
	set_task(TRAP_TIME_EFFECT, "RemoveTrap", id+TASK_REMOVETRAP)
	
	// update TrapOrigins
	UpdateTrap(ent_trap)
}
UpdateTrap(ent_trap)
{
	//new id = entity_get_int(ent_trap, EV_INT_iuser1)
	new id = pev(ent_trap, pev_owner)

	new total, TrapOrigins_new[MAX_TRAP][4]
	for (new i = 1; i <= g_total_traps[id]; i++)
	{
		if (TrapOrigins[id][i][0] != ent_trap)
		{
			total += 1
			TrapOrigins_new[total][0] = TrapOrigins[id][i][0]
			TrapOrigins_new[total][1] = TrapOrigins[id][i][1]
			TrapOrigins_new[total][2] = TrapOrigins[id][i][2]
			TrapOrigins_new[total][3] = TrapOrigins[id][i][3]
		}
	}
	TrapOrigins[id] = TrapOrigins_new
	g_total_traps[id] = total
}
public RemoveTrap(taskid)
{
	new id = ID_REMOVETRAP
	
	// set speed for player
	//set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
	
	// remove trap
	remove_trapped_when_infected(id)
	
	if (task_exists(taskid)) remove_task(taskid)
}
remove_trapped_when_infected(id)
{
	new p_trapped = g_player_trapped[id]
	if (p_trapped)
	{
		// remove trap
		if (pev_valid(p_trapped)) engfunc(EngFunc_RemoveEntity, p_trapped)
		
		// reset value of player
		g_player_trapped[id] = 0
	}
}
create_w_class(id)
{
	if (!zb3_get_user_zombie(id)) return -1;

	new user_flags = pev(id, pev_flags)
	if (!(user_flags & FL_ONGROUND))
	{
		return 0;
	}
	
	// get origin
	new Float:origin[3]
	pev(id, pev_origin, origin)

	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if (!ent) return -1;
	
	// Set trap data
	set_pev(ent, pev_classname, trap_classname)
	set_pev(ent, pev_solid, SOLID_TRIGGER)
	set_pev(ent, pev_movetype, 6)
	set_pev(ent, pev_sequence, 0)
	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_owner, id)
	//set_pev(ent, pev_iuser1, id)
	
	// Set trap size
	new Float:mins[3] = { -20.0, -20.0, 0.0 }
	new Float:maxs[3] = { 20.0, 20.0, 30.0 }
	engfunc(EngFunc_SetSize, ent, mins, maxs)
	
	// Set trap model
	engfunc(EngFunc_SetModel, ent, model_trap)

	// Set trap position
	set_pev(ent, pev_origin, origin)
	
	
	// set invisible
	fm_set_rendering(ent,kRenderFxGlowShell,0,0,0,kRenderTransAlpha, TRAP_INVISIBLE)
	
	// trap counter
	g_total_traps[id] += 1
	TrapOrigins[id][g_total_traps[id]][0] = ent
	TrapOrigins[id][g_total_traps[id]][1] = FloatToNum(origin[0])
	TrapOrigins[id][g_total_traps[id]][2] = FloatToNum(origin[1])
	TrapOrigins[id][g_total_traps[id]][3] = FloatToNum(origin[2])
	
	return -1;
}
PlayEmitSound(id, const sound[])
{
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16) 
{
	new Float:RenderColor[3];
	RenderColor[0] = float(r);
	RenderColor[1] = float(g);
	RenderColor[2] = float(b);

	set_pev(entity, pev_renderfx, fx);
	set_pev(entity, pev_rendercolor, RenderColor);
	set_pev(entity, pev_rendermode, render);
	set_pev(entity, pev_renderamt, float(amount));

	return 1;
}

FloatToNum(Float:floatn)
{
	new str[64], num
	float_to_str(floatn, str, 63)
	num = str_to_num(str)
	
	return num
}

remove_traps()
{
	// reset model
	new nextitem  = find_ent_by_class(-1, trap_classname)
	while(nextitem)
	{
		remove_entity(nextitem)
		nextitem = find_ent_by_class(-1, trap_classname)
	}
	
	// reset oringin
	//new TrapOrigins_reset[33][MAX_TRAP][4]
	//TrapOrigins = TrapOrigins_reset
}
remove_traps_player(id)
{
	// remove model trap in map
	for (new i = 1; i <= g_total_traps[id]; i++)
	{
		new trap_ent = TrapOrigins[id][i][0]
		if (is_valid_ent(trap_ent)) engfunc(EngFunc_RemoveEntity, trap_ent)
	}
	
	// reset oringin
	new TrapOrigins_pl[MAX_TRAP][4]
	TrapOrigins[id] = TrapOrigins_pl
}
user_screen_shake(id, amplitude = 4, duration = 2, frequency = 10)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, id)
	write_short((1<<12)*amplitude) // ??
	write_short((1<<12)*duration) // ??
	write_short((1<<12)*frequency) // ??
	message_end()
}

public zb3_skill_show(id)
{
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 	
		
	if(g_current_time[id] < (zb3_get_user_level(id) > 1 ? (TRAP_SKILL_COOLDOWN_ORIGIN): (TRAP_SKILL_COOLDOWN_HOST )))
		g_current_time[id]++
	
	static percent
	static timewait
	
	timewait = zb3_get_user_level(id) > 1 ? (TRAP_SKILL_COOLDOWN_ORIGIN): (TRAP_SKILL_COOLDOWN_HOST )
	percent = floatround((float(g_current_time[id]) / float(timewait)) * 100.0)
	
	set_hudmessage(255, 255, 255, -1.0, 0.10, 0, 3.0, 3.0)
	ShowSyncHudMsg(id, g_synchud1, "[G] - %s (%i%%)", zclass_desc, percent)
	
	if(percent > 99 && !g_can_set_trap[id]) 
		g_can_set_trap[id] = 1
		
}

stock EmitSound(id, chan, const file_sound[])
{
	if(!is_user_connected(id))
		return
		
	emit_sound(id, chan, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
