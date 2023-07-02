/* #####################################################
	---------------------------------------
	-*- Zombie: The Hero III - Native -*-
	---------------------------------------
###################################################### */ 

// Enum
enum PlayerTeams
{
	TEAM_ALL = 0,
	TEAM_ZOMBIE,
	TEAM_HUMAN,
	TEAM_START
}

enum
{
	TEAM2_ZOMBIE = 1,
	TEAM2_HUMAN
}

enum
{
	WPN_PRIMARY = 1,
	WPN_SECONDARY,
	WPN_MELEE
}

enum
{
	SEX_NONE = 0,
	SEX_MALE,
	SEX_FEMALE
}

enum
{
	HERO_ANDREY = 1,
	HERO_KATE
}

enum
{
	ZOMBIE_HOST = 0,
	ZOMBIE_ORIGIN
}

enum
{
	GAMESTART_NEWROUND = 0,
	GAMESTART_COUNTING,
	GAMESTART_ZOMBIEAPPEAR
}

enum
{
	SYNCHUD_NOTICE = 0,
	SYNCHUD_HUMANZOMBIE_ITEM,
	SYNCHUD_ZBHM_SKILL1,
	SYNCHUD_ZBHM_TOPHUD,
	SYNCHUD_LVLBAR,
	SYCHUDD_EFFECTKILLER
}

// Natives
native zb3_infect(id, attacker, origin_zombie, respawn); // Infect a Player

native zb3_get_user_zombie(id); // Return if User is A Zombie
native zb3_get_user_zombie_class(id); // Return id class of zombie

native zb3_set_user_respawn_time(id, Time);
native zb3_reset_user_respawn_time(id);

native zb3_set_user_infect_multiplier(id, HP_Percent);
native zb3_reset_user_infect_multiplier(id);

native zb3_get_user_hero(id); // Return hero class (0 = Non-Hero | 1 = Andrey | 2 = Kate)
native zb3_set_lock_hero(id, lock);

native zb3_get_user_sex(id);
native zb3_set_user_sex(id, Sex);

native zb3_set_user_speed(id, Speed);
native zb3_reset_user_speed(id);

native zb3_set_user_nvg(id, on, auto_on, give, remove);
native zb3_get_user_nvg(id);

native zb3_set_user_health(id, Health);
native zb3_set_user_light(id, const light[]);
native zb3_set_user_rendering(id, fx, r, g, b, render, amount);

native zb3_get_synchud_id(hudtype);
native zb3_show_dhud(id, R, G, B, Float:X, Float:Y, Float:TimeLive, const Text[]);

native zb3_set_user_level(id, level);
native zb3_get_user_level(id);

native zb3_set_user_maxlevel(id, maxlevel);
native zb3_get_user_maxlevel(id);

native zb3_set_user_starthealth(id, Health);
native zb3_get_user_starthealth(id);

native zb3_set_user_startarmor(id, Health);
native zb3_get_user_startarmor(id);

native zb3_register_zombie_class(const Name[], const Desc[], Sex, LockCost, Float:Gravity, Float:SpeedHost, Float:SpeedOrigin, Float:KnockBack, Float:PainShock,Float:DmgMulti, Float:ClawsDistance1, Float:ClawsDistance2);
native zb3_set_zombie_class_data(const ModelHost[], const ModelOrigin[], const ClawsModel_Host[], const ClawsModel_Origin[], const DeathSound1[], const DeathSound2[], const HurtSound1[], const HurtSound2[], const HealSound[], const EvolSound[]);

native zb3_register_item(const name[], const desc[], cost, team, permanent_buy);
native zb3_register_zbgre_model(const v_model_host[], const v_model_origin[]);

native zb3_supplybox_random_getitem(id, hero);

// Forwards
forward zb3_user_infected(id, infector, really_infect); // Call when a guy get infect
forward zb3_user_change_class(id, oldclass, newclass);
forward zb3_user_spawned(id); // Call when a guy Respawn
forward zb3_user_dead(id, attacker, headshot); // Call when a guy got Killed
forward zb3_game_start(start_type); // Call when New Round (0), Counting (1), Zombie Appear (2)
forward zb3_game_end({PlayerTeams,_}:team_win);
forward zb3_zombie_evolution(id, level);
forward zb3_user_become_hero(id, hero_type);
forward zb3_time_change();
forward zb3_skill_show(id);

forward zb3_item_selected_pre(id, itemid);
forward zb3_item_selected_post(id, itemid);

forward zb3_weapon_selected_pre(id, weaponid);
forward zb3_weapon_selected_post(id, weaponid);	
forward zb3_weapon_refill_ammo(id);
//forward zb3_weapon_selected_post(id, weaponid);
//forward zb3_remove_weapon(id, weaponid);

//native zb3_register_weapon(const Name[], weapon_type, unlock_cost)

native zb3_register_weapon(const SystemName[]);
native zb3_weapon_menu_open(id);//Mileage_OpenWeapon(id);
native zb3_weapon_random(id);

native zb3_remove_weapon(id);//Mileage_RemoveWeapon(id);
native zb3_resetweapon(id, NewPlayer);
native zb3_weapon_refill(id);

native zb3_weapon_allow_select(id, Allow);//Mileage_WeaponAllow_Set(id, Allow);
native zb3_weapon_allow_get(id)


