#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <zombie_thehero2> // (Edit at: 178, 188, 642)

new g_MaxPlayers
new g_smokepuff_id, g_trail, g_exp_sprid, m_iBlood[2], g_oldweapon[33]


// SVDEX
#define SVDEX_GRENADE_CLASSNAME "svd_grenade"
#define SVDEX_CODE 323232
#define SVDEX_CHANGE_TIME 1.5
#define SVDEX_GRENADE_HITRADIUS 300.0
#define SVDEX_GRENADE_DAMAGE 2000.0
#define SVDEX_GRENADE_AMOUNT 10

const pev_bpammo = pev_iuser3
const pev_clip = pev_iuser4

// Fire Start
#define WEAPON_ATTACH_F 40.0
#define WEAPON_ATTACH_R 10.0
#define WEAPON_ATTACH_U -10.0	
#define SVDEX_GRENADE_VELOCITY 1500

#define TASK_CHANGING 342342

#define SVDEX_CARBINE_DAMAGE 480.0
#define SVDEX_CARBINE_RECOIL 0.4
#define SVDEX_CARBINE_ACCUARY 0.0
#define SVDEX_CARBINE_SPEED 0.35
#define SVDEX_CARBINE_CLIP 20
#define SVDEX_CARBINE_BPAMMO 180
#define SVDEX_CARBINE_RELOADTIME 3.8

#define SVDEX_GL_RELOAD 2.8
#define m_fAccuary 62

new const svdex_model[5][] = 
{
	"models/zombie_thehero/hero_wpn/v_svdex_1.mdl",
	"models/zombie_thehero/hero_wpn/v_svdex_2.mdl",
	"models/zombie_thehero/hero_wpn/p_svdex.mdl",
	"models/zombie_thehero/hero_wpn/w_svdex.mdl",
	"models/zombie_thehero/hero_wpn/shell_svdex.mdl"
}

new const svdex_sound[7][] =
{
	"weapons/svdex_shoot1.wav",
	"weapons/svdex_clipout.wav",
	"weapons/svdex_clipin.wav",
	"weapons/svdex_clipon.wav",
	"weapons/svdex_draw.wav",
	"weapons/svdex_exp.wav",
	"weapons/svdex_shoot2.wav"
}

enum
{
	SVDEX_ANIM_IDLE = 0,
	SVDEX_ANIM_RELOAD,
	SVDEX_ANIM_DRAW,
	SVDEX_ANIM_SHOOT1,
	SVDEX_ANIM_SHOOT2,
	SVDEX_ANIM_SHOOT3,
	SVDEX_ANIM_CHANGE
}

enum
{
	SVDEX2_ANIM_IDLE = 0,
	SVDEX2_ANIM_RELOAD,
	SVDEX2_ANIM_DRAW,
	SVDEX2_ANIM_SHOOT1,
	SVDEX2_ANIM_SHOOT2,
	SVDEX2_ANIM_SHOOT3,
	SVDEX2_ANIM_CHANGE,
	SVDEX2_ANIM_SHOOT4,
	SVDEX2_ANIM_SHOOT_LAST
}

enum
{
	SVDEX_MODE_CARBINE = 1,
	SVDEX_MODE_GRENADE_LAUNCHER
}

new g_had_svdex[33], g_svdex_mode[33], g_ak47_event,
g_svdex_clip[33], g_svdex_reload[33], g_changing_mode[33], Float:Last_Shoot_Grenade[33], g_svdex_grenade[33]
#define CSW_SVDEX CSW_AK47
#define weapon_svdex "weapon_ak47"

// Quad Barrel
#define QB_DAMAGE 85.0
#define QB_RECOIL 0.01
#define QB_SPEED 0.1
#define QB_CLIP 4
#define QB_BPAMMO 150
#define QB_RELOADTIME 3.0

#define QB_CODE 4234234

new const qb_model[3][] = 
{
	"models/zombie_thehero/hero_wpn/v_qbarrel.mdl",
	"models/zombie_thehero/hero_wpn/p_qbarrel.mdl",
	"models/zombie_thehero/hero_wpn/w_qbarrel.mdl"
}

new const qb_sound[5][] = 
{
	"weapons/qbarrel_clipin1.wav",
	"weapons/qbarrel_clipin2.wav",
	"weapons/qbarrel_clipout1.wav",
	"weapons/qbarrel_draw.wav",
	"weapons/qbarrel_shoot.wav"
}

enum
{
	QB_ANIM_IDLE = 0,
	QB_ANIM_SHOOT1,
	QB_ANIM_SHOOT2,
	QB_ANIM_RELOAD,
	QB_ANIM_DRAW
}

new g_had_qb[33], g_event_qb
#define CSW_QUADBARREL CSW_XM1014
#define weapon_quadbarrel "weapon_xm1014"

