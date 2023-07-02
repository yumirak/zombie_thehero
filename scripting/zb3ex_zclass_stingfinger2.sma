#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombie_thehero2>

#define PLUGIN "[ZB3] Zombie Class: Sting Finger"
#define VERSION "2.0"
#define AUTHOR "Dias"

new const LANG_FILE[] = "zombie_thehero2.txt"

// Zombie Configs
new const zclass_name[] = "Sting Finger"
new const zclass_desc[] = "Tentacle"
new const zclass_desc2[] = "High Jump"
new const zclass_sex = SEX_FEMALE
new const zclass_lockcost = 10000
new const zclass_hostmodel[] = "resident_zombi_host"
new const zclass_originmodel[] = "resident_zombi_origin"
new const zclass_clawsmodelhost[] = "v_knife_resident_zombi.mdl"
new const zclass_clawsmodelorigin[] = "v_knife_resident_zombi.mdl"
new const zombiegrenade_modelhost[] = "models/zombie_thehero/v_zgren_resident.mdl"
new const zombiegrenade_modelorigin[] = "models/zombie_thehero/v_zgren_resident.mdl"
new const Float:zclass_gravity = 0.85
new const Float:zclass_speedhost = 280.0
new const Float:zclass_speedorigin = 290.0
new const Float:zclass_knockback = 2.75
new const Float:zclass_painshock = 0.25
new const Float:zclass_dmgmulti = 1.2

new const DeathSound[2][] =
{
	"zombie_thehero/resident_death.wav",
	"zombie_thehero/resident_death.wav"
}
new const HurtSound[2][] = 
{
	"zombie_thehero/resident_hurt1.wav",
	"zombie_thehero/resident_hurt2.wav"	
}
new const HealSound[] = "zombie_thehero/zombi_heal_female.wav"
new const EvolSound[] = "zombie_thehero/zombi_evolution_female.wav"
new const Float:ClawsDistance1 = 1.1
new const Float:ClawsDistance2 = 1.2

new const TentacleSound[] = "zombie_thehero/resident_skill1.wav"
new const HeavyJumpSound[] = "zombie_thehero/resident_skill2.wav"

new g_zombie_classid
new g_Msg_Fov, g_synchud1, g_current_time[33], g_current_time2[33]
new g_can_tentacle[33], g_can_hj[33], g_hj_ing[33], g_temp_attack[33], m_iBlood[2]

#define LANG_OFFICIAL LANG_PLAYER

#define TASK_HEAVYJUMP 312543
#define TASK_HEAVYJUMP_START 423423

// Tentacle
#define TENTACLE_TIME 0.5
#define TENTACLE_ANIM 8
#define TENTACLE_PLAYERANIM 91

#define TENTACLE_COOLDOWN_ORIGIN 120
#define TENTACLE_COOLDOWN_HOST 240
#define TENTACLE_DISTANCE_ORIGIN 160
#define TENTACLE_DISTANCE_HOST 140

// Heavy Jump
#define HEAVYJUMP_TIME 1.0
#define HEAVYJUMP_STARTTIME 1.0
#define HEAVYJUMP_ANIM 9
#define HEAVYJUMP_PLAYERANIM 98
#define HEAVYJUMP_FOV 120

#define HEAVYJUMP_COOLDOWN_ORIGIN 100
#define HEAVYJUMP_COOLDOWN_HOST 200
#define HEAVYJUMP_TIME_ORIGIN 10
#define HEAVYJUMP_TIME_HOST 5
#define HEAVYJUMP_AMOUNT_ORIGIN 0.35
#define HEAVYJUMP_AMOUNT_HOST 0.5

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_dictionary(LANG_FILE)
	
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_TraceLine, "fw_TraceLine")
	register_forward(FM_TraceHull, "fw_TraceHull")	
	
	register_clcmd("drop", "cmd_drop")
	
	g_Msg_Fov = get_user_msgid("SetFOV")
	g_synchud1 = zb3_get_synchud_id(SYNCHUD_ZBHM_SKILL1)
	//g_synchud2 = zb3_get_synchud_id(SYNCHUD_ZBHM_SKILL2)
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
	engfunc(EngFunc_PrecacheSound, TentacleSound)
	engfunc(EngFunc_PrecacheSound, HeavyJumpSound)
	
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")	
}

