#include <amxmodx>
#include <fakemeta>

#define PLUGIN "[Zombie: CSO] Addon: UnPrecache"
#define VERSION "1.0"
#define AUTHOR "Dias"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_precache()
{
	register_forward(FM_PrecacheSound, "fw_PrecacheSound")
}

public fw_PrecacheSound(const Sound[])
{
	if(containi(Sound, "/hostage/") != -1)
		return FMRES_SUPERCEDE
		
	return FMRES_IGNORED
}
