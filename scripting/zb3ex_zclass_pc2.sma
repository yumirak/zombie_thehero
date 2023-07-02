#include <amxmodx>
#include <fakemeta>
#include <zombie_thehero2>

#define PLUGIN "NST Zombie Class Pc"
#define VERSION "1.0"
#define AUTHOR "NST"

new const LANG_FILE[] = "zombie_thehero2.txt"

// Zombie Configs
new const zclass_name[] = "Psycho"
new const zclass_desc[] = "Smoke"
new const zclass_sex = SEX_MALE
new const zclass_lockcost = 0
new const zclass_hostmodel[] = "pc_zombi_host"
new const zclass_originmodel[] = "pc_zombi_origin"
new const zclass_clawsmodelhost[] = "v_knife_pc_zombi.mdl"
new const zclass_clawsmodelorigin[] = "v_knife_pc_zombi.mdl"
new const zombiegrenade_modelhost[] = "models/zombie_thehero/v_zgren_pc_zombi.mdl"
new const zombiegrenade_modelorigin[] = "models/zombie_thehero/v_zgren_pc_zombi.mdl"
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

new g_zombie_classid, g_can_smoke[33],  g_current_time[33]
new const sound_smoke[] = "zombie_thehero/zombi_smoke.wav"
new const sprites_smoke[] = "sprites/zombie_thehero/zb_smoke.spr"

// Main Vars
new id_smoke1
new g_smoke[33], g_smoke_wait[33], Float:g_smoke_origin[33][3]
// Task offsets
enum (+= 100)
{
	TASK_SMOKE = 2000,
	TASK_SMOKE_EXP,
	TASK_WAIT_SMOKE,
	TASK_BOT_USE_SKILL
}
// IDs inside tasks
#define ID_SMOKE (taskid - TASK_SMOKE)
#define ID_SMOKE_EXP (taskid - TASK_SMOKE_EXP)
#define ID_WAIT_SMOKE (taskid - TASK_WAIT_SMOKE)
#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)


#define LANG_OFFICIAL LANG_PLAYER
///
#define SMOKE_TIME_HOST 5
#define SMOKE_TIME_ORIGIN 10
#define SMOKE_COOLDOWN_HOST (10 + SMOKE_TIME_HOST)
#define SMOKE_COOLDOWN_ORIGIN (5 + SMOKE_TIME_ORIGIN)
#define SMOKE_SIZE 3
#define SMOKE_TIMEWAIT 10

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
	//engfunc(EngFunc_PrecacheSound, berserk_startsound)
	id_smoke1 = precache_model(sprites_smoke)
	
	engfunc(EngFunc_PrecacheSound, sound_smoke)
}

public zb3_user_infected(id, infector)
{
	if(zb3_get_user_zombie_class(id) == g_zombie_classid)
	{
		reset_skill(id)/*
		if (is_user_bot(id))
		{
			if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)
			set_task(float(random_num(5,15)), "bot_use_skill", id+TASK_BOT_USE_SKILL)
		}*/
		
		g_can_smoke[id] = 1
		g_current_time[id] = zb3_get_user_level(id) > 1 ? (SMOKE_COOLDOWN_ORIGIN) : (SMOKE_COOLDOWN_HOST)
	}
}

public reset_skill(id)
{
	g_can_smoke[id] = 0
	g_current_time[id] = 0
	
	
	if (task_exists(id+TASK_SMOKE)) remove_task(id+TASK_SMOKE)
	if (task_exists(id+TASK_WAIT_SMOKE)) remove_task(id+TASK_WAIT_SMOKE)
	if (task_exists(id+TASK_SMOKE_EXP)) remove_task(id+TASK_SMOKE_EXP)
	if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)

	g_smoke[id] = 0
	g_smoke_wait[id] = 0
}

public zb3_user_spawned(id) 
{
	if(!zb3_get_user_zombie(id)) set_task(0.1, "reset_skill", id)
}

public zb3_user_dead(id) reset_skill(id)

// bot use skill
public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	if (!is_user_bot(id)) return;

	cmd_drop(id)
	if (task_exists(taskid)) remove_task(taskid)
	set_task(float(random_num(20,35)), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}
public cmd_drop(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
	if(!zb3_get_user_zombie(id))
		return PLUGIN_CONTINUE
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return PLUGIN_CONTINUE
	if(!g_can_smoke[id])
		return PLUGIN_HANDLED
		
	Do_Berserk(id)

	return PLUGIN_HANDLED
}

public Do_Berserk(id)
{
	g_can_smoke[id] = 0
	g_current_time[id] = 0
	g_smoke[id] = 1
		
	// task smoke exp
	pev(id,pev_origin,g_smoke_origin[id])
	if (task_exists(id+TASK_SMOKE_EXP)) remove_task(id+TASK_SMOKE_EXP)
	set_task(0.1, "SmokeExplode", id+TASK_SMOKE_EXP)
		
	// task remove smoke
	new Float:time_s
	time_s = zb3_get_user_level(id) > 1 ? float(SMOKE_TIME_ORIGIN) : float(SMOKE_TIME_HOST)

	if (task_exists(id+TASK_SMOKE)) remove_task(id+TASK_SMOKE)
	set_task(time_s, "RemoveSmoke", id+TASK_SMOKE)
		
	// play sound
	//PlaySound(id, sound_smoke)
	EmitSound(id, CHAN_VOICE, sound_smoke)
		
		
	//client_print(id, print_chat, "[%i]", fnFloatToNum(time_invi))
		
	return PLUGIN_HANDLED
	
}

