#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombie_thehero2>

#define PLUGIN "[ZB3] Zombie Class: Stamper"
#define VERSION "2.0"
#define AUTHOR "Dias"

new const LANG_FILE[] = "zombie_thehero2.txt"

// Zombie Configs
new const zclass_name[] = "Stamper"
new const zclass_desc[] = "Stamping the Coffin"
new const zclass_sex = SEX_MALE
new const zclass_lockcost = 0
new const zclass_hostmodel[] = "stamper_zombi_host"
new const zclass_originmodel[] = "stamper_zombi_origin"
new const zclass_clawsmodelhost[] = "v_knife_stamper_zombi.mdl"
new const zclass_clawsmodelorigin[] = "v_knife_stamper_zombi.mdl"
new const zombiegrenade_modelhost[] = "models/zombie_thehero/v_zgren_stamper_zombi.mdl"
new const zombiegrenade_modelorigin[] = "models/zombie_thehero/v_zgren_stamper_zombi.mdl"
new const Float:zclass_gravity = 0.8
new const Float:zclass_speedhost = 280.0
new const Float:zclass_speedorigin = 280.0
new const Float:zclass_knockback = 1.5
new const Float:zclass_painshock = 0.4
new const Float:zclass_dmgmulti = 1.1
new const DeathSound[2][] =
{
	"zombie_thehero/zombi_death_stamper_1.wav",
	"zombie_thehero/zombi_death_stamper_2.wav"
}
new const HurtSound[2][] = 
{
	"zombie_thehero/zombi_hurt_stamper_1.wav",
	"zombie_thehero/zombi_hurt_stamper_2.wav"	
}
new const HealSound[] = "zombie_thehero/zombi_heal.wav"
new const EvolSound[] = "zombie_thehero/zombi_evolution.wav"
new const Float:ClawsDistance1 = 1.0
new const Float:ClawsDistance2 = 1.1

new const CoffinModel[] = "models/zombie_thehero/zombipile.mdl"
new const StampingSound[] = "zombie_thehero/zombi_stamper_iron_maiden_stamping.wav"
new const CoffinExp[] = "zombie_thehero/zombi_stamper_iron_maiden_explosion.wav"
new const CoffinHitSound[] = "zombie_thehero/zombi_attack_3.wav"
new const CoffinExpSpr[] = "sprites/zombie_thehero/zombiebomb_exp.spr"
new const HandSound[2][] =
{
	"zombie_thehero/zombi_stamper_clap.wav",
	"zombie_thehero/zombi_stamper_glove.wav"
}

new g_zombie_classid

const UNIT_SECOND = (1<<12)
const BREAK_WOOD = 0x08

const pev_livetime = pev_iuser4
const pev_checktime = pev_fuser4

#define LANG_OFFICIAL LANG_PLAYER
#define HEALTH_OFFSET 1000

#define TASK_STAMPING 43534
#define TASK_COOLDOWN 43535
#define TASK_FREEZING 43536

#define COFFIN_CLASSNAME "coffin"
#define COFFIN_HEALTH 300
#define COFFIN_EXP_RADIUS 200
#define COFFIN_EXP_KNOCKBACK 800
#define COFFIN_EXP_DAMAGE 10
#define COFFIN_LIVETIME_ORIGIN 14
#define COFFIN_LIVETIME_HOST 14

#define STAMPING_COOLDOWN_ORIGIN 15
#define STAMPING_COOLDOWN_HOST 15
#define STAMPING_ANIM random_num(1, 2)
#define STAMPING_PLAYERANIM 10
#define STAMPING_FOV 100
#define STAMPING_STARTTIME 0.5

#define HUMAN_SLOWTIME 5
#define HUMAN_SLOWSPEED 200

new g_SprBeam_Id, g_SprExp_Id, g_SprBlast_Id
new g_msg_ScreenShake, g_Msg_Fov
new g_can_stamping[33], g_stamping[33], g_freezing[33]