public plugin_init()
{
	register_plugin("[Zombie: The Hero] Sub-Plugin: Hero Weapons", "2.0", "Dias")
	
	
	register_event("CurWeapon", "Event_CheckWeapon", "be", "1=1")

	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_Touch, "fw_Touch")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	
	// SvDex
	RegisterHam(Ham_Weapon_Reload, weapon_svdex, "fw_Reload_Svdex")
	RegisterHam(Ham_Weapon_Reload, weapon_svdex, "fw_Reload_Svdex_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_svdex, "fw_PostFrame_Svdex")	
	RegisterHam(Ham_Item_AddToPlayer, weapon_svdex, "fw_AddToPlayer_Svdex_Post", 1)	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_svdex, "fw_PrimaryAttack_Svdex")
	
	// Quad Barrel
	RegisterHam(Ham_Weapon_Reload, weapon_quadbarrel, "fw_Reload_QuadBarrel_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_quadbarrel, "fw_PostFrame_QuadBarrel")
	RegisterHam(Ham_Item_AddToPlayer, weapon_quadbarrel, "fw_AddToPlayer_QuadBarrel_Post", 1)	
	
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	for(new i = 0; i < sizeof(svdex_model); i++)
		engfunc(EngFunc_PrecacheModel, svdex_model[i])
	for(new i = 0; i < sizeof(svdex_sound); i++)
		engfunc(EngFunc_PrecacheSound, svdex_sound[i])
	for(new i = 0; i < sizeof(qb_model); i++)
		engfunc(EngFunc_PrecacheModel, qb_model[i])
	for(new i = 0; i < sizeof(qb_sound); i++)
		engfunc(EngFunc_PrecacheSound, qb_sound[i])		
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	
	g_smokepuff_id = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	g_trail = engfunc(EngFunc_PrecacheModel, "sprites/smoke.spr")
	g_exp_sprid = engfunc(EngFunc_PrecacheModel, "sprites/zerogxplode.spr")
	
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")	
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal("events/ak47.sc", name))
		g_ak47_event = get_orig_retval()
	if(equal("events/xm1014.sc", name))
		g_event_qb = get_orig_retval()
}

public reset_weapon(id)
{
	remove_task(id+TASK_CHANGING)

	g_oldweapon[id] = g_had_svdex[id] = g_svdex_mode[id] = 0
	g_svdex_clip[id] = g_svdex_reload[id] = g_changing_mode[id] = 0	
	g_svdex_grenade[id] = 0

	g_had_qb[id] = 0
}

public zb3_user_spawned(id)
{
	if(zb3_get_user_zombie(id))
		return
		
	reset_weapon(id)
	remove_entity_name(SVDEX_GRENADE_CLASSNAME)
}

public zb3_user_become_hero(id, hero_type)
{
	zb3_supplybox_random_getitem(id, 1)
	
	if(hero_type == HERO_ANDREY) 
	{
		//zb3_remove_weapon(id)
		get_svdex(id)
	}
	if(hero_type == HERO_KATE) 
	{
		//zb3_remove_weapon(id)
		get_quadbarrel(id)
	}
}
public zb3_weapon_refill_ammo(id)
{
	if(!is_user_alive(id) || zb3_get_user_zombie(id) || !zb3_get_user_hero(id))
		return 
	if(g_had_svdex[id])	
	{
		g_svdex_grenade[id] = SVDEX_GRENADE_AMOUNT
		cs_set_user_bpammo(id, CSW_SVDEX, SVDEX_CARBINE_BPAMMO)
	} else if(g_had_qb[id])
	{
		cs_set_user_bpammo(id, CSW_QUADBARREL, QB_BPAMMO)	
	}
}
public get_svdex(id)
{
	if(!is_user_alive(id))
		return
	
	reset_weapon(id)
	
	g_had_svdex[id] = 1
	g_svdex_mode[id] = SVDEX_MODE_CARBINE
	g_svdex_grenade[id] = SVDEX_GRENADE_AMOUNT
	
	give_item(id, weapon_svdex)
	
	static ent
	ent = fm_get_user_weapon_entity(id, CSW_SVDEX)
	
	cs_set_weapon_ammo(ent, SVDEX_CARBINE_CLIP)
	cs_set_user_bpammo(id, CSW_SVDEX, SVDEX_CARBINE_BPAMMO)
}

public get_quadbarrel(id)
{
	if(!is_user_alive(id))
		return
	
	reset_weapon(id)
	
	g_had_qb[id] = 1
	
	give_item(id, weapon_quadbarrel)
	
	static ent
	ent = fm_get_user_weapon_entity(id, CSW_QUADBARREL)
	
	cs_set_weapon_ammo(ent, QB_CLIP)
	cs_set_user_bpammo(id, CSW_QUADBARREL, QB_BPAMMO)	
}

