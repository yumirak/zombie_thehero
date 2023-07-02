#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombie_thehero2>
#include <fun>

#define PLUGIN "[Zombie: The Hero] Addon: SupplyBox Item"
#define VERSION "2.0"
#define AUTHOR "Dias"

// ===== Vars
new precache_forward, g_bloodspray, g_blood, g_ham_bot, g_attacking[33]
new Float:cl_pushangle[33][3]

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const NADE_WEAPONS_BIT_SUM = ((1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG))

new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

#define m_fAccuary 62			
			
// Dual MP7A1
const pev_check = pev_impulse

#define CSW_DMP7A1 CSW_P90
#define weapon_dmp7a1 "weapon_p90"
#define DMP7A1_SECRET_KEY 1541913

new const dmp7a1_model[3][] = 
{
	"models/zombie_thehero/supplybox_item/v_dual_mp7a1.mdl",
	"models/zombie_thehero/supplybox_item/p_dual_mp7a1.mdl",
	"models/zombie_thehero/supplybox_item/w_dual_mp7a1.mdl"
}

new const dmp7a1_sound[5][] =
{
	"weapons/dmp7-1.wav",
	"weapons/dmp7_drop.wav",
	"weapons/dmp7_draw.wav",
	"weapons/mp7_foley2.wav",
	"weapons/mp7_foley4.wav"
}

enum
{
	DMP7A1_ANIM_IDLE = 0,
	DMP7A1_ANIM_RELOAD,
	DMP7A1_ANIM_DRAW,	
	DMP7A1_ANIM_SHOOT_LEFT1,
	DMP7A1_ANIM_SHOOT_RIGHT1,
	DMP7A1_ANIM_SHOOT_LEFT2
}

new g_had_dmp7a1[33], g_dmp7a1_clip[33], g_dmp7a1_reload[33], dmp7a1_event, g_shoot_where[33]

#define DMP7A1_DEFAULT_BPAMMO 240
#define DMP7A1_DEFAULT_CLIP 80
#define DMP7A1_DAMAGE 25.0
#define DMP7A1_RELOAD_TIME 3.0
#define DMP7A1_RECOIL 0.7
#define DMP7A1_SPEED 0.85

// AK47 - 60R
const pev_check = pev_impulse

#define CSW_AK4760R CSW_AK47
#define weapon_ak4760r "weapon_ak47"
#define AK4760R_SECRET_KEY 1541914

new const ak4760r_model[3][] = 
{
	"models/zombie_thehero/supplybox_item/v_ak47_60r.mdl",
	"models/zombie_thehero/supplybox_item/p_ak47_60r.mdl",
	"models/zombie_thehero/supplybox_item/w_ak47_60r.mdl"
}

new const ak4760r_sound[4][] =
{
	"weapons/ak47_60r_shoot.wav",
	"weapons/ak47_clipin.wav",
	"weapons/ak47_clipout.wav",
	"weapons/ak47_boltpull.wav"
}

enum
{
	AK4760R_ANIM_IDLE = 0,
	AK4760R_ANIM_RELOAD,
	AK4760R_ANIM_DRAW,	
	AK4760R_ANIM_SHOOT1,
	AK4760R_ANIM_SHOOT2,
	AK4760R_ANIM_SHOOT3
}

#define AK4760R_DEFAULT_BPAMMO 180
#define AK4760R_DEFAULT_CLIP 60
#define AK4760R_DAMAGE 62.0
#define AK4760R_RELOAD_TIME 2.5
#define AK4760R_RECOIL 0.4
#define AK4760R_SPEED 1.0 

new g_had_ak4760r[33], g_ak4760r_clip[33], g_ak4760r_reload[33], ak4760r_event, g_ak4760r_zoom[33]

// AK47 - 60R
const pev_check = pev_impulse

#define CSW_DNH CSW_ELITE
#define weapon_dnh "weapon_elite"
#define DNH_SECRET_KEY 1541915

new const dnh_model[3][] = 
{
	"models/zombie_thehero/supplybox_item/v_ddeagle.mdl",
	"models/zombie_thehero/supplybox_item/p_ddeagle.mdl",
	"models/zombie_thehero/supplybox_item/w_ddeagle.mdl"
}

new const dnh_sound[6][] =
{
	"weapons/dde-1.wav",
	"weapons/dde_clipoff.wav",
	"weapons/dde_twirl.wav",
	"weapons/dde_clipin.wav",
	"weapons/dde_clipout.wav",
	"weapons/dde_load.wav"
}

enum
{
	DNH_ANIM_IDLE = 0,
	DNH_ANIM_IDLE_LEFT_EMPTY,
	DNH_ANIM_SHOOT_LEFT1,
	DNH_ANIM_SHOOT_LEFT2,
	DNH_ANIM_SHOOT_LEFT3,
	DNH_ANIM_SHOOT_LEFT4,
	DNH_ANIM_SHOOT_LEFT5,
	DNH_ANIM_SHOOT_LEFT_LAST,
	DNH_ANIM_SHOOT_RIGHT1,
	DNH_ANIM_SHOOT_RIGHT2,
	DNH_ANIM_SHOOT_RIGHT3,
	DNH_ANIM_SHOOT_RIGHT4,
	DNH_ANIM_SHOOT_RIGHT5,
	DNH_ANIM_SHOOT_RIGHT_LAST,
	DNH_ANIM_RELOAD,
	DNH_ANIM_DRAW
}

