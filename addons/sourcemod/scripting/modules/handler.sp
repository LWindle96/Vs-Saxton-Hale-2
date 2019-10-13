/**
ALL NON-BOSS AND NON-MINION RELATED CODE IS AT THE BOTTOM. HAVE FUN CODING!
*/


/** When you add custom Bosses into the plugin, add to the anonymous enum as the Boss' ID */
enum /* Bosses */ {
	Hale = 0,
	Vagineer = 1,
	CBS = 2,
	HHHjr = 3,
	Bunny = 4,
};

#define MAXBOSS    Bunny + (g_hBossesRegistered.Length)

#include "modules/bosses.sp"

/**
PLEASE REMEMBER THAT PLAYERS THAT DON'T HAVE THEIR BOSS ID'S SET ARE NOT BOSSES.
THIS PLUGIN HAS BEEN SETUP SO THAT IF YOU BECOME A BOSS, YOU MUST HAVE A VALID BOSS ID

FOR MANAGEMENT FUNCTIONS, DO NOT HAVE THEM DISCRIMINATE WHO IS A BOSS OR NOT, SIMPLY CHECK THE ITYPE TO SEE IF IT REALLY WAS A BOSS PLAYER.
*/


public void ManageDownloads()
{
	Action act = Call_OnCallDownloads();    /// in forwards.sp
	if( act==Plugin_Stop )
		return;
	
	PrecacheSound("ui/item_store_add_to_cart.wav", true);
	PrecacheSound("player/doubledonk.wav", true);

	PrecacheSound("saxton_hale/9000.wav", true);
	CheckDownload("sound/saxton_hale/9000.wav");
	PrecacheSound("vo/announcer_am_capincite01.mp3", true);
	PrecacheSound("vo/announcer_am_capincite03.mp3", true);
	PrecacheSound("vo/announcer_am_capenabled02.mp3", true);
	
	PrecacheSound("vo/announcer_ends_60sec.mp3", true);
	PrecacheSound("vo/announcer_ends_30sec.mp3", true);
	PrecacheSound("vo/announcer_ends_10sec.mp3", true);
	PrecacheSound("vo/announcer_ends_1sec.mp3", true);
	PrecacheSound("vo/announcer_ends_2sec.mp3", true);
	PrecacheSound("vo/announcer_ends_3sec.mp3", true);
	PrecacheSound("vo/announcer_ends_4sec.mp3", true);
	PrecacheSound("vo/announcer_ends_5sec.mp3", true);
	PrecacheSound("items/pumpkin_pickup.wav", true);
	
	AddHaleToDownloads   ();
	AddVagToDownloads    ();
	AddCBSToDownloads    ();
	AddHHHToDownloads    ();
	AddBunnyToDownloads  ();
}

public void ManageMenu(Menu& menu)
{
	AddHaleToMenu(menu);
	AddVagToMenu(menu);
	AddCBSToMenu(menu);
	AddHHHToMenu(menu);
	AddBunnyToMenu(menu);
	Call_OnBossMenu(menu);
}

public void ManageDisconnect(const int client)
{
	BaseBoss leaver = BaseBoss(client);
	if( leaver.bIsBoss ) {
		if( gamemode.iRoundState >= StateRunning ) {	/// Arena mode flips out when no one is on the other team
			BaseBoss[] bosses = new BaseBoss[MaxClients];
			int numbosses = gamemode.GetBosses(bosses, false);
			if( numbosses-1 > 0 ) {	/// Exclude leaver, this is why CountBosses() can't be used
				for( int i=0; i<numbosses; i++ ) {
					if( bosses[i] == leaver )
						continue;
					if( IsPlayerAlive(bosses[i].index) )
						break;
					
					BaseBoss next = gamemode.FindNextBoss();
					if( gamemode.hNextBoss ) {
						next = gamemode.hNextBoss;
						gamemode.hNextBoss = view_as< BaseBoss >(0);
					}
					if( IsValidClient(next.index) ) {
						next.bIsMinion = true;	/// Dumb hack, prevents spawn hook from forcing them back to red
						next.ForceTeamChange(VSH2Team_Boss);
					}
					
					if( gamemode.iRoundState == StateRunning )
						ForceTeamWin(VSH2Team_Red);
					break;
				}
			} else {	/// No bosses left
				BaseBoss next = gamemode.FindNextBoss();
				if( gamemode.hNextBoss ) {
					next = gamemode.hNextBoss;
					gamemode.hNextBoss = view_as< BaseBoss >(0);
				}
				if( IsValidClient(next.index) ) {
					next.bIsMinion = true;
					next.ForceTeamChange(VSH2Team_Boss);
				}
				
				if( gamemode.iRoundState == StateRunning )
					ForceTeamWin(VSH2Team_Red);
			}
		} else if( gamemode.iRoundState == StateStarting ) {
			BaseBoss replace = gamemode.FindNextBoss();
			if( gamemode.hNextBoss ) {
				replace = gamemode.hNextBoss;
				gamemode.hNextBoss = view_as< BaseBoss >(0);
			}
			if( IsValidClient(replace.index) ) {
				replace.MakeBossAndSwitch(replace.iPresetType == -1 ? leaver.iBossType : replace.iPresetType, true);
				CPrintToChat(replace.index, "{olive}[VSH 2]{green} Surprise! You're on NOW!");
			}
		}
		CPrintToChatAll("{olive}[VSH 2]{red} A Boss Just Disconnected!");
	} else {
		RequestFrame(CheckAlivePlayers, 0);
		//SetPawnTimer(CheckAlivePlayers, 0.2);
		if( client == gamemode.FindNextBoss().index )
			SetPawnTimer(_SkipBossPanel, 1.0);
		
		if( leaver.userid == gamemode.hNextBoss.userid )
			gamemode.hNextBoss = view_as< BaseBoss >(0);
	}
}

public void ManageOnBossSelected(const BaseBoss base)
{
	SetPawnTimer(_SkipBossPanel, 4.0);
	Action act = Call_OnBossSelected(base);
	if( act > Plugin_Changed )
		return;
	
	ManageBossHelp(base);
	if( !cvarVSH2[AllowRandomMultiBosses].BoolValue || gamemode.iPlaying < 10 || GetRandomInt(0, 3) > 0 )
		return;
	
	int playing = gamemode.iPlaying;
	int extraBosses = GetRandomInt(1, playing / 12);
	if( extraBosses > cvarVSH2[MaxRandomMultiBosses].IntValue )
		extraBosses = cvarVSH2[MaxRandomMultiBosses].IntValue;
	while( extraBosses-- > 0 )
		gamemode.FindNextBoss().MakeBossAndSwitch(GetRandomInt(Hale, MAXBOSS), false);
}

public Action ManageOnTouchPlayer(const BaseBoss base, const BaseBoss victim)
{
	return Call_OnTouchPlayer(base, victim);
}

public Action ManageOnTouchBuilding(const BaseBoss base, const int building)
{
	return Call_OnTouchBuilding(base, EntIndexToEntRef(building));
}

public void ManageBossHelp(const BaseBoss base)
{
	switch( base.iBossType ) {
		case -1: {}
		case Hale:		ToCHale(base).Help();
		case Vagineer:		ToCVagineer(base).Help();
		case CBS:		ToCChristian(base).Help();
		case HHHjr:		ToCHHHJr(base).Help();
		case Bunny:		ToCBunny(base).Help();
	}
}

public void ManageBossThink(const BaseBoss base)
{
	/** Adding this so bosses can take minicrits if airborne */
	TF2_AddCondition(base.index, TFCond_GrapplingHookSafeFall, 0.2);
	
	Action act = Call_OnBossThink(base);
	if( act > Plugin_Changed )
		return;
	
	switch( base.iBossType ) {
		case -1: {}
		case Hale:		ToCHale(base).Think();
		case Vagineer:		ToCVagineer(base).Think();
		case CBS:		ToCChristian(base).Think();
		case HHHjr:		ToCHHHJr(base).Think();
		case Bunny:		ToCBunny(base).Think();
	}
}

public void ManageBossModels(const BaseBoss base)
{
	Action act = Call_OnBossModelTimer(base);
	if( act > Plugin_Changed )
		return;
	
	switch( base.iBossType ) {
		case -1: {}
		case Hale:		ToCHale(base).SetModel();
		case Vagineer:		ToCVagineer(base).SetModel();
		case CBS:		ToCChristian(base).SetModel();
		case HHHjr:		ToCHHHJr(base).SetModel();
		case Bunny:		ToCBunny(base).SetModel();
	}
}

public void ManageBossDeath(const BaseBoss base)
{
	Action act = Call_OnBossDeath(base);
	if( act > Plugin_Changed )
		return;
	
	switch( base.iBossType ) {
		case -1: {}
		case Hale:		ToCHale(base).Death();
		case Vagineer:		ToCVagineer(base).Death();
		case CBS:		ToCChristian(base).Death();
		case HHHjr:		ToCHHHJr(base).Death();
		case Bunny:		ToCBunny(base).Death();
	}
	gamemode.iHealthBarState = !gamemode.iHealthBarState;
}

public void ManageBossEquipment(const BaseBoss base)
{
	Action act = Call_OnBossEquipped(base);
	if( act > Plugin_Changed )
		return;
		
	switch( base.iBossType ) {
		case -1: {}
		case Hale:		ToCHale(base).Equip();
		case Vagineer:		ToCVagineer(base).Equip();
		case CBS:		ToCChristian(base).Equip();
		case HHHjr:		ToCHHHJr(base).Equip();
		case Bunny:		ToCBunny(base).Equip();
	}
}

/** whatever stuff needs initializing should be done here */
public void ManageBossTransition(const BaseBoss base)
{
	switch( base.iBossType ) {
		case -1: {}
		case Hale:
			TF2_SetPlayerClass(base.index, TFClass_Soldier, _, false);
		case Vagineer:
			TF2_SetPlayerClass(base.index, TFClass_Engineer, _, false);
		case CBS:
			TF2_SetPlayerClass(base.index, TFClass_Sniper, _, false);
		case HHHjr, Bunny:
			TF2_SetPlayerClass(base.index, TFClass_DemoMan, _, false);
	}
	ManageBossModels(base);
	/// Patch: Aug 18, 2018 - patching bad first person animations on custom boss models.
	Call_OnBossInitialized(base);
	ManageBossEquipment(base);
}

public void ManageMinionTransition(const BaseBoss base)
{
	if( !base.bIsMinion )
		return;
	
	base.ForceTeamChange(VSH2Team_Boss); /// Force our guy to the dark side lmao
	int ent = -1;
	while( (ent = FindEntityByClassname(ent, "tf_wearable")) != -1 ) {
		if( GetOwner(ent) == base.index ) {
			int index = GetItemIndex(ent);
			switch( index ) {
				case 438, 463, 167, 477, 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 1015, 5607: {}
				default: TF2_RemoveWearable(base.index, ent); //AcceptEntityInput(ent, "kill");
			}
		}
	}
	ent = -1;
	while( (ent = FindEntityByClassname(ent, "tf_powerup_bottle")) != -1 ) {
		if( GetOwner(ent) == base.index ) {
			int index = GetItemIndex(ent);
			switch( index ) {
				case 438, 463, 167, 477, 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 1015, 5607: {}
				default: TF2_RemoveWearable(base.index, ent); //AcceptEntityInput(ent, "kill");
			}
		}
	}
	ent = -1;
	while( (ent = FindEntityByClassname(ent, "tf_wearable_demoshield")) != -1 ) {
		if( GetOwner(ent) == base.index )
			TF2_RemoveWearable(base.index, ent);
	}
	
	BaseBoss master = BaseBoss(base.iOwnerBoss);
	Call_OnMinionInitialized(base, master);
}