public Event_CheckWeapon(id)
{
	if(!is_user_alive(id))
		return 1
	if(g_oldweapon[id] == CSW_SVDEX && get_user_weapon(id) != CSW_SVDEX)
		hide_crosshair(id, 0)
	
	if(get_user_weapon(id) == CSW_SVDEX && g_had_svdex[id])
	{
		switch(g_svdex_mode[id])
		{
			case SVDEX_MODE_CARBINE:
			{
				static ViewModel[64]
				pev(id, pev_viewmodel2, ViewModel, sizeof(ViewModel))
				
				if(!equal(ViewModel, svdex_model[0]))
				{
					set_pev(id, pev_viewmodel2, svdex_model[0])
					set_pev(id, pev_weaponmodel2, svdex_model[2])
					
					static Ent
					Ent = fm_get_user_weapon_entity(id, CSW_SVDEX)
					
					if(pev_valid(Ent)) 
					{
						set_pev(Ent, pev_bpammo, cs_get_user_bpammo(id, CSW_SVDEX))
						set_pev(Ent, pev_clip, cs_get_weapon_ammo(Ent))
		
						update_ammo(id, Ent, 1)
					}
				}
				
				hide_crosshair(id, 0)
				Carbine_Shoot_Speed(id)
			}
			
			case SVDEX_MODE_GRENADE_LAUNCHER:
			{
				static ViewModel[64]
				pev(id, pev_viewmodel2, ViewModel, sizeof(ViewModel))
				
				if(!equal(ViewModel, svdex_model[1]))
				{
					set_pev(id, pev_viewmodel2, svdex_model[1])
					set_pev(id, pev_weaponmodel2, svdex_model[2])
					
					static Ent
					Ent = fm_get_user_weapon_entity(id, CSW_SVDEX)
					
					if(pev_valid(Ent)) update_ammo(id, Ent, 0)
				}
				
				hide_crosshair(id, 1)
			}
		}
	}
	
	if(get_user_weapon(id) == CSW_QUADBARREL && g_had_qb[id])
	{
		set_pev(id, pev_viewmodel2, qb_model[0])
		set_pev(id, pev_weaponmodel2, qb_model[1])
		
		if(g_oldweapon[id] != CSW_QUADBARREL)
		{
			set_pdata_float(id, 83, 1.0, 5)
			set_weapon_anim(id, QB_ANIM_DRAW)
		}
	}
		
	
	g_oldweapon[id] = get_user_weapon(id)
	
	return 0
}

public update_ammo(id, ent, reset)
{
	if(!is_user_alive(id))
		return
		
	if(reset == 0)
	{
		set_pev(ent, pev_bpammo, cs_get_user_bpammo(id, CSW_SVDEX))
		set_pev(ent, pev_clip, cs_get_weapon_ammo(ent))
	}
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), _, id)
	write_byte(1)
	write_byte(CSW_SVDEX)
	write_byte(reset == 1 ? pev(ent, pev_clip) : -1)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
	write_byte(2)
	write_byte(reset == 1 ? pev(ent, pev_bpammo) : g_svdex_grenade[id])
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), _, id)
	write_byte(1)
	write_byte(CSW_SVDEX)
	write_byte(pev(ent, pev_clip))
	message_end()


}

public Carbine_Shoot_Speed(id)
{
	static weapon_ent
	weapon_ent = fm_get_user_weapon_entity(id, CSW_SVDEX)
	
	if(weapon_ent) set_pdata_float(weapon_ent, 46, SVDEX_CARBINE_SPEED, 4)	
}

public fw_TraceAttack(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_connected(attacker))
		return HAM_IGNORED	
	
	if(get_user_weapon(attacker) == CSW_SVDEX && g_had_svdex[attacker] && g_svdex_mode[attacker] == SVDEX_MODE_CARBINE)
	{
		static Float:flEnd[3], Float:vecPlane[3], Float:Origin[3]
		
		get_tr2(ptr, TR_vecEndPos, flEnd)
		get_tr2(ptr, TR_vecPlaneNormal, vecPlane)
		
		
		//make_bullet(attacker, flEnd)
		/*
		if(is_user_alive(ent) && cs_get_user_team(ent) != cs_get_user_team(attacker))
		{
			create_blood(flEnd)
		} else if(!is_user_alive(ent)) {
			fake_smoke(attacker, ptr)
			make_bullet(attacker, flEnd)
		}
		*/
		SetHamParamFloat(3, SVDEX_CARBINE_DAMAGE)	
		/*
		if(is_user_alive(ent) && zb3_get_user_zombie(ent))
		{
			pev(attacker, pev_origin, Origin)
			hook_ent2(ent, Origin, Damage * 25.0)
		}
		*/
	}
	if(get_user_weapon(attacker) == CSW_QUADBARREL && g_had_qb[attacker])
	{
		static Float:flEnd[3], Float:Origin[3]
		get_tr2(ptr, TR_vecEndPos, flEnd)
		
		make_bullet(attacker, flEnd)
		pev(attacker, pev_origin, Origin)

		//static Damage_New
		//Damage_New = get_damage_body(get_tr2(ptr, TR_iHitgroup), random_float(random_start, random_end))
	
		SetHamParamFloat(3, QB_DAMAGE)	
		
		if(is_user_alive(ent) && zb3_get_user_zombie(ent))
		{
			pev(attacker, pev_origin, Origin)
			
			static Float:KnockBack, Float:CurrentDis
	
			CurrentDis = entity_range(ent, attacker)
			KnockBack = 500.0 - ((CurrentDis / 2048) * 500.0)

			hook_ent2(ent, Origin, Damage * KnockBack)
		} /*else if(!is_user_alive(ent)) {
			fake_smoke(attacker, ptr)
		}*/
	}	
	
	return HAM_HANDLED
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_SVDEX && g_had_svdex[id])
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001) 
	if(get_user_weapon(id) == CSW_QUADBARREL && g_had_qb[id])	
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(get_user_weapon(invoker) == CSW_SVDEX && g_had_svdex[invoker] && eventid == g_ak47_event)
	{
		playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)	
		Svdex_Shoot(invoker)
		
		return FMRES_SUPERCEDE
	}
	if(get_user_weapon(invoker) == CSW_QUADBARREL && g_had_qb[invoker] && eventid == g_event_qb)
	{
		playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)	
		QuadBarrel_Shoot(invoker)
		
		return FMRES_SUPERCEDE
	}
	
	return FMRES_HANDLED
}

