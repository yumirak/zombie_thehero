#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombie_thehero2>
#include <fun>

#define PLUGIN "[Zombie: The Hero 2] Melee Weapon: Hammer"
#define VERSION "2.0"
#define AUTHOR "Dias"

#define HAMMER_DRAWTIME_SLASH 1.0
#define HAMMER_DRAWTIME_STAB 0.5
#define HAMMER_CHANGE_TIME 2.0
#define HAMMER_RADIUS_SLASH 120.0
#define HAMMER_RADIUS_STAB 110.0
#define HAMMER_ATTACKTIME_SLASH 1.0
#define HAMMER_ATTACKTIME_STAB 0.1
#define HAMMER_DAMAGE_SLASH 1000
#define HAMMER_DAMAGE_STAB 500
#define HAMMER_WEIGHT 100
#define HAMMER_KNOCKPOWER 1000

new const v_model[] = "models/zombie_thehero/wpn/melee/v_hammer.mdl"
new const p_model[] = "models/zombie_thehero/wpn/melee/p_hammer.mdl"

new const hammer_sound[4][] = 
{
	"weapons/hammer_draw.wav",
	"weapons/hammer_hit_slash.wav",
	"weapons/hammer_hit_stab.wav",
	"weapons/hammer_miss.wav"
}

enum
{
	HAMMER_MODE_SLASH = 1,
	HAMMER_MODE_STAB
}

enum
{
	KNIFE_ANIM_IDLE = 0,
	KNIFE_ANIM_SLASH1,
	KNIFE_ANIM_SLASH2,
	KNIFE_ANIM_DRAW,
	KNIFE_ANIM_STAB_HIT,
	KNIFE_ANIM_STAB_MISS,
	KNIFE_ANIM_MIDSLASH1,
	KNIFE_ANIM_MIDSLASH2
}

enum
{
	HAMMER_ANIM_IDLESLASH = 0,
	HAMMER_ANIM_SLASH,
	HAMMER_ANIM_DRAWSLASH,
	HAMMER_ANIM_MOVETO_STAB,
	
	HAMMER_ANIM_IDLESTAB,
	HAMMER_ANIM_STAB,
	HAMMER_ANIM_DRAWSTAB,
	HAMMER_ANIM_MOVETO_SLASH
}

const m_szAnimExtention = 492

#define TASK_CHANGING 42342
#define TASK_ATTACKING 423423

new g_hammer, g_old_weapon[33]
new g_had_hammer[33], g_hammer_mode[33], g_temp_attack[33], g_changing_mode[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_TraceLine, "fw_TraceLine")
	register_forward(FM_TraceHull, "fw_TraceHull")	
	
	RegisterHam(Ham_CS_Weapon_SendWeaponAnim, "weapon_knife", "fw_Knife_SendAnim", 1)	
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack", 1)
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, v_model)
	engfunc(EngFunc_PrecacheModel, p_model)
	
	for(new i = 0; i < sizeof(hammer_sound); i++)
		engfunc(EngFunc_PrecacheSound, hammer_sound[i])	
		
	g_hammer = zb3_register_weapon("hammer")
}

public zb3_weapon_selected_post(id, wpnid)
{
	if(wpnid == g_hammer) get_hammer(id)
}

public zb3_user_spawned(id) remove_hammer(id)
public zb3_user_dead(id) remove_hammer(id)
public zb3_user_infected(id) remove_hammer(id)

public get_hammer(id)
{
	g_had_hammer[id] = 1
	g_hammer_mode[id] = HAMMER_MODE_SLASH
	g_temp_attack[id] = 0
	g_changing_mode[id] = 0

	if(get_user_weapon(id) == CSW_KNIFE) 
	{
		Event_CurWeapon(id)
		set_weapon_anim(id, HAMMER_ANIM_DRAWSLASH)
	}		
}

