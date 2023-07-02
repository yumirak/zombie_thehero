#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <zombie_thehero2>

#define PLUGIN "[ZB3] Zombie Class: Voodoo"
#define VERSION "2.0"
#define AUTHOR "Dias"

new const LANG_FILE[] = "zombie_thehero2.txt"

// Zombie Configs
new const zclass_name[] = "Voodoo"
new const zclass_desc[] = "Heal"
new const zclass_sex = SEX_MALE
new const zclass_lockcost = 0
new const zclass_hostmodel[] = "heal_zombi_host"
new const zclass_originmodel[] = "heal_zombi_origin"
new const zclass_clawsmodelhost[] = "v_knife_heal_zombi.mdl"
new const zclass_clawsmodelorigin[] = "v_knife_heal_zombi.mdl"
new const zombiegrenade_modelhost[] = "models/zombie_thehero/v_zgren_heal_zombi.mdl"
new const zombiegrenade_modelorigin[] = "models/zombie_thehero/v_zgren_heal_zombi.mdl"
new const Float:zclass_gravity = 0.8
new const Float:zclass_speedhost = 280.0
new const Float:zclass_speedorigin = 280.0
new const Float:zclass_knockback = 1.5
new const Float:zclass_painshock = 0.4
new const Float:zclass_dmgmulti = 1.1
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
new const HealSound_Female[] = "zombie_thehero/zombi_heal_female.wav"
new const EvolSound[] = "zombie_thehero/zombi_evolution.wav"
new const HealSkillSound[] = "zombie_thehero/td_heal.wav"
new const HealerSpr[] = "sprites/zombie_thehero/zombihealer.spr"
new const HealedSpr[] = "sprites/zombie_thehero/zombiheal_head.spr"
new const Float:ClawsDistance1 = 1.0
new const Float:ClawsDistance2 = 1.1

new g_HealerSpr_Id, g_HealedSpr_Id
new g_zombie_classid, g_can_heal[33], g_current_time[33]//, g_heal_left[33]

#define LANG_OFFICIAL LANG_PLAYER

#define HEAL_AMOUNT_HOST 1000
#define HEAL_AMOUNT_ORIGIN 500
#define HEAL_COOLDOWN_HOST 20
#define HEAL_COOLDOWN_ORIGIN 15
#define HEAL_RADIUS 400.0
#define HEAL_FOV 100

#define TASK_COOLDOWN 12001

new g_synchud1, g_MaxPlayers, g_Msg_Fov

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_dictionary(LANG_FILE)
	
	register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", 1)
	register_clcmd("drop", "cmd_drop")
	
	g_synchud1 = zb3_get_synchud_id(SYNCHUD_ZBHM_SKILL1)
	g_MaxPlayers = get_maxplayers()
	g_Msg_Fov = get_user_msgid("SetFOV")
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
	engfunc(EngFunc_PrecacheSound, HealSound_Female)
	engfunc(EngFunc_PrecacheSound, HealSkillSound)
	
	g_HealerSpr_Id = engfunc(EngFunc_PrecacheModel, HealerSpr)
	g_HealedSpr_Id = engfunc(EngFunc_PrecacheModel, HealedSpr)
}

