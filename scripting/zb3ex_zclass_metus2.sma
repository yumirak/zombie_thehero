#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_thehero2>

#define PLUGIN "[ZB3] Zombie Class: Regular"
#define VERSION "2.0"
#define AUTHOR "Dias"

new const LANG_FILE[] = "zombie_thehero2.txt"

// Zombie Configs
new const zclass_name[] = "Metus"
new const zclass_desc[] = "Plunge"
new const zclass_sex = SEX_MALE
new const zclass_lockcost = 7000
new const zclass_hostmodel[] = "deimos_zombi_host"
new const zclass_originmodel[] = "deimos2_zombi_origin"
new const zclass_clawsmodelhost[] = "v_knife_deimos_zombi_host.mdl"
new const zclass_clawsmodelorigin[] = "v_knife_deimos2_zombi.mdl"
new const zombiegrenade_modelhost[] = "models/zombie_thehero/v_zgren_deimos_zombi_host.mdl"
new const zombiegrenade_modelorigin[] = "models/zombie_thehero/v_zgren_deimos2_zombi_origin.mdl"
new const Float:zclass_gravity = 0.8
new const Float:zclass_speedhost = 280.0
new const Float:zclass_speedorigin = 280.0
new const Float:zclass_knockback = 0.4
new const Float:zclass_painshock = 0.5
new const Float:zclass_dmgmulti = 0.9
new const DeathSound[2][] =
{
	"zombie_thehero/zombi_death_1.wav",
	"zombie_thehero/zombi_death_2.wav"
}
new const HurtSound[2][] = 
{
	"zombie_thehero/zombi_hurt_01.wav",
	"zombie_thehero/zombi_hurt_02.wav"	
}
new const HealSound[] = "zombie_thehero/zombi_heal.wav"
new const EvolSound[] = "zombie_thehero/zombi_evolution.wav"
new const Float:ClawsDistance1 = 1.0
new const Float:ClawsDistance2 = 1.1

new g_zombie_classid, g_can_charge[33], g_charging[33], g_current_time[33]
new const berserk_startsound[] = "zombie_thehero/zombi_pressure.wav"


#define LANG_OFFICIAL LANG_PLAYER

#define CHARGE_COLOR_R 255
#define CHARGE_COLOR_G 3
#define CHARGE_COLOR_B 0

#define FASTRUN_FOV 105
#define CHARGE_SPEED 200
#define CHARGE_GRAVITY 0.7

#define CHARGE_TIME_HOST 2
#define CHARGE_TIME_ORIGIN 3
#define CHARGE_COOLDOWN_HOST (15 + CHARGE_TIME_HOST)
#define CHARGE_COOLDOWN_ORIGIN (10 + CHARGE_TIME_ORIGIN)

#define TASK_CHARGING 13025
#define TASK_COOLDOWN 13026
#define TASK_CHARGE_SOUND 13027

const OFFSET_PAINSHOCK = 108

new g_Msg_Fov, g_synchud1

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_dictionary(LANG_FILE)
	register_clcmd("drop", "cmd_drop")
	RegisterHam(Ham_TakeDamage, "player", "fw_PlayerTakeDamage_Post", 1)
	g_Msg_Fov = get_user_msgid("SetFOV")
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
	engfunc(EngFunc_PrecacheSound, berserk_startsound)
	
}

public zb3_user_infected(id, infector)
{
	if(zb3_get_user_zombie_class(id) == g_zombie_classid)
	{
		if(is_user_bot(id))
			bot_use_skill(id)
		reset_skill(id)
		
		g_can_charge[id] = 1
		g_current_time[id] = zb3_get_user_level(id) > 1 ? (CHARGE_COOLDOWN_ORIGIN) : (CHARGE_COOLDOWN_HOST)
	}
}

public reset_skill(id)
{
	g_can_charge[id] = 0
	g_charging[id] = 0
	g_current_time[id] = 0
	
	remove_task(id+TASK_CHARGING)
	remove_task(id+TASK_COOLDOWN)
	remove_task(id+TASK_CHARGE_SOUND)
	
	if(is_user_connected(id)) set_fov(id)
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
	set_task(zb3_get_user_level(id) > 1 ? float(CHARGE_COOLDOWN_ORIGIN) : float(CHARGE_COOLDOWN_HOST),"bot_use_skill",id)
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
	if(!g_can_charge[id] || g_charging[id])
		return PLUGIN_HANDLED
		
	Do_Charge(id)

	return PLUGIN_HANDLED
}