const m_szAnimExtention = 492

new g_had_dnh[33], g_dnh_clip[33], g_dnh_reload[33], dnh_event1, dnh_event2

#define DNH_DEFAULT_BPAMMO 180
#define DNH_DEFAULT_CLIP 28
#define DNH_DAMAGE 47.0
#define DNH_RELOAD_TIME 4.6
#define DNH_RECOIL 0.3

new g_smokepuff_id

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_dictionary("zombie_thehero2.txt")
	
	// Events
	register_event("CurWeapon", "event_curweapon", "be", "1=1")
	register_event("DeathMsg", "event_death", "a")
	
	// Fakemeta Forwards
	unregister_forward(FM_PrecacheEvent, precache_forward, 1)
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_forward(FM_SetModel, "fw_SetModel")
	//register_forward(FM_CmdStart, "fw_CmdStart")
	
	// Ham Forwards
	RegisterHam(Ham_Spawn, "player", "fw_Ham_Spawn_Post", 1)
	
	// Dual MP7A1
	RegisterHam(Ham_Item_AddToPlayer, weapon_dmp7a1, "fw_Ham_AddToPlayer_Dmp7a1", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_dmp7a1, "fw_Ham_PriAttack_Dmp7a1")	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_dmp7a1, "fw_Ham_PriAttack_Post_Dmp7a1", 1)	
	RegisterHam(Ham_Weapon_Reload, weapon_dmp7a1, "fw_Ham_Reload_Dmp7a1")
	RegisterHam(Ham_Weapon_Reload, weapon_dmp7a1, "fw_Ham_Reload_Post_Dmp7a1", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_dmp7a1, "fw_Ham_PostFrame_Dmp7a1")
	RegisterHam(Ham_CS_Weapon_SendWeaponAnim, weapon_dmp7a1, "fw_Ham_SendAnim_Dmp7a1", 1)	
	
	// AK47 - 60R
	RegisterHam(Ham_Item_AddToPlayer, weapon_ak4760r, "fw_Ham_AddToPlayer_Ak4760r", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_ak4760r, "fw_Ham_PriAttack_Ak4760r")	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_ak4760r, "fw_Ham_PriAttack_Post_Ak4760r", 1)	
	RegisterHam(Ham_Weapon_Reload, weapon_ak4760r, "fw_Ham_Reload_Ak4760r")
	RegisterHam(Ham_Weapon_Reload, weapon_ak4760r, "fw_Ham_Reload_Post_Ak4760r", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_ak4760r, "fw_Ham_PostFrame_Ak4760r")
	
	// Dual NightHawk
	RegisterHam(Ham_Item_AddToPlayer, weapon_dnh, "fw_Ham_AddToPlayer_Dnh", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_dnh, "fw_Ham_PriAttack_Dnh")	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_dnh, "fw_Ham_PriAttack_Post_Dnh", 1)	
	RegisterHam(Ham_Weapon_Reload, weapon_dnh, "fw_Ham_Reload_Dnh")
	RegisterHam(Ham_Weapon_Reload, weapon_dnh, "fw_Ham_Reload_Post_Dnh", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_dnh, "fw_Ham_PostFrame_Dnh")
	RegisterHam(Ham_CS_Weapon_SendWeaponAnim, weapon_dnh, "fw_Ham_SendAnim_Dnh", 1)	
	
	// Other Ham
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_Ham_TraceAttack")
	RegisterHam(Ham_TraceAttack, "player", "fw_Ham_TraceAttack")	
	
	register_clcmd("dias_get_dmp7a1", "get_dmp7a1")
	register_clcmd("dias_get_ak47long", "get_ak4760r")
	register_clcmd("dias_get_dnh", "get_dnh")
}

public plugin_precache()
{
	new i
	for(i = 0; i < sizeof(dmp7a1_model); i++)
		engfunc(EngFunc_PrecacheModel, dmp7a1_model[i])
	for(i = 0; i < sizeof(dmp7a1_sound); i++)
		engfunc(EngFunc_PrecacheSound, dmp7a1_sound[i])
	for(i = 0; i < sizeof(ak4760r_model); i++)
		engfunc(EngFunc_PrecacheModel, ak4760r_model[i])
	for(i = 0; i < sizeof(ak4760r_sound); i++)
		engfunc(EngFunc_PrecacheSound, ak4760r_sound[i])	
	for(i = 0; i < sizeof(dnh_model); i++)
		engfunc(EngFunc_PrecacheModel, dnh_model[i])
	for(i = 0; i < sizeof(dnh_sound); i++)
		engfunc(EngFunc_PrecacheSound, dnh_sound[i])	
	
	precache_forward = register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	
	g_smokepuff_id = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	g_blood = precache_model("sprites/blood.spr")
	g_bloodspray = precache_model("sprites/bloodspray.spr")		
}

public plugin_natives()
{
	register_native("zb3_supplybox_random_getitem", "native_getitem", 1)
}

