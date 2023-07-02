#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>
#include <zombie_thehero2>

#define PLUGIN "[Mileage] Primary: Default"
#define VERSION "1.0"
#define AUTHOR "Dias Pendragon"

new g_AK47, g_M4A1, g_AUG, g_M3, g_XM1014, g_AWP , g_M249 , g_G3SG1 , g_Elite

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_AK47 = zb3_register_weapon("ak47")
	g_M4A1 = zb3_register_weapon("m4a1")
	g_AUG = zb3_register_weapon("aug")
	g_M3 = zb3_register_weapon("m3")
	g_M249 = zb3_register_weapon("m249")
	g_XM1014 = zb3_register_weapon("xm1014")
	g_G3SG1 = zb3_register_weapon("g3sg1")
	g_AWP = zb3_register_weapon("awp")
	g_Elite = zb3_register_weapon("elite")
}

public zb3_weapon_selected_post(id, ItemID)
{
	
	if(ItemID == g_AK47) {
		give_item(id, "weapon_ak47")
		cs_set_user_bpammo(id, CSW_AK47, 210)
	} else if(ItemID == g_M4A1) {
		give_item(id, "weapon_m4a1")
		cs_set_user_bpammo(id, CSW_M4A1, 210)	
	} else if(ItemID == g_AUG) {
		give_item(id, "weapon_aug")
		cs_set_user_bpammo(id, CSW_AUG, 210)
	} else if(ItemID == g_M3) {
		give_item(id, "weapon_m3")
		cs_set_user_bpammo(id, CSW_M3, 120)
	} else if(ItemID == g_XM1014) {
		give_item(id, "weapon_xm1014")
		cs_set_user_bpammo(id, CSW_XM1014, 120)
	} else if(ItemID == g_AWP) {
		give_item(id, "weapon_awp")
		cs_set_user_bpammo(id, CSW_AWP, 100)
	} else if(ItemID == g_M249){
		give_item(id, "weapon_m249")
		cs_set_user_bpammo(id, CSW_M249, 250)
	} else if(ItemID ==  g_G3SG1){
		give_item(id, "weapon_g3sg1")
		cs_set_user_bpammo(id, CSW_G3SG1, 210)
	} else if(ItemID ==  g_Elite){
		give_item(id, "weapon_elite")
		cs_set_user_bpammo(id, CSW_ELITE, 210)
	}
}
public zb3_weapon_refill_ammo(id)
{
		cs_set_user_bpammo(id, CSW_AK47, 210)
		cs_set_user_bpammo(id, CSW_M4A1, 210)
		cs_set_user_bpammo(id, CSW_AUG, 210)
		cs_set_user_bpammo(id, CSW_M3, 120)
		cs_set_user_bpammo(id, CSW_XM1014, 120)
		cs_set_user_bpammo(id, CSW_AWP, 100)
		cs_set_user_bpammo(id, CSW_M249, 250)
		cs_set_user_bpammo(id, CSW_G3SG1, 210)
		cs_set_user_bpammo(id, CSW_ELITE, 210)
	
}