public void ManagePlayBossIntro(const BaseBoss base)
{
	Action act = Call_OnBossPlayIntro(base);
	if( act > Plugin_Changed )
		return;
	
	switch( base.iBossType ) {
		case -1: {}
		case Hale:	ToCHale(base).PlaySpawnClip();
		case Vagineer:	ToCVagineer(base).PlaySpawnClip();
		case CBS:	ToCChristian(base).PlaySpawnClip();
		case HHHjr:	ToCHHHJr(base).PlaySpawnClip();
		case Bunny:	ToCBunny(base).PlaySpawnClip();
	}
}

public Action ManageOnBossTakeDamage(const BaseBoss victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	switch( victim.iBossType ) {
		case -1: {}
		default: {
			int bFallDamage = (damagetype & DMG_FALL);
			char trigger[32];
			if( attacker > MaxClients && GetEdictClassname(attacker, trigger, sizeof(trigger)) && !strcmp(trigger, "trigger_hurt", false) )
			{
				Action act = Call_OnBossTakeDamage_OnTriggerHurt(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
				if( act > Plugin_Changed )
					return Plugin_Continue;
				
				if( gamemode.bTeleToSpawn || damage >= victim.iHealth )
					victim.TeleToSpawn(VSH2Team_Boss);
				/// TODO: add cvar for trigger_hurt threshold
				else if( damage >= 200.0 ) {
					if( victim.iBossType==HHHjr )
						victim.flCharge = HALEHHH_TELEPORTCHARGE;
					else victim.bSuperCharge = true;
				}
				
				if( damage > 500.0 ) {
					if( act != Plugin_Changed )
						damage = 500.0;
					return Plugin_Changed;
				}
			} else if( attacker <= 0 && bFallDamage ) {
				if( Call_OnBossTakeFallDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) != Plugin_Changed )
					damage = (victim.iHealth > 100) ? 1.0 : 30.0;
				return Plugin_Changed;
			}
			
			if( attacker <= 0 || attacker > MaxClients )
				return Plugin_Continue;
			
			victim.iHits++;
			char classname[64], inflictor_name[32];
			if( IsValidEntity(inflictor) )
				GetEntityClassname(inflictor, inflictor_name, sizeof(inflictor_name));
			if( IsValidEntity(weapon) )
				GetEdictClassname(weapon, classname, sizeof(classname));
			
			/// Bosses shouldn't die from a single backstab
			int wepindex = GetItemIndex(weapon);
			if( damagecustom == TF_CUSTOM_BACKSTAB || (!strcmp(classname, "tf_weapon_knife", false) && damage > victim.iHealth) ) {
				float changedamage = ( (Pow(float(victim.iMaxHealth)*0.0014, 2.0) + 899.0) - (float(victim.iMaxHealth)*(float(victim.iStabbed)/100)) );
				if( victim.iStabbed < 4 )
					victim.iStabbed++;
				
				/// You can level "damage dealt" with backstabs
				damage = changedamage/3;
				damagetype |= DMG_CRIT;
				EmitSoundToAll("player/spy_shield_break.wav", victim.index, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, true, 0.0);
				EmitSoundToAll("player/crit_received3.wav", victim.index, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, true, 0.0);
				
				float curtime = GetGameTime();
				SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", curtime+2.0);
				SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", curtime+2.0);
				SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", curtime+2.0);
				
				int vm = GetEntPropEnt(attacker, Prop_Send, "m_hViewModel");
				if( vm > MaxClients && IsValidEntity(vm) && TF2_GetPlayerClass(attacker) == TFClass_Spy ) {
					int melee = GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee);
					int anim = 15;
					switch( melee ) {
						case 727: anim = 41;
						case 4, 194, 665, 794, 803, 883, 892, 901, 910: anim = 10;
						case 638: anim = 31;
					}
					SetEntProp(vm, Prop_Send, "m_nSequence", anim);
				}
				char boss_name[MAX_BOSS_NAME_SIZE];
				victim.GetName(boss_name);
				PrintCenterText(attacker, "You Tickled %s!", boss_name);
				PrintCenterText(victim.index, "You Were Just Tickled!");
				int pistol = GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary);
				
				/// Diamondback gains 2 crits on backstab
				if( pistol == 525 ) {
					int iCrits = GetEntProp(attacker, Prop_Send, "m_iRevengeCrits");
					SetEntProp(attacker, Prop_Send, "m_iRevengeCrits", iCrits+2);
				}
				
				/// connivers kunai
				if( wepindex == 356 ) {
					int health = GetClientHealth(attacker)+180;
					if (health > 195)
						health = 250;
					SetEntProp(attacker, Prop_Data, "m_iHealth", health);
					SetEntProp(attacker, Prop_Send, "m_iHealth", health);
				}
				
				/// Big Earner gives full cloak on backstab
				else if( wepindex == 461 )
					SetEntPropFloat(attacker, Prop_Send, "m_flCloakMeter", 100.0);
				
				if( Call_OnBossTakeDamage_OnStabbed(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) != Plugin_Changed ) {
					switch( victim.iBossType ) {
						case Hale:      ToCHale(victim).Stabbed();
						case Vagineer:  ToCVagineer(victim).Stabbed();
						case HHHjr:     ToCHHHJr(victim).Stabbed();
						case Bunny:     ToCBunny(victim).Stabbed();
					}
					return Plugin_Changed;
				}
				return Plugin_Changed;
			}
			
			if( damagecustom == TF_CUSTOM_TELEFRAG ) {
				if( Call_OnBossTakeDamage_OnTelefragged(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) != Plugin_Changed ) {
					damage = victim.iHealth+0.2;
				}
				int teleowner = FindTeleOwner(attacker);
				if( teleowner != -1 && teleowner != attacker ) {
					BaseBoss builder = BaseBoss(teleowner);
					builder.iDamage += RoundFloat(damage) / 2;
				}
				return Plugin_Changed;
			}
			
			if( cvarVSH2[Anchoring].BoolValue ) {
				int iFlags = GetEntityFlags(victim.index);
#if defined _tf2attributes_included
				if( gamemode.bTF2Attribs ) {
					/// If Hale is ducking on the ground, it's harder to knock him back
					if( (iFlags & (FL_ONGROUND|FL_DUCKING)) == (FL_ONGROUND|FL_DUCKING) )
						TF2Attrib_SetByDefIndex(victim.index, 252, 0.0);
					else TF2Attrib_RemoveByDefIndex(victim.index, 252);
				} else {
					/// Does not protect against sentries or FaN, but does against miniguns and rockets
					if( (iFlags & (FL_ONGROUND|FL_DUCKING)) == (FL_ONGROUND|FL_DUCKING) )
						damagetype |= DMG_PREVENT_PHYSICS_FORCE;
				}
#else
				if( (iFlags & (FL_ONGROUND|FL_DUCKING)) == (FL_ONGROUND|FL_DUCKING) )
					damagetype |= DMG_PREVENT_PHYSICS_FORCE;
#endif
			}
			
			/// Gives 4 heads if successful sword killtaunt!
			/// TODO: add cvar for this?
			if( damagecustom == TF_CUSTOM_TAUNT_BARBARIAN_SWING ) {
				repeat(4) IncrementHeadCount(attacker);
				if( Call_OnBossTakeDamage_OnSwordTaunt(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) == Plugin_Changed )
					return Plugin_Changed;
			}
			
			/// Heavy Shotguns heal for damage dealt
			if( StrContains(classname, "tf_weapon_shotgun", false) > -1 && TF2_GetPlayerClass(attacker) == TFClass_Heavy ) {
				return Call_OnBossTakeDamage_OnHeavyShotgun(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
			} else if( StrContains(classname, "tf_weapon_sniperrifle", false) > -1 && gamemode.iRoundState != StateEnding ) {
				if( wepindex != 230 && wepindex != 526 && wepindex != 752 && wepindex != 30665 ) {
					float bossGlow = victim.flGlowtime;
					float chargelevel = (IsValidEntity(weapon) && weapon > MaxClients ? GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") : 0.0);
					float time = (bossGlow > 10 ? 1.0 : 2.0);
					time += (bossGlow > 10 ? (bossGlow > 20 ? 1 : 2) : 4)*(chargelevel/100);
					bossGlow += RoundToCeil(time);
					if( bossGlow > 30.0 )
						bossGlow = 30.0; /// TODO: Add cvar for this?
					victim.flGlowtime = bossGlow;
				}
				/// bazaar bargain I think
				if( wepindex == 402 && damagecustom == TF_CUSTOM_HEADSHOT )
					IncrementHeadCount(attacker, false);
				if( wepindex == 752 ) {
					float chargelevel = (IsValidEntity(weapon) && weapon > MaxClients ? GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") : 0.0);
					float add = 10 + (chargelevel / 10);
					if( TF2_IsPlayerInCondition(attacker, view_as< TFCond >(46)) )
						add /= 3.0;
					float rage = GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");
					SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", (rage + add > 100) ? 100.0 : rage + add);
				}
				
				if( wepindex == 230 )
					victim.flRAGE -= (damage * cvarVSH2[SydneySleeperRageRemove].FloatValue);
				
				if( !(damagetype & DMG_CRIT) ) {
					bool ministatus = (TF2_IsPlayerInCondition(attacker, TFCond_CritCola) || TF2_IsPlayerInCondition(attacker, TFCond_Buffed) || TF2_IsPlayerInCondition(attacker, TFCond_CritHype));
					if( Call_OnBossTakeDamage_OnSniped(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) != Plugin_Changed ) {
						damage *= (ministatus) ? 2.222222 : 3.0;
						return Plugin_Changed;
					}
					return Plugin_Changed;
				}
			}
			
			switch( wepindex ) {
				/// Third Degree
				case 593: {
					int medics;
					int numhealers = GetEntProp(attacker, Prop_Send, "m_nNumHealers");
					int healer;
					int i;
					for( i=0; i<numhealers; i++ ) {
						/// Dispensers > MaxClients
						if( 0 < GetHealerByIndex(attacker, i) <= MaxClients )
							medics++;
					}
					for( i=0; i<numhealers; i++ ) {
						if( 0 < (healer = GetHealerByIndex(attacker, i)) <= MaxClients ) {
							int medigun = GetPlayerWeaponSlot(healer, TFWeaponSlot_Secondary);
							if( IsValidEntity(medigun) ) {
								char cls[32];
								GetEdictClassname(medigun, cls, sizeof(cls));
								if( !strcmp(cls, "tf_weapon_medigun", false) ) {
									float uber = GetMediCharge(medigun) + (0.1/medics);
									float max = 1.0;
									if( GetEntProp(medigun, Prop_Send, "m_bChargeRelease") )
										max = 1.5;
									if( uber > max )
										uber = max;
									SetMediCharge(medigun, uber);
								}
							}
						}
					}
					if( Call_OnBossTakeDamage_OnThirdDegreed(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) == Plugin_Changed ) {
						return Plugin_Changed;
					}
				}
				/*
				case 14, 201, 230, 402, 526, 664, 752, 792, 801, 851, 881, 890, 899, 908, 957, 966, 1098: {
					switch (wepindex) {	/// cleaner to read than if wepindex == || wepindex == || etc.
						case 14, 201, 664, 792, 801, 851, 881, 890, 899, 908, 957, 966: {	/// sniper rifles
							if (gamemode.iRoundState != StateEnding) {
								float bossGlow = victim.flGlowtime;
								float chargelevel = (IsValidEntity(weapon) && weapon > MaxClients ? GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") : 0.0);
								float time = (bossGlow > 10 ? 1.0 : 2.0);
								time += (bossGlow > 10 ? (bossGlow > 20 ? 1 : 2) : 4)*(chargelevel/100);
								bossGlow += RoundToCeil(time);
								if( bossGlow > 30.0 )
									bossGlow = 30.0;
								victim.flGlowtime = bossGlow;
							}
						}
					}
					if( wepindex == 402 ) {	/// bazaar bargain I think
						if( damagecustom == TF_CUSTOM_HEADSHOT )
							IncrementHeadCount(attacker, false);
					}
					if( wepindex == 752 && gamemode.iRoundState != StateEnding ) {
						float chargelevel = (IsValidEntity(weapon) && weapon > MaxClients ? GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") : 0.0);
						float add = 10 + (chargelevel 0/ 10);
						if( TF2_IsPlayerInCondition(attacker, view_as< TFCond >(46)) )
							add /= 3;
						float rage = GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");
						SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", (rage + add > 100) ? 100.0 : rage + add);
					}
					if( !(damagetype & DMG_CRIT) ) {
						bool ministatus = (TF2_IsPlayerInCondition(attacker, TFCond_CritCola) || TF2_IsPlayerInCondition(attacker, TFCond_Buffed) || TF2_IsPlayerInCondition(attacker, TFCond_CritHype));

						damage *= (ministatus) ? 2.222222 : 3.0;
						if (wepindex == 230) {
							victim.flRAGE -= (damage * 0.035);
						}
						return Plugin_Changed;
					}
					else if( wepindex == 230 )
						victim.flRAGE -= (damage * 0.035);
				}
				*/
				/// Swords
				case 132, 266, 482, 1082: {
					IncrementHeadCount(attacker);
					if( Call_OnBossTakeDamage_OnHitSword(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) == Plugin_Changed )
						return Plugin_Changed;
				}
				/// Fan O War
				case 355: {
					victim.flRAGE -= cvarVSH2[FanoWarRage].FloatValue;
					if( Call_OnBossTakeDamage_OnHitFanOWar(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) == Plugin_Changed )
						return Plugin_Changed;
				}
				/// Candy Cane
				case 317: {
					SpawnSmallHealthPackAt(attacker, GetClientTeam(attacker));
					if( Call_OnBossTakeDamage_OnHitCandyCane(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) == Plugin_Changed )
						return Plugin_Changed;
				}
				
				/// Chdata's Market Gardener backstab
				case 416: {
					if( BaseBoss(attacker).bInJump ) {
						damage = ( Pow(float(victim.iMaxHealth), (0.74074))/*512.0*/ - (victim.iMarketted/128*float(victim.iMaxHealth)) )/3.0;
						
						damage *= gamemode.CountBosses(true);
						
						/// divide by 3 because this is basedamage and lolcrits (0.714286)) + 1024.0)
						damagetype |= DMG_CRIT;
						if( victim.iMarketted < 5 )
							victim.iMarketted++;
						
						char name[MAX_BOSS_NAME_SIZE]; victim.GetName(name);
						PrintCenterText(attacker, "You Market Gardened %s!", name);
						PrintCenterText(victim.index, "You Were Just Market Gardened!");
						
						EmitSoundToAll("player/doubledonk.wav", victim.index, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, true, 0.0);
						SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+2.0);
						
						if( Call_OnBossTakeDamage_OnMarketGardened(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) != Plugin_Changed )
							return Plugin_Changed;
						return Plugin_Changed;
					}
				}
				/// PowerJackass
				case 214: {
					int health = GetClientHealth(attacker);
					int max = GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
					int newhealth = health+25;
					if( health < max+50 ) {
						if( newhealth > max+50 )
							newhealth = max+50;
						SetEntProp(attacker, Prop_Data, "m_iHealth", newhealth);
						SetEntProp(attacker, Prop_Send, "m_iHealth", newhealth);
					}
					if( TF2_IsPlayerInCondition(attacker, TFCond_OnFire) )
						TF2_RemoveCondition(attacker, TFCond_OnFire);
					
					if( Call_OnBossTakeDamage_OnPowerJack(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) == Plugin_Changed )
						return Plugin_Changed;
				}
				/// Katana
				case 357: {
					SetEntProp(weapon, Prop_Send, "m_bIsBloody", 1);
					if( GetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy") < 1 )
						SetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
					int health = GetClientHealth(attacker);
					int max = GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
					int newhealth = health+35;
					if( health < max+25 ) {
						if( newhealth > max+25 )
							newhealth = max+25;
						SetEntProp(attacker, Prop_Data, "m_iHealth", newhealth);
						SetEntProp(attacker, Prop_Send, "m_iHealth", newhealth);
					}
					if( TF2_IsPlayerInCondition(attacker, TFCond_OnFire) )
						TF2_RemoveCondition(attacker, TFCond_OnFire);
					//int weap = GetPlayerWeaponSlot(victim.index, TFWeaponSlot_Melee);
					//int index = GetItemIndex(weap);
					//int active = GetEntPropEnt(victim.index, Prop_Send, "m_hActiveWeapon");
					if( Call_OnBossTakeDamage_OnKatana(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) == Plugin_Changed )
						return Plugin_Changed;
					/*
					if( index == 357 && active == weap ) {
						damage = 195.0 / 3.0;
						return Plugin_Changed;
					}
					*/
				}
				/// Ambassador + Festive ver.
				case 61, 1006: {  /// Ambassador does 2.5x damage on headshot
					if( damagecustom == TF_CUSTOM_HEADSHOT ) {
						if( Call_OnBossTakeDamage_OnAmbassadorHeadshot(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) != Plugin_Changed )
							damage *= 2.5;
						return Plugin_Changed;
					}
				}
				/*
				case 16, 203, 751, 1149: {  /// SMG does 2.5x damage on headshot
					if( damagecustom == TF_CUSTOM_HEADSHOT ) {
						damage = 27.0;
						return Plugin_Changed;
					}
				}
				*/
				/// Diamondback & Manmelter
				case 525, 595: {
					/// If a revenge crit was used, give a damage bonus
					int iCrits = GetEntProp(attacker, Prop_Send, "m_iRevengeCrits");
					if( iCrits ) {
						if( Call_OnBossTakeDamage_OnDiamondbackManmelterCrit(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) != Plugin_Changed )
							damage = 85.0;
						return Plugin_Changed;
					}
				}
				/// Tickle Hoovy Fists.
				case 656: {
					SetPawnTimer(_StopTickle, cvarVSH2[StopTickleTime].FloatValue, victim.userid);
					if( TF2_IsPlayerInCondition(attacker, TFCond_Dazed) )
						TF2_RemoveCondition(attacker, TFCond_Dazed);
					
					if( Call_OnBossTakeDamage_OnHolidayPunch(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) == Plugin_Changed )
						return Plugin_Changed;
				}
			}
			
			if( !(GetEntityFlags(victim.index) & FL_ONGROUND) && !StrContains(inflictor_name, "tf_projectile_", false) ) {
				float ray_angle[] = { 90.0, 0.0, 0.0 };
				TR_TraceRayFilter(damagePosition, ray_angle, MASK_PLAYERSOLID_BRUSHONLY, RayType_Infinite, TraceRayIgnoreEnts);
				if( TR_DidHit() ) {
					float end_pos[3]; TR_GetEndPosition(end_pos);
					if( GetVectorDistance(damagePosition, end_pos) >= cvarVSH2[AirShotDist].FloatValue )
						if( Call_OnBossAirShotProj(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) )
							return Plugin_Changed;
				}
			}
			
			/// everything else covered here.
			return Call_OnBossTakeDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
		}
	}
	return Plugin_Continue;
}

public Action ManageOnBossDealDamage(const BaseBoss victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	BaseBoss fighter = BaseBoss(attacker);
	switch( fighter.iBossType ) {
		case -1: {}
		default: {
			victim.iHits++;
			if( damagetype & DMG_CRIT )
				damagetype &= ~DMG_CRIT;
			
			int client = victim.index;
			if( damagecustom == TF_CUSTOM_BOOTS_STOMP ) {
				if( Call_OnBossDealDamage_OnStomp(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) != Plugin_Changed ) {
					float flFallVelocity = GetEntPropFloat(inflictor, Prop_Send, "m_flFallVelocity");
					/// TF2 Fall Damage formula, modified for VSH2
					damage = 10.0 * (GetRandomFloat(0.8, 1.2) * (5.0 * (flFallVelocity / 300.0)));
				}
				return Plugin_Changed;
			}
			if( TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed) ) {
				if( Call_OnBossDealDamage_OnHitDefBuff(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) != Plugin_Changed ) {
					ScaleVector(damageForce, 9.0);
					damage *= 0.3;
				}
				return Plugin_Changed;
			}
			/*
			if( TF2_IsPlayerInCondition(client, TFCond_DefenseBuffMmmph) ) {
				damage *= 9;
				/// Patch: Nov 14, 2017 - removing post-bonk slowdown.
				TF2_AddCondition(client, TFCond_UberchargedOnTakeDamage, 0.1);
				return Plugin_Changed;
			}
			*/
			if( TF2_IsPlayerInCondition(client, TFCond_CritMmmph) ) {
				if( Call_OnBossDealDamage_OnHitCritMmmph(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) != Plugin_Changed ) {
					damage *= 0.25;
					return Plugin_Changed;
				}
				return Plugin_Changed;
			}
			
			int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
			char mediclassname[32];
			if( IsValidEntity(medigun)
				&& GetEdictClassname(medigun, mediclassname, sizeof(mediclassname))
				&& !strcmp(mediclassname, "tf_weapon_medigun", false)
				&& !TF2_IsPlayerInCondition(client, TFCond_Ubercharged)
				&& weapon == GetPlayerWeaponSlot(attacker, 2)) {
				/**
					If medic has (nearly) full uber, use it as a single-hit shield to prevent medics from dying early.
					Entire team is pretty much screwed if all the medics just die.
				*/
				if( Call_OnBossDealDamage_OnHitMedic(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) != Plugin_Changed ) {
					if( cvarVSH2[MedicUberShield].BoolValue && GetMediCharge(medigun) >= 0.90 ) {
						SetMediCharge(medigun, 0.1);
						ScaleVector(damageForce, 9.0);
						damage *= 0.1;
						/// Patch: Nov 14, 2017 - removing post-bonk slowdown.
						//TF2_AddCondition(client, TFCond_UberchargedOnTakeDamage, 0.1);
						TF2_AddCondition(client, TFCond_SpeedBuffAlly, 5.0);
						return Plugin_Changed;
					}
				}
				return Plugin_Changed;
			}
			
			/// eggs probably do melee damage to spies, then? That's not ideal, but eh.
			if( TF2_GetPlayerClass(client) == TFClass_Spy ) {
				if( GetEntProp(client, Prop_Send, "m_bFeignDeathReady") || TF2_IsPlayerInCondition(client, TFCond_Cloaked) ) {
					if( GetClientCloakIndex(client) == 59 ) {
						if( Call_OnBossDealDamage_OnHitDeadRinger(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) != Plugin_Changed ) {
							if( damagetype & DMG_CRIT )
								damagetype &= ~DMG_CRIT;
							if( damagetype & DMG_CLUB )
								damage = cvarVSH2[DeadRingerDamage].FloatValue / FindConVar("tf_feign_death_damage_scale").FloatValue;
							return Plugin_Changed;
						}
						return Plugin_Changed;
					} else {
						if( Call_OnBossDealDamage_OnHitCloakedSpy(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) != Plugin_Changed ) {
							if( damagetype & DMG_CRIT )
								damagetype &= ~DMG_CRIT;
							if( damagetype & DMG_CLUB )
								damage = cvarVSH2[CloakDamage].FloatValue / FindConVar("tf_stealth_damage_reduction").FloatValue;
							return Plugin_Changed;
						}
						return Plugin_Changed;
					}
				}
			}
			
			/// TODO: Fix up this code into a separate stock. Same with Razorback one.
			int ent = -1;
			while( (ent = FindEntityByClassname(ent, "tf_wearable_demoshield")) != -1 ) {
				if( GetOwner(ent) == client
					&& !TF2_IsPlayerInCondition(client, TFCond_Ubercharged)
					&& !GetEntProp(ent, Prop_Send, "m_bDisguiseWearable")
					&& weapon == GetPlayerWeaponSlot(attacker, 2) )
				{
					if( Call_OnBossDealDamage_OnHitShield(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) != Plugin_Changed ) {
						/// Patch: Nov 14, 2017 - removing post-bonk slowdown.
						TF2_AddCondition(client, TFCond_PasstimeInterception, 0.1);
						TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.0);
						TF2_RemoveWearable(client, ent);
						EmitSoundToAll("player/spy_shield_break.wav", client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, true, 0.0);
						return Plugin_Continue;
					}
					return Plugin_Changed;
				}
			}
			ent = -1;
			while( (ent = FindEntityByClassname(ent, "tf_wearable_razorback")) != -1 ) {
				if( GetOwner(ent) == client
					&& !TF2_IsPlayerInCondition(client, TFCond_Ubercharged)
					&& !GetEntProp(ent, Prop_Send, "m_bDisguiseWearable")
					&& weapon == GetPlayerWeaponSlot(attacker, 2)
					&& damage >= GetClientHealth(client)+0.0 )
				{
					if( Call_OnBossDealDamage_OnHitShield(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom) != Plugin_Changed ) {
						/// Patch: Nov 14, 2017 - removing post-bonk slowdown.
						TF2_AddCondition(client, TFCond_PasstimeInterception, 0.1);
						TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.0);
						TF2_RemoveWearable(client, ent);
						EmitSoundToAll("player/spy_shield_break.wav", client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, true, 0.0);
						return Plugin_Continue;
					}
					return Plugin_Changed;
				}
			}
			return Call_OnBossDealDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
		}
	}
	return Plugin_Continue;
}