public fake_smoke(id, trace_result)
{
	static Float:vecSrc[3], Float:vecEnd[3], TE_FLAG
	
	get_weapon_attachment(id, vecSrc)
	global_get(glb_v_forward, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)

	get_tr2(trace_result, TR_vecEndPos, vecSrc)
	get_tr2(trace_result, TR_vecPlaneNormal, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 2.5, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)
    
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecEnd[0])
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2] - 10.0)
	write_short(g_smokepuff_id)
	write_byte(2)
	write_byte(50)
	write_byte(TE_FLAG)
	message_end()
}

public Svdex_Shoot(id)
{
	if(!is_user_alive(id))
		return
		
	new ent
	ent = fm_get_user_weapon_entity(id, CSW_SVDEX)
	
	if(!pev_valid(ent))
		return

	if(get_user_weapon(id) == CSW_SVDEX && g_had_svdex[id] )
	{
		new Float:push[3]
		pev(id, pev_punchangle, push)
		
		push[0] += random_float(0.0, -2.0)
		push[1] += random_float(-2.0, 2.0)

		xs_vec_mul_scalar(push, SVDEX_CARBINE_RECOIL, push)
		set_pev(id, pev_punchangle,push)			
		
		set_weapon_anim(id, random_num(SVDEX_ANIM_SHOOT1, SVDEX_ANIM_SHOOT3))
		
		//emit_sound(id, CHAN_WEAPON, svdex_sound[0], 1.0, ATTN_NORM, 0, PITCH_LOW)
		emit_sound(id, CHAN_WEAPON, svdex_sound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}		
}

public QuadBarrel_Shoot(id)
{
	if(!is_user_alive(id))
		return
		
	new ent
	ent = fm_get_user_weapon_entity(id, CSW_QUADBARREL)
	
	if(!pev_valid(ent))
		return
	
	if(g_had_qb[id])
	{
		new Float:push[3]
		pev(id, pev_punchangle, push)
		
		push[0] += random_float(0.0, -2.0)
		push[1] += random_float(-2.0, 2.0)
		
		xs_vec_mul_scalar(push, QB_RECOIL, push)
		set_pev(id, pev_punchangle,push)			
		
		set_weapon_anim(id, random_num(QB_ANIM_SHOOT1, QB_ANIM_SHOOT2))
		emit_sound(id, CHAN_WEAPON, qb_sound[4], 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		set_pdata_float(id, 83, 0.3, 5)
	}	
}

public fw_Reload_Svdex(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	new id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_svdex[id])
		return HAM_IGNORED
	
	g_svdex_clip[id] = -1
	
	new bpammo = cs_get_user_bpammo(id, CSW_SVDEX)
	if (bpammo <= 0)
		return HAM_SUPERCEDE
	
	new iClip = get_pdata_int(ent, 51, 4)
	if(iClip >= SVDEX_CARBINE_CLIP)
		return HAM_SUPERCEDE		
	
	g_svdex_clip[id] = iClip
	g_svdex_reload[id] = 1
	
	return HAM_IGNORED
}

public fw_Reload_Svdex_Post(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	new id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_svdex[id])
		return HAM_IGNORED
	
	if (g_svdex_clip[id] == -1)
		return HAM_IGNORED
	
	new Float:reload_time = SVDEX_CARBINE_RELOADTIME
	
	set_pdata_int(ent, 51, g_svdex_clip[id], 4)
	set_pdata_float(ent, 48, reload_time, 4)
	set_pdata_float(id, 83, reload_time, 5)
	set_pdata_int(ent, 54, 1, 4)
	
	set_weapon_anim(id, SVDEX_ANIM_RELOAD)
	
	return HAM_IGNORED
}

public fw_Reload_QuadBarrel_Post(ent)
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_alive(id))
		return HAM_IGNORED
		
	if(g_had_qb[id])
	{
		static Cur_BpAmmo
		Cur_BpAmmo = cs_get_user_bpammo(id, CSW_QUADBARREL)

		if(Cur_BpAmmo > 0)
		{
			set_pdata_int(ent, 55, 0, 4)
			set_pdata_float(id, 83, QB_RELOADTIME, 5)
			set_pdata_float(ent, 48, QB_RELOADTIME + 0.5, 4)
			set_pdata_float(ent, 46, QB_RELOADTIME + 0.25, 4)
			set_pdata_float(ent, 47, QB_RELOADTIME + 0.25, 4)
			set_pdata_int(ent, 54, 1, 4)
			
			set_weapon_anim(id, QB_ANIM_RELOAD)		
		}
		
		return HAM_HANDLED
	}
	return HAM_IGNORED
	
}