public SmokeExplode(taskid)
{
	new id = ID_SMOKE_EXP
	
	// remove smoke
	if (!g_smoke[id])
	{
		if (task_exists(id+TASK_SMOKE_EXP)) remove_task(id+TASK_SMOKE_EXP)
		return;
	}
	
	new Float:origin[3]
	origin[0] = g_smoke_origin[id][0]// + random_num(-75,75)
	origin[1] = g_smoke_origin[id][1]// + random_num(-75,75)
	origin[2] = g_smoke_origin[id][2]// + random_num(0,65)
	
	new flags = pev(id, pev_flags)
	if (!((flags & FL_DUCKING) && (flags & FL_ONGROUND)))
		origin[2] -= 36.0
	
	Create_Smoke_Group(origin)
	
	// task smoke exp
	if (task_exists(id+TASK_SMOKE_EXP)) remove_task(id+TASK_SMOKE_EXP)
	set_task(1.0, "SmokeExplode", id+TASK_SMOKE_EXP)
	
	return;
}
public RemoveSmoke(taskid)
{
	new id = ID_SMOKE
	
	// remove smoke
	g_smoke[id] = 0
	if (task_exists(taskid)) remove_task(taskid)

	// set time wait
	g_smoke_wait[id] = 1
	if (task_exists(id+TASK_WAIT_SMOKE)) remove_task(id+TASK_WAIT_SMOKE)
	set_task(float(SMOKE_TIMEWAIT), "RemoveWaitSmoke", id+TASK_WAIT_SMOKE)
}
public RemoveWaitSmoke(taskid)
{
	new id = ID_WAIT_SMOKE
	g_smoke_wait[id] = 0
	if (task_exists(taskid)) remove_task(taskid)
}
public zb3_skill_show(id)
{
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 	
		
	if(g_current_time[id] < (zb3_get_user_level(id) > 1 ? (SMOKE_COOLDOWN_ORIGIN): (SMOKE_COOLDOWN_HOST )))
		g_current_time[id]++
	
	static percent
	static timewait
	
	timewait = zb3_get_user_level(id) > 1 ? (SMOKE_COOLDOWN_ORIGIN): (SMOKE_COOLDOWN_HOST )
	percent = floatround((float(g_current_time[id]) / float(timewait)) * 100.0)
	
	set_hudmessage(255, 255, 255, -1.0, 0.10, 0, 3.0, 3.0)
	ShowSyncHudMsg(id, g_synchud1, "[G] - %s (%i%%)", zclass_desc, percent)
	
	if(percent > 99 && !g_can_smoke[id]) 
		g_can_smoke[id] = 1
		
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
Create_Smoke_Group(Float:position[3])
{
	new Float:origin[12][3]
	get_spherical_coord(position, 40.0, 0.0, 0.0, origin[0])
	get_spherical_coord(position, 40.0, 90.0, 0.0, origin[1])
	get_spherical_coord(position, 40.0, 180.0, 0.0, origin[2])
	get_spherical_coord(position, 40.0, 270.0, 0.0, origin[3])
	get_spherical_coord(position, 100.0, 0.0, 0.0, origin[4])
	get_spherical_coord(position, 100.0, 45.0, 0.0, origin[5])
	get_spherical_coord(position, 100.0, 90.0, 0.0, origin[6])
	get_spherical_coord(position, 100.0, 135.0, 0.0, origin[7])
	get_spherical_coord(position, 100.0, 180.0, 0.0, origin[8])
	get_spherical_coord(position, 100.0, 225.0, 0.0, origin[9])
	get_spherical_coord(position, 100.0, 270.0, 0.0, origin[10])
	get_spherical_coord(position, 100.0, 315.0, 0.0, origin[11])
	
	for (new i = 0; i < SMOKE_SIZE; i++)
	{
			create_Smoke(origin[i], id_smoke1, 100, 0)
	}
}
create_Smoke(const Float:position[3], sprite_index, life, framerate)
{
	// Alphablend sprite, move vertically 30 pps
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SMOKE) // TE_SMOKE (5)
	engfunc(EngFunc_WriteCoord, position[0]) // position.x
	engfunc(EngFunc_WriteCoord, position[1]) // position.y
	engfunc(EngFunc_WriteCoord, position[2]) // position.z
	write_short(sprite_index) // sprite index
	write_byte(life) // scale in 0.1's
	write_byte(framerate) // framerate
	message_end()
}
get_spherical_coord(const Float:ent_origin[3], Float:redius, Float:level_angle, Float:vertical_angle, Float:origin[3])
{
	new Float:length
	length  = redius * floatcos(vertical_angle, degrees)
	origin[0] = ent_origin[0] + length * floatcos(level_angle, degrees)
	origin[1] = ent_origin[1] + length * floatsin(level_angle, degrees)
	origin[2] = ent_origin[2] + redius * floatsin(vertical_angle, degrees)
}