public Do_Charge(id)
{
	
	zb3_reset_user_speed(id)
		
	// Set Vars
	g_charging[id] = 1
	g_can_charge[id] = 0
	g_current_time[id] = 0
		
	// Decrease Health
	//zb3_set_user_health(id, get_user_health(id) - HEALTH_DECREASE)
		
	// Set Render Red
	zb3_set_user_rendering(id, kRenderFxGlowShell, CHARGE_COLOR_R, CHARGE_COLOR_G, CHARGE_COLOR_B, kRenderNormal, 0)
	
	// Set Fov
	set_fov(id, FASTRUN_FOV)
		
	// Set MaxSpeed & Gravity
	zb3_set_user_speed(id, CHARGE_SPEED)
	//set_pev(id, pev_maxspeed, BERSERK_GRAVITY)
	set_pev(id, pev_gravity, CHARGE_GRAVITY)	
	// Play Berserk Sound
	EmitSound(id, CHAN_VOICE, berserk_startsound)
		
	// Set Task
	//set_task(2.0, "Berserk_HeartBeat", id+TASK_BERSERK_SOUND)
		
	static Float:SkillTime
	SkillTime = zb3_get_user_level(id) > 1 ? float(CHARGE_TIME_ORIGIN) : float(CHARGE_TIME_HOST)
		
	set_task(SkillTime, "Remove_Charge", id+TASK_CHARGING)
	
}

public Remove_Charge(id)
{
	id -= TASK_CHARGING

	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 
	if(!g_charging[id])
		return	

	// Set Vars
	g_charging[id] = 0
	g_can_charge[id] = 0	
	
	// Reset Rendering
	zb3_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 0)
	
	// Reset FOV
	set_fov(id)
	
	// Reset Speed
	static Float:DefaultSpeed
	DefaultSpeed = zb3_get_user_level(id) > 1 ? zclass_speedorigin : zclass_speedhost
	
	zb3_set_user_speed(id, floatround(DefaultSpeed))
}

public fw_PlayerTakeDamage_Post(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(!is_user_alive(victim) || !is_user_alive(attacker) || !zb3_get_user_zombie(victim))
		return HAM_IGNORED	
	//if(fm_cs_get_user_team(victim) == fm_cs_get_user_team(attacker))
	//	return HAM_IGNORED
	if(!zb3_get_user_zombie(attacker) && zb3_get_user_zombie(victim) && zb3_get_user_zombie_class(victim) == g_zombie_classid && g_charging[victim]) 
	{
		//if(pev_valid(victim) == 2 ) 
		set_pdata_float(victim, OFFSET_PAINSHOCK, 100.0, 5)
	}		
		
	return HAM_IGNORED
}
public zb3_skill_show(id)
{
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 	
		
	if(g_current_time[id] < (zb3_get_user_level(id) > 1 ? (CHARGE_COOLDOWN_ORIGIN): (CHARGE_COOLDOWN_HOST )))
		g_current_time[id]++
	
	static percent
	static timewait
	
	timewait = zb3_get_user_level(id) > 1 ? (CHARGE_COOLDOWN_ORIGIN): (CHARGE_COOLDOWN_HOST )
	percent = floatround((float(g_current_time[id]) / float(timewait)) * 100.0)
	
	set_hudmessage(255, 255, 255, -1.0, 0.10, 0, 3.0, 3.0)
	ShowSyncHudMsg(id, g_synchud1, "[G] - %s (%i%%)", zclass_desc, percent)
	
	if(percent > 99 && !g_can_charge[id]) 
		g_can_charge[id] = 1
		
}

stock set_fov(id, num = 90)
{
	if(!is_user_connected(id))
		return
	
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_Fov, {0,0,0}, id)
	write_byte(num)
	message_end()
}

stock EmitSound(id, chan, const file_sound[])
{
	if(!is_user_connected(id))
		return
		
	emit_sound(id, chan, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