public fw_PostFrame_Svdex(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	new id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_svdex[id])
		return HAM_IGNORED
	
	new Float:flNextAttack = get_pdata_float(id, 83, 5)
	new bpammo = cs_get_user_bpammo(id, CSW_SVDEX)
	
	new iClip = get_pdata_int(ent, 51, 4)
	new fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		new temp = min(SVDEX_CARBINE_CLIP - iClip, bpammo)
		
		set_pdata_int(ent, 51, iClip + temp, 4)
		cs_set_user_bpammo(id, CSW_SVDEX, bpammo - temp)		
		set_pdata_int(ent, 54, 0, 4)
		
		fInReload = 0
		g_svdex_reload[id] = 0
	}		
	
	return HAM_IGNORED
}

public fw_PostFrame_QuadBarrel(ent)
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_alive(id))
		return
	
	if(g_had_qb[id])
	{
		static iBpAmmo ; iBpAmmo = get_pdata_int(id, 381, 5)
		static iClip ; iClip = get_pdata_int(ent, 51, 4)
		static iMaxClip ; iMaxClip = QB_CLIP

		if(get_pdata_int(ent, 54, 4) && get_pdata_float(id, 83, 5) <= 0.0 )
		{
			new j = min(iMaxClip - iClip, iBpAmmo)
			set_pdata_int(ent, 51, iClip + j, 4)
			set_pdata_int(id, 381, iBpAmmo-j, 5)
			
			set_pdata_int(ent, 54, 0, 4)
			cs_set_weapon_ammo(ent, QB_CLIP)
		
			return
		}
	}	
}

public fw_AddToPlayer_Svdex_Post(ent, id)
{
	if(!is_valid_ent(ent))
		return HAM_IGNORED
	
	if(entity_get_int(ent, EV_INT_impulse) == SVDEX_CODE)
	{
		g_had_svdex[id] = 1
		entity_set_int(id, EV_INT_impulse, 0)
		
		return HAM_HANDLED
	}		
	
	return HAM_HANDLED
}

public fw_AddToPlayer_QuadBarrel_Post(ent, id)
{
	if(!is_valid_ent(ent))
		return HAM_IGNORED
		
	if(entity_get_int(ent, EV_INT_impulse) == QB_CODE)
	{
		g_had_qb[id] = 1
		entity_set_int(id, EV_INT_impulse, 0)
		
		return HAM_HANDLED
	}		

	return HAM_HANDLED
}

public fw_PrimaryAttack_Svdex(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static id; id = pev(ent,pev_owner)
	
	if(is_user_alive(id) && g_had_svdex[id])
		set_pdata_float(ent, 62, 0.01, 4)
	
	return HAM_HANDLED
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED
	if(get_user_weapon(id) == CSW_QUADBARREL && g_had_qb[id])
	{
		static CurButton
		CurButton = get_uc(uc_handle, UC_Buttons)	
		
		new ent = find_ent_by_owner(-1, weapon_quadbarrel, id)
		new Float:flNextAttack ; flNextAttack = get_pdata_float(id, 83, 5)
		
		if (!ent) return FMRES_IGNORED
		
		if(CurButton & IN_RELOAD)
		{
			if (flNextAttack > 0.0)
				return FMRES_IGNORED
			if(cs_get_weapon_ammo(ent) >= QB_CLIP)
			{
				set_weapon_anim(id, QB_ANIM_IDLE)
				
				// Block Button
				CurButton &= ~IN_RELOAD
				set_uc(uc_handle, UC_Buttons, CurButton)
				
				return FMRES_IGNORED
			}
		}	
		
		if((CurButton & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2))
		{
			if (flNextAttack > 0.0)
				return FMRES_IGNORED
			if(cs_get_weapon_ammo(ent) <= 0)
				return FMRES_IGNORED
			for(new i = 0; i < QB_CLIP; i++)
					ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
			//while(cs_get_weapon_ammo(ent) > 0)
			//	ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
		}
		
		return FMRES_IGNORED
	}
	
	if(get_user_weapon(id) != CSW_SVDEX || !g_had_svdex[id])
	{
		if(g_changing_mode[id]) Stop_Change(id)
		return FMRES_IGNORED
	}
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if((CurButton & IN_ATTACK) && !(pev(id, pev_oldbuttons) & IN_ATTACK))
	{
		if(g_svdex_mode[id] == SVDEX_MODE_GRENADE_LAUNCHER && !g_changing_mode[id] && pev(id, pev_weaponanim) != SVDEX2_ANIM_DRAW)
		{
			if(get_gametime() - SVDEX_GL_RELOAD > Last_Shoot_Grenade[id])
			{
				Grenade_Shoot(id)
				Last_Shoot_Grenade[id] = get_gametime()
			}
		}
	}
	
	if((CurButton & IN_ATTACK) && g_svdex_mode[id] == SVDEX_MODE_GRENADE_LAUNCHER)
	{
		CurButton &= ~IN_ATTACK
		set_uc(uc_handle, UC_Buttons, CurButton)
		
	}	
	
	if((CurButton & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2))
	{
		static WeaponEnt
		WeaponEnt = fm_get_user_weapon_entity(id, CSW_SVDEX)
		
		if(!pev_valid(WeaponEnt))
			return FMRES_IGNORED
		
		if(!g_changing_mode[id] /*&& pev(id, pev_weaponanim) == SVDEX_ANIM_IDLE*/)
		{
			g_changing_mode[id] = 1
			
			// Stop Weapon
			set_player_nextattack(id, CSW_SVDEX, SVDEX_CHANGE_TIME)
			
			// Play Anim Change
			set_weapon_anim(id, g_svdex_mode[id] == SVDEX_MODE_CARBINE ? SVDEX_ANIM_CHANGE : SVDEX2_ANIM_CHANGE)
			
			// Set Task
			set_task(SVDEX_CHANGE_TIME, "Change_Complete", id+TASK_CHANGING)
		} else {
			static fInReload
			fInReload = get_pdata_int(WeaponEnt, 54, 4)
			
			if(fInReload) Stop_Change(id)
		}
	}
	
	return FMRES_HANDLED
}