public remove_hammer(id)
{
	g_had_hammer[id] = 0
	g_hammer_mode[id] = 0
	g_temp_attack[id] = 0
	g_changing_mode[id] = 0
	
	remove_task(id+TASK_CHANGING)
	
	if(is_user_alive(id)) zb3_reset_user_speed(id)
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return 1
	
	if(g_old_weapon[id] == CSW_KNIFE && get_user_weapon(id) != CSW_KNIFE && g_had_hammer[id])
		zb3_reset_user_speed(id)
	
	g_old_weapon[id] = get_user_weapon(id)
	
	if(get_user_weapon(id) != CSW_KNIFE)
		return 1
	if(!g_had_hammer[id])
		return 1
		
	set_pev(id, pev_viewmodel2, v_model)
	set_pev(id, pev_weaponmodel2, p_model)
		
	return 0
}

public fw_TraceAttack(victim, attacker, Float:Damage, Float:direction[3], tracehandle, damagebits)
{
	if(!is_user_alive(victim) || !is_user_alive(attacker))
		return HAM_IGNORED
	if(cs_get_user_team(victim) == cs_get_user_team(attacker))
		return HAM_IGNORED	
	if(get_user_weapon(attacker) != CSW_KNIFE || !g_had_hammer[attacker])
		return HAM_IGNORED
	if(g_hammer_mode[attacker] != HAMMER_MODE_STAB)
		return HAM_IGNORED
		
	static Float:Origin[3]
	pev(attacker, pev_origin, Origin)
	
	hook_ent2(victim, Origin, float(HAMMER_KNOCKPOWER), 2)
		
	return HAM_IGNORED
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!is_user_connected(id))
		return FMRES_IGNORED
	if(get_user_weapon(id) != CSW_KNIFE || !g_had_hammer[id])
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

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id)) 
		return
	if(get_user_weapon(id) != CSW_KNIFE)
		return
	if(!g_had_hammer[id])
		return
	
	static ent
	ent = find_ent_by_owner(-1, "weapon_knife", id)
	
	if(!pev_valid(ent))
		return
	if(get_pdata_float(ent, 46, 4) > 0.0 || get_pdata_float(ent, 47, 4) > 0.0) 
		return
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if(CurButton & IN_ATTACK)
	{
		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK)
		
		if(g_hammer_mode[id] == HAMMER_MODE_SLASH)
		{
			g_temp_attack[id] = 1
			ExecuteHamB(Ham_Weapon_PrimaryAttack, get_pdata_cbase(id, 373, 5))
			g_temp_attack[id] = 0
			
			set_weapons_timeidle(id, HAMMER_ATTACKTIME_SLASH + 1.0)
			set_player_nextattack(id, HAMMER_ATTACKTIME_SLASH + 1.0)
			
			set_weapon_anim(id, HAMMER_ANIM_SLASH)
			set_task(HAMMER_ATTACKTIME_SLASH, "Start_SlashNow", id+TASK_ATTACKING)
		} else {
			g_temp_attack[id] = 1
			ExecuteHamB(Ham_Weapon_PrimaryAttack, get_pdata_cbase(id, 373, 5))
			g_temp_attack[id] = 0
			
			set_weapons_timeidle(id, HAMMER_ATTACKTIME_STAB + 2.0)
			set_player_nextattack(id, HAMMER_ATTACKTIME_STAB + 2.0)
			
			set_weapon_anim(id, HAMMER_ANIM_STAB)
			set_task(HAMMER_ATTACKTIME_STAB, "Start_StabNow", id+TASK_ATTACKING)
		}
	} else if(CurButton & IN_ATTACK2) {
		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK2)
		
		if(!g_changing_mode[id])
		{
			g_changing_mode[id] = 1
			
			set_weapons_timeidle(id, HAMMER_CHANGE_TIME)
			set_player_nextattack(id, HAMMER_CHANGE_TIME)
			
			set_weapon_anim(id, g_hammer_mode[id] == HAMMER_MODE_SLASH ? HAMMER_ANIM_MOVETO_STAB : HAMMER_ANIM_MOVETO_SLASH)
			set_task(HAMMER_CHANGE_TIME - 0.1, "Hammer_ChangeMode", id+TASK_CHANGING)
		}
	}
}

