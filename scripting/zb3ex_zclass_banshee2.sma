#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombie_thehero2>

#define PLUGIN "[ZB3] Zombie Class: Banshee"
#define VERSION "2.0"
#define AUTHOR "Dias"

new const LANG_FILE[] = "zombie_thehero2.txt"

// Zombie Configs
new const zclass_name[] = "Banshee"
new const zclass_desc[] = "Summon Bats"
new const zclass_sex = SEX_FEMALE
new const zclass_lockcost = 5000
new const zclass_hostmodel[] = "witch_zombi_host"
new const zclass_originmodel[] = "witch_zombi_origin"
new const zclass_clawsmodelhost[] = "v_knife_witch2_zombi_host.mdl"
new const zclass_clawsmodelorigin[] = "v_knife_witch2_zombi_origin.mdl"
new const zombiegrenade_modelhost[] = "models/zombie_thehero/v_zgren_witch2_zombi_host.mdl"
new const zombiegrenade_modelorigin[] = "models/zombie_thehero/v_zgren_witch2_zombi_origin.mdl"
new const Float:zclass_gravity = 0.8
new const Float:zclass_speedhost = 280.0
new const Float:zclass_speedorigin = 280.0
new const Float:zclass_knockback = 2.0
new const Float:zclass_painshock = 0.2
new const Float:zclass_dmgmulti = 1.1

new const DeathSound[2][] =
{
	"zombie_thehero/zombi_banshee_death.wav",
	"zombie_thehero/zombi_banshee_death.wav"
}
new const HurtSound[2][] = 
{
	"zombie_thehero/zombi_banshee_hurt.wav",
	"zombie_thehero/zombi_banshee_hurt.wav"	
}
new const HealSound[] = "zombie_thehero/zombi_heal_female.wav"
new const EvolSound[] = "zombie_thehero/zombi_evolution_female.wav"
new const Float:ClawsDistance1 = 1.1
new const Float:ClawsDistance2 = 1.2

new const BatModel[] = "models/zombie_thehero/bat_witch.mdl"
new const BatFireSound[] = "zombie_thehero/zombi_banshee_laugh.wav"
new const BatFlySound[] = "zombie_thehero/zombi_banshee_pulling_fire.wav"
new const BatFailSound[] = "zombie_thehero/zombi_banshee_pulling_fail.wav"
new const Catch_Player_Male[] = "zombie_thehero/zombi_trapped.wav"
new const Catch_Player_Female[] = "zombie_thehero/zombi_trapped_female.wav"
new const BatExpSpr[] = "sprites/zombie_thehero/ef_bat.spr"

new g_zombie_classid
new g_Msg_Fov, g_synchud1, g_Msg_Shake, g_BatExpSpr_Id, g_current_time[33]
new g_can_skill[33], g_skilling[33], g_catcher[33], g_temp_attack[33]

const pev_catched = pev_iuser1
const pev_catchid = pev_iuser2
const pev_maxdistance = pev_iuser3
const pev_catchedspeed = pev_iuser4
const pev_timechange = pev_fuser1
const pev_livetime = pev_fuser2

#define LANG_OFFICIAL LANG_PLAYER

#define BAT_CLASSNAME "bat"
#define BAT_FOV 100
#define BAT_ANIM 2
#define BAT_PLAYERANIM 151
#define BAT_PLAYERANIM_HOLD 152

#define BAT_SPEED_HOST 550
#define BAT_SPEED_ORIGIN 750
#define BAT_CATCH_SPEED_HOST 150
#define BAT_CATCH_SPEED_ORIGIN 300
#define BAT_MAX_DISTANCE_HOST 750
#define BAT_MAX_DISTANCE_ORIGIN 1500
#define BAT_TIMELIVE_HOST 7
#define BAT_TIMELIVE_ORIGIN 15
#define BAT_COOLDOWN_HOST 25
#define BAT_COOLDOWN_ORIGIN 20

#define TASK_COOLDOWN 423432
#define TASK_SKILLING 312312
#define TASK_CATCHING 423423
#define TASK_BATFLYING 23423

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_dictionary(LANG_FILE)
	
	//register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_clcmd("drop", "cmd_drop")
	
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_TraceLine, "fw_TraceLine")
	register_forward(FM_TraceHull, "fw_TraceHull")		
	
	register_touch(BAT_CLASSNAME, "*", "fw_Bat_Touch")
	register_think(BAT_CLASSNAME, "fw_Bat_Think")	
	
	g_Msg_Fov = get_user_msgid("SetFOV")
	g_Msg_Shake = get_user_msgid("ScreenShake")
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
	engfunc(EngFunc_PrecacheModel, BatModel)
	engfunc(EngFunc_PrecacheSound, BatFireSound)
	engfunc(EngFunc_PrecacheSound, BatFailSound)
	engfunc(EngFunc_PrecacheSound, BatFlySound)
	engfunc(EngFunc_PrecacheSound, Catch_Player_Male)
	engfunc(EngFunc_PrecacheSound, Catch_Player_Female)
	
	g_BatExpSpr_Id = engfunc(EngFunc_PrecacheModel, BatExpSpr)
}