public native_getitem(id, hero)
{
	if(!is_user_alive(id))
		return
	if(hero) {
		//zb3_set_lock_hero(id, 0)
		refill_ammo(id)
		get_dnh(id, 1)
		//zb3_set_lock_hero(id, 1)
	}
	else
	{
		get_random_weapon(id)
	}	
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal("events/p90.sc", name))
		dmp7a1_event = get_orig_retval()
	else if(equal("events/ak47.sc", name))
		ak4760r_event = get_orig_retval()	
	else if(equal("events/elite_left.sc", name))
		dnh_event1 = get_orig_retval()
	else if(equal("events/elite_right.sc", name))
		dnh_event2 = get_orig_retval()		
}

public client_putinserver(id)
{
	if(!g_ham_bot && is_user_bot(id))
	{
		g_ham_bot = 1
		set_task(0.1, "do_register_ham_bot", id)
	}
}

public do_register_ham_bot(id)
{
	// Ham Forwards
	RegisterHamFromEntity(Ham_Spawn, id, "fw_Ham_Spawn_Post", 1)

	// Other Ham
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_Ham_TraceAttack")		
}

public zb3_user_infected(id)
{
	g_had_dmp7a1[id] = 0
	g_had_ak4760r[id] = 0
	g_had_dnh[id] = 0
	
	g_ak4760r_zoom[id] = 0
	g_attacking[id] = 0	
}

public get_random_weapon(id)
{
	switch(random_num(0, 100))
	{
		case 0..30: refill_ammo(id)
		case 31..40: zb3_set_user_nvg(id, 1, 1, 1, 0)
		case 41.. 60: get_dnh(id, 0)
		case 61..80: get_dmp7a1(id)
		case 81..100: get_ak4760r(id)
	}
}

public refill_ammo(id)
{
	if(!is_user_alive(id))
		return
		
	give_nade(id, 1)
	//give_ammo(id)
	zb3_weapon_refill(id)
}

public get_dnh(id, hero)
{
	drop_weapons(id, 2)
	
	g_had_dnh[id] = 1
	fm_give_item(id, weapon_dnh)
	
	static ent
	ent = fm_get_user_weapon_entity(id, CSW_DNH)	
	
	if(pev_valid(ent))
		cs_set_weapon_ammo(ent, DNH_DEFAULT_CLIP)
	cs_set_user_bpammo(id, CSW_DNH, DNH_DEFAULT_BPAMMO)
	
	if(!hero)
	{
		new buffer[256], name[64]
		get_user_name(id, name, sizeof(name))
		
		format(buffer, charsmax(buffer), "%L", LANG_PLAYER, "NOTICE_ITEM_PICKUP_BROADCAST", name, "Dual NightHawk")
		
		for (new i = 1; i <= get_maxplayers(); i++)
		{
			 if (!is_user_connected(i) || i == id) continue;
			 
			 SendCenterText(i, buffer)
		}
		
		format(buffer, charsmax(buffer), "%L", LANG_PLAYER, "NOTICE_ITEM_PICKUP", "Dual NightHawk")
		SendCenterText(id, buffer)
	}
}

public get_dnh_hero(id)
{
	drop_weapons(id, 2)
	
	g_had_dnh[id] = 1
	fm_give_item(id, weapon_dnh)
	
	static ent
	ent = fm_get_user_weapon_entity(id, CSW_DNH)	
	
	if(pev_valid(ent))
		cs_set_weapon_ammo(ent, DNH_DEFAULT_CLIP)
	cs_set_user_bpammo(id, CSW_DNH, DNH_DEFAULT_BPAMMO)
}

public get_dmp7a1(id)
{
	drop_weapons(id, 1)
	
	g_had_dmp7a1[id] = 1
	fm_give_item(id, weapon_dmp7a1)
	
	static ent
	ent = fm_get_user_weapon_entity(id, CSW_DMP7A1)	
	
	if(pev_valid(ent))
		cs_set_weapon_ammo(ent, DMP7A1_DEFAULT_CLIP)
	cs_set_user_bpammo(id, CSW_DMP7A1, DMP7A1_DEFAULT_BPAMMO)
	
	new buffer[256], name[64]
	get_user_name(id, name, sizeof(name))
	
	format(buffer, charsmax(buffer), "%L", LANG_PLAYER, "NOTICE_ITEM_PICKUP_BROADCAST", name, "Dual MP7A1")
	
	for (new i = 1; i <= get_maxplayers(); i++)
	{
		 if (!is_user_connected(i) || i == id) continue;
		 
		 SendCenterText(i, buffer)
	}
	
	format(buffer, charsmax(buffer), "%L", LANG_PLAYER, "NOTICE_ITEM_PICKUP", "Dual MP7A1")
	SendCenterText(id, buffer)	
}