public fw_Touch(ent, id)
{
	if(!pev_valid(ent))
		return
		
	static ClassName[64]
	pev(ent, pev_classname, ClassName, sizeof(ClassName))
	
	if(!equal(ClassName, SVDEX_GRENADE_CLASSNAME))
		return
		
	// Get it's origin
	static Float:Origin[3]
	pev(ent, pev_origin, Origin)
	
	// Explosion
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_exp_sprid)
	write_byte(40)
	write_byte(30)
	write_byte(0)
	message_end()	
	
	static id
	id = pev(ent, pev_owner)
	
	if(is_user_connected(id))
		check_radius_damage(ent, id)
		
	engfunc(EngFunc_RemoveEntity, ent)
}

public check_radius_damage(ent, attacker)
{
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(cs_get_user_team(attacker) == cs_get_user_team(i))
			continue
		if(entity_range(ent, i) > SVDEX_GRENADE_HITRADIUS)
			continue
			
		Do_TakeDamage(ent, i, attacker, can_see_fm(ent, i))
	}
}

public Do_TakeDamage(Ent, Victim, Attacker, can_see)
{
	static Float:Damage, Float:CurrentDis
	
	CurrentDis = entity_range(Ent, Victim)
	Damage = SVDEX_GRENADE_DAMAGE - ((CurrentDis / SVDEX_GRENADE_HITRADIUS) * SVDEX_GRENADE_DAMAGE)
	
	if(Damage > 0)
	{
		static WeaponEnt
		WeaponEnt = fm_get_user_weapon_entity(Attacker, CSW_SVDEX)
		
		if(!pev_valid(WeaponEnt))
			WeaponEnt = 0
			
		//if(!can_see)
		//	Damage /= 2
			
		//if(!zb3_get_user_zombie(Attacker))
		//	Damage *= g_fDamageMulti[zb3_get_user_level(Attacker)]
			
		//do_TraceAttack(Attacker, Victim, Damage, DMG_BURN)
		ExecuteHamB(Ham_TakeDamage, Victim, WeaponEnt, Attacker, Damage, DMG_BURN)
	}	
}

public hook_ent2(ent, Float:VicOrigin[3], Float:speed)
{
	if(!pev_valid(ent))
		return
	
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]
	
	pev(ent, pev_origin, EntOrigin)
	
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	
	if (distance_f > 1.0)
	{
		new Float:fl_Time = distance_f / speed
		
		fl_Velocity[0] = ((VicOrigin[0] - EntOrigin[0]) / fl_Time) * -1
		fl_Velocity[1] = ((VicOrigin[1] - EntOrigin[1]) / fl_Time) * -1
		fl_Velocity[2] = ((VicOrigin[2] - EntOrigin[2]) / fl_Time) * -1
	} else {
		fl_Velocity[0] = 0.0
		fl_Velocity[1] = 0.0
		fl_Velocity[2] = 0.0
	}

	entity_set_vector(ent, EV_VEC_velocity, fl_Velocity)
}

public do_TraceAttack(attacker, victim, Float:damage, damagebits)
{
	static Float:Direction[3], Float:TempDirection[3], tr_handle
	static Float:AttackOrigin[3], Float:VicOrigin[3]
	
	pev(attacker, pev_origin, AttackOrigin)
	pev(victim, pev_origin, VicOrigin)
	tr_handle = create_tr2()
	
	TempDirection[0] = VicOrigin[0] - AttackOrigin[0]
	TempDirection[1] = VicOrigin[1] - AttackOrigin[1]
	TempDirection[2] = VicOrigin[2] - AttackOrigin[2]

	set_tr2(tr_handle, TR_pHit, victim)
	set_tr2(tr_handle, TR_iHitgroup, HIT_CHEST)
	//set_tr2(tr_handle, TR_vecEndPos, VicOrigin)
	
	xs_vec_normalize(TempDirection, Direction)
	ExecuteHamB(Ham_TraceAttack, victim, attacker, damage, Direction, tr_handle, damagebits)
	
	free_tr2(tr_handle)
}