public zb3_user_infected(id, infector)
{
	if(zb3_get_user_zombie_class(id) == g_zombie_classid)
	{
		if(is_user_bot(id))
			bot_use_skill(id)
		reset_skill(id)
		
		g_can_skill[id] = 1
		g_skilling[id] = 0
		
		g_current_time[id] = 100
	}
}

public zb3_user_change_class(id, oldclass, newclass)
{
	if(oldclass == g_zombie_classid && oldclass != newclass)
	{
		reset_skill(id)
	}
}

public reset_skill(id)
{
	g_can_skill[id] = 0
	g_skilling[id] = 0
	g_catcher[id] = 0
	g_temp_attack[id] = 0
	
	remove_task(id+TASK_SKILLING)
	remove_task(id+TASK_COOLDOWN)
	remove_task(id+TASK_CATCHING)
	remove_task(id+TASK_BATFLYING)
	//remove_entity_name(BAT_CLASSNAME)

	//if(is_user_connected(id)) set_fov(id)
}

public zb3_user_spawned(id) 
{
	if(!zb3_get_user_zombie(id)) set_task(0.1, "reset_skill", id)
}

public zb3_user_dead(id) reset_skill(id)

/*
public Event_NewRound()
{
	remove_entity_name(BAT_CLASSNAME)
}
*/
public bot_use_skill(id)
{
	if(!is_user_alive(id) || !zb3_get_user_zombie(id) || !is_user_bot(id))
		return PLUGIN_CONTINUE
		
	cmd_drop(id)
	set_task(zb3_get_user_level(id) > 1 ? float(BAT_COOLDOWN_ORIGIN) : float(BAT_COOLDOWN_HOST),"bot_use_skill",id)
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
	if(get_user_weapon(id) != CSW_KNIFE)
		return PLUGIN_HANDLED
	if(!g_can_skill[id] || g_skilling[id])
		return PLUGIN_HANDLED
	if(pev(id, pev_flags) & FL_DUCKING)
	{
		client_print(id, print_chat, "%L", LANG_OFFICIAL, "ZOMBIE_BANSHEE_NODUCK")
		return PLUGIN_HANDLED
	}	
	
	Do_Skill(id)

	return PLUGIN_HANDLED
}

public Do_Skill(id)
{
	g_can_skill[id] = 0
	g_skilling[id] = 1
	g_current_time[id] = 0
	
	zb3_set_user_speed(id, 1)
	
	set_weapons_timeidle(id, 99999.0)
	set_player_nextattack(id, 99999.0)
	
	do_fake_attack(id)
	//set_fov(id, BAT_FOV)
	
	set_weapon_anim(id, BAT_ANIM)
	set_entity_anim(id, BAT_PLAYERANIM, 0.35)
	
	EmitSound(id, CHAN_ITEM, BatFireSound)
	set_task(1.0, "Skilling", id+TASK_SKILLING)
}

public Skilling(id)
{
	id -= TASK_SKILLING
	
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 
		
	g_can_skill[id] = 0
	g_skilling[id] = 0
	
	CreateBat(id)
}

public CreateBat(id)
{
	new bat
	bat = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	if(!pev_valid(bat))
		return
		
	static Float:BatOrigin[3], Float:Angles[3], Float:Velocity[3]
	
	get_position(id, 50.0, 0.0, 0.0, BatOrigin)
	pev(id, pev_angles, Angles)
	
	set_pev(bat, pev_origin, BatOrigin)
	set_pev(bat, pev_angles, Angles)
	
	engfunc(EngFunc_SetModel, bat, BatModel)
	engfunc(EngFunc_SetSize, bat, {-10.0,-7.5,-4.0}, {10.0,7.5,4.0})
	
	set_pev(bat, pev_classname, BAT_CLASSNAME)
	set_pev(bat, pev_solid, 2)
	set_pev(bat, pev_movetype, MOVETYPE_FLY)
	set_pev(bat, pev_owner, id)
	set_pev(bat, pev_fuser1, (zb3_get_user_level(id) > 1 ? BAT_TIMELIVE_ORIGIN : BAT_TIMELIVE_HOST))
	
	velocity_by_aim(id, zb3_get_user_level(id) > 1 ? BAT_SPEED_ORIGIN : BAT_SPEED_HOST, Velocity)
	set_pev(bat, pev_velocity, Velocity)
	
	set_entity_anim(bat, 0, 1.0)
	set_pev(bat, pev_nextthink, get_gametime() + 0.1)
	
	// Set Secret Data
	set_pev(bat, pev_catched, 0)
	set_pev(bat, pev_catchid, 0)
	set_pev(bat, pev_maxdistance, zb3_get_user_level(id) > 1 ? BAT_MAX_DISTANCE_ORIGIN : BAT_MAX_DISTANCE_HOST)
	set_pev(bat, pev_catchedspeed, zb3_get_user_level(id) > 1 ? BAT_CATCH_SPEED_ORIGIN : BAT_CATCH_SPEED_HOST)
	
	set_pev(bat, pev_timechange, 0.0)
	set_pev(bat, pev_livetime, zb3_get_user_level(id) > 1 ? float(BAT_TIMELIVE_ORIGIN) : float(BAT_TIMELIVE_HOST))

	EmitSound(bat, CHAN_BODY, BatFlySound)
}

