# NativeProtection
SpawnProtection & Team coloring with native 

# ConVars
**prot_spawn_protection_time**  
> _Time of protection from player spawn.
> **Set 0 or lower is turn off this option**
>> Default - 5

**prot_notify**
> _Enable notification of player about protection_
> **0 - disable, 1 - enable.**
>> Default - 1

**prot_color**
> _RGBA-string in which the players should be colored during the protection_
> **"RRR GGG BBB AAA"** 
>> Default - "0 255 0 120"

**prot_after_coloring_team**
> _Set T-player to red color, CT-players to blue after end of protection_
**0 - disable, 1 - enable**
>> Default - 1

# Natives
**`bool SP_GetClientProtectionState(int client)`**
> _Return true if player already is protected false in any other case_
> - int client - Player's index.

**`void SP_SetClientProtectionState(int client, bool state, float time = 0.0)`**
> _Set/remove protection from player_
> - int client - Player's index.
> - bool state - True - set protection, False - remove
> - float time - Time of protection, set 0.0 if state = false. Default - 0.0