public zb3_user_infected(id, infector)
{
	if(zb3_get_user_zombie_class(id) == g_zombie_classid)
	{
		if(is_user_bot(id))
			bot_user_skill(id)
		reset_skill(id)
		
		g_can_heal[id] = 1
		g_current_time[id] = 100
		//g_heal_left[id] = 5
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
	g_can_heal[id] = 0
	g_current_time[id] = 0
	//g_heal_left[id] = 0

	remove_task(id+TASK_COOLDOWN)
}

public zb3_user_spawned(id) 
{
	if(!zb3_get_user_zombie(id)) set_task(0.1, "reset_skill", id)
}

public zb3_user_dead(id) reset_skill(id)

public bot_user_skill(id)
{
	if(!is_user_alive(id) || !zb3_get_user_zombie(id))
		return PLUGIN_CONTINUE	
	cmd_drop(id)
	set_task(zb3_get_user_level(id) > 1 ? float(HEAL_COOLDOWN_ORIGIN) : float(HEAL_COOLDOWN_HOST), "bot_user_skill", id)
	return PLUGIN_HANDLED
}
public fw_AddToFullPack_Post(es, e, ent, host, hostflags, player, pSet)
{
	if(!player)
		return FMRES_IGNORED
	if(!is_user_alive(ent) || !is_user_alive(host))
		return FMRES_IGNORED
	if(!zb3_get_user_zombie(ent) || !zb3_get_user_zombie(host))
		return FMRES_IGNORED
	if(zb3_get_user_zombie_class(host) != g_zombie_classid)
		return FMRES_IGNORED
	if(!zb3_get_user_nvg(host))
		return FMRES_IGNORED
		
	static Float:CurHealth, Float:MaxHealth
	static Float:Percent, Percent2, RealPercent
	
	CurHealth = float(get_user_health(ent))
	MaxHealth = float(zb3_get_user_starthealth(ent))
	
	Percent = (CurHealth / MaxHealth) * 100.0
	Percent2 = floatround(Percent)
	RealPercent = clamp(Percent2, 1, 100)
	
	static Color[3]
	
	switch(RealPercent)
	{
		case 1..49: Color = {75, 0, 0}
		case 50..79: Color = {75, 75, 0}
		case 80..100: Color = {0, 75, 0}
	}
	
	set_es(es, ES_RenderFx, kRenderFxGlowShell)
	set_es(es, ES_RenderMode, kRenderNormal)
	set_es(es, ES_RenderColor, Color)
	set_es(es, ES_RenderAmt, 16)
	
	return FMRES_HANDLED
}


public cmd_drop(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE	
	if(!zb3_get_user_zombie(id))
		return PLUGIN_CONTINUE
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return PLUGIN_CONTINUE
	if(!g_can_heal[id])
		return PLUGIN_HANDLED

	Do_Heal(id)
	set_task(zb3_get_user_level(id) > 1 ? float(HEAL_COOLDOWN_ORIGIN) : float(HEAL_COOLDOWN_HOST), "Remove_Heal", id+TASK_COOLDOWN)
	return PLUGIN_HANDLED
}

public Do_Heal(id)
{
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 
	//if(!g_heal_left[id])
	//	return
		
	static CurrentHealth, MaxHealth, RealHealth
	
	g_current_time[id] = 0
	g_can_heal[id] = 0
	//g_heal_left[id]--
	
	if(zb3_get_user_level(id) > 1) // Origin Zombie
	{
		for(new i = 0; i < g_MaxPlayers; i++)
		{
			if(!is_user_alive(i))
				continue
			if(!zb3_get_user_zombie(i))
				continue
			if(entity_range(id, i) > HEAL_RADIUS)
				continue
				
			CurrentHealth = get_user_health(i)
			MaxHealth = zb3_get_user_starthealth(i)
			
			RealHealth = clamp(CurrentHealth + HEAL_AMOUNT_ORIGIN, CurrentHealth, MaxHealth)
			zb3_set_user_health(i, RealHealth)
			
			if(id == i) Heal_Icon(i, 1)
			else Heal_Icon(i, 0)
			
			//PlaySound(i, zb3_get_user_sex(id) == SEX_MALE ? HealSound : HealSound_Female)
			EmitSound(i,CHAN_BODY, zb3_get_user_sex(i) == SEX_MALE ? HealSound : HealSound_Female)
		}
		
		EmitSound(id, CHAN_BODY, HealSkillSound)
	} else { // Host Zombie
		CurrentHealth = get_user_health(id)
		MaxHealth = zb3_get_user_starthealth(id)
		
		RealHealth = clamp(CurrentHealth + HEAL_AMOUNT_HOST, CurrentHealth, MaxHealth)
		zb3_set_user_health(id, RealHealth)
		
		Heal_Icon(id, 1)
		EmitSound(id, CHAN_BODY, HealSkillSound)
	}
	
	set_fov(id, HEAL_FOV)
	set_task(0.5, "Remove_Fov", id)
	
	//set_task(3.0, "Do_Heal", id)
}

public Remove_Fov(id)
{
	if(!is_user_connected(id))
		return
		
	set_fov(id)
}

public Remove_Heal(id)
{
	id -= TASK_COOLDOWN

	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 
	if(g_can_heal[id])
		return	
		
	g_can_heal[id] = 1
	g_current_time[id] = 100
	//g_heal_left[id] = 5
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
	
	timewait = zb3_get_user_level(id) > 1 ? float(HEAL_COOLDOWN_ORIGIN) : float(HEAL_COOLDOWN_HOST)
	
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
		
		if(!g_can_heal[id]) 
		{
			g_can_heal[id] = 1
			//g_heal_left[id] = 5
		}
	}	
}

stock Heal_Icon(id, Healer)
{
	if(!is_user_connected(id))
		return
	
	static Float:origin[3];
	pev(id,pev_origin,origin);
    
	message_begin(MSG_PVS,SVC_TEMPENTITY); 
	write_byte(TE_EXPLOSION); // TE_EXPLOSION
	write_coord(floatround(origin[0])); // origin x
	write_coord(floatround(origin[1])); // origin y
	write_coord(floatround(origin[2]) + Healer == 1 ? 0 : 35); // origin z
	write_short(Healer == 1 ? g_HealerSpr_Id : g_HealedSpr_Id); // sprites
	write_byte(15); // scale in 0.1's
	write_byte(12); // framerate
	write_byte(14); // flags 
	message_end(); // message end
}

stock EmitSound(id, chan, const file_sound[])
{
	if(!is_user_connected(id))
		return
		
	emit_sound(id, chan, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

stock PlaySound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}

stock set_fov(id, num = 90)
{
	if(!is_user_connected(id))
		return
	
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_Fov, {0,0,0}, id)
	write_byte(num)
	message_end()
}