public Stop_Change(id)
{
	if(!is_user_connected(id))
		return
	
	g_changing_mode[id] = 0
	remove_task(id+TASK_CHANGING)
}

public Change_Complete(id)
{
	id -= TASK_CHANGING
	
	if(!is_user_connected(id))
		return
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_SVDEX || !g_had_svdex[id])
		return
	
	Stop_Change(id)
	
	switch(g_svdex_mode[id])
	{
		case SVDEX_MODE_CARBINE: g_svdex_mode[id] = SVDEX_MODE_GRENADE_LAUNCHER
		case SVDEX_MODE_GRENADE_LAUNCHER: g_svdex_mode[id] = SVDEX_MODE_CARBINE
	}
	
	hide_crosshair(id, g_svdex_mode[id] == SVDEX_MODE_GRENADE_LAUNCHER ? 1 : 0)
	set_pev(id, pev_viewmodel2, svdex_model[g_svdex_mode[id] == SVDEX_MODE_CARBINE ? 0 : 1])
	
	set_weapon_anim(id, SVDEX_ANIM_IDLE)
	set_player_nextattack(id, CSW_SVDEX, 0.25)
	
	static Ent
	Ent = fm_get_user_weapon_entity(id, CSW_SVDEX)
	
	if(pev_valid(Ent)) 
	{
		set_pev(Ent, pev_bpammo, cs_get_user_bpammo(id, CSW_SVDEX))
		set_pev(Ent, pev_clip, cs_get_weapon_ammo(Ent))

		update_ammo(id, Ent, g_svdex_mode[id] == SVDEX_MODE_CARBINE ? 1 : 0)
	}	
}

public Grenade_Shoot(id)
{
	if(g_svdex_grenade[id] > 0)
	{
		set_player_nextattack(id, CSW_SVDEX, SVDEX_GL_RELOAD)
		
		do_fake_attack(id)
		set_weapon_anim(id, g_svdex_grenade[id] != 1 ? random_num(SVDEX2_ANIM_SHOOT1, SVDEX2_ANIM_SHOOT3) : SVDEX2_ANIM_SHOOT_LAST)
		
		/*
		new Float:push[3]
		
		push[0] = random_float(0.0, -2.0)
		push[1] = random_float(-2.0, 2.0)

		xs_vec_mul_scalar(push, SVDEX_CARBINE_RECOIL, push)
		
		set_pev(id, pev_punchangle,push)
		*/
		emit_sound(id, CHAN_WEAPON, svdex_sound[6], 1.0, ATTN_NORM, 0, PITCH_LOW)
		
		// Create Grenade
		Create_Grenade(id)
		
		// Update Ammo
		g_svdex_grenade[id]--
		
		// Update Ammo
		static Ent
		Ent = fm_get_user_weapon_entity(id, CSW_SVDEX)
		
		if(pev_valid(Ent)) 
		{
			set_pev(Ent, pev_bpammo, cs_get_user_bpammo(id, CSW_SVDEX))
			set_pev(Ent, pev_clip, cs_get_weapon_ammo(Ent))
	
			update_ammo(id, Ent, g_svdex_mode[id] == SVDEX_MODE_CARBINE ? 1 : 0)
		}	
	}
}

public do_fake_attack(id)
{
	if(!is_user_alive(id))
		return
	
	static svdex
	svdex = fm_find_ent_by_owner(-1, "weapon_knife", id)
	
	if(pev_valid(svdex)) ExecuteHam(Ham_Weapon_PrimaryAttack, svdex)	
}


public Create_Grenade(id)
{
	Shoot_Smoke_Effect(id)
	
	static grenade
	grenade = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	if(!pev_valid(grenade))
		return
	
	static Float:Origin[3], Float:Angles[3], Float:Velocity[3]
	
	get_position(id, WEAPON_ATTACH_F, WEAPON_ATTACH_R, WEAPON_ATTACH_U, Origin)	
	pev(id, pev_v_angle, Angles)
	
	set_pev(grenade, pev_classname, SVDEX_GRENADE_CLASSNAME)
	engfunc(EngFunc_SetModel, grenade, svdex_model[4])
	
	new Float:MinBox[3] = {-1.0, -1.0, -1.0}
	new Float:MaxBox[3] = {1.0, 1.0, 1.0}
	entity_set_vector(grenade, EV_VEC_mins, MinBox)
	entity_set_vector(grenade, EV_VEC_maxs, MaxBox)
	
	set_pev(grenade, pev_origin, Origin)
	set_pev(grenade, pev_v_angle, Angles)
	
	set_pev(grenade, pev_effects, 2)
	set_pev(grenade, pev_solid, 1)
	set_pev(grenade, pev_movetype, 10)
	set_pev(grenade, pev_owner, id)
	
	VelocityByAim(id, SVDEX_GRENADE_VELOCITY, Velocity)
	set_pev(grenade, pev_velocity, Velocity)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte(TE_BEAMFOLLOW)
	write_short(grenade)
	write_short(g_trail)
	write_byte(10)
	write_byte(5)
	write_byte(255)
	write_byte(255)
	write_byte(255)
	write_byte(255)
	message_end()
}

