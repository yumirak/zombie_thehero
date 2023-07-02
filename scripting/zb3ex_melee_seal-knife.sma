#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombie_thehero2>
#include <cstrike>

#define PLUGIN "[Zombie: The Hero] Melee Weapon: Seal-Knife"
#define VERSION "2.0"
#define AUTHOR "Dias"

new g_sealknife

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

const m_szAnimExtention = 492

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	RegisterHam(Ham_CS_Weapon_SendWeaponAnim, "weapon_knife", "fw_Knife_SendAnim", 1)
}

public plugin_precache()
{
	g_sealknife = zb3_register_weapon("knife")
}

public zb3_weapon_selected_post(id, wpnid)
{
	if(wpnid == g_sealknife)
		if(get_user_weapon(id) == CSW_KNIFE) set_weapon_anim(id, KNIFE_ANIM_DRAW)
}

public fw_Knife_SendAnim(ent, anim, skip_local)
{
	if(pev_valid(ent) != 2)
		return HAM_IGNORED
		
	new id
	id = get_pdata_cbase(ent, 41 , 4)
	
	set_pdata_string(id, m_szAnimExtention * 4, "knife", -1 , 20)
		
	return HAM_IGNORED
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