public get_ak4760r(id)
{
	drop_weapons(id, 1)
	
	g_had_ak4760r[id] = 1
	g_ak4760r_zoom[id] = 0
	
	fm_give_item(id, weapon_ak4760r)
	
	static ent
	ent = fm_get_user_weapon_entity(id, CSW_AK4760R)	
	
	if(pev_valid(ent))
		cs_set_weapon_ammo(ent, AK4760R_DEFAULT_CLIP)
	cs_set_user_bpammo(id, CSW_AK4760R, AK4760R_DEFAULT_BPAMMO)
	
	new buffer[256], name[64]
	get_user_name(id, name, sizeof(name))
	
	format(buffer, charsmax(buffer), "%L", LANG_PLAYER, "NOTICE_ITEM_PICKUP_BROADCAST", name, "AK47 - 60R")
	
	for (new i = 1; i <= get_maxplayers(); i++)
	{
		 if (!is_user_connected(i) || i == id) continue;
		 
		 SendCenterText(i, buffer)
	}
	
	format(buffer, charsmax(buffer), "%L", LANG_PLAYER, "NOTICE_ITEM_PICKUP", "AK47 - 60R")
	SendCenterText(id, buffer)		
}

// ======================== Main Public ======================
public event_curweapon(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return PLUGIN_HANDLED

	if(get_user_weapon(id) == CSW_DMP7A1 && g_had_dmp7a1[id])
	{
		set_pev(id, pev_viewmodel2, dmp7a1_model[0])
		set_pev(id, pev_weaponmodel2, dmp7a1_model[1])
		
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_DMP7A1)
		
		if(pev_valid(ent))
		{
			static Float:Delay, Float:iSpeed
			
			iSpeed = DMP7A1_SPEED
			Delay = get_pdata_float(ent, 46, 4) * iSpeed
			
			if(Delay > 0.0)
				set_pdata_float(ent, 46, Delay, 4)	
		}
	} else if(get_user_weapon(id) == CSW_AK4760R && g_had_ak4760r[id]) {
		set_pev(id, pev_viewmodel2, ak4760r_model[0])
		set_pev(id, pev_weaponmodel2, ak4760r_model[1])
		
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_AK4760R)
		
		if(pev_valid(ent))
		{
			static Float:Delay, Float:iSpeed
			
			iSpeed = AK4760R_SPEED
			Delay = get_pdata_float(ent, 46, 4) * iSpeed
			
			if(Delay > 0.0)
				set_pdata_float(ent, 46, Delay, 4)	
		}
	} else if(get_user_weapon(id) == CSW_DNH && g_had_dnh[id]) {
		set_pev(id, pev_viewmodel2, dnh_model[0])
		set_pev(id, pev_weaponmodel2, dnh_model[1])
	}
	
	return PLUGIN_HANDLED
}	

public event_death()
{
	new id = read_data(2)
	
	g_had_dmp7a1[id] = 0
	g_had_ak4760r[id] = 0
	g_had_dnh[id] = 0
	
	g_ak4760r_zoom[id] = 0
	g_attacking[id] = 0	
}

// ======================== Fakemeta Forwards ======================
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED
	
	if(get_user_weapon(id) == CSW_DMP7A1 && g_had_dmp7a1[id])
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001) 
	else if(get_user_weapon(id) == CSW_AK4760R && g_had_ak4760r[id])
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001) 
	else if(get_user_weapon(id) == CSW_DNH && g_had_dnh[id])
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001) 
		
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	
		
	if(eventid == dmp7a1_event && g_had_dmp7a1[invoker])
	{
		playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
		
		if(g_shoot_where[invoker] == 1) set_weapon_anim(invoker, 27)
		else if(g_shoot_where[invoker] == 1) set_weapon_anim(invoker, 28)

		return FMRES_SUPERCEDE
	}
	if(eventid == ak4760r_event && g_had_ak4760r[invoker])
	{
		playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)	
		return FMRES_SUPERCEDE
	}
	if(eventid == dnh_event1 && g_had_dnh[invoker])
	{
		playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)	
		
		new Float:push[3]
		pev(invoker, pev_punchangle, push)
		xs_vec_sub(push, cl_pushangle[invoker], push)
		
		push[1] = random_float(0.1, 1.5)
		g_shoot_where[invoker] = 1
		set_weapon_anim(invoker, random_num(DNH_ANIM_SHOOT_LEFT1, DNH_ANIM_SHOOT_LEFT5))

		xs_vec_mul_scalar(push, DNH_RECOIL, push)
		xs_vec_add(push, cl_pushangle[invoker], push)
		
		//set_pev(invoker, pev_punchangle, push)		
		emit_sound(invoker, CHAN_WEAPON, dnh_sound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		return FMRES_SUPERCEDE
	}
	if(eventid == dnh_event2 && g_had_dnh[invoker])
	{
		playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)		
		
		new Float:push[3]
		pev(invoker, pev_punchangle, push)
		xs_vec_sub(push, cl_pushangle[invoker], push)
		
		push[1] = random_float(-0.1, -1.5)
		g_shoot_where[invoker] = 2
		set_weapon_anim(invoker, random_num(DNH_ANIM_SHOOT_RIGHT1, DNH_ANIM_SHOOT_RIGHT5))

		xs_vec_mul_scalar(push, DNH_RECOIL, push)
		xs_vec_add(push, cl_pushangle[invoker], push)
		
		set_pev(invoker, pev_punchangle, push)		
		emit_sound(invoker, CHAN_WEAPON, dnh_sound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		return FMRES_SUPERCEDE
	}
	
	return FMRES_HANDLED
}