public fw_Bat_Think(ent)
{
	if(!pev_valid(ent))
		return

	static Owner
	Owner = pev(ent, pev_owner)
	
	if(!is_user_alive(Owner) || !zb3_get_user_zombie(Owner))
	{
		Bat_Explosion(ent)
		return
	}		
		
	static catched, catchid
	
	catched = pev(ent, pev_catched)
	catchid = pev(ent, pev_catchid)
	
	if(get_gametime() - 1.0 > pev(ent, pev_timechange))
	{
		set_pev(ent, pev_livetime, pev(ent, pev_livetime) - 1.0)
		set_pev(ent, pev_timechange, get_gametime())
	}
	
	if(pev(ent, pev_livetime) <= 0.0)
	{
		Bat_Explosion(ent)
		Reset_Owner(Owner)
				
		return
	}
	
	if(catched)
	{
		if(is_user_alive(catchid))
		{
			if(entity_range(catchid, Owner) >= 70)
				hook_ent(catchid, Owner, float(pev(ent, pev_catchedspeed)))
			else 
			{
				Bat_Explosion(ent)
				Reset_Owner(Owner)
				
				return
			}
		} else {
			Bat_Explosion(ent)
			Reset_Owner(Owner)
			
			return
		}
	} else {
		if(entity_range(ent, Owner) > pev(ent, pev_maxdistance))
		{
			Bat_Explosion(ent)
			Reset_Owner(Owner)
			
			return
		}
	}
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public fw_Bat_Touch(bat, id)
{
	if(!pev_valid(bat))
		return
	
	static Owner
	Owner = pev(bat, pev_owner)
	
	if(!is_user_alive(Owner) || !zb3_get_user_zombie(Owner) )
	{
		Bat_Explosion(bat)
		return
	}
	
	if(is_user_alive(id))
	{
		Catch_Player(bat, id, Owner)
	} else {
		Bat_Explosion(bat)
		Reset_Owner(Owner)
	}
}

public Catch_Player(ent, id, owner)
{
	if(!pev_valid(ent) || !is_user_alive(id) )
		return
	
	set_pev(ent, pev_catched, 1)
	set_pev(ent, pev_catchid, id)
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_aiment, id)
	set_pev(ent, pev_movetype, MOVETYPE_FOLLOW)
	
	g_catcher[id] = owner
	
	if(!zb3_get_user_zombie(id))
	{
		if(!zb3_get_user_hero(id))
		{
			ScreenShake(id)
			EmitSound(id, CHAN_VOICE, zb3_get_user_sex(id) == SEX_MALE ? Catch_Player_Male : Catch_Player_Female)
		} else {
			Bat_Explosion(ent)
			Reset_Owner(owner)
			
			return
		}
	}
}

public Reset_Owner(id)
{
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 
		
	g_can_skill[id] = 0
	g_skilling[id] = 0

	//set_fov(id)
	zb3_set_user_speed(id, zb3_get_user_level(id) > 1 ? floatround(zclass_speedorigin) : floatround(zclass_speedhost))
	
	set_weapons_timeidle(id, 1.0)
	set_player_nextattack(id, 1.0)
	set_weapon_anim(id, 3)
}

public Bat_Explosion(ent)
{
	if(!pev_valid(ent))
		return	
		
	static Float:Origin[3]
	pev(ent, pev_origin, Origin)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_BatExpSpr_Id)
	write_byte(40)
	write_byte(30)
	write_byte(0)
	message_end()		
	
	EmitSound(ent, CHAN_BODY, BatFailSound)
	engfunc(EngFunc_RemoveEntity, ent)	
}

public Remove_Skill(id)
{
	id -= TASK_COOLDOWN

	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 
}

