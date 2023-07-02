#include <amxmodx>
#include <fakemeta>
#include <zombie_thehero2>

#define PLUGIN "[ZB3] Zombie Class: Regular"
#define VERSION "2.0"
#define AUTHOR "Dias"

new const LANG_FILE[] = "zombie_thehero2.txt"

// Zombie Configs
new const zclass_name[] = "Regular"
new const zclass_desc[] = "Berserk"
new const zclass_sex = SEX_MALE
new const zclass_lockcost = 0
new const zclass_hostmodel[] = "tank_zombi_host"
new const zclass_originmodel[] = "tank_zombi_origin"
new const zclass_clawsmodelhost[] = "v_knife_tank_zombi.mdl"
new const zclass_clawsmodelorigin[] = "v_knife_tank_zombi.mdl"
new const zombiegrenade_modelhost[] = "models/zombie_thehero/v_zgren_tank_zombi.mdl"
new const zombiegrenade_modelorigin[] = "models/zombie_thehero/v_zgren_tank_zombi.mdl"
new const Float:zclass_gravity = 0.8
new const Float:zclass_speedhost = 280.0
new const Float:zclass_speedorigin = 280.0
new const Float:zclass_knockback = 1.0
new const Float:zclass_painshock = 0.4
new const Float:zclass_dmgmulti = 1.0

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

new g_zombie_classid, g_can_berserk[33], g_berserking[33], g_current_time[33]
new const berserk_startsound[] = "zombie_thehero/zombi_pressure.wav"
new const berserk_sound[2][] =
{
	"zombie_thehero/zombi_pre_idle_1.wav",
	"zombie_thehero/zombi_pre_idle_2.wav"
}

#define LANG_OFFICIAL LANG_PLAYER

#define BERSERK_COLOR_R 255
#define BERSERK_COLOR_G 3
#define BERSERK_COLOR_B 0

#define FASTRUN_FOV 105
#define BERSERK_SPEED 340
#define BERSERK_GRAVITY 0.7

#define BERSERK_TIME_HOST 5
#define BERSERK_TIME_ORIGIN 10
#define BERSERK_COOLDOWN_HOST (10 + BERSERK_TIME_HOST)
#define BERSERK_COOLDOWN_ORIGIN (5 + BERSERK_TIME_ORIGIN)

#define TASK_BERSERKING 12000
#define TASK_COOLDOWN 12001
#define TASK_BERSERK_SOUND 12002

new g_Msg_Fov, g_synchud1

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_dictionary(LANG_FILE)
	register_clcmd("drop", "cmd_drop")
	
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
	
	for(new i = 0; i < sizeof(berserk_sound); i++)
		engfunc(EngFunc_PrecacheSound, berserk_sound[i])
}

public zb3_user_infected(id, infector)
{
	if(zb3_get_user_zombie_class(id) == g_zombie_classid)
	{
		if (is_user_bot(id))
			bot_use_skill(id)
			
		reset_skill(id)
		
		g_can_berserk[id] = 1
		g_current_time[id] = zb3_get_user_level(id) > 1 ? (BERSERK_COOLDOWN_ORIGIN) : (BERSERK_COOLDOWN_HOST)
	}
}

public reset_skill(id)
{
	g_can_berserk[id] = 0
	g_berserking[id] = 0
	g_current_time[id] = 0
	
	remove_task(id+TASK_BERSERKING)
	remove_task(id+TASK_COOLDOWN)
	remove_task(id+TASK_BERSERK_SOUND)
	
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
	set_task(zb3_get_user_level(id) > 1 ? float(BERSERK_COOLDOWN_ORIGIN) : float(BERSERK_COOLDOWN_HOST),"bot_use_skill",id)
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
	if(!g_can_berserk[id] || g_berserking[id])
		return PLUGIN_HANDLED
		
	Do_Berserk(id)

	return PLUGIN_HANDLED
}

public Do_Berserk(id)
{
	
	zb3_reset_user_speed(id)
		
	// Set Vars
	g_berserking[id] = 1
	g_can_berserk[id] = 0
	g_current_time[id] = 0
		
	// Decrease Health
	//zb3_set_user_health(id, get_user_health(id) - HEALTH_DECREASE)
		
	// Set Render Red
	zb3_set_user_rendering(id, kRenderFxGlowShell, BERSERK_COLOR_R, BERSERK_COLOR_G, BERSERK_COLOR_B, kRenderNormal, 0)
	
	// Set Fov
	set_fov(id, FASTRUN_FOV)
		
	// Set MaxSpeed & Gravity
	zb3_set_user_speed(id, BERSERK_SPEED)
	//set_pev(id, pev_maxspeed, BERSERK_GRAVITY)
	set_pev(id, pev_gravity, BERSERK_GRAVITY)	
	// Play Berserk Sound
	EmitSound(id, CHAN_VOICE, berserk_startsound)
		
	// Set Task
	set_task(2.0, "Berserk_HeartBeat", id+TASK_BERSERK_SOUND)
		
	static Float:SkillTime
	SkillTime = zb3_get_user_level(id) > 1 ? float(BERSERK_TIME_ORIGIN) : float(BERSERK_TIME_HOST)
		
	set_task(SkillTime, "Remove_Berserk", id+TASK_BERSERKING)
	
}

public Remove_Berserk(id)
{
	id -= TASK_BERSERKING

	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 
	if(!g_berserking[id])
		return	

	// Set Vars
	g_berserking[id] = 0
	g_can_berserk[id] = 0	
	
	// Reset Rendering
	zb3_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 0)
	
	// Reset FOV
	set_fov(id)
	
	// Reset Speed
	static Float:DefaultSpeed
	DefaultSpeed = zb3_get_user_level(id) > 1 ? zclass_speedorigin : zclass_speedhost
	
	zb3_set_user_speed(id, floatround(DefaultSpeed))
}

public Berserk_HeartBeat(id)
{
	id -= TASK_BERSERK_SOUND
	
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 
	if(!g_can_berserk[id] || g_berserking[id])
		return
		
	EmitSound(id, CHAN_VOICE, berserk_sound[random_num(0, sizeof(berserk_sound))])
	set_task(2.0, "Berserk_HeartBeat", id+TASK_BERSERK_SOUND)
}

public zb3_skill_show(id)
{
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 	
		
	if(g_current_time[id] < (zb3_get_user_level(id) > 1 ? (BERSERK_COOLDOWN_ORIGIN): (BERSERK_COOLDOWN_HOST )))
		g_current_time[id]++
	
	static percent
	static timewait
	
	timewait = zb3_get_user_level(id) > 1 ? (BERSERK_COOLDOWN_ORIGIN): (BERSERK_COOLDOWN_HOST )
	percent = floatround((float(g_current_time[id]) / float(timewait)) * 100.0)
	
	set_hudmessage(255, 255, 255, -1.0, 0.10, 0, 3.0, 3.0)
	ShowSyncHudMsg(id, g_synchud1, "[G] - %s (%i%%)", zclass_desc, percent)
	
	if(percent > 99 && !g_can_berserk[id]) 
		g_can_berserk[id] = 1
		
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