public fw_SetModel(ent, model[])
{
	if(!is_valid_ent(ent))
		return FMRES_IGNORED
	
	static classname[33]
	pev(ent, pev_classname, classname, sizeof(classname))
	
	if(!equal(classname, "weaponbox"))
		return FMRES_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(equal(model, "models/w_p90.mdl"))
	{
		static weapon
		weapon = find_ent_by_owner(-1, weapon_dmp7a1, ent)	
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_dmp7a1[id])
		{
			g_had_dmp7a1[id] = 0
			
			engfunc(EngFunc_SetModel, ent, dmp7a1_model[2])
			set_pev(weapon, pev_check, DMP7A1_SECRET_KEY)

			return FMRES_SUPERCEDE
		}
	} else if(equal(model, "models/w_ak47.mdl")) {
		static weapon
		weapon = find_ent_by_owner(-1, weapon_ak4760r, ent)	
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_ak4760r[id])
		{
			g_had_ak4760r[id] = 0
			
			engfunc(EngFunc_SetModel, ent, ak4760r_model[2])
			set_pev(weapon, pev_check, AK4760R_SECRET_KEY)

			return FMRES_SUPERCEDE
		}
	} else if(equal(model, "models/w_elite.mdl")) {
		static weapon
		weapon = find_ent_by_owner(-1, weapon_dnh, ent)	
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_dnh[id])
		{
			g_had_dnh[id] = 0
			
			engfunc(EngFunc_SetModel, ent, dnh_model[2])
			set_pev(weapon, pev_check, DNH_SECRET_KEY)

			return FMRES_SUPERCEDE
		}
	}	
	
	return FMRES_IGNORED
}
/*
public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_connected(id) || !is_user_alive(id))
		return FMRES_IGNORED
	
	if(get_user_weapon(id) == CSW_AK4760R && g_had_ak4760r[id])
	{
		static CurButton
		CurButton = get_uc(uc_handle, UC_Buttons)
		
		if((CurButton & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2))
		{
			if(pev(id, pev_weaponanim) != AK4760R_ANIM_RELOAD && pev(id, pev_weaponanim) != AK4760R_ANIM_DRAW)
			{
				if(!g_ak4760r_zoom[id])
				{
					g_ak4760r_zoom[id] = 1
					cs_set_user_zoom(id, CS_SET_AUGSG552_ZOOM, 1)
				} else {
					g_ak4760r_zoom[id] = 0
					cs_set_user_zoom(id, CS_RESET_ZOOM, 1)
				}
			} else {
				g_ak4760r_zoom[id] = 0
				cs_set_user_zoom(id, CS_RESET_ZOOM, 1)			
			}
		}
	}
	
	return FMRES_HANDLED
}
*/
// ======================== Ham Forwards ======================
public fw_Ham_Spawn_Post(id)
{
	if(is_user_connected(id))
	{
		g_had_dmp7a1[id] = 0
		g_had_ak4760r[id] = 0
		g_had_dnh[id] = 0
		
		g_ak4760r_zoom[id] = 0
		g_attacking[id] = 0
	}
}

public fw_Ham_TraceAttack(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_connected(attacker))
		return HAM_IGNORED
	
	if(get_user_weapon(attacker) == CSW_DMP7A1 && g_had_dmp7a1[attacker])
	{
		static Float:flEnd[3]
		get_tr2(ptr, TR_vecEndPos, flEnd)
		
		//make_bullet(attacker, flEnd)
		//if(!is_user_alive(ent))	fake_smoke(attacker, ptr)

		SetHamParamFloat(3, DMP7A1_DAMAGE)
	} else if(get_user_weapon(attacker) == CSW_AK4760R && g_had_ak4760r[attacker]){
		static Float:flEnd[3]
		get_tr2(ptr, TR_vecEndPos, flEnd)
		
		//make_bullet(attacker, flEnd)
		//if(!is_user_alive(ent))	fake_smoke(attacker, ptr)
		
		SetHamParamFloat(3, AK4760R_DAMAGE)		
	} else if(get_user_weapon(attacker) == CSW_DNH && g_had_dnh[attacker]){
		static Float:flEnd[3]
		get_tr2(ptr, TR_vecEndPos, flEnd)
		
		//make_bullet(attacker, flEnd)
		//if(!is_user_alive(ent))	fake_smoke(attacker, ptr)
		
		SetHamParamFloat(3, DNH_DAMAGE)
	}
	
	return HAM_HANDLED
}

public get_damage_body(body, Float:damage)
{
	switch(body)
	{
		case HIT_HEAD: damage *= 4.0
		case HIT_CHEST: damage *= 1.5
		case HIT_STOMACH: damage *= 1.25
		default: damage *= 1.0
	}

	return floatround(damage)
}

public fw_Ham_AddToPlayer_Dmp7a1(ent, id)
{
	if(pev(ent, pev_check) == DMP7A1_SECRET_KEY)
	{
		g_had_dmp7a1[id] = 1
		set_pev(ent, pev_check, 0)
	}			
}

public fw_Ham_AddToPlayer_Ak4760r(ent, id)
{
	if(pev(ent, pev_check) == AK4760R_SECRET_KEY)
	{
		g_had_ak4760r[id] = 1
		set_pev(ent, pev_check, 0)
	}			
}