new g_synchud1, g_current_time[33]
new g_temp_attack[33]

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_dictionary(LANG_FILE)
	register_clcmd("drop", "cmd_drop")
	
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	
	RegisterHam(Ham_TraceAttack, "info_target", "Coffin_TraceAttack")
	RegisterHam(Ham_Think, "info_target", "Coffin_Think")
	RegisterHam(Ham_TakeDamage, "info_target", "Coffin_TakeDamage", 1)
		
	g_Msg_Fov = get_user_msgid("SetFOV")
	g_msg_ScreenShake = get_user_msgid("ScreenShake")
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
	engfunc(EngFunc_PrecacheModel, CoffinModel)
	engfunc(EngFunc_PrecacheSound, StampingSound)
	engfunc(EngFunc_PrecacheSound, CoffinExp)
	engfunc(EngFunc_PrecacheSound, CoffinHitSound)
	
	g_SprBeam_Id = precache_model("sprites/shockwave.spr")
	g_SprExp_Id = precache_model("models/woodgibs.mdl")
	g_SprBlast_Id = precache_model(CoffinExpSpr)
	
	for(new i = 0; i < sizeof(HandSound); i++)
		engfunc(EngFunc_PrecacheSound, HandSound[i])
}

public zb3_user_infected(id, infector)
{
	if(zb3_get_user_zombie_class(id) == g_zombie_classid)
	{
		if(is_user_bot(id))
			bot_use_skill(id)
		
		reset_skill(id)
		
		g_can_stamping[id] = 1
		g_stamping[id] = 0
		g_freezing[id] = 0
		
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
	g_can_stamping[id] = 0
	g_stamping[id] = 0
	g_freezing[id] = 0
	g_current_time[id] = 0
	g_temp_attack[id] = 0
	
	remove_task(id+TASK_STAMPING)
	remove_task(id+TASK_COOLDOWN)
	remove_task(id+TASK_FREEZING)
	
	if(is_user_connected(id)) set_fov(id)
}

public zb3_user_spawned(id) 
{
	if(!zb3_get_user_zombie(id)) set_task(0.1, "reset_skill", id)
}

public zb3_user_dead(id) reset_skill(id)

public Event_NewRound()
{
	remove_entity_name(COFFIN_CLASSNAME)
}
public bot_use_skill(id)
{
	if(!is_user_alive(id) || !zb3_get_user_zombie(id))
		return PLUGIN_CONTINUE
		
	cmd_drop(id)
	set_task(zb3_get_user_level(id) > 1 ? float(STAMPING_COOLDOWN_ORIGIN) : float(STAMPING_COOLDOWN_HOST),"bot_use_skill",id)
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
		return PLUGIN_CONTINUE
	if(!g_can_stamping[id] || g_stamping[id])
		return PLUGIN_HANDLED

	Do_Stamping(id)

	return PLUGIN_HANDLED
}

public Do_Stamping(id)
{
	g_can_stamping[id] = 0
	g_current_time[id] = 0
	g_stamping[id] = 1
	
	set_weapons_timeidle(id, STAMPING_STARTTIME)
	set_player_nextattack(id, STAMPING_STARTTIME)
	
	do_fake_attack(id)
	set_fov(id, STAMPING_FOV)
	set_weapon_anim(id, STAMPING_ANIM)
	set_pev(id, pev_sequence, STAMPING_PLAYERANIM)

	// Start Stamping
	set_task(STAMPING_STARTTIME, "Set_Stamping", id+TASK_STAMPING)
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

public Set_Stamping(id)
{
	id -= TASK_STAMPING

	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 
	if(!g_stamping[id])
		return	
		
	// Reset
	g_stamping[id] = 0
	set_fov(id)
		
	Create_Coffin(id)	
}

public Create_Coffin(id)
{
	static Float:Origin[3], Float:Angle1[3], Float:Angle2[3], Float:PutOrigin[3]

	pev(id, pev_origin, Origin)
	pev(id, pev_angles, Angle1)
	get_origin_distance(id, PutOrigin, 40.0)
	
	// Add Vector
	PutOrigin[2] += 25.0

	static coffin
	coffin = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	if(!pev_valid(coffin))
		return
	
	// Init
	set_pev(coffin, pev_classname, COFFIN_CLASSNAME)
	
	// Origin & Angles & Vector
	pev(coffin, pev_angles, Angle2)
	Angle1[0] = Angle2[0]
	set_pev(coffin, pev_angles, Angle1)
	set_pev(coffin, pev_origin, PutOrigin)
	
	// Set Coffin Data
	entity_set_float(coffin, EV_FL_takedamage, 1.0)
	entity_set_float(coffin, EV_FL_health, float(HEALTH_OFFSET + COFFIN_HEALTH))
	engfunc(EngFunc_SetModel, coffin, CoffinModel)
	set_pev(coffin, pev_body, 1)
	set_pev(coffin, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(coffin, pev_solid, SOLID_BBOX)
	new Float:mins[3] = {-10.0, -6.0, -36.0}
	new Float:maxs[3] = {10.0, 6.0, 36.0}
	entity_set_size(coffin, mins, maxs)

	// Set Owner
	// set_pev(coffin, pev_owner, id)
	
	// Drop To Floor
	engfunc(EngFunc_DropToFloor, coffin)
	
	// Make Effect
	static Float:StampedOrigin[3]
	
	pev(coffin, pev_origin, StampedOrigin)
	StampingEffect(coffin, StampedOrigin)

	set_pev(coffin, pev_livetime, zb3_get_user_level(id) > 1 ? COFFIN_LIVETIME_ORIGIN : COFFIN_LIVETIME_HOST)
	set_pev(coffin, pev_nextthink, get_gametime() + 0.5)
	
	static Victim; Victim = -1
	while((Victim = find_ent_in_sphere(Victim, StampedOrigin, float(COFFIN_EXP_RADIUS))) != 0)
	{
		if(is_user_alive(Victim))
		{
			// Shake
			CreateScreenShake(Victim)
			
			if(!zb3_get_user_zombie(Victim))
			{
				// Freeze Player
				g_freezing[Victim] = 1
				zb3_set_user_speed(Victim, HUMAN_SLOWSPEED)
			
				set_task(float(HUMAN_SLOWTIME), "ResetFreeze", Victim+TASK_FREEZING)
			}
		}
	}
	
	set_task(0.1, "CheckStuck", coffin)
}

public CheckStuck(ent)
{
	if(!pev_valid(ent))
		return
		
	if(is_entity_stuck(ent)) CoffinExp_Handle(ent, 1)
}

public ResetFreeze(id)
{
	id -= TASK_FREEZING
	
	if(!is_user_connected(id))
		return
		
	g_freezing[id] = 0
	
	if(zb3_get_user_zombie(id))
	{
		zb3_set_user_speed(id, zb3_get_user_level(id) > 1 ? floatround(zclass_speedorigin) : floatround(zclass_speedhost))
		return
	}
	
	zb3_reset_user_speed(id)
}

public StampingEffect(ent, Float:Origin[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_BEAMCYLINDER)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 200.0)
	write_short(g_SprBeam_Id)
	write_byte(0)
	write_byte(0)
	write_byte(4)
	write_byte(10)
	write_byte(0)
	write_byte(150)
	write_byte(150)
	write_byte(150)
	write_byte(200)
	write_byte(0)
	message_end()	
	
	EmitSound(ent, CHAN_BODY, StampingSound)
}

public CoffinExp_Handle(ent, Exp)
{
	if(!pev_valid(ent))
		return

	static Float:Origin[3]
	pev(ent, pev_origin, Origin)
	
	if(Exp)
	{
		// Exp Spr
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(g_SprBlast_Id)
		write_byte(40)
		write_byte(30)
		write_byte(14)
		message_end()
	}
	
	// Break Model
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_BREAKMODEL)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 24)
	engfunc(EngFunc_WriteCoord, 16)
	engfunc(EngFunc_WriteCoord, 16)
	engfunc(EngFunc_WriteCoord, 16)
	engfunc(EngFunc_WriteCoord, random_num(-50, 50))
	engfunc(EngFunc_WriteCoord, random_num(-50, 50))
	engfunc(EngFunc_WriteCoord, 25)
	write_byte(10)
	write_short(g_SprExp_Id)
	write_byte(10)
	write_byte(25)
	write_byte(BREAK_WOOD)
	message_end()
	
	if(Exp)
		emit_sound(ent, CHAN_BODY, CoffinExp,  VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	if(Exp)
	{
		static Victim; Victim = -1
		while((Victim = find_ent_in_sphere(Victim, Origin, float(COFFIN_EXP_RADIUS))) != 0)
		{
			if(!is_user_alive(Victim) || !is_valid_ent(Victim)) 
				continue
			
			static Float:VictimOrigin[3], Float:Distance, Float:Speed, Float:NewSpeed, Float:Velocity[3]
			pev(Victim, pev_origin, VictimOrigin)
			
			Distance = get_distance_f(Origin, VictimOrigin)
			Speed = float(COFFIN_EXP_KNOCKBACK)
			NewSpeed = Speed * (1.0 - (Distance / float(COFFIN_EXP_RADIUS)))
			GetSpeedVector(Origin, VictimOrigin, NewSpeed, Velocity)
			
			set_pev(Victim, pev_velocity, Velocity)
			CreateScreenShake(Victim)
			
			if(get_user_health(Victim) > COFFIN_EXP_DAMAGE) ExecuteHam(Ham_TakeDamage, Victim, 0, Victim, COFFIN_EXP_DAMAGE, DMG_BLAST)
			else ExecuteHamB(Ham_Killed, Victim, 0, 0)
		}
	}
	
	if(pev_valid(ent)) engfunc(EngFunc_RemoveEntity, ent)			
}

public Coffin_Think(ent)
{
	if(!pev_valid(ent)) 
		return
	
	static ClassName[32]
	pev(ent, pev_classname, ClassName, sizeof(ClassName))
	
	if(!equal(ClassName, COFFIN_CLASSNAME)) 
		return
		
	if(get_gametime() - 1.0 > pev(ent, pev_checktime))
	{
		set_pev(ent, pev_livetime, pev(ent, pev_livetime) - 1)
		set_pev(ent, pev_checktime, get_gametime())
	}
	
	if(pev(ent, pev_livetime) <= 0)
	{
		CoffinExp_Handle(ent, 0)
		return
	}
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.5)
}