public zb3_user_infected(id, infector)
{
	if(zb3_get_user_zombie_class(id) == g_zombie_classid)
	{
		reset_skill(id)
		
		g_can_tentacle[id] = 1
		g_can_hj[id] = 1
		g_hj_ing[id] = 0
		
		g_current_time[id] = zb3_get_user_level(id) > 1 ? TENTACLE_COOLDOWN_ORIGIN : TENTACLE_COOLDOWN_HOST
		g_current_time2[id] = zb3_get_user_level(id) > 1 ? HEAVYJUMP_COOLDOWN_ORIGIN : HEAVYJUMP_COOLDOWN_HOST
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
	g_can_tentacle[id] = 0
	g_can_hj[id] = 0
	g_hj_ing[id] = 0
	g_temp_attack[id] = 0
	
	g_current_time[id] = 0
	g_current_time2[id] = 0
	
	remove_task(id+TASK_HEAVYJUMP)
	remove_task(id+TASK_HEAVYJUMP_START)
	
	if(is_user_connected(id)) set_fov(id)
}

public zb3_user_spawned(id) 
{
	if(!zb3_get_user_zombie(id)) set_task(0.1, "reset_skill", id)
}

public zb3_user_dead(id) reset_skill(id)

public cmd_drop(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
	if(!zb3_get_user_zombie(id))
		return PLUGIN_CONTINUE
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return PLUGIN_CONTINUE
	if(get_user_weapon(id) != CSW_KNIFE)
		return PLUGIN_CONTINUE
	if(!g_can_tentacle[id])
		return PLUGIN_HANDLED

	Do_Tentacle(id)

	return PLUGIN_HANDLED
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED
	if(!zb3_get_user_zombie(id))
		return FMRES_IGNORED
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return FMRES_IGNORED
	if(get_user_weapon(id) != CSW_KNIFE)
		return FMRES_IGNORED
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if((CurButton & IN_RELOAD) && !(pev(id, pev_oldbuttons) & IN_RELOAD))
	{
		if(!g_can_hj[id] || g_hj_ing[id])
			return FMRES_IGNORED
			
		Do_HeavyJump(id)				
	}
		
	return FMRES_IGNORED
}

public Do_Tentacle(id)
{
	g_can_tentacle[id] = 0
	g_current_time[id] = 0
	
	set_weapons_timeidle(id, TENTACLE_TIME)
	set_player_nextattack(id, TENTACLE_TIME)
	
	do_fake_attack(id)
	//set_fov(id, BAT_FOV)
	
	set_weapon_anim(id, TENTACLE_ANIM)
	//set_entity_anim(id, TENTACLE_PLAYERANIM, 1.0)
	set_pev(id, pev_sequence, TENTACLE_PLAYERANIM)
	
	EmitSound(id, CHAN_ITEM, TentacleSound)
	Check_Tentacle(id)
}

public Check_Tentacle(id)
{
	#define MAX_POINT 4
	static Float:Max_Distance, Float:Point[MAX_POINT][3], Float:TB_Distance
	
	Max_Distance = zb3_get_user_level(id) > 1 ? float(TENTACLE_DISTANCE_ORIGIN) : float(TENTACLE_DISTANCE_HOST)
	TB_Distance = Max_Distance / float(MAX_POINT)
	
	static Float:VicOrigin[3], Float:MyOrigin[3]
	pev(id, pev_origin, MyOrigin)
	
	for(new i = 0; i < MAX_POINT; i++)
		get_position(id, TB_Distance * (i + 1), 0.0, 0.0, Point[i])
		
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue
		if(zb3_get_user_zombie(i))
			continue
		if(entity_range(id, i) > Max_Distance)
			continue
	
		pev(i, pev_origin, VicOrigin)
		if(is_wall_between_points(MyOrigin, VicOrigin, id))
			continue

		if(get_distance_f(VicOrigin, Point[0]) <= 35.0 
		|| get_distance_f(VicOrigin, Point[1]) <= 35.0
		|| get_distance_f(VicOrigin, Point[2]) <= 35.0
		|| get_distance_f(VicOrigin, Point[3]) <= 35.0)
		{
			VicOrigin[2] += 15.0
			//create_blood(VicOrigin)
			zb3_infect(i, id, 0, 0)
		}

	}		
}

public Do_HeavyJump(id)
{
	g_can_hj[id] = 0
	g_hj_ing[id] = 1
	g_current_time2[id] = 0
	
	set_weapons_timeidle(id, HEAVYJUMP_TIME)
	set_player_nextattack(id, HEAVYJUMP_TIME)
	
	do_fake_attack(id)
	set_weapon_anim(id, HEAVYJUMP_ANIM)
	set_pev(id, pev_sequence, HEAVYJUMP_PLAYERANIM)
	
	EmitSound(id, CHAN_ITEM, HeavyJumpSound)
	set_task(HEAVYJUMP_STARTTIME, "Start_HeavyJump", id+TASK_HEAVYJUMP_START)
}