public fw_Ham_AddToPlayer_Dnh(ent, id)
{
	if(pev(ent, pev_check) == DNH_SECRET_KEY)
	{
		g_had_dnh[id] = 1
		set_pev(ent, pev_check, 0)
	}			
}

public fw_Ham_PriAttack_Dmp7a1(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	new id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_dmp7a1[id])
		return HAM_IGNORED

	set_pdata_float(ent, 62, 1.0, 4)
		
	g_attacking[id] = 1
	pev(id, pev_punchangle, cl_pushangle[id])
	
	return HAM_HANDLED
}

public fw_Ham_PriAttack_Ak4760r(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	new id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_ak4760r[id])
		return HAM_IGNORED

	set_pdata_float(ent, 62, 1.0, 4)
		
	g_attacking[id] = 1
	pev(id, pev_punchangle, cl_pushangle[id])
	
	return HAM_HANDLED
}

public fw_Ham_PriAttack_Dnh(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	new id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_dnh[id])
		return HAM_IGNORED

	set_pdata_float(ent, 62, 1.0, 4)
		
	g_attacking[id] = 1
	pev(id, pev_punchangle, cl_pushangle[id])
	
	return HAM_HANDLED
}

public fw_Ham_PriAttack_Post_Dmp7a1(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	new id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_dmp7a1[id])
		return HAM_IGNORED
	
	static clip
	clip = cs_get_weapon_ammo(ent)
	
	if(clip > 0)
	{
		new Float:push[3]
		pev(id, pev_punchangle, push)
		xs_vec_sub(push, cl_pushangle[id], push)
		
		if(!g_shoot_where[id])
		{	
			push[1] = random_float(0.1, 1.5)
			g_shoot_where[id] = 1
			
			set_weapon_anim(id, DMP7A1_ANIM_SHOOT_LEFT1)
		} else if(g_shoot_where[id]) {
			push[1] = random_float(-0.1, -1.5)
			g_shoot_where[id] = 0
			
			set_weapon_anim(id, DMP7A1_ANIM_SHOOT_RIGHT1)
		}		

		xs_vec_mul_scalar(push, DMP7A1_RECOIL, push)
		xs_vec_add(push, cl_pushangle[id], push)
		
		set_pev(id, pev_punchangle, push)		
		emit_sound(id, CHAN_WEAPON, dmp7a1_sound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	
	g_attacking[id] = 0
	
	return HAM_HANDLED
}

public fw_Ham_PriAttack_Post_Ak4760r(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	new id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_ak4760r[id])
		return HAM_IGNORED
	
	static clip
	clip = cs_get_weapon_ammo(ent)
	
	if(clip > 0)
	{
		new Float:push[3]
		pev(id, pev_punchangle, push)
		
		xs_vec_sub(push, cl_pushangle[id], push)
		xs_vec_mul_scalar(push, AK4760R_RECOIL, push)
		xs_vec_add(push, cl_pushangle[id], push)
		set_pev(id, pev_punchangle, push)		
		
		set_weapon_anim(id, random_num(AK4760R_ANIM_SHOOT1, AK4760R_ANIM_SHOOT2))
		emit_sound(id, CHAN_WEAPON, ak4760r_sound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	
	g_attacking[id] = 0
	
	return HAM_HANDLED
}

public fw_Ham_PriAttack_Post_Dnh(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	new id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_dnh[id] || !g_attacking[id])
		return HAM_IGNORED

	static clip
	clip = cs_get_weapon_ammo(ent)
	
	if(clip > 0)
	{

	}
	
	g_attacking[id] = 0
	
	return HAM_HANDLED
}

public fw_Ham_Reload_Dmp7a1(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	new id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_dmp7a1[id])
		return HAM_IGNORED
		
	g_dmp7a1_clip[id] = -1
	
	new bpammo = cs_get_user_bpammo(id, CSW_DMP7A1)
	if (bpammo <= 0)
		return HAM_SUPERCEDE
	
	new iClip = get_pdata_int(ent, 51, 4)
	if(iClip >= DMP7A1_DEFAULT_CLIP)
		return HAM_SUPERCEDE		
	
	g_dmp7a1_clip[id] = iClip
	g_dmp7a1_reload[id] = 1

	return HAM_IGNORED
}

public fw_Ham_Reload_Ak4760r(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	new id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_ak4760r[id])
		return HAM_IGNORED
		
	g_ak4760r_clip[id] = -1
	
	new bpammo = cs_get_user_bpammo(id, CSW_AK4760R)
	if (bpammo <= 0)
		return HAM_SUPERCEDE
	
	new iClip = get_pdata_int(ent, 51, 4)
	if(iClip >= AK4760R_DEFAULT_CLIP)
		return HAM_SUPERCEDE		
	
	g_ak4760r_clip[id] = iClip
	g_ak4760r_reload[id] = 1

	return HAM_IGNORED
}

public fw_Ham_Reload_Dnh(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	new id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_dnh[id])
		return HAM_IGNORED
		
	g_dnh_clip[id] = -1
	
	new bpammo = cs_get_user_bpammo(id, CSW_DNH)
	if (bpammo <= 0)
		return HAM_SUPERCEDE
	
	new iClip = get_pdata_int(ent, 51, 4)
	if(iClip >= DNH_DEFAULT_CLIP)
		return HAM_SUPERCEDE		
	
	g_dnh_clip[id] = iClip
	g_dnh_reload[id] = 1

	return HAM_IGNORED
}