public Shoot_Smoke_Effect(id)
{
	static Float:Origin[3]
	get_position(id, WEAPON_ATTACH_F, WEAPON_ATTACH_R, WEAPON_ATTACH_U, Origin)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_EXPLOSION) 
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_smokepuff_id) 
	write_byte(10)
	write_byte(30)
	write_byte(14)
	message_end()	
}

public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED;
	
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
	
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED;
	
	static iOwner
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	
	if(equal(model, "models/w_ak47.mdl")) 
	{
		static weapon
		weapon = find_ent_by_owner(-1, weapon_svdex, entity)
		
		if(!is_valid_ent(weapon))
			return FMRES_IGNORED;
		
		if(g_had_svdex[iOwner])
		{
			entity_set_int(weapon, EV_INT_impulse, SVDEX_CODE)
			entity_set_model(entity, svdex_model[3])
			
			// Hide Weapon
			entity_set_int(entity, EV_INT_solid, SOLID_NOT)
			fm_set_rendering(entity, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0)
			
			g_had_svdex[iOwner] = 0
			
			return FMRES_SUPERCEDE
		}
	} else if(equal(model, "models/w_xm1014 .mdl")) {
		static weapon
		weapon = find_ent_by_owner(-1, weapon_quadbarrel, entity)
		
		if(!is_valid_ent(weapon))
			return FMRES_IGNORED;
		
		if(g_had_qb[iOwner])
		{
			entity_set_int(weapon, EV_INT_impulse, QB_CODE)
			entity_set_model(entity, qb_model[2])
			
			// Hide Weapon
			entity_set_int(entity, EV_INT_solid, SOLID_NOT)
			fm_set_rendering(entity, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0)
			
			g_had_qb[iOwner] = 0
			
			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED;
}

stock make_bullet(id, Float:Origin[3])
{
	// Find target
	new decal = random_num(41, 45)
	const loop_time = 2
	
	static Body, Target
	get_user_aiming(id, Target, Body, 999999)
	
	if(is_user_connected(Target))
		return
	
	for(new i = 0; i < loop_time; i++)
	{
		// Put decal on "world" (a wall)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_byte(decal)
		message_end()
		
		// Show sparcles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(id)
		write_byte(decal)
		message_end()
	}
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

stock set_player_nextattack(player, weapon_id, Float:NextTime)
{
	if(!is_user_connected(player))
		return
	
	const m_flNextPrimaryAttack = 46
	const m_flNextSecondaryAttack = 47
	const m_flTimeWeaponIdle = 48
	const m_flNextAttack = 83
	
	static weapon
	weapon = fm_get_user_weapon_entity(player, weapon_id)
	
	set_pdata_float(player, m_flNextAttack, NextTime, 5)
	if(pev_valid(weapon))
	{
		set_pdata_float(weapon, m_flNextPrimaryAttack , NextTime, 4)
		set_pdata_float(weapon, m_flNextSecondaryAttack, NextTime, 4)
		set_pdata_float(weapon, m_flTimeWeaponIdle, NextTime, 4)
	}
}

stock hide_crosshair(id, hide)
{
	if(!is_user_alive(id))
		return
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("HideWeapon"), _, id)
	if(hide)
		write_byte((1<<6))
	else
		write_byte(0)
	message_end()	
}

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

public can_see_fm(entindex1, entindex2)
{
	if (!entindex1 || !entindex2)
		return false

	if (pev_valid(entindex1) && pev_valid(entindex1))
	{
		new flags = pev(entindex1, pev_flags)
		if (flags & EF_NODRAW || flags & FL_NOTARGET)
		{
			return 0
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
			return 0
		} 
		else 
		{
			new Float:flFraction
			get_tr2(0, TraceResult:TR_flFraction, flFraction)
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
			{
				return 1
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
					return 1
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
						return 1
					}
				}
			}
		}
	}
	return 0
}

stock get_weapon_attachment(id, Float:output[3], Float:fDis = 40.0)
{ 
	new Float:vfEnd[3], viEnd[3] 
	get_user_origin(id, viEnd, 3)  
	IVecFVec(viEnd, vfEnd) 
	
	new Float:fOrigin[3], Float:fAngle[3]
	
	pev(id, pev_origin, fOrigin) 
	pev(id, pev_view_ofs, fAngle)
	
	xs_vec_add(fOrigin, fAngle, fOrigin) 
	
	new Float:fAttack[3]
	
	xs_vec_sub(vfEnd, fOrigin, fAttack)
	xs_vec_sub(vfEnd, fOrigin, fAttack) 
	
	new Float:fRate
	
	fRate = fDis / vector_length(fAttack)
	xs_vec_mul_scalar(fAttack, fRate, fAttack)
	
	xs_vec_add(fOrigin, fAttack, output)
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