public Coffin_TraceAttack(ent, attacker, Float: damage, Float: direction[3], trace, damageBits)
{
	if(ent == attacker || !is_user_connected(attacker) || !pev_valid(ent)) 
		return HAM_IGNORED
	if(get_user_weapon(attacker) != CSW_KNIFE || !zb3_get_user_zombie(attacker)) 
		return HAM_IGNORED
	
	new ClassName[32]
	pev(ent, pev_classname, ClassName, sizeof(ClassName))
	
	if(!equali(ClassName, COFFIN_CLASSNAME)) 
		return HAM_IGNORED
	
	new Float:End[3]
	get_tr2(trace, TR_vecEndPos, End)
	
	message_begin(MSG_PVS,SVC_TEMPENTITY)
	write_byte(TE_SPARKS)
	engfunc(EngFunc_WriteCoord, End[0])
	engfunc(EngFunc_WriteCoord, End[1])
	engfunc(EngFunc_WriteCoord, End[2])
	message_end()
	
	emit_sound(ent, CHAN_WEAPON, CoffinHitSound,  VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	return HAM_IGNORED
}

public Coffin_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(!pev_valid(victim) || !pev_valid(attacker))
		return HAM_IGNORED
		
	new ClassName[32]
	pev(victim, pev_classname, ClassName, sizeof(ClassName))
	
	if(!equali(ClassName, COFFIN_CLASSNAME)) 
		return HAM_IGNORED

	if((pev(victim, pev_health) - HEALTH_OFFSET) <= 0)
	{
		CoffinExp_Handle(victim, 1)
		return HAM_IGNORED
	}
	
	return HAM_HANDLED
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
	
	timewait = zb3_get_user_level(id) > 1 ? float(STAMPING_COOLDOWN_ORIGIN) : float(STAMPING_COOLDOWN_HOST)
	
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
		
		if(!g_can_stamping[id]) 
		{
			g_can_stamping[id] = 1
			g_stamping[id] = 0
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

stock get_origin_distance(index, Float:Origin[3], Float:Dist)
{
	if(!pev_valid(index))
		return 0
	
	new Float:start[3]
	new Float:view_ofs[3]
	
	pev(index, pev_origin, start)
	pev(index, pev_view_ofs, view_ofs)
	xs_vec_add(start, view_ofs, start)
	
	new Float:dest[3]
	pev(index, pev_angles, dest)
	
	engfunc(EngFunc_MakeVectors, dest)
	global_get(glb_v_forward, dest)
	
	xs_vec_mul_scalar(dest, Dist, dest)
	xs_vec_add(start, dest, dest)
	
	engfunc(EngFunc_TraceLine, start, dest, 0, index, 0)
	get_tr2(0, TR_vecEndPos, Origin)
	
	return 1
}

stock CreateScreenShake(id)
{
	if(!is_user_connected(id))
		return
	
	new shake[3]
	shake[0] = random_num(2,20)
	shake[1] = random_num(2,5)
	shake[2] = random_num(2,20)
	
	message_begin(MSG_ONE_UNRELIABLE, g_msg_ScreenShake, _, id)
	write_short(UNIT_SECOND * shake[0])
	write_short(UNIT_SECOND * shake[1])
	write_short(UNIT_SECOND * shake[2])
	message_end()
}

stock is_entity_stuck(ent)
{
	if(!pev_valid(ent))
		return false
	
	static Float:originF[3]
	pev(ent, pev_origin, originF)
	
	engfunc(EngFunc_TraceHull, originF, originF, 0, (pev(ent, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, ent, 0)
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return true
	
	return false
}

GetSpeedVector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1042\\ f0\\ fs16 \n\\ par }
*/