public fw_Ham_Reload_Post_Dmp7a1(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_dmp7a1[id])
		return HAM_IGNORED
		
	if (g_dmp7a1_clip[id] == -1)
		return HAM_IGNORED

	set_pdata_int(ent, 51, g_dmp7a1_clip[id], 4)
	set_pdata_float(ent, 48, DMP7A1_RELOAD_TIME, 4)
	set_pdata_float(id, 83, DMP7A1_RELOAD_TIME, 5)
	set_pdata_int(ent, 54, 1, 4)
	
	set_weapon_anim(id, DMP7A1_ANIM_RELOAD)
	
	return HAM_IGNORED
}

public fw_Ham_Reload_Post_Ak4760r(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_ak4760r[id])
		return HAM_IGNORED
		
	if (g_ak4760r_clip[id] == -1)
		return HAM_IGNORED

	set_pdata_int(ent, 51, g_ak4760r_clip[id], 4)
	set_pdata_float(ent, 48, AK4760R_RELOAD_TIME, 4)
	set_pdata_float(id, 83, AK4760R_RELOAD_TIME, 5)
	set_pdata_int(ent, 54, 1, 4)
	
	set_weapon_anim(id, AK4760R_ANIM_RELOAD)
	
	return HAM_IGNORED
}

public fw_Ham_Reload_Post_Dnh(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_dnh[id])
		return HAM_IGNORED
		
	if (g_dnh_clip[id] == -1)
		return HAM_IGNORED

	set_pdata_int(ent, 51, g_dnh_clip[id], 4)
	set_pdata_float(ent, 48, DNH_RELOAD_TIME, 4)
	set_pdata_float(id, 83, DNH_RELOAD_TIME, 5)
	set_pdata_int(ent, 54, 1, 4)
	
	set_weapon_anim(id, DNH_ANIM_RELOAD)
	
	return HAM_IGNORED
}

public fw_Ham_PostFrame_Dmp7a1(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	new id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_dmp7a1[id])
		return HAM_IGNORED
		
	new Float:flNextAttack = get_pdata_float(id, 83, 5)
	new bpammo = cs_get_user_bpammo(id, CSW_DMP7A1)
	
	new iClip = get_pdata_int(ent, 51, 4)
	new fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		new temp = min(DMP7A1_DEFAULT_CLIP - iClip, bpammo)
		
		set_pdata_int(ent, 51, iClip + temp, 4)
		cs_set_user_bpammo(id, CSW_DMP7A1, bpammo - temp)		
		set_pdata_int(ent, 54, 0, 4)
		
		fInReload = 0
		g_dmp7a1_reload[id] = 0
	}		
	
	return HAM_IGNORED
}

public fw_Ham_PostFrame_Ak4760r(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	new id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_ak4760r[id])
		return HAM_IGNORED
		
	new Float:flNextAttack = get_pdata_float(id, 83, 5)
	new bpammo = cs_get_user_bpammo(id, CSW_AK4760R)
	
	new iClip = get_pdata_int(ent, 51, 4)
	new fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		new temp = min(AK4760R_DEFAULT_CLIP - iClip, bpammo)
		
		set_pdata_int(ent, 51, iClip + temp, 4)
		cs_set_user_bpammo(id, CSW_AK4760R, bpammo - temp)		
		set_pdata_int(ent, 54, 0, 4)
		
		fInReload = 0
		g_ak4760r_reload[id] = 0
	}		
	
	return HAM_IGNORED
}

public fw_Ham_PostFrame_Dnh(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	new id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_dnh[id])
		return HAM_IGNORED
		
	new Float:flNextAttack = get_pdata_float(id, 83, 5)
	new bpammo = cs_get_user_bpammo(id, CSW_DNH)
	
	new iClip = get_pdata_int(ent, 51, 4)
	new fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		new temp = min(DNH_DEFAULT_CLIP - iClip, bpammo)
		
		set_pdata_int(ent, 51, iClip + temp, 4)
		cs_set_user_bpammo(id, CSW_DNH, bpammo - temp)		
		set_pdata_int(ent, 54, 0, 4)
		
		fInReload = 0
		g_dnh_reload[id] = 0
	}		
	
	return HAM_IGNORED
}

public fw_Ham_SendAnim_Dmp7a1(ent, anim, skip_local)
{
	if(pev_valid(ent) != 2)
		return HAM_IGNORED
		
	new id
	id = get_pdata_cbase(ent, 41 , 4)
	
	if(!g_had_dmp7a1[id])
		return HAM_IGNORED
	
	set_pdata_string(id, m_szAnimExtention * 4, "dualpistols", -1 , 20)
		
	return HAM_IGNORED
}

public fw_Ham_SendAnim_Dnh(ent, anim, skip_local)
{
	if(pev_valid(ent) != 2)
		return HAM_IGNORED
		
	new id
	id = get_pdata_cbase(ent, 41 , 4)
	
	if(!g_had_dnh[id])
		return HAM_IGNORED
	
	set_pdata_string(id, m_szAnimExtention * 4, "dualpistols", -1 , 20)
		
	return HAM_IGNORED
}