public zb3_skill_show(id)
{
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 	
		
	if(g_current_time[id] < 100)
		g_current_time[id]++
	
	static Float:percent, percent2
	static Float:timewait
	
	timewait = zb3_get_user_level(id) > 1 ? float(BAT_COOLDOWN_ORIGIN) : float(BAT_COOLDOWN_HOST)

	percent = (float(g_current_time[id]) / timewait) * 100.0
	percent2 = floatround(percent)
	
	if(percent2 > 0 && percent2 < 50)
	{
		set_hudmessage(255, 0, 0, -1.0, 0.10, 0, 3.0, 3.0)
		ShowSyncHudMsg(id, g_synchud1, "[G] - %s (%i%%)", zclass_desc, percent2)
	} else if(percent2 >= 50 && percent < 100) {
		set_hudmessage(255, 255, 0, -1.0, 0.10, 0, 3.0, 3.0)
		ShowSyncHudMsg(id, g_synchud1, "[G] - %s (%i%%)", zclass_desc, percent2)
	} else if(percent2 >= 100) {
		set_hudmessage(255, 255, 255, -1.0, 0.10, 0, 3.0, 3.0)
		ShowSyncHudMsg(id, g_synchud1, "[G] - %s (Ready)", zclass_desc)
		
		if(!g_can_skill[id])
		{
			g_can_skill[id] = 1
			g_skilling[id] = 0
		}
	}	
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!is_user_connected(id))
		return FMRES_IGNORED
	if(!zb3_get_user_zombie(id))
		return FMRES_IGNORED
	if(!g_temp_attack[id])
		return FMRES_IGNORED
		
	if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
	{
		if(sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
		{	
			return FMRES_SUPERCEDE
		}
		if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't') // hit
		{
			if(sample[17] == 'w')
			{
				return FMRES_SUPERCEDE
			} else {
				return FMRES_SUPERCEDE
			}
		}
		if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a') // stab
		{
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED
}

public fw_TraceLine(Float:vector_start[3], Float:vector_end[3], ignored_monster, id, handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED
	if(!zb3_get_user_zombie(id))
		return FMRES_IGNORED
	if(!g_temp_attack[id])
		return FMRES_IGNORED
	
	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)

	xs_vec_mul_scalar(v_forward, 0.0, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceLine, vecStart, vecEnd, ignored_monster, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_TraceHull(Float:vector_start[3], Float:vector_end[3], ignored_monster, hull, id, handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED
	if(!zb3_get_user_zombie(id))
		return FMRES_IGNORED
	if(!g_temp_attack[id])
		return FMRES_IGNORED
	
	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)

	xs_vec_mul_scalar(v_forward, 0.0, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceHull, vecStart, vecEnd, ignored_monster, hull, id, handle)
	
	return FMRES_SUPERCEDE
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
	if(!pev_valid(id))
		return
		
	emit_sound(id, chan, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

stock set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return
		
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(0)
	message_end()	
}

stock set_weapons_timeidle(id, Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	const m_flTimeWeaponIdle = 48
	
	new entwpn = fm_get_user_weapon_entity(id, CSW_KNIFE)
	if (pev_valid(entwpn)) set_pdata_float(entwpn, m_flTimeWeaponIdle, TimeIdle + 3.0, 4)
}

stock set_player_nextattack(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	const m_flNextAttack = 83
	set_pdata_float(id, m_flNextAttack, nexttime, 5)
}

stock do_fake_attack(id)
{
	if(!is_user_alive(id))
		return
	
	static ent
	ent = fm_find_ent_by_owner(-1, "weapon_knife", id)
	
	if(pev_valid(ent)) 
	{
		g_temp_attack[id] = 1
		ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)	
		g_temp_attack[id] = 0
	}	
}

stock set_entity_anim(ent, anim, Float:framerate)
{
	if(!pev_valid(ent))
		return
		
	set_pev(ent, pev_animtime, get_gametime())
	set_pev(ent, pev_framerate, framerate)
	set_pev(ent, pev_sequence, anim)
}

stock get_position(ent, Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(ent, pev_origin, vOrigin)
	pev(ent, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	vAngle[0] = 0.0
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

public ScreenShake(id)
{
	if(!is_user_connected(id))
		return
		
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_Shake, _, id)
	write_short(255<<14)
	write_short(10<<14)
	write_short(255<<14)
	message_end()
}

stock hook_ent(victim, attacker, Float:speed)
{
	if(!pev_valid(victim) || !pev_valid(attacker))
		return
	
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3], Float:VicOrigin[3]
	
	pev(victim, pev_origin, EntOrigin)
	pev(attacker, pev_origin, VicOrigin)
	
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	
	if (distance_f > 60.0)
	{
		new Float:fl_Time = distance_f / speed
		
		fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
		fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time
	} else {
		fl_Velocity[0] = 0.0
		fl_Velocity[1] = 0.0
		fl_Velocity[2] = 0.0
	}

	entity_set_vector(victim, EV_VEC_velocity, fl_Velocity)
}
