#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_thehero2>
#include <xs>

#define MAX_NORMAL_KILL 7
#define MAX_FIRST_KILL 5
#define MAX_FIRST_KILL_SPR 1
#define MAX_HEADSHOT_KILL 1
#define MAX_HEADSHOT_KILL_SPR 1
#define MAX_MELEE_KILL 1
#define MAX_MELEE_KILL_SPR 1
#define MAX_MELEE_KILLED 1
#define MAX_GRENADE_KILL_SPR 1

#define RESET_TIME 3.0

#define TASK_RESET_TIME 534544
#define TASK_REMOVE_HUD 436456

enum
{
	HUD_KILL_NORMAL = 0,
	HUD_KILL_FIRST,
	HUD_KILL_HEADSHOT,
	HUD_KILL_MELEE,
	HUD_KILL_GRENADE
}

new const normal_kill[MAX_NORMAL_KILL][] =
{
	"zombie_thehero/vox/doublekill.wav",
	"zombie_thehero/vox/triplekill.wav",
	"zombie_thehero/vox/multikill.wav",
	"zombie_thehero/vox/monsterkill.wav",
	"zombie_thehero/vox/megakill.wav",
	"zombie_thehero/vox/incredible.wav",
	"zombie_thehero/vox/outofworld.wav"
}

new const first_kill[MAX_FIRST_KILL][] =
{
	"zombie_thehero/vox/cantbelive.wav",
	"zombie_thehero/vox/crazy.wav",
	"zombie_thehero/vox/excellent.wav",
	"zombie_thehero/vox/gotit.wav",
	"zombie_thehero/vox/outofworld.wav"
}

new const headshot_kill[MAX_HEADSHOT_KILL][] =
{
	"zombie_thehero/vox/headshot.wav"
}

new const melee_kill[MAX_MELEE_KILL][] =
{
	"zombie_thehero/vox/humililation.wav"
	//"zombie_thehero/vox/cantbelive.wav",
	//"zombie_thehero/vox/godlike.wav"
}

new const melee_killed[MAX_MELEE_KILLED][] =
{
	"zombie_thehero/vox/ohno.wav"
}

// Hardcode
new g_kill_count[33], g_sync_hud1

public plugin_init()
{
	register_plugin("[Zombie: The Hero] Addon: Effect Killer", "2.0", "Dias")
	
	RegisterHam(Ham_Spawn, "player", "fw_Spawn_Post", 1)
	register_event("DeathMsg", "event_death", "a")
	
	g_sync_hud1 = zb3_get_synchud_id(SYCHUDD_EFFECTKILLER)
}

public plugin_precache()
{
	new i
	for(i = 0; i < MAX_NORMAL_KILL; i++)
		engfunc(EngFunc_PrecacheSound, normal_kill[i])
	for(i = 0; i < MAX_FIRST_KILL; i++)
		engfunc(EngFunc_PrecacheSound, first_kill[i])
	for(i = 0; i < MAX_HEADSHOT_KILL; i++)
		engfunc(EngFunc_PrecacheSound, headshot_kill[i])
	for(i = 0; i < MAX_MELEE_KILL; i++)
		engfunc(EngFunc_PrecacheSound, melee_kill[i])
	for(i = 0; i < MAX_MELEE_KILLED; i++)
		engfunc(EngFunc_PrecacheSound, melee_killed[i])	
}

public fw_Spawn_Post(id)
{
	if(!is_user_connected(id))
		return HAM_IGNORED
		
	g_kill_count[id] = 0
	
	return HAM_HANDLED
}