// ============================== Stocks ================================
stock set_weapon_anim(id, anim)
{ 
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
	
	/*
	static ent
	ent = fm_get_user_weapon_entity(id, get_user_weapon(id))
	
	if(pev_valid(ent)) ExecuteHamB(Ham_CS_Weapon_SendWeaponAnim, ent, anim, 0)*/
}

stock make_bullet(id, Float:Origin[3])
{
	// Find target
	new target, body
	get_user_aiming(id, target, body, 999999)
	
	if(target > 0 && target <= get_maxplayers())
	{
		new Float:fStart[3], Float:fEnd[3], Float:fRes[3], Float:fVel[3]
		pev(id, pev_origin, fStart)
		
		// Get ids view direction
		velocity_by_aim(id, 64, fVel)
		
		// Calculate position where blood should be displayed
		fStart[0] = Origin[0]
		fStart[1] = Origin[1]
		fStart[2] = Origin[2]
		fEnd[0] = fStart[0]+fVel[0]
		fEnd[1] = fStart[1]+fVel[1]
		fEnd[2] = fStart[2]+fVel[2]
		
		// Draw traceline from victims origin into ids view direction to find
		// the location on the wall to put some blood on there
		new res
		engfunc(EngFunc_TraceLine, fStart, fEnd, 0, target, res)
		get_tr2(res, TR_vecEndPos, fRes)
		
		// Show some blood :)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
		write_byte(TE_BLOODSPRITE)
		write_coord(floatround(fStart[0])) 
		write_coord(floatround(fStart[1])) 
		write_coord(floatround(fStart[2])) 
		write_short(g_bloodspray)
		write_short(g_blood)
		write_byte(70)
		write_byte(random_num(1,2))
		message_end()
		
		
		} else {
		new decal = 41
		
		// Check if the wall hit is an entity
		if(target)
		{
			// Put decal on an entity
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_DECAL)
			write_coord(floatround(Origin[0]))
			write_coord(floatround(Origin[1]))
			write_coord(floatround(Origin[2]))
			write_byte(decal)
			write_short(target)
			message_end()
			} else {
			// Put decal on "world" (a wall)
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_WORLDDECAL)
			write_coord(floatround(Origin[0]))
			write_coord(floatround(Origin[1]))
			write_coord(floatround(Origin[2]))
			write_byte(decal)
			message_end()
		}
		
		// Show sparcles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		write_coord(floatround(Origin[0]))
		write_coord(floatround(Origin[1]))
		write_coord(floatround(Origin[2]))
		write_short(id)
		write_byte(decal)
		message_end()
	}
}

stock SendCenterText(id, const message[])
{
	new dest
	if (id) dest = MSG_ONE_UNRELIABLE
	else dest = MSG_BROADCAST
	
	message_begin(dest, get_user_msgid("TextMsg"), {0,0,0}, id)
	write_byte(4)
	write_string(message)
	message_end()
}

// Drop primary/secondary weapons
stock drop_weapons(id, dropwhat, type=0)
{
	// Get user weapons
	static weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	
	// Loop through them and drop primaries or secondaries
	for (i = 0; i < num; i++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[i]
		
		if (get_weapon_type(weaponid) == dropwhat)
		{
			if (type==1)
			{
				fm_strip_user_gun(id, weaponid)
			}
			else
			{
				// Get weapon entity
				static wname[32]
				get_weaponname(weaponid, wname, charsmax(wname))
				
				// Player drops the weapon and looses his bpammo
				engclient_cmd(id, "drop", wname)
			}
		}
	}
}

stock get_weapon_type(weaponid)
{
	new type_wpn = 0
	if ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM) type_wpn = 1
	else if ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM) type_wpn = 2
	else if ((1<<weaponid) & NADE_WEAPONS_BIT_SUM) type_wpn = 4
	return type_wpn
}

stock give_nade(id, type)
{
	if (!is_user_alive(id)) return
	
	new weapons[32], num, check_vl[3]
	num = 0
	get_user_weapons(id, weapons, num)
	
	for (new i = 0; i < num; i++)
	{
		if (weapons[i] == CSW_HEGRENADE) check_vl[0] = 1
		else if (weapons[i] == CSW_FLASHBANG) check_vl[1] = 1
		else if (weapons[i] == CSW_SMOKEGRENADE) check_vl[2] = 1
	}
	
	if (!check_vl[0]) give_item(id, WEAPONENTNAMES[CSW_HEGRENADE])
	
	if(type == 1)
	{
		if (!check_vl[1])
		{	
			give_item(id, WEAPONENTNAMES[CSW_FLASHBANG])
			give_item(id, WEAPONENTNAMES[CSW_FLASHBANG])
		}
	}
	if (!check_vl[2]) give_item(id, WEAPONENTNAMES[CSW_SMOKEGRENADE])
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

public give_ammo(id)
{
	if (!is_user_alive(id)) return
	
	// Get user weapons
	static weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	
	// Loop through them and drop primaries or secondaries
	for (i = 0; i < num; i++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[i]
		
		if (get_weapon_type(weaponid) == 1 || get_weapon_type(weaponid) == 2)
			cs_set_user_bpammo(id, weaponid, 200)
	}	
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