public Start_HeavyJump(id)
{
	id -= TASK_HEAVYJUMP_START
	
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 	
	if(!g_hj_ing[id])
		return
		
	set_fov(id, HEAVYJUMP_FOV)
	set_pev(id, pev_gravity, zb3_get_user_level(id) > 1 ? HEAVYJUMP_AMOUNT_ORIGIN : HEAVYJUMP_AMOUNT_HOST)
	
	set_task(zb3_get_user_level(id) > 1 ? float(HEAVYJUMP_TIME_ORIGIN) : float(HEAVYJUMP_TIME_HOST), "Stop_HeavyJump", id+TASK_HEAVYJUMP)
}

public Stop_HeavyJump(id)
{
	id -= TASK_HEAVYJUMP
	
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 	
	if(!g_hj_ing[id])
		return
		
	set_fov(id)
	set_pev(id, pev_gravity, zclass_gravity)
}

public zb3_skill_show(id)
{
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 	
	
	if(g_current_time[id] < (zb3_get_user_level(id) > 1 ? float(TENTACLE_COOLDOWN_ORIGIN) : float(TENTACLE_COOLDOWN_HOST)) )
		g_current_time[id]++
	if(g_current_time2[id] < (zb3_get_user_level(id) > 1 ? float(HEAVYJUMP_COOLDOWN_ORIGIN) : float(HEAVYJUMP_COOLDOWN_HOST)) )
		g_current_time2[id]++
	
	static percent , percent2
	static timewait , timewait2
	
	// Tentacle Skill
	timewait = zb3_get_user_level(id) > 1 ? TENTACLE_COOLDOWN_ORIGIN : TENTACLE_COOLDOWN_HOST
	percent = floatround((float(g_current_time[id]) / float(timewait)) * 100.0)
	// HeavyJump Skill
	timewait2 = zb3_get_user_level(id) > 1 ? HEAVYJUMP_COOLDOWN_ORIGIN : HEAVYJUMP_COOLDOWN_HOST
	percent2 = floatround((float(g_current_time2[id]) / float(timewait2)) * 100.0)
	
	set_hudmessage(255, 255, 255, -1.0, 0.10, 0, 3.0, 3.0)
	ShowSyncHudMsg(id, g_synchud1, "[G] - %s (%i%%)^n[R] - %s (%i%%)", zclass_desc, percent, zclass_desc2, percent2)
	
	if(percent == 100 &&!g_can_tentacle[id])
		g_can_tentacle[id] = 1
	
	if(percent2 == 100 && !g_can_hj[id])
	{
		g_can_hj[id] = 1
		g_hj_ing[id] = 0
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

public do_fake_attack(id)
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
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
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

stock is_wall_between_points(Float:start[3], Float:end[3], ignore_ent)
{
	static ptr
	ptr = create_tr2()

	engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ignore_ent, ptr)
	
	static Float:EndPos[3]
	get_tr2(ptr, TR_vecEndPos, EndPos)

	return floatround(get_distance_f(end, EndPos))
} 

stock create_blood(const Float:origin[3])
{
	// Show some blood :)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(75)
	write_byte(5)
	message_end()
}

public bool:can_see_fm(entindex1, entindex2)
{
	if (!entindex1 || !entindex2)
		return false

	if (pev_valid(entindex1) && pev_valid(entindex1))
	{
		new flags = pev(entindex1, pev_flags)
		if (flags & EF_NODRAW || flags & FL_NOTARGET)
		{
			return false
		}

		new Float:lookerOrig[3]
		new Float:targetBaseOrig[3]
		new Float:targetOrig[3]
		new Float:temp[3]

		pev(entindex1, pev_origin, lookerOrig)
		pev(entindex1, pev_view_ofs, temp)
		lookerOrig[0] += temp[0]
		lookerOrig[1] += temp[1]
		lookerOrig[2] += temp[2]

		pev(entindex2, pev_origin, targetBaseOrig)
		pev(entindex2, pev_view_ofs, temp)
		targetOrig[0] = targetBaseOrig [0] + temp[0]
		targetOrig[1] = targetBaseOrig [1] + temp[1]
		targetOrig[2] = targetBaseOrig [2] + temp[2]

		engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the had of seen player
		if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater))
		{
			return false
		} 
		else 
		{
			new Float:flFraction
			get_tr2(0, TraceResult:TR_flFraction, flFraction)
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
			{
				return true
			}
			else
			{
				targetOrig[0] = targetBaseOrig [0]
				targetOrig[1] = targetBaseOrig [1]
				targetOrig[2] = targetBaseOrig [2]
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the body of seen player
				get_tr2(0, TraceResult:TR_flFraction, flFraction)
				if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
				{
					return true
				}
				else
				{
					targetOrig[0] = targetBaseOrig [0]
					targetOrig[1] = targetBaseOrig [1]
					targetOrig[2] = targetBaseOrig [2] - 17.0
					engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the legs of seen player
					get_tr2(0, TraceResult:TR_flFraction, flFraction)
					if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
					{
						return true
					}
				}
			}
		}
	}
	return false
}