public Start_SlashNow(id)
{
	id -= TASK_ATTACKING
	
	g_temp_attack[id] = 0
	
	if (!is_user_alive(id)) 
		return
	if(get_user_weapon(id) != CSW_KNIFE)
		return
	if(!g_had_hammer[id])
		return	
		
	if(Check_Slash(id, 1))
	{
		emit_sound(id, CHAN_WEAPON, hammer_sound[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
		Check_Slash(id, 0)
	} else {
		emit_sound(id, CHAN_WEAPON, hammer_sound[3], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}

public Check_Slash(id, First_Check)
{
	#define MAX_POINT 2
	static Float:Max_Distance, Float:Point[MAX_POINT][3], Float:TB_Distance
	
	Max_Distance = HAMMER_RADIUS_SLASH
	TB_Distance = Max_Distance / float(MAX_POINT)
	
	static Float:VicOrigin[3], Float:MyOrigin[3]
	pev(id, pev_origin, MyOrigin)
	
	for(new i = 0; i < MAX_POINT; i++)
		get_position(id, TB_Distance * (i + 1), 0.0, 0.0, Point[i])
		
	static Have_Victim; Have_Victim = 0
	static ent
	ent = fm_get_user_weapon_entity(id, get_user_weapon(id))
		
	if(!pev_valid(ent))
		return 0
		
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue
		if(id == i)
			continue
		if(!can_see_fm(id, i))
			continue
		if(entity_range(id, i) > Max_Distance)
			continue
			
		pev(i, pev_origin, VicOrigin)
			
		if(get_distance_f(VicOrigin, Point[0]) <= 36.0
		|| get_distance_f(VicOrigin, Point[1]) <= 36.0)
		{
			if(!Have_Victim) Have_Victim = 1
			if(!First_Check) do_attack(id, i, ent, float(HAMMER_DAMAGE_SLASH))
		}
	}	
	
	if(Have_Victim)
		return 1
	
	return 0
}	

public Start_StabNow(id)
{
	id -= TASK_ATTACKING
	
	g_temp_attack[id] = 0
	
	if (!is_user_alive(id)) 
		return
	if(get_user_weapon(id) != CSW_KNIFE)
		return
	if(!g_had_hammer[id])
		return	
		
	if(Check_Stab(id, 1))
	{
		emit_sound(id, CHAN_WEAPON, hammer_sound[2], 1.0, ATTN_NORM, 0, PITCH_NORM)
		Check_Stab(id, 0)
	} else {
		emit_sound(id, CHAN_WEAPON, hammer_sound[3], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}

public Check_Stab(id, First_Check)
{
	#define MAX_POINT 2
	static Float:Max_Distance, Float:Point[MAX_POINT][3], Float:TB_Distance
	
	Max_Distance = HAMMER_RADIUS_STAB
	TB_Distance = Max_Distance / float(MAX_POINT)
	
	static Float:VicOrigin[3], Float:MyOrigin[3]
	pev(id, pev_origin, MyOrigin)
	
	for(new i = 0; i < MAX_POINT; i++)
		get_position(id, TB_Distance * (i + 1), 0.0, 0.0, Point[i])
		
	static Have_Victim; Have_Victim = 0
	static ent
	ent = fm_get_user_weapon_entity(id, get_user_weapon(id))
		
	if(!pev_valid(ent))
		return 0
		
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue
		if(id == i)
			continue
		if(!can_see_fm(id, i))
			continue
		if(entity_range(id, i) > Max_Distance)
			continue
			
		pev(i, pev_origin, VicOrigin)
			
		if(get_distance_f(VicOrigin, Point[0]) <= 40.0
		|| get_distance_f(VicOrigin, Point[1]) <= 40.0)
		{
			if(!Have_Victim) Have_Victim = 1
			if(!First_Check) do_attack(id, i, ent, float(HAMMER_DAMAGE_STAB))
		}
	}	
	
	if(Have_Victim)
		return 1
	
	return 0
}	

public Hammer_ChangeMode(id)
{
	id -= TASK_CHANGING
	
	g_changing_mode[id] = 0
	
	if (!is_user_alive(id)) 
		return
	if(get_user_weapon(id) != CSW_KNIFE)
		return	
	if(!g_had_hammer[id])
		return				
		
	if(g_hammer_mode[id] == HAMMER_MODE_SLASH) // Change to Stab
	{
		g_hammer_mode[id] = HAMMER_MODE_STAB
		set_weapon_anim(id, HAMMER_ANIM_IDLESTAB)
		
		zb3_set_user_speed(id, pev(id, pev_maxspeed) - HAMMER_WEIGHT)
	} else { // Change to Slash
		g_hammer_mode[id] = HAMMER_MODE_SLASH
		set_weapon_anim(id, HAMMER_ANIM_IDLESLASH)
		
		zb3_reset_user_speed(id)
	}
}

public fw_Knife_SendAnim(ent, anim, skip_local)
{
	if(pev_valid(ent) != 2)
		return HAM_IGNORED
		
	new id
	id = get_pdata_cbase(ent, 41 , 4)
	
	if(!g_had_hammer[id])
		return HAM_IGNORED
	
	set_pdata_string(id, m_szAnimExtention * 4, "hammer", -1 , 20)
		
	switch(anim)
	{
		case KNIFE_ANIM_DRAW:
		{
			if(g_hammer_mode[id] == HAMMER_MODE_SLASH)
			{
				set_weapon_anim(id, HAMMER_ANIM_DRAWSLASH)
				
				set_weapons_timeidle(id, HAMMER_DRAWTIME_SLASH)
				set_player_nextattack(id, HAMMER_DRAWTIME_SLASH)
				
				zb3_reset_user_speed(id)
			} else {
				set_weapon_anim(id, HAMMER_ANIM_DRAWSTAB)
				
				set_weapons_timeidle(id, HAMMER_DRAWTIME_STAB)
				set_player_nextattack(id, HAMMER_DRAWTIME_STAB)

				zb3_set_user_speed(id, pev(id, pev_maxspeed) - HAMMER_WEIGHT)
			}
		}
		case KNIFE_ANIM_IDLE:
		{
			if(g_hammer_mode[id] == HAMMER_MODE_SLASH)
			{
				set_weapon_anim(id, HAMMER_ANIM_IDLESLASH)
			} else {
				set_weapon_anim(id, HAMMER_ANIM_IDLESTAB)			
			}			
		}
	}
	
	return HAM_IGNORED
}

public fw_TraceLine(Float:vector_start[3], Float:vector_end[3], ignored_monster, id, handle)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED
	if(zb3_get_user_zombie(id))
		return FMRES_IGNORED		
	if (get_user_weapon(id) != CSW_KNIFE)
		return FMRES_IGNORED
	if(!g_had_hammer[id])
		return FMRES_IGNORED
	
	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)

	static Float:scalar
	
	if(g_hammer_mode[id] == HAMMER_MODE_SLASH)
		scalar = HAMMER_RADIUS_SLASH
	else
		scalar = HAMMER_RADIUS_STAB
	
	if(g_temp_attack[id])
		scalar = 0.0	
	
	xs_vec_mul_scalar(v_forward, scalar, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceLine, vecStart, vecEnd, ignored_monster, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_TraceHull(Float:vector_start[3], Float:vector_end[3], ignored_monster, hull, id, handle)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED
	if(zb3_get_user_zombie(id))
		return FMRES_IGNORED
	if (get_user_weapon(id) != CSW_KNIFE)
		return FMRES_IGNORED
	if(!g_had_hammer[id])
		return FMRES_IGNORED
	
	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)
	
	static Float:scalar
	
	if(g_hammer_mode[id] == HAMMER_MODE_SLASH)
		scalar = HAMMER_RADIUS_SLASH
	else
		scalar = HAMMER_RADIUS_STAB
	
	if(g_temp_attack[id])
		scalar = 0.0	
	
	xs_vec_mul_scalar(v_forward, scalar, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceHull, vecStart, vecEnd, ignored_monster, hull, id, handle)
	
	return FMRES_SUPERCEDE
}

do_attack(Attacker, Victim, Inflictor, Float:fDamage)
{
	fake_player_trace_attack(Attacker, Victim, fDamage)
	fake_take_damage(Attacker, Victim, fDamage, Inflictor)
}

fake_player_trace_attack(iAttacker, iVictim, &Float:fDamage)
{
	// get fDirection
	new Float:fAngles[3], Float:fDirection[3]
	pev(iAttacker, pev_angles, fAngles)
	angle_vector(fAngles, ANGLEVECTOR_FORWARD, fDirection)
	
	// get fStart
	new Float:fStart[3], Float:fViewOfs[3]
	pev(iAttacker, pev_origin, fStart)
	pev(iAttacker, pev_view_ofs, fViewOfs)
	xs_vec_add(fViewOfs, fStart, fStart)
	
	// get aimOrigin
	new iAimOrigin[3], Float:fAimOrigin[3]
	get_user_origin(iAttacker, iAimOrigin, 3)
	IVecFVec(iAimOrigin, fAimOrigin)
	
	// TraceLine from fStart to AimOrigin
	new ptr = create_tr2() 
	engfunc(EngFunc_TraceLine, fStart, fAimOrigin, DONT_IGNORE_MONSTERS, iAttacker, ptr)
	new pHit = get_tr2(ptr, TR_pHit)
	new iHitgroup = get_tr2(ptr, TR_iHitgroup)
	new Float:fEndPos[3]
	get_tr2(ptr, TR_vecEndPos, fEndPos)

	// get target & body at aiming
	new iTarget, iBody
	get_user_aiming(iAttacker, iTarget, iBody)
	
	// if aiming find target is iVictim then update iHitgroup
	if (iTarget == iVictim)
	{
		iHitgroup = iBody
	}
	
	// if ptr find target not is iVictim
	else if (pHit != iVictim)
	{
		// get AimOrigin in iVictim
		new Float:fVicOrigin[3], Float:fVicViewOfs[3], Float:fAimInVictim[3]
		pev(iVictim, pev_origin, fVicOrigin)
		pev(iVictim, pev_view_ofs, fVicViewOfs) 
		xs_vec_add(fVicViewOfs, fVicOrigin, fAimInVictim)
		fAimInVictim[2] = fStart[2]
		fAimInVictim[2] += get_distance_f(fStart, fAimInVictim) * floattan( fAngles[0] * 2.0, degrees )
		
		// check aim in size of iVictim
		new iAngleToVictim = get_angle_to_target(iAttacker, fVicOrigin)
		iAngleToVictim = abs(iAngleToVictim)
		new Float:fDis = 2.0 * get_distance_f(fStart, fAimInVictim) * floatsin( float(iAngleToVictim) * 0.5, degrees )
		new Float:fVicSize[3]
		pev(iVictim, pev_size , fVicSize)
		if ( fDis <= fVicSize[0] * 0.5 )
		{
			// TraceLine from fStart to aimOrigin in iVictim
			new ptr2 = create_tr2() 
			engfunc(EngFunc_TraceLine, fStart, fAimInVictim, DONT_IGNORE_MONSTERS, iAttacker, ptr2)
			new pHit2 = get_tr2(ptr2, TR_pHit)
			new iHitgroup2 = get_tr2(ptr2, TR_iHitgroup)
			
			// if ptr2 find target is iVictim
			if ( pHit2 == iVictim && (iHitgroup2 != HIT_HEAD || fDis <= fVicSize[0] * 0.25) )
			{
				pHit = iVictim
				iHitgroup = iHitgroup2
				get_tr2(ptr2, TR_vecEndPos, fEndPos)
			}
			
			free_tr2(ptr2)
		}
		
		// if pHit still not is iVictim then set default HitGroup
		if (pHit != iVictim)
		{
			// set default iHitgroup
			iHitgroup = HIT_GENERIC
			
			new ptr3 = create_tr2() 
			engfunc(EngFunc_TraceLine, fStart, fVicOrigin, DONT_IGNORE_MONSTERS, iAttacker, ptr3)
			get_tr2(ptr3, TR_vecEndPos, fEndPos)
			
			// free ptr3
			free_tr2(ptr3)
		}
	}
	
	// set new Hit & Hitgroup & EndPos
	set_tr2(ptr, TR_pHit, iVictim)
	set_tr2(ptr, TR_iHitgroup, iHitgroup)
	set_tr2(ptr, TR_vecEndPos, fEndPos)
	
	// hitgroup multi fDamage
	new Float:fMultifDamage 
	switch(iHitgroup)
	{
		case HIT_HEAD: fMultifDamage  = 4.0
		case HIT_STOMACH: fMultifDamage  = 1.25
		case HIT_LEFTLEG: fMultifDamage  = 0.75
		case HIT_RIGHTLEG: fMultifDamage  = 0.75
		default: fMultifDamage  = 1.0
	}
	
	fDamage *= fMultifDamage
	
	// ExecuteHam
	fake_trake_attack(iAttacker, iVictim, fDamage, fDirection, ptr)
	
	// free ptr
	free_tr2(ptr)
}

stock fake_trake_attack(iAttacker, iVictim, Float:fDamage, Float:fDirection[3], iTraceHandle, iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
	ExecuteHamB(Ham_TraceAttack, iVictim, iAttacker, fDamage, fDirection, iTraceHandle, iDamageBit)
}

stock fake_take_damage(iAttacker, iVictim, Float:fDamage, iInflictor = 0, iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
	iInflictor = (!iInflictor) ? iAttacker : iInflictor
	ExecuteHamB(Ham_TakeDamage, iVictim, iInflictor, iAttacker, fDamage, iDamageBit)
}

stock get_angle_to_target(id, const Float:fTarget[3], Float:TargetSize = 0.0)
{
	new Float:fOrigin[3], iAimOrigin[3], Float:fAimOrigin[3], Float:fV1[3]
	pev(id, pev_origin, fOrigin)
	get_user_origin(id, iAimOrigin, 3) // end position from eyes
	IVecFVec(iAimOrigin, fAimOrigin)
	xs_vec_sub(fAimOrigin, fOrigin, fV1)
	
	new Float:fV2[3]
	xs_vec_sub(fTarget, fOrigin, fV2)
	
	new iResult = get_angle_between_vectors(fV1, fV2)
	
	if (TargetSize > 0.0)
	{
		new Float:fTan = TargetSize / get_distance_f(fOrigin, fTarget)
		new fAngleToTargetSize = floatround( floatatan(fTan, degrees) )
		iResult -= (iResult > 0) ? fAngleToTargetSize : -fAngleToTargetSize
	}
	
	return iResult
}

stock get_angle_between_vectors(const Float:fV1[3], const Float:fV2[3])
{
	new Float:fA1[3], Float:fA2[3]
	engfunc(EngFunc_VecToAngles, fV1, fA1)
	engfunc(EngFunc_VecToAngles, fV2, fA2)
	
	new iResult = floatround(fA1[1] - fA2[1])
	iResult = iResult % 360
	iResult = (iResult > 180) ? (iResult - 360) : iResult
	
	return iResult
}

stock set_weapons_timeidle(id, Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	new entwpn = fm_get_user_weapon_entity(id, CSW_KNIFE)
	if (pev_valid(entwpn)) 
	{
		set_pdata_float(entwpn, 46, TimeIdle, 4)
		set_pdata_float(entwpn, 47, TimeIdle, 4)
		set_pdata_float(entwpn, 48, TimeIdle + 1.0, 4)
	}
}

stock set_player_nextattack(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	const m_flNextAttack = 83
	set_pdata_float(id, m_flNextAttack, nexttime, 5)
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

stock bool:can_see_fm(entindex1, entindex2)
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

stock hook_ent2(ent, Float:VicOrigin[3], Float:speed, type)
{
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]
	static Float:EntVelocity[3]
	
	pev(ent, pev_velocity, EntVelocity)
	pev(ent, pev_origin, EntOrigin)
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	
	static Float:fl_Time; fl_Time = distance_f / speed
	
	if(type == 1)
	{
		fl_Velocity[0] = ((VicOrigin[0] - EntOrigin[0]) / fl_Time) * 1.5
		fl_Velocity[1] = ((VicOrigin[1] - EntOrigin[1]) / fl_Time) * 1.5
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time		
	} else if(type == 2) {
		fl_Velocity[0] = ((EntOrigin[0] - VicOrigin[0]) / fl_Time) * 1.5
		fl_Velocity[1] = ((EntOrigin[1] - VicOrigin[1]) / fl_Time) * 1.5
		fl_Velocity[2] = (EntOrigin[2] - VicOrigin[2]) / fl_Time
	}

	xs_vec_add(EntVelocity, fl_Velocity, fl_Velocity)
	set_pev(ent, pev_velocity, fl_Velocity)
}