#if defined _goomba_included_
public Action ManageOnGoombaStomp(int attacker, int client, float& damageMultiplier, float& damageAdd, float& JumpPower)
{
	BaseBoss boss = BaseBoss(client);
	/// Players Stomping the Boss
	if( boss.bIsBoss ) {
		switch( boss.iBossType ) {
			/// Ignore if not boss at all.
			case -1: {}
			/// Default behaviour for Goomba Stompoing the Boss
			default: {
				/// Prevent goomba stomp for mantreads/demo boots if being able to is disabled.
				if (IsValidEntity(FindPlayerBack(attacker, { 444, 405, 608 }, 3)) && !cvarVSH2[CanMantreadsGoomba].BoolValue)
					return Plugin_Handled;
				
				damageAdd = float(cvarVSH2[GoombaDamageAdd].IntValue);
				damageMultiplier = cvarVSH2[GoombaLifeMultiplier].FloatValue;
				JumpPower = cvarVSH2[GoombaReboundPower].FloatValue;
				
				//PrintToChatAll("%N Just Goomba stomped %N(The Boss)!", attacker, client);
				CPrintToChatAllEx(attacker, "{olive}>> {teamcolor}%N {default}just goomba stomped {unique}%N{default}!", attacker, client);
				return Plugin_Changed;
			}
		}
   		return Plugin_Continue;
	}
	
	boss = BaseBoss(attacker);
	/// The Boss(es) Stomping a player
	if( boss.bIsBoss ) {
		switch (boss.iBossType) {
			/// Ignore if not boss at all.
			case -1: {}
			/// Default behaviour for the Boss Goomba Stomping other players.
			default: {
				/// Block the Boss from Goomba Stomping if disabled.
				if( !cvarVSH2[CanBossGoomba].BoolValue )
					return Plugin_Handled;
				/// If the demo had a shield to break
				if( RemoveDemoShield(client) || RemoveRazorBack(client) ) {
					EmitSoundToAll("player/spy_shield_break.wav", client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, true, 0.0);
					/// Patch: Nov 14, 2017 - removing post-bonk slowdown.
					TF2_AddCondition(client, TFCond_PasstimeInterception, 0.1);
					TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.0);
					damageAdd = 0.0;
					damageMultiplier = 0.0;
					//JumpPower = 0.0;
					return Plugin_Changed;
				}
				//PrintToChatAll("%N(The Boss) just got stomped by %N!", client, attacker);
			}
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}
#endif

public void ManageBossKillPlayer(const BaseBoss attacker, const BaseBoss victim, Event event)
{
	Action act = Call_OnPlayerKilled(attacker, victim, event);
	if( act > Plugin_Changed )
		return;
	
	//int dmgbits = event.GetInt("damagebits");
	int deathflags = event.GetInt("death_flags");
	
	/// If victim is a boss, kill him off
	if( victim.bIsBoss )
		RequestFrame(_BossDeath, victim.userid);
		//SetPawnTimer(_BossDeath, 0.1, victim.userid);
	
	if( attacker.bIsBoss ) {
		switch( attacker.iBossType ) {
			case -1: {}
			case Hale: {
				if( deathflags & TF_DEATHFLAG_DEADRINGER )
					event.SetString("weapon", "fists");
				else ToCHale(attacker).KilledPlayer(victim, event);
			}
			case Vagineer:	ToCVagineer(attacker).KilledPlayer(victim, event);
			case CBS:	ToCChristian(attacker).KilledPlayer(victim, event);
			case HHHjr:	ToCHHHJr(attacker).KilledPlayer(victim, event);
			case Bunny:	ToCBunny(attacker).KilledPlayer(victim, event);
		}
	}
}
public void ManageHurtPlayer(const BaseBoss attacker, const BaseBoss victim, Event event)
{
	Action act = Call_OnPlayerHurt(attacker, victim, event);
	if( act > Plugin_Changed )
		return;
	
	int damage = event.GetInt("damageamount");
	int custom = event.GetInt("custom");
	int weapon = event.GetInt("weaponid");
	switch( victim.iBossType ) {
		case -1: {}
		case Hale, Vagineer, CBS, HHHjr, Bunny: {
			victim.GiveRage(damage);
		}
	}
	
	/// Minions shouldn't have their damage tracked.
	if( attacker.bIsMinion )
		return;
	
	
	/// Telefrags normally 1-shot the boss but let's cap damage at 9k
	if( custom == TF_CUSTOM_TELEFRAG )
		damage = (IsPlayerAlive(attacker.index) ? 9001 : 1);
	
	/// block off bosses from doing the rest of things but track their damage.
	attacker.iDamage += damage;
	if( attacker.bIsBoss )
		return;
	
	if( !GetEntProp(attacker.index, Prop_Send, "m_bShieldEquipped")
		&& GetPlayerWeaponSlot(attacker.index, TFWeaponSlot_Secondary) <= 0
		&& TF2_GetPlayerClass(attacker.index) == TFClass_DemoMan )
	{
		int iReqDmg = cvarVSH2[ShieldRegenDmgReq].IntValue;
		if( iReqDmg>0 ) {
			attacker.iShieldDmg += damage;
			if( attacker.iShieldDmg >= iReqDmg ) {
				/// TODO: figure out a better way to regenerate shield.
				/// save data so we can get our shield back.
				/// save health, heads, and weapon data.
				int client = attacker.index;
				int health = GetClientHealth(client);
				
				int heads;
				if( HasEntProp(client, Prop_Send, "m_iDecapitations") )
					heads = GetEntProp(client, Prop_Send, "m_iDecapitations");
				int primammo = GetAmmo(client, TFWeaponSlot_Primary);
				int primclip = GetClip(client, TFWeaponSlot_Primary);
				
				/// "respawn" player.
				TF2_RegeneratePlayer(client);
				
				/// reset old data
				SetEntityHealth(client, health);
				
				/// PATCH Sept 22, 2019: Demos that lost shield but changed loadouts during round retaining their heads...
				if( HasEntProp(client, Prop_Send, "m_iDecapitations") && heads > 0 ) {
					if( GetEntProp(client, Prop_Send, "m_bShieldEquipped") )
						SetEntProp(client, Prop_Send, "m_iDecapitations", heads);
					else SetEntProp(client, Prop_Send, "m_iDecapitations", 0);
				}
				SetAmmo(client, TFWeaponSlot_Primary, primammo);
				SetClip(client, TFWeaponSlot_Primary, primclip);
				attacker.iShieldDmg = 0;
			}
		}
	}
	
	/// Compatibility patch for Randomizer
	if( GetIndexOfWeaponSlot(attacker.index, TFWeaponSlot_Primary) == 1104 ) {
		if( weapon == TF_WEAPON_ROCKETLAUNCHER )
			attacker.iAirDamage += damage;
		int div = cvarVSH2[AirStrikeDamage].IntValue;
		SetEntProp(attacker.index, Prop_Send, "m_iDecapitations", attacker.iAirDamage/div);
	}
	
	/// Heavy Shotgun healing.
	else if( TF2_GetPlayerClass(attacker.index)==TFClass_Heavy && weapon==TF_WEAPON_SHOTGUN_HWG ) {
		int health = GetClientHealth(attacker.index);
		int maxhp = GetEntProp(attacker.index, Prop_Data, "m_iMaxHealth");
		int heavy_overheal = RoundFloat(FindConVar("tf_max_health_boost").FloatValue * maxhp);
		int health_from_dmg = ( health < maxhp ) ? (maxhp - health) % damage : (heavy_overheal - health) % damage;
		SetEntityHealth(attacker.index, (!health_from_dmg) ?
													((health + damage) >> view_as< int >((health > maxhp))) :
													(health + health_from_dmg));
	}
	
	/// Medics now count as 3/5 of a backstab, similar to telefrag assists.
	int healers = GetEntProp(attacker.index, Prop_Send, "m_nNumHealers");
	int healercount;
	for( int i=0; i<healers; i++) {
		if( 0 < GetHealerByIndex(attacker.index, i) <= MaxClients )
			healercount++;
	}
	
	BaseBoss medic;
	for( int r=0; r<healers; r++ ) {
		medic = BaseBoss(GetHealerByIndex(attacker.index, r));
		if( 0 < medic.index <= MaxClients ) {
			if( damage < 10 || medic.iUberTarget == attacker.userid )
				medic.iDamage += damage;
			else medic.iDamage += damage/(healercount+1);
		}
	}
}

public void ManagePlayerAirblast(const BaseBoss airblaster, const BaseBoss airblasted, Event event)
{
	Action act = Call_OnPlayerAirblasted(airblaster, airblasted, event);
	if( act > Plugin_Changed )
		return;
	
	switch( airblasted.iBossType ) {
		case -1: {}
		case Hale, CBS, HHHjr, Bunny:
			airblasted.flRAGE += cvarVSH2[AirblastRage].FloatValue;
		case Vagineer: {
			if( TF2_IsPlayerInCondition(airblasted.index, TFCond_Ubercharged) ) {
				float dur = GetConditionDuration(airblasted.index, TFCond_Ubercharged);
				SetConditionDuration(airblasted.index, TFCond_Ubercharged, dur + 2.0 < VAG_UBER_TIME ? dur + 2.0 : VAG_UBER_TIME);
				//TF2_AddCondition(airblasted.index, TFCond_Ubercharged, 2.0);
			}
			else airblasted.flRAGE += cvarVSH2[AirblastRage].FloatValue;
		}
	}
}

public Action ManageTraceHit(const BaseBoss victim, const BaseBoss attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup)
{
	return Call_OnTraceAttack(victim, attacker, inflictor, damage, damagetype, ammotype, hitbox, hitgroup);
}
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if( !cvarVSH2[Enabled].BoolValue || !IsPlayerAlive(client) )
		return Plugin_Continue;

	BaseBoss base = BaseBoss(client);
	switch( base.iBossType ) {
		case -1: {}
		case Bunny: {
			if( GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) == GetActiveWep(client) ) {
				buttons &= ~IN_ATTACK;
				return Plugin_Changed;
			}
		}
		case HHHjr: {
			if( base.flCharge >= 47.0 && (buttons & IN_ATTACK) ) {
				buttons &= ~IN_ATTACK;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	BaseBoss player = BaseBoss(client);
	if( !player.bIsBoss )
		return;

	switch( condition ) {
		case TFCond_Disguised, TFCond_Jarated, TFCond_MarkedForDeath:
			TF2_RemoveCondition(client, condition);
	}
}

public void ManageBossMedicCall(const BaseBoss base)
{
	Action act = Call_OnBossMedicCall(base);
	if( act > Plugin_Changed )
		return;
	
	switch( base.iBossType ) {
		case -1: {}
		case Hale, Vagineer, CBS, HHHjr, Bunny: {
			if( base.flRAGE < 100.0 )
				return;
			DoTaunt(base.index, "", 0);
			base.flRAGE = 0.0;
		}
	}
}
public void ManageBossTaunt(const BaseBoss base)
{
	Action act = Call_OnBossTaunt(base);
	if( act > Plugin_Changed )
		return;
	
	switch( base.iBossType ) {
		case -1: {}
		case Hale:	ToCHale(base).RageAbility();
		case Vagineer:	ToCVagineer(base).RageAbility();
		case CBS:	ToCChristian(base).RageAbility();
		case HHHjr:	ToCHHHJr(base).RageAbility();
		case Bunny:	ToCBunny(base).RageAbility();
	}
}
public void ManageBuildingDestroyed(const BaseBoss base, const int building, const int objecttype, Event event)
{
	Action act = Call_OnBossKillBuilding(base, building, event);
	if( act > Plugin_Changed )
		return;
	
	switch( base.iBossType ) {
		case -1: {}
		case Hale: {
			event.SetString("weapon", "fists");
			ToCHale(base).KillToy();
		}
	}
}
public void ManagePlayerJarated(const BaseBoss attacker, const BaseBoss victim)
{
	Action act = Call_OnBossJarated(victim, attacker);
	if( act > Plugin_Changed )
		return;
	
	switch( victim.iBossType ) {
		case -1: {}
		case Hale, Vagineer, CBS, HHHjr, Bunny:
			victim.flRAGE -= cvarVSH2[JarateRage].FloatValue;
	}
}
public Action HookSound(int clients[64], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags)
{
	if( !cvarVSH2[Enabled].BoolValue || !IsValidClient(entity) )
		return Plugin_Continue;
	
	BaseBoss base = BaseBoss(entity);
	switch( base.iBossType ) {
		case -1: {}
		case Hale: {
			if( !strncmp(sample, "vo", 2, false) )
				return Plugin_Handled;
		}
		case Vagineer: {
			if( StrContains(sample, "vo/engineer_laughlong01", false) != -1 ) {
				strcopy(sample, PLATFORM_MAX_PATH, VagineerKSpree);
				return Plugin_Changed;
			}
			if( !strncmp(sample, "vo", 2, false) ) {
				if( StrContains(sample, "positivevocalization01", false) != -1 )	/// For backstab sound
					return Plugin_Continue;
				if( StrContains(sample, "engineer_moveup", false) != -1 )
					Format(sample, PLATFORM_MAX_PATH, "%s%i.wav", VagineerJump, GetRandomInt(1, 2));

				else if( StrContains(sample, "engineer_no", false) != -1 || GetRandomInt(0, 9) > 6 )
					strcopy(sample, PLATFORM_MAX_PATH, "vo/engineer_no01.mp3");

				else strcopy(sample, PLATFORM_MAX_PATH, "vo/engineer_jeers02.mp3");
				return Plugin_Changed;
			}
			else return Plugin_Continue;
		}
		case HHHjr: {
			if( !strncmp(sample, "vo", 2, false) ) {
				if( GetRandomInt(0, 30) <= 10 ) {
					Format(sample, PLATFORM_MAX_PATH, "%s0%i.mp3", HHHLaught, GetRandomInt(1, 4));
					return Plugin_Changed;
				}
				if( StrContains(sample, "halloween_boss") == -1 )
					return Plugin_Handled;
			}
		}
		case Bunny: {
			if( StrContains(sample, "gibberish", false) == -1
				&& StrContains(sample, "burp", false) == -1
				&& !GetRandomInt(0, 2) ) /// Do sound things
			{
				strcopy(sample, PLATFORM_MAX_PATH, BunnyRandomVoice[GetRandomInt(0, sizeof(BunnyRandomVoice)-1)]);
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool& result)
{
	if( !cvarVSH2[Enabled].BoolValue )
		return Plugin_Continue;
	
	BaseBoss base = BaseBoss(client);
	if( base.bIsBoss ) {
		switch( base.iBossType ) {
			case -1: {}
			case HHHjr: {
				if( base.iClimbs < cvarVSH2[HHHMaxClimbs].IntValue ) {
					if( base.ClimbWall(weapon, cvarVSH2[HHHClimbVelocity].FloatValue, 0.0, false) ) {
						base.flWeighDown = 0.0;
						base.iClimbs++;
					}
				}
			}
		}
		
		/// Fuck random crits
		if( TF2_IsPlayerCritBuffed(base.index) )
			return Plugin_Continue;
		result = false;
		return Plugin_Changed;
	}
	if( !base.bIsBoss && !base.bIsMinion ) {
		if( TF2_GetPlayerClass(base.index) == TFClass_Sniper && IsWeaponSlotActive(base.index, TFWeaponSlot_Melee) )
			base.ClimbWall(weapon, cvarVSH2[SniperClimbVelocity].FloatValue, 15.0, true);
	}
	return Plugin_Continue;
}

/**
IT SHOULD BE WORTH NOTING THAT ManageMessageIntro IS CALLED AFTER BOSS HEALTH CALCULATION, IT MAY OR MAY NOT BE A GOOD IDEA TO RESET BOSS HEALTH HERE IF NECESSARY. ESPECIALLY IF YOU HAVE A MULTIBOSS THAT REQUIRES UNEQUAL HEALTH DISTRIBUTION.
*/
public void ManageMessageIntro(ArrayList bosses)
{
	gameMessage[0] = '\0';
	if( gamemode.bDoors ) {
		int ent = -1;
		while( (ent = FindEntityByClassname(ent, "func_door")) != -1 ) {
			AcceptEntityInput(ent, "Open");
			AcceptEntityInput(ent, "Unlock");
		}
	}
	
	int i;
	BaseBoss base;
	int len = bosses.Length;
	for( i=0; i<len; ++i ) {
		base = bosses.Get(i);
		if( base == view_as< BaseBoss >(0) )
			continue;
		
		char name[MAX_BOSS_NAME_SIZE];
		base.GetName(name);
		Action act = Call_OnMessageIntro(base, gameMessage);
		if( act > Plugin_Changed )
			continue;
		
		Format(gameMessage, MAXMESSAGE, "%s\n%N has become %s with %i Health", gameMessage, base.index, name, base.iHealth);
	}
	SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
	for( i=MaxClients; i; --i ) {
		if( IsValidClient(i) )
			ShowHudText(i, -1, "%s", gameMessage);
	}
	gamemode.iRoundState = StateRunning;
	delete bosses;
}

public void ManageBossPickUpItem(const BaseBoss base, const char item[64])
{
	/// block Persian Persuader
	//if( GetIndexOfWeaponSlot(base.index, TFWeaponSlot_Melee) == 404 )
	//	return;
	
	Action act = Call_OnBossPickUpItem(base, item);
	if( act > Plugin_Changed )
		return;
	
	switch( base.iBossType ) {
		case -1: {}
	}
}

public void ManageResetVariables(const BaseBoss base)
{
	Action act = Call_OnVariablesReset(base);
	if( act > Plugin_Changed )
		return;
	
	base.bIsBoss = base.bSetOnSpawn = false;
	base.iBossType = -1;
	base.iStabbed = 0;
	base.iMarketted = 0;
	base.flRAGE = 0.0;
	base.bIsMinion = false;
	base.iDifficulty = 0;
	base.iDamage = 0;
	base.iAirDamage = 0;
	base.iUberTarget = 0;
	base.flCharge = 0.0;
	base.bGlow = 0;
	base.flGlowtime = 0.0;
	base.bUsedUltimate = false;
	base.iOwnerBoss = 0;
	base.iSongPick = -1;
	SetEntityRenderColor(base.index, 255, 255, 255, 255);
	base.flLastShot = 0.0;
	base.flLastHit = 0.0;
	base.iState = -1;
	base.iHits = 0;
	base.iLives = ((gamemode.bMedieval || cvarVSH2[ForceLives].BoolValue) ? cvarVSH2[MedievalLives].IntValue : 0);
	base.iHealth = 0;
	base.iMaxHealth = 0;
	base.iShieldDmg = 0;
}
public void ManageEntityCreated(const int entity, const char[] classname)
{
	if( StrContains(classname, "rune") != -1 )	/// Special request
		CreateTimer( 0.1, RemoveEnt, EntIndexToEntRef(entity) );
	/// Remove dropped weapons to avoid bad things
	else if( !cvarVSH2[DroppedWeapons].BoolValue && StrEqual(classname, "tf_dropped_weapon") ) {
		AcceptEntityInput(entity, "kill");
		return;
	} else if( !strcmp(classname, "tf_projectile_cleaver", false) ) {
		SDKHook(entity, SDKHook_SpawnPost, OnCleaverSpawned);
	} else if( gamemode.iRoundState == StateRunning && !strcmp(classname, "tf_projectile_pipe", false) )
		SDKHook(entity, SDKHook_SpawnPost, OnEggBombSpawned);
}
public void OnEggBombSpawned(int entity)
{
	int owner = GetOwner(entity);
	BaseBoss boss = BaseBoss(owner);
	if( IsClientValid(owner) && boss.bIsBoss && boss.iBossType == Bunny )
		CreateTimer(0.0, Timer_SetEggBomb, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
}
public void OnCleaverSpawned(int entity)
{
	char kunai_model[] = "models/weapons/c_models/c_shogun_kunai/c_shogun_kunai.mdl";
	PrecacheModel(kunai_model, true);
	SetEntityModel(entity, kunai_model);
	SetEntityGravity(entity, 10.0);
}

public void ManageUberDeploy(const BaseBoss medic, const BaseBoss patient)
{
	int medigun = GetPlayerWeaponSlot(medic.index, TFWeaponSlot_Secondary);
	if( IsValidEntity(medigun) ) {
		char strMedigun[32]; GetEdictClassname(medigun, strMedigun, sizeof(strMedigun));
		if( !strcmp(strMedigun, "tf_weapon_medigun", false) ) {
			Action act = Call_OnUberDeployed(medic, patient);
			if( act > Plugin_Changed )
				return;
			
			SetMediCharge(medigun, 1.51);
			TF2_AddCondition(medic.index, TFCond_CritOnWin, 0.5, medic.index);
			if( IsClientValid(patient.index) && IsPlayerAlive(patient.index) ) {
				TF2_AddCondition(patient.index, TFCond_CritOnWin, 0.5, medic.index);
				medic.iUberTarget = patient.userid;
			}
			else medic.iUberTarget = 0;
			CreateTimer(0.1, Timer_UberLoop, EntIndexToEntRef(medigun), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public void ManageMusic(char song[PLATFORM_MAX_PATH], float& time)
{
	/// UNFORTUNATELY, we have to get a random boss so we can set our music, tragic I know...
	/// Remember that you can get a random boss filtered by type as well!
	BaseBoss currBoss = gamemode.GetRandomBoss(true);
	Action act = Call_OnMusic(song, time, currBoss);
	if( act > Plugin_Changed )
		return;
	else if( currBoss ) {
		switch( currBoss.iBossType ) {
			case -1: {song = ""; time = -1.0;}
			case CBS: {
				strcopy(song, sizeof(song), CBSTheme);
				time = 140.0;
			}
			case HHHjr: {
				strcopy(song, sizeof(song), HHHTheme);
				time = 90.0;
			}
		}
	}
}
public void StopBackGroundMusic()
{
	if( BackgroundSong[0] != '\0' ) {
		for( int i=MaxClients; i; --i ) {
			if( !IsClientValid(i) )
				continue;
			StopSound(i, SNDCHAN_AUTO, BackgroundSong);
		}
	}
}

public void ManageRoundEndBossInfo(ArrayList bosses, bool bossWon)
{
	gameMessage[0] = '\0';
	int i=0;
	BaseBoss base;
	int len = bosses.Length;
	for( i=0; i<len; ++i ) {
		base = bosses.Get(i);
		if( base == view_as< BaseBoss >(0) )
			continue;
		
		char name[MAX_BOSS_NAME_SIZE];
		base.GetName(name);
		Action act = Call_OnRoundEndInfo(base, bossWon, gameMessage);
		if( act > Plugin_Changed )
			continue;
		Format(gameMessage, MAXMESSAGE, "%s\n%s (%N) had %i (of %i) health left.", gameMessage, name, base.index, base.iHealth, base.iMaxHealth);
		
		if( bossWon ) {
			switch( base.iBossType ) {
				case -1: {}
				case Vagineer:	ToCVagineer(base).PlayWinSound();
				case Bunny:	ToCBunny(base).PlayWinSound();
				case Hale:	ToCHale(base).PlayWinSound();
			}
		}
	}
	if( gameMessage[0] != '\0' ) {
		CPrintToChatAll("{olive}[VSH 2] End of Round{default} %s", gameMessage);
		SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
		for( i=MaxClients; i; --i ) {
			if( IsValidClient(i) && !(GetClientButtons(i) & IN_SCORE) )
				ShowHudText(i, -1, "%s", gameMessage);
		}
	}
	delete bosses;
}
public void ManageLastPlayer()
{
	BaseBoss currBoss = gamemode.GetRandomBoss(true);
	Action act = Call_OnLastPlayer(currBoss);
	if( act > Plugin_Changed )
		return;
	
	switch( currBoss.iBossType ) {
		case -1: {}
		case Hale:	ToCHale(currBoss).LastPlayerSoundClip();
		case Vagineer:	ToCVagineer(currBoss).LastPlayerSoundClip();
		case CBS:	ToCChristian(currBoss).LastPlayerSoundClip();
		case Bunny:	ToCBunny(currBoss).LastPlayerSoundClip();
	}
}
public void ManageBossCheckHealth(const BaseBoss base)
{
	static int LastBossTotalHealth;
	float currtime = GetGameTime();
	
	/// If a boss reveals their own health, only show that one boss' health.
	if( base.bIsBoss && IsPlayerAlive(base.index) ) {
		Action act = Call_OnBossHealthCheck(base, true, gameMessage);
		if( act > Plugin_Changed )
			return;
		
		char name[MAX_BOSS_NAME_SIZE];
		base.GetName(name);
		PrintCenterTextAll("%s showed his current HP: %i of %i", name, base.iHealth, base.iMaxHealth);
		LastBossTotalHealth = base.iHealth;
		return;
	}
	/// If a non-boss is checking health, reveal all Boss' hp
	else if( currtime >= gamemode.flHealthTime ) {
		gamemode.iHealthChecks++;
		BaseBoss boss;
		int totalHealth;
		gameMessage[0] = '\0';
		for( int i=MaxClients; i; --i ) {
			/// exclude dead bosses for health check
			if( !IsValidClient(i) || !IsPlayerAlive(i) )
				continue;
			boss = BaseBoss(i);
			if( !boss.bIsBoss )
				continue;
			
			Action act = Call_OnBossHealthCheck(boss, false, gameMessage);
			if( act > Plugin_Changed )
				continue;
			
			char name[MAX_BOSS_NAME_SIZE];
			boss.GetName(name);
			Format(gameMessage, MAXMESSAGE, "%s\n%s's current health is: %i of %i", gameMessage, name, boss.iHealth, boss.iMaxHealth);
			totalHealth += boss.iHealth;
		}
		PrintCenterTextAll(gameMessage);
		CPrintToChatAll("{olive}[VSH 2] Boss Health Check{default} %s", gameMessage);
		LastBossTotalHealth = totalHealth;
		gamemode.flHealthTime = currtime + ((gamemode.iHealthChecks < 3) ? 10.0 : 60.0);
	} else {
		CPrintToChat(base.index, "{olive}[VSH 2]{default} You cannot see the Boss HP now (wait %i seconds). Last known total boss health was %i.", RoundFloat(gamemode.flHealthTime-currtime), LastBossTotalHealth);
	}
}

public void CheckAlivePlayers(const any nil)
{
	if( gamemode.iRoundState != StateRunning )
		return;
	
	int living = GetLivingPlayers(VSH2Team_Red);
	if( !living )
		ForceTeamWin(VSH2Team_Boss);
	
	if( living == 1 && gamemode.CountBosses(true) > 0 && gamemode.iTimeLeft <= 0 ) {
		ManageLastPlayer();	/// in handler.sp
		gamemode.iTimeLeft = cvarVSH2[LastPlayerTime].IntValue;
		
		/// maybe some day :/ ...
		/*
		int round_timer = -1;
		round_timer = FindEntityByClassname(RoundTimer, "team_round_timer");
		if( round_timer <= 0 )
			round_timer = CreateEntityByName("team_round_timer");
		
		if( round_timer > MaxClients && IsValidEntity(round_timer) ) {
			SetVariantInt(cvarVSH2[LastPlayerTime].IntValue);
			//DispatchKeyValue(round_timer, "targetname", TIMER_NAME);
			//DispatchKeyValue(round_timer, "setup_length", setupLength);
			//DispatchKeyValue(round_timer, "setup_length", "30");
			DispatchKeyValue(round_timer, "reset_time", "1");
			DispatchKeyValue(round_timer, "auto_countdown", "1");
			char time[5];
			IntToString(cvarVSH2[LastPlayerTime].IntValue, time, sizeof(time));
			DispatchKeyValue(round_timer, "timer_length", time);
			DispatchSpawn(round_timer);
		}
		*/
		CreateTimer(1.0, Timer_DrawGame, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	int Alive = cvarVSH2[AliveToEnable].IntValue;
	if( !cvarVSH2[PointType].BoolValue && living <= Alive && !gamemode.bPointReady ) {
		PrintHintTextToAll("%i players are left; control point enabled!", living);
		if( living == Alive )
			EmitSoundToAll("vo/announcer_am_capenabled02.mp3");
		else if( living < Alive ) {
			Format(snd, PLATFORM_MAX_PATH, "vo/announcer_am_capincite0%i.mp3", GetRandomInt(0, 1) ? 1 : 3);
			EmitSoundToAll(snd);
		}
		SetControlPoint(true);
		gamemode.bPointReady = true;
	}
}

public void ManageOnBossCap(char sCappers[MAXPLAYERS+1], const int CappingTeam)
{
	Call_OnControlPointCapped(sCappers, CappingTeam);
}

/// TODO: fix this up so it appears more often.
public void _SkipBossPanel()
{
	BaseBoss upnext[3];
	for( int j=0; j<3; ++j ) {
		upnext[j] = gamemode.FindNextBoss();
		if( !upnext[j].userid )
			continue;
		upnext[j].bSetOnSpawn = true;
		
		/// If up next to become a boss.
		if( !j )
			SkipBossPanelNotify(upnext[j].index);
		else if( !IsFakeClient(upnext[j].index) )
			CPrintToChat(upnext[j].index, "{olive}[VSH 2]{default} You are going to be a Boss soon! Type {olive}/halenext{default} to check/reset your queue points & !setboss to set your boss.");
	}
	
	/// Ughhh, reset shit...
	for( int n=MaxClients; n; --n ) {
		if( !IsValidClient(n) )
			continue;
		upnext[0] = BaseBoss(n);
		if( !upnext[0].bIsBoss )
			upnext[0].bSetOnSpawn = false;
	}
}

public void PrepPlayers(const BaseBoss player)
{
	int client = player.index;
	if( gamemode.iRoundState == StateEnding || !IsValidClient(client) || !IsPlayerAlive(client) || player.bIsBoss )
		return;
	
	Action act = Call_OnPrepRedTeam(player);
	if( act > Plugin_Changed )
		return;
	
#if defined _tf2attributes_included
	if( gamemode.bTF2Attribs )
		TF2Attrib_RemoveAll(client);
#endif
	/// Added fix by Chdata to correct team colors
	if( GetClientTeam(client) != VSH2Team_Red && GetClientTeam(client) > VSH2Team_Spectator ) {
		player.ForceTeamChange(VSH2Team_Red);
		TF2_RegeneratePlayer(client);
	}
	TF2_RegeneratePlayer(client);
	SetEntityHealth(client, GetEntProp(client, Prop_Data, "m_iMaxHealth"));
	if( !GetRandomInt(0, 1) )
		player.HelpPanelClass();
	
#if defined _tf2attributes_included
	/// Fixes mantreads to have jump height again
	if( gamemode.bTF2Attribs && IsValidEntity(FindPlayerBack(client, { 444 }, 1)) )
		/// "self dmg push force increased"
		TF2Attrib_SetByDefIndex(client, 58, 1.8);
#endif
	int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	int index = -1;
	if( weapon > MaxClients && IsValidEntity(weapon) ) {
		index = GetItemIndex(weapon);
		switch( index ) {
			/// blocks rocket jumper
			case 237: {
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
				weapon = player.SpawnWeapon("tf_weapon_rocketlauncher", 18, 1, 0, "114; 1.0");
				SetWeaponAmmo(weapon, 20);
			}
			case 17, 204: {
				if( GetItemQuality(weapon) != 10 ) {
					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
					player.SpawnWeapon("tf_weapon_syringegun_medic", 17, 1, 10, "17; 0.05; 144; 1");
				}
			}
		}
	}
	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if( weapon > MaxClients && IsValidEntity(weapon) ) {
		index = GetItemIndex(weapon);
		switch( index ) {
			/// Razorback
			/*
			case 57: {
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
				weapon = player.SpawnWeapon("tf_weapon_smg", 16, 1, 0, "");
			}
			*/
			/// Stickyjumper
			case 265: {
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
				weapon = player.SpawnWeapon("tf_weapon_pipebomblauncher", 20, 1, 0, "");
				SetWeaponAmmo(weapon, 24);
			}
			/*
			case 311, 433: {
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
				weapon = player.SpawnWeapon("tf_weapon_pipebomblauncher", 20, 5, 10, "280; 3; 6; 0.7; 97; 0.5; 78; 1.2");
				SetWeaponAmmo(weapon, GetMaxAmmo(client, 1));
			}
			*/
			/// Replace sapper with more useful syringe-firing Pistol aka nailgun.
			case 735, 736, 810, 831, 933, 1080, 1102: {
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
				//weapon = player.SpawnWeapon("tf_weapon_handgun_scout_secondary", 23, 5, 10, "280; 5; 6; 0.7; 2; 0.66; 4; 4.167; 78; 8.333; 137; 6.0");
				//SetWeaponAmmo(weapon, 200);
				
				/// kunai-cleavers for spy instead of sapper!
				player.SpawnWeapon("tf_weapon_cleaver", 356, 5, 10, "279; 4.0 ; 149 ; 5");
			}
			case 39, 351, 1081: {
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
				weapon = player.SpawnWeapon("tf_weapon_flaregun", index, 5, 10, "551; 1; 25; 0.5; 207; 1.33; 144; 1; 58; 3.2");
				SetWeaponAmmo(weapon, 20);
			}
			/// scorch shot
			case 740: {
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
				weapon = player.SpawnWeapon("tf_weapon_flaregun", index, 5, 10, "551; 1; 25; 0.5; 207; 1.33; 416; 3; 58; 2.08; 1; 0.65");
				SetWeaponAmmo(weapon, 20);
			}
		}
	}
	/*
	if( IsValidEntity (FindPlayerBack(client, { 57 }, 1)) ) {
		RemovePlayerBack(client, { 57 }, 1);
		weapon = player.SpawnWeapon("tf_weapon_smg", 16, 1, 0, "");
	}
	*/
	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if( weapon > MaxClients && IsValidEntity(weapon) ) {
		index = GetItemIndex(weapon);
		switch( index ) {
			case 331: {
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
				weapon = player.SpawnWeapon("tf_weapon_fists", 195, 1, 6, "");
			}
			case 357: SetPawnTimer(_NoHonorBound, 1.0, player.userid);
			case 589: {	/// eureka effect
				if( !cvarVSH2[BlockEureka].BoolValue ) {
					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
					weapon = player.SpawnWeapon("tf_weapon_wrench", 7, 1, 0, "");
				}
			}
		}
	}
	weapon = GetPlayerWeaponSlot(client, 4);
	if( weapon > MaxClients && IsValidEntity(weapon) && GetItemIndex(weapon) == 60 ) {
		TF2_RemoveWeaponSlot(client, 4);
		weapon = player.SpawnWeapon("tf_weapon_invis", 30, 1, 0, "2; 1.0");
	}
	TFClassType equip = TF2_GetPlayerClass(client);
	switch( equip ) {
		case TFClass_Medic: {
			weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
			//int mediquality = GetItemQuality(weapon);
			//if( mediquality != 10 ) {
			//	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
			//	if( cvarVSH2[PermOverheal].BoolValue )
			//		weapon = player.SpawnWeapon("tf_weapon_medigun", 35, 5, 10, "14; 0.0; 18; 0.0; 10; 1.25; 178; 0.75");
			//	else weapon = player.SpawnWeapon("tf_weapon_medigun", 35, 5, 10, "18; 0.0; 10; 1.25; 178; 0.75");
			/// 200; 1 for area of effect healing, 178; 0.75 Faster switch-to, 14; 0.0 perm overheal, 11; 1.25 Higher overheal
			if( GetMediCharge(weapon) != 0.41 )
				SetMediCharge(weapon, 0.41);
			//}
		}
	}
#if defined _tf2attributes_included
	if( gamemode.bTF2Attribs && cvarVSH2[HealthRegenForPlayers].BoolValue )
		TF2Attrib_SetByDefIndex(client, 57, GetClientHealth(client)/50.0+cvarVSH2[HealthRegenAmount].FloatValue);
#endif
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int iItemDefinitionIndex, Handle &hItem)
{
	if( !cvarVSH2[Enabled].BoolValue )
		return Plugin_Continue;
	
	TF2Item hItemOverride = null;
	TF2Item hItemCast = view_as< TF2Item >(hItem);
	switch( iItemDefinitionIndex ) {
		case 59: {	/// dead ringer
			hItemOverride = PrepareItemHandle(hItemCast, _, _, "35; 2.0");
		}
		case 1103: {	/// Backscatter
			hItemOverride = PrepareItemHandle(hItemCast, _, _, "179; 1.0");
		}
		case 40, 1146: {	/// backburner
			hItemOverride = PrepareItemHandle(hItemCast, _, _, "165; 1.0");
		}
		case 220: {	/// shortstop
			hItemOverride = PrepareItemHandle(hItemCast, _, _, "525; 1; 526; 1.2; 533; 1.4; 534; 1.4; 328; 1; 241; 1.5; 78; 1.389; 97; 0.75", true);
		}
		case 349: {	/// sun on a stick
			hItemOverride = PrepareItemHandle(hItemCast, _, _, "134; 13; 208; 1");
		}
		case 648: {	/// wrap assassin
			hItemOverride = PrepareItemHandle(hItemCast, _, _, "279; 3.0");
		}
		case 224:{	/// Letranger
			hItemOverride = PrepareItemHandle(hItemCast, _, _, "166; 15; 1; 0.8", true);
		}
		case 225, 574: {	/// YER
			hItemOverride = PrepareItemHandle(hItemCast, _, _, "155; 1; 160; 1", true);
		}
		case 232, 401: {	/// Bushwacka + Shahanshah
			hItemOverride = PrepareItemHandle(hItemCast, _, _, "236; 1");
		}
		case 226: {	/// The Battalion's Backup
			hItemOverride = PrepareItemHandle(hItemCast, _, _, "252; 0.25");
		}
		case 305, 1079: {	/// Medic Xbow
			hItemOverride = PrepareItemHandle(hItemCast, _, _, "17; 0.15; 2; 1.45"); //; 266; 1.0");
		}
		case 56, 1005, 1092: {	/// Huntsman
			hItemOverride = PrepareItemHandle(hItemCast, _, _, "2 ; 1.5 ; 76; 2.0");
		}
		case 43, 239, 1084, 1100: {	/// GRU
			hItemOverride = PrepareItemHandle(hItemCast, _, iItemDefinitionIndex, "107; 1.5; 1; 0.5; 128; 1; 206; 2.0; 772; 1.5", true);
		}
		case 415: {	/// reserve shooter
			if( TF2_GetPlayerClass(client)==TFClass_Soldier )
				hItemOverride = PrepareItemHandle(hItemCast, _, _, "135 ; 0.7 ; 179; 1; 114; 1.0; 178; 0.6; 2; 1.1; 3; 0.66", true);
			else hItemOverride = PrepareItemHandle(hItemCast, _, _, "179; 1; 114; 1.0; 178; 0.6; 2; 1.1; 3; 0.66", true);
		}
		case 405, 608: {	/// Demo boots have falling stomp damage
			hItemOverride = PrepareItemHandle(hItemCast, _, _, "259; 1; 252; 0.25");
		}
		case 36, 412: {	/// Blutsauger and Overdose
			hItemOverride = PrepareItemHandle(hItemCast, _, _, "17; 0.01");
		}
		case 772: {	/// Baby Face's Blaster
			//hItemOverride = PrepareItemHandle(hItemCast, _, _, "106; 0.3; 4; 1.33; 45; 0.6; 114; 1.0", true);
			/// 36 ; 1.25 -> less accuracy.
			hItemOverride = PrepareItemHandle(hItemCast, _, _, "418 ; 1; 49 ; 1; 3 ; 0.66; 532 ; 1; 793 ; 1", true);
		}
		//case 133: {	/// Gunboats; make gunboats attractive compared to the mantreads by having it reduce more rj dmg
		//	hItemOverride = PrepareItemHandle(hItemCast, _, _, "135; 0.2", true);
		//}
		//case 444: {    /// Mantreads
		//	hItemOverride = PrepareItemHandle(hItemCast, _, _, " 275 ; 1");
		//}
		/// Enforcer
		case 460: {
			hItemOverride = PrepareItemHandle(hItemCast, _, _, "2; 1.2");
		}
		/// Righteous Bison
		//case 442: {
		//	hItemOverride = PrepareItemHandle(hItemCast, _, _, "275; 1.0");
		//}
		/// Darwin's Danger Shield
		case 231: {
			hItemOverride = PrepareItemHandle(hItemCast, _, _, "26; 35.0");
		}
		/// boston basher & 3rune blade
		//case 325, 452: {
		//	hItemOverride = PrepareItemHandle(hItemCast, _, _, "204 ; 0 ; 149 ; 5", true);
		//}
		/// gas passer
		case 1180: {
			hItemOverride = PrepareItemHandle(hItemCast, _, _, "875 ; 1.0");
		}
		/// thermal thruster
		case 1179: {
			hItemOverride = PrepareItemHandle(hItemCast, _, _, "872 ; 1.0");
		}
		/// Axtinguisher, Postal Pummeler, & Festive Axtinguisher
		case 38, 457, 1000: {
			hItemOverride = PrepareItemHandle(hItemCast, _, _, "795 ; 1.20");
		}
		/// Hot Hand
		case 1181: {
			hItemOverride = PrepareItemHandle(hItemCast, _, _, "877 ; 2.0");
		}
	}
	if( hItemOverride != null ) {
		Action act = Call_OnItemOverride(BaseBoss(client), classname, iItemDefinitionIndex, view_as< Handle >(hItemOverride));
		if( act > Plugin_Changed )
			return Plugin_Continue;
		hItem = view_as< Handle >(hItemOverride);
		return Plugin_Changed;
	}
	
	TFClassType iClass = TF2_GetPlayerClass(client);
	if( !strncmp(classname, "tf_weapon_rocketlauncher", 24, false) || !strncmp(classname, "tf_weapon_particle_cannon", 25, false) ) {
		switch( iItemDefinitionIndex ) {
			/// Direct Hit
			case 127: hItemOverride = PrepareItemHandle(hItemCast, _, _, "114; 1.0; 179; 1.0");
			
			/// Liberty Launcher.
			case 414: hItemOverride = PrepareItemHandle(hItemCast, _, _, "114; 1.0; 99; 1.25");
			
			/// Air Strike.
			case 1104: hItemOverride = PrepareItemHandle(hItemCast, _, _, "76; 1.25; 114; 1.0");
			//case 730: hItemOverride = PrepareItemHandle(hItemCast, _, _, "394; 0.2; 241; 1.3; 3; 0.75; 411; 5; 6; 0.1; 642; 1; 413; 1", true);
			default: hItemOverride = PrepareItemHandle(hItemCast, _, _, "114; 1.0");
		}
	}
	if( !strncmp(classname, "tf_weapon_grenadelauncher", 25, false) /*|| !strncmp(classname, "tf_weapon_cannon", 16, false)*/ ) {
		switch( iItemDefinitionIndex ) {
			/// loch n load
			case 308: hItemOverride = PrepareItemHandle(hItemCast, _, _, "114; 1.0; 208; 1.0");
			default: hItemOverride = PrepareItemHandle(hItemCast, _, _, "114; 1.0; 128; 1; 135; 0.5");
		}
	}
	if( !strncmp(classname, "tf_weapon_sword", 15, false) ) {
		hItemOverride = PrepareItemHandle(hItemCast, _, _, "178; 0.8");
	}
	if( !StrContains(classname, "tf_weapon_shotgun", false) || !strncmp(classname, "tf_weapon_sentry_revenge", 24, false) ) {
		switch( iClass ) {
			case TFClass_Soldier:
				hItemOverride = PrepareItemHandle(hItemCast, _, _, "135; 0.6; 114; 1.0");
			default: hItemOverride = PrepareItemHandle(hItemCast, _, _, "114; 1.0");
		}
		//hItemOverride = PrepareItemHandle(hItem, _, _, "114; 1.0");
	}
	if( !strncmp(classname, "tf_weapon_wrench", 16, false) || !strncmp(classname, "tf_weapon_robot_arm", 19, false) ) {
		if( iItemDefinitionIndex == 142 )
			hItemOverride = PrepareItemHandle(hItemCast, _, _, "26; 55");
		else hItemOverride = PrepareItemHandle(hItemCast, _, _, "26; 25");
	}
	if( !strncmp(classname, "tf_weapon_minigun", 17, false) ) {
		switch( iItemDefinitionIndex ) {
			case 41: /// Natascha
				hItemOverride = PrepareItemHandle(hItemCast, _, _, "76; 1.5", true);
			default: hItemOverride = PrepareItemHandle(hItemCast, _, _, "233; 1.15");
		}
	}
	switch( iClass ) {
		case TFClass_Medic: {
			/// Medic mediguns
			if( !StrContains(classname, "tf_weapon_medigun", false) ) {
				if( cvarVSH2[PermOverheal].BoolValue ) {
					/// Kritzkrieg
					if( iItemDefinitionIndex==35 )
						hItemOverride = PrepareItemHandle(hItemCast, _, _, "14; 0.0; 10 ; 2.26 ; 178 ; 0.75 ; 18 ; 0");
					/// Other Mediguns
					else hItemOverride = PrepareItemHandle(hItemCast, _, _, "14; 0.0; 10 ; 1.81 ; 178 ; 0.75 ; 18 ; 0", true);
				} else {
					if( iItemDefinitionIndex==35 )
						hItemOverride = PrepareItemHandle(hItemCast, _, _, "10 ; 2.26 ; 178 ; 0.75 ; 18 ; 0");
					else hItemOverride = PrepareItemHandle(hItemCast, _, _, "10 ; 1.81 ; 178 ; 0.75 ; 18 ; 0", true);
				}
			}
		}
	}
	if( hItemOverride != null ) {
		Action act = Call_OnItemOverride(BaseBoss(client), classname, iItemDefinitionIndex, view_as< Handle >(hItemOverride));
		if( act > Plugin_Changed )
			return Plugin_Continue;
		hItem = view_as< Handle >(hItemOverride);
		return Plugin_Changed;
	}
	return Call_OnItemOverride(BaseBoss(client), classname, iItemDefinitionIndex, hItem);
}

public void ManageFighterThink(const BaseBoss fighter)
{
	if( GetClientTeam(fighter.index) != VSH2Team_Red )
		return;
	
	Action act = Call_OnRedPlayerThink(fighter);
	if( act > Plugin_Changed )
		return;
	
	char HUDText[300];
	int i = fighter.index;
	char wepclassname[64];
	int buttons = GetClientButtons(i);
	SetHudTextParams(-1.0, 0.88, 0.35, 90, 255, 90, 255, 0, 0.35, 0.0, 0.1);
	if( !IsPlayerAlive(i) ) {
		int obstarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
		if( IsValidClient(obstarget) && GetClientTeam(obstarget) != 3 && obstarget != i ) {
			if( !(buttons & IN_SCORE) )
				Format(HUDText, 300, "Damage: %d - %N's Damage: %d", fighter.iDamage, obstarget, BaseBoss(obstarget).iDamage);
		} else {
			if( !(buttons & IN_SCORE) )
				Format(HUDText, 300, "Damage: %d", fighter.iDamage);
		}
		ShowSyncHudText(i, hHudText, HUDText);
		return;
	}
	
	if( !(buttons & IN_SCORE) ) {
		if( gamemode.bMedieval || cvarVSH2[ForceLives].BoolValue )
			Format(HUDText, 300, "Damage: %d | Lives: %d", fighter.iDamage, fighter.iLives);
		else Format(HUDText, 300, "Damage: %d", fighter.iDamage);
		ShowSyncHudText(i, hHudText, HUDText);
	}
	
	if( HasEntProp(i, Prop_Send, "m_iKillStreak") ) {
		int killstreaker = fighter.iDamage/1000;
		if( killstreaker && GetEntProp(i, Prop_Send, "m_iKillStreak") >= 0 )
			SetEntProp(i, Prop_Send, "m_iKillStreak", killstreaker);
	}
	
	TFClassType TFClass = TF2_GetPlayerClass(i);
	int weapon = GetActiveWep(i);
	if( weapon <= MaxClients || !IsValidEntity(weapon) || !GetEdictClassname(weapon, wepclassname, sizeof(wepclassname)) )
		strcopy(wepclassname, sizeof(wepclassname), "");
	bool validwep = ( !strncmp(wepclassname, "tf_wea", 6, false) );
	int index = GetItemIndex(weapon);

	switch( TFClass ) {
		/// Chdata's Deadringer Notifier
		case TFClass_Spy: {
			if( GetClientCloakIndex(i) == 59 ) {
				int drstatus = TF2_IsPlayerInCondition(i, TFCond_Cloaked) ? 2 : GetEntProp(i, Prop_Send, "m_bFeignDeathReady") ? 1 : 0;
				char s[32];
				switch( drstatus ) {
					case 1: {
						Format(s, sizeof(s), "Status: Feign-Death Ready");
					}
					case 2: {
						Format(s, sizeof(s), "Status: Dead-Ringered");
					}
					default: {
						Format(s, sizeof(s), "Status: Inactive");
					}
				}
				Format(HUDText, 300, "%s\n%s", HUDText, s);
			}
			int spy_secondary = GetPlayerWeaponSlot(i, TFWeaponSlot_Secondary);
			if( spy_secondary > MaxClients && IsValidEntity(spy_secondary) )
				Format(HUDText, 300, "%s | Kunai: %s", HUDText, GetWeaponAmmo(spy_secondary) ? "Ready" : "None");
		}
		case TFClass_Medic: {
			int medigun = GetPlayerWeaponSlot(i, TFWeaponSlot_Secondary);
			char mediclassname[32];
			if( medigun > MaxClients && IsValidEntity(medigun) ) {
				GetEdictClassname(medigun, mediclassname, sizeof(mediclassname));
				if( !strcmp(mediclassname, "tf_weapon_medigun", false) ) {
					int charge = RoundToFloor(GetMediCharge(medigun) * 100);
					Format(HUDText, 300, "%s\nUbercharge: %i%%", HUDText, charge);
					
					/// Fixes Ubercharges ending prematurely on Medics.
					if( GetEntProp(medigun, Prop_Send, "m_bChargeRelease") && GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel") > 0.0 && GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon")==medigun )
						TF2_AddCondition(i, TFCond_Ubercharged, 1.0);
				}
			}
		}
		case TFClass_Soldier: {
			if( GetIndexOfWeaponSlot(i, TFWeaponSlot_Primary) == 1104 ) {
				Format(HUDText, 300, "%s\nAir Strike Damage: %i", HUDText, fighter.iAirDamage);
			}
		}
		case TFClass_DemoMan: {
			int shield = GetPlayerWeaponSlot(i, TFWeaponSlot_Secondary);
			if( shield <= 0 ) {
				if( !(buttons & IN_SCORE) ) {
					if( GetEntProp(i, Prop_Send, "m_bShieldEquipped") )
						Format(HUDText, 300, "%s\nShield: Active", HUDText);
					else Format(HUDText, 300, "%s\nShield: Gone", HUDText);
				}
			}
		}
	}
	if( !(buttons & IN_SCORE) )
		ShowSyncHudText(i, hHudText, HUDText);
	
	int living = GetLivingPlayers(VSH2Team_Red);
	if( living == 1 && !TF2_IsPlayerInCondition(i, TFCond_Cloaked) ) {
		TF2_AddCondition(i, TFCond_CritOnWin, 0.2);
		int primary = GetPlayerWeaponSlot(i, TFWeaponSlot_Primary);
		if( TFClass==TFClass_Engineer && weapon==primary && StrEqual(wepclassname, "tf_weapon_sentry_revenge", false) )
			SetEntProp(i, Prop_Send, "m_iRevengeCrits", 3);
		TF2_AddCondition(i, TFCond_Buffed, 0.2);
		return;
	}
	else if( living == 2 && !TF2_IsPlayerInCondition(i, TFCond_Cloaked) )
		TF2_AddCondition(i, TFCond_Buffed, 0.2);
	
	/** THIS section really needs cleaning! */
	
	TFCond cond = TFCond_CritOnWin;
	if( TF2_IsPlayerInCondition(i, TFCond_CritCola) && (TFClass==TFClass_Scout || TFClass==TFClass_Heavy) ) {
		TF2_AddCondition(i, cond, 0.2);
		return;
	}
	
	bool addthecrit = false;
	bool addmini = false;
	int healers = GetEntProp(i, Prop_Send, "m_nNumHealers");
	for( int u=0; u<healers; u++ ) {
		if( 0 < GetHealerByIndex(i, u) <= MaxClients ) {
			addmini = true;
			break;
		}
	}
	
	if( validwep && weapon == GetPlayerWeaponSlot(i, TFWeaponSlot_Melee) ) {
		/// slightly longer check but makes sure that any weapon that can backstab will not crit (e.g. Saxxy)
		addthecrit = !!strcmp(wepclassname, "tf_weapon_knife", false);
	}
	if( validwep && weapon == GetPlayerWeaponSlot(i, TFWeaponSlot_Primary) ) /// Primary weapon crit list
	{
		if (StrStarts(wepclassname, "tf_weapon_compound_bow") || /// Sniper bows
			StrStarts(wepclassname, "tf_weapon_crossbow") || /// Medic crossbows
			StrEqual(wepclassname, "tf_weapon_shotgun_building_rescue") || /// Engineer Rescue Ranger
			StrEqual(wepclassname, "tf_weapon_drg_pomson")) /// Engineer Pomson
		{
			addthecrit = true;
		}
	}
	if( validwep && weapon == GetPlayerWeaponSlot(i, TFWeaponSlot_Secondary) ) /// Secondary weapon crit list
	{
		if (StrStarts(wepclassname, "tf_weapon_pistol") || /// Engineer/Scout pistols
			StrStarts(wepclassname, "tf_weapon_handgun_scout_secondary") || /// Scout pistols
			StrStarts(wepclassname, "tf_weapon_flaregun") || /// Flare guns
			StrEqual(wepclassname, "tf_weapon_smg")) /// Sniper SMGs minus Cleaner's Carbine
		{
			if( TFClass == TFClass_Scout && cond == TFCond_CritOnWin )
				cond = TFCond_Buffed;

			int PrimaryIndex = GetIndexOfWeaponSlot(i, TFWeaponSlot_Primary);
			if( (TFClass == TFClass_Pyro && PrimaryIndex == 594) || (IsValidEntity(FindPlayerBack(i, { 642 }, 1))) ) /// No crits if using Phlogistinator or Cozy Camper
				addthecrit = false;
			else addthecrit = true;
		}
		if( StrStarts(wepclassname, "tf_weapon_jar") || /// Jarate/Milk
			StrEqual(wepclassname, "tf_weapon_cleaver") ) /// Flying Guillotine
			addthecrit = true;
	}
	
	/// Specific weapon crit list
	switch( index ) {
		/// Holiday Punch
		case 656: {
			addthecrit = true;
			cond = TFCond_Buffed;
		}
		/// Market Gardener
		case 416: {
			addthecrit = false;
		}
	}
	
	if( TFClass == TFClass_DemoMan && !IsValidEntity(GetPlayerWeaponSlot(i, TFWeaponSlot_Secondary)) ) {
		float flShieldMeter = GetEntPropFloat(i, Prop_Send, "m_flChargeMeter");
		if( cvarVSH2[DemoShieldCrits].IntValue >= 1 ) {
			addthecrit = true;
			if( cvarVSH2[DemoShieldCrits].IntValue == 1 || (cvarVSH2[DemoShieldCrits].IntValue == 3 && flShieldMeter < 100.0) )
				cond = TFCond_Buffed;
			if( cvarVSH2[DemoShieldCrits].IntValue == 3 && (flShieldMeter < 35.0 || !GetEntProp(i, Prop_Send, "m_bShieldEquipped")) )
				addthecrit = false;
		}
	}
	
	if( addthecrit ) {
		TF2_AddCondition(i, cond, 0.2);
		if( addmini && cond != TFCond_Buffed )
			TF2_AddCondition(i, TFCond_Buffed, 0.2);
	}
	if( TFClass == TFClass_Spy && validwep && weapon == GetPlayerWeaponSlot(i, TFWeaponSlot_Primary) ) {
		if( !TF2_IsPlayerCritBuffed(i)
			&& !TF2_IsPlayerInCondition(i, TFCond_Buffed)
			&& !TF2_IsPlayerInCondition(i, TFCond_Cloaked)
			&& !TF2_IsPlayerInCondition(i, TFCond_Disguised)
			&& !GetEntProp(i, Prop_Send, "m_bFeignDeathReady") )
		{
			TF2_AddCondition(i, TFCond_CritCola, 0.2);
		}
	}
	if( TFClass == TFClass_Engineer && weapon == GetPlayerWeaponSlot(i, TFWeaponSlot_Primary) && StrEqual(wepclassname, "tf_weapon_sentry_revenge", false) )
	{
		int sentry = FindSentry(i);
		if( IsValidEntity(sentry) ) {
			/// Trying to target minions as well
			int enemy = GetEntPropEnt(sentry, Prop_Send, "m_hEnemy");
			if( enemy > 0 && GetClientTeam(enemy) == VSH2Team_Boss ) {
				SetEntProp(i, Prop_Send, "m_iRevengeCrits", 3);
				TF2_AddCondition(i, TFCond_Kritzkrieged, 0.2);
			} else {
				if( HasEntProp(i, Prop_Send, "m_iRevengeCrits") )
					SetEntProp(i, Prop_Send, "m_iRevengeCrits", 0);
				else if( TF2_IsPlayerInCondition(i, TFCond_Kritzkrieged) && !TF2_IsPlayerInCondition(i, TFCond_Healing) )
					TF2_RemoveCondition(i, TFCond_Kritzkrieged);
			}
		}
	}
}

/// too many temp funcs just to call as a timer. No wonder sourcepawn needs lambda funcs...
public void _RespawnPlayer(const int userid)
{
	TF2_RespawnPlayer( GetClientOfUserId(userid) );
}