public kill_check(Victim, Attacker, Headshot, Weapon)
{
	if(is_user_bot(Attacker))
		return
	if(!is_user_alive(Attacker))
		return
		
	static AddKill
	AddKill = 1
	
	

	if(g_kill_count[Attacker] == 0)
	{
		if(!zb3_get_user_zombie(Attacker))
		{
			if(!Headshot && Weapon != CSW_KNIFE && Weapon != CSW_HEGRENADE)
			{
				set_hudmessage(0,255,255, -1.0, 0.20, 0, RESET_TIME, RESET_TIME)
				ShowSyncHudMsg(Attacker, g_sync_hud1, "1 KILL")
		
				PlaySound(Attacker, first_kill[random(MAX_FIRST_KILL)])
			} else if(Headshot) {
				set_hudmessage(255, 0, 0, -1.0, 0.20, 0, RESET_TIME, RESET_TIME)
				ShowSyncHudMsg(Attacker, g_sync_hud1, "HEADSHOT")
				
				PlaySound(Attacker, headshot_kill[random(MAX_HEADSHOT_KILL)])
			} else if(Weapon == CSW_KNIFE && !Headshot) {
				set_hudmessage(255, 0, 0, -1.0, 0.20, 0, RESET_TIME, RESET_TIME)
				ShowSyncHudMsg(Attacker, g_sync_hud1, "HUMILILATION")
				
				PlaySound(Attacker, melee_kill[random(MAX_MELEE_KILL)])
				PlaySound(Victim, melee_killed[random(MAX_MELEE_KILLED)])
			} else if(Weapon == CSW_HEGRENADE) {
				set_hudmessage(255, 0, 0, -1.0, 0.20, 0, RESET_TIME, RESET_TIME)
				ShowSyncHudMsg(Attacker, g_sync_hud1, "GRENADE KILL")
				
				PlaySound(Attacker, first_kill[random(MAX_FIRST_KILL)])
			}
		} else {
			set_hudmessage(255, 0, 0, -1.0, 0.20, 0, RESET_TIME, RESET_TIME)
			ShowSyncHudMsg(Attacker, g_sync_hud1, "1 KILL")
			
			PlaySound(Attacker, first_kill[random(MAX_FIRST_KILL)])			
		}
		g_kill_count[Attacker]++

		AddKill = 0
	} else {
		if(g_kill_count[Attacker] >= (MAX_NORMAL_KILL + 1))
		{
			PlaySound(Attacker, normal_kill[MAX_NORMAL_KILL - 1])
		} else {
			PlaySound(Attacker, normal_kill[g_kill_count[Attacker] - 1])
		}
		
		static Color[3]
		get_kill_color(g_kill_count[Attacker], Color)
		
		set_hudmessage(Color[0], Color[1], Color[2], -1.0, 0.20, 1, RESET_TIME, RESET_TIME)
		ShowSyncHudMsg(Attacker, g_sync_hud1, "%i KILL", g_kill_count[Attacker] + 1)
		/*
		static Name[64]
		get_user_name(Attacker, Name, sizeof(Name))
		
		client_printc(0, "!g[Zombie: The Hero]!n Player !g%s!n did !t%i!n Kill(s)", Name, g_kill_count[Attacker] + 1)
		
		AddKill = 1*/
	}
	
	if(AddKill && g_kill_count[Attacker] < 4)
		g_kill_count[Attacker]++
		
	if(task_exists(Attacker+TASK_RESET_TIME)) remove_task(Attacker+TASK_RESET_TIME)
	set_task(RESET_TIME, "reset_kill", Attacker+TASK_RESET_TIME)		
}

public event_death()
{
	static Attacker, Victim, Headshot, Weapon, Weapon_Temp[32]
	
	Attacker = read_data(1)
	Victim = read_data(2)
	Headshot = read_data(3)

	read_data(4, Weapon_Temp, charsmax(Weapon_Temp))
	Weapon = get_cswpn_from_deathmsg(Weapon_Temp)
		
	kill_check(Victim, Attacker, Headshot, Weapon)
}

public reset_kill(id)
{
	id -= TASK_RESET_TIME
	
	g_kill_count[id] = 0
}

stock PlaySound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}

stock PlayEmitSound(id, const Sound[])
{
	if(is_user_connected(id))
		emit_sound(id, CHAN_VOICE, Sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

stock get_cswpn_from_deathmsg(const sSprite[])
{
	new sWpnName[32]
	format(sWpnName, charsmax(sWpnName), "%s", sSprite)
	if ( equal(sWpnName, "grenade") )
	{
		format(sWpnName, charsmax(sWpnName), "hegrenade")
	}
	format(sWpnName, charsmax(sWpnName), "weapon_%s", sWpnName)
	return get_weaponid(sWpnName)
}

stock get_kill_color(kill, color[3])
{
	switch(kill)
	{
		case 1: color = {0,255,255}
		case 2: color = {0,177,0}
		case 3: color = {255,130,0}
		case 4: color = {200,0,0}
		/*
		case 5: color = {137,191,20}
		case 6: color = {250,229,0}
		case 7: color = {250,229,0}
		case 8: color = {243,127,1}
		case 9: color = {243,127,1}
		case 10: color = {255,3,0}
		case 11: color = {127,40,208}
		case 12: color = {127,40,208}
		case 13: color = {127,40,208}
		*/
		default: color = {255,255,255}
	}
}


// Colour Chat
stock client_printc(const id, const input[], any:...)
{
	new count = 1, players[32];
	static msg[191];
	vformat(msg, 190, input, 3);
    
	replace_all(msg, 190, "!g", "^x04"); // Green Color
	replace_all(msg, 190, "!n", "^x01"); // Default Color
	replace_all(msg, 190, "!t", "^x03"); // Team Color
    
	if (id) players[0] = id; else get_players(players, count, "ch");
	{
		for (new i = 0; i < count; i++)
		{
			if (is_user_connected(players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]);
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	}
}  
