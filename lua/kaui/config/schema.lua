local schema = {}

local function field(field_type, default, description)
    return {
        type = field_type or 'string',
        default = default,
        description = description or '',
    }
end

schema.sections = {
    'General',
    'SpellS',
    'Spells',
    'Buffs',
    'Melee',
    'GoM',
    'AE',
    'DPS',
    'Aggro',
    'Heals',
    'Cures',
    'Pet',
    'Merc',
    'Mez',
    'Burn',
    'Pull',
    'PullAdvanced',
    'AFKTools',
    'KConditions',
}

schema.fields = {
    General = {
        KissAssistVer = field('string', '0.0', 'KissAssist version written by the macro.'),
        Role = field('string', 'Assist', 'Primary role: Assist, Puller, Tank, etc.'),
        CampRadius = field('int', 30, 'Camp radius.'),
        CampRadiusExceed = field('int', 400, 'Maximum distance before camp correction.'),
        ReturnToCamp = field('int', 0, 'Automatically return to camp.'),
        ChaseAssist = field('int', 0, 'Follow the main assist.'),
        ChaseDistance = field('int', 25, 'Chase distance.'),
        MedOn = field('int', 1, 'Enable medding.'),
        MedStart = field('int', 20, 'Mana/endurance threshold to start medding.'),
        MedStop = field('int', 100, 'Mana/endurance threshold to stop medding.'),
        MedCombat = field('int', 0, 'Allow medding in combat.'),
        LootOn = field('int', 0, 'Enable looting.'),
        RezAcceptOn = field('string', '1|90', 'Rez acceptance and threshold.'),
        AcceptInvitesOn = field('int', 1, 'Accept group invites.'),
        GroupWatchOn = field('string', '0', 'Group watch.'),
        GroupWatchCheck = field('string', 'FALSE', 'GroupWatch check mode.'),
        CorpseRecoveryOn = field('int', 0, 'Corpse recovery.'),
        EQBCOn = field('string', '0', 'EQBC integration.'),
        DanNetOn = field('string', '0', 'DanNet integration.'),
        DanNetDelay = field('int', 20, 'DanNet delay.'),
        IRCOn = field('int', 0, 'Legacy IRC integration.'),
        CampfireOn = field('int', 0, 'Campfire handling.'),
        GroupEscapeOn = field('int', 0, 'Group escape.'),
        DPSMeter = field('int', 0, 'DPS meter display.'),
        ScatterOn = field('int', 0, 'Group scatter.'),
        LOSBeforeCombat = field('int', 0, 'Check line of sight before combat.'),
        UseSpawnMaster = field('int', 0, 'Use SpawnMaster.'),
        TwistOn = field('int', 0, 'General bard twist.'),
        TwistMed = field('string', 'Mana song gem', 'Med twist gem/song.'),
        TwistWhat = field('string', 'Twist order here', 'General twist order.'),
    },
    SpellS = {
        MiscGem = field('int', 8, 'Misc gem.'),
        MiscGemLW = field('int', 0, 'Low-level misc gem.'),
        MiscGemRemem = field('int', 1, 'Rememorize misc gem.'),
        LoadSpellSet = field('int', 0, 'Load a spell set on startup.'),
        SpellSetName = field('string', 'KissAssist', 'Spell set name.'),
    },
    Spells = {
        CastingInterruptOn = field('int', 1, 'Interrupt casting when needed.'),
        CheckStuckGem = field('int', 1, 'Stuck gem detection.'),
    },
    Buffs = {
        BuffsOn = field('int', 0, 'Enable buffs.'),
        BuffsSize = field('int', 20, 'Maximum number of buffs.'),
        RebuffOn = field('int', 1, 'Automatic rebuff.'),
        CheckBuffsTimer = field('int', 10, 'Buff check interval.'),
        PowerSource = field('string', 'NULL', 'Power source to equip.'),
    },
    Melee = {
        AssistAt = field('int', 95, 'Target HP percentage to assist at.'),
        MeleeOn = field('int', 0, 'Enable melee.'),
        FaceMobOn = field('int', 1, 'Face the target.'),
        MeleeDistance = field('int', 75, 'Melee/stick distance.'),
        StickHow = field('string', 'snaproll', 'Stick parameters.'),
        AutoFireOn = field('int', 0, 'Autofire ranger.'),
        UseMQ2Melee = field('int', 0, 'Delegate to MQ2Melee.'),
        TargetSwitchingOn = field('int', 0, 'Allow target switching.'),
        AutoHide = field('int', 1, 'Auto hide rogues.'),
        MeleeTwistOn = field('int', 0, 'Twist bard melee.'),
        MeleeTwistWhat = field('string', 'DPS twist order here', 'Melee twist order.'),
        PetTauntOverride = field('int', 0, 'Override pet taunt.'),
    },
    GoM = {
        GoMSHelp = field('string', 'Format - Spell|Target, MA Me or Mob, i.e. Rampaging Servant Rk. II|Mob', 'GoM help.'),
        GoMSize = field('int', 3, 'Number of GoM entries.'),
    },
    AE = {
        AEOn = field('int', 0, 'Enable AE.'),
        AESize = field('int', 10, 'Number of AE entries.'),
        AERadius = field('int', 50, 'AE radius.'),
    },
    DPS = {
        DPSOn = field('int', 0, 'Enable DPS.'),
        DPSSize = field('int', 20, 'Number of DPS entries.'),
        DPSSkip = field('int', 20, 'HP threshold to skip DPS.'),
        DPSInterval = field('int', 2, 'DPS interval.'),
        DebuffAllOn = field('int', 0, 'Debuff all targets.'),
    },
    Aggro = {
        AggroOn = field('int', 0, 'Enable aggro handling.'),
        AggroSize = field('int', 5, 'Number of aggro entries.'),
    },
    Heals = {
        Help = field('string', 'Format Spell|% to heal at i.e. Devout Light Rk. II|50', 'Heals help.'),
        HealsOn = field('int', 0, 'Enable heals.'),
        HealInterval = field('int', 0, 'Heals interval.'),
        AutoRezOn = field('int', 0, 'Automatic rez.'),
        HealsSize = field('int', 5, 'Number of heals.'),
        XTarHeal = field('int', 0, 'Heals XTarget.'),
        XTarHealList = field('string', 'Xtar slots here Example: 5|6|7', 'XTarget slots to heal.'),
        HealGroupPetsOn = field('int', 0, 'Heal group pets.'),
        RezMeLast = field('int', 0, 'Rez self last.'),
    },
    Cures = {
        CuresOn = field('int', 0, 'Enable cures.'),
        CuresSize = field('int', 5, 'Number of cures.'),
    },
    Pet = {
        PetOn = field('int', 0, 'Enable pet.'),
        PetSpell = field('string', 'YourPetSpell', 'Pet summon spell.'),
        PetFocus = field('string', 'NULL', 'Focus pet.'),
        PetShrinkOn = field('int', 0, 'Shrink pet.'),
        PetShrinkSpell = field('string', 'Tiny Companion', 'Pet shrink spell.'),
        PetBuffsOn = field('int', 0, 'Buffs pet.'),
        PetBuffsSize = field('int', 8, 'Number of pet buffs.'),
        PetCombatOn = field('int', 1, 'Pet combat.'),
        PetAssistAt = field('int', 95, 'Pet assist threshold.'),
        PetAttackDistance = field('int', 115, 'Pet attack distance.'),
        PetToysSize = field('int', 6, 'Number of pet toys.'),
        PetToysOn = field('int', 0, 'Give pet toys.'),
        PetToysGave = field('string', 'NULL', 'Pet toys already given.'),
        PetBreakMezSpell = field('string', 'NULL', 'Pet break mez spell.'),
        PetRampPullWait = field('int', 0, 'Ramp pull wait.'),
        PetSuspend = field('int', 0, 'Suspend pet.'),
        MoveWhenHit = field('int', 0, 'Move when hit.'),
        PetHoldOn = field('int', 1, 'Pet hold.'),
        PetForceHealOnMed = field('int', 0, 'Force pet heal while medding.'),
    },
    Merc = {
        Help = field('string', 'To use: Turn off Auto Assist in Manage Mercenary Window', 'Merc help.'),
        MercOn = field('int', 0, 'Enable merc.'),
        MercAssistAt = field('int', 92, 'Merc assist threshold.'),
    },
    Mez = {
        MezOn = field('int', 0, 'Enable mez.'),
        MezRadius = field('int', 50, 'Mez radius.'),
        MezMinLevel = field('int', 'Min Mez Spell Level', 'Minimum mez level.'),
        MezMaxLevel = field('int', 'Max Mez Spell Level', 'Maximum mez level.'),
        MezStopHPs = field('int', 80, 'Stop mez below this HP.'),
        MezSpell = field('string', 'Your Mez Spell|2', 'Mez spell.'),
        MezDebuffOnResist = field('int', 0, 'Debuff on mez resist.'),
        MezDebuffSpell = field('string', 'Your Debuff Spell', 'Mez debuff spell.'),
        MezAESpell = field('string', 'Your AE Mez Spell|0', 'AE mez spell.'),
    },
    Burn = {
        BurnAllNamed = field('int', 0, 'Burn all named mobs.'),
        UseTribute = field('int', 0, 'Enable tribute during burn.'),
        BurnSize = field('int', 15, 'Number of burn entries.'),
    },
    Pull = {
        PullWith = field('string', 'Melee', 'Pull method.'),
        PullMeleeStick = field('int', 0, 'Stick melee pull.'),
        MaxRadius = field('int', 350, 'Maximum pull radius.'),
        MaxZRange = field('int', 50, 'Maximum Z range.'),
        UseWayPointZ = field('int', 0, 'Use waypoint Z.'),
        PullWait = field('int', 5, 'Pull wait.'),
        PullRadiusToUse = field('int', 90, 'Active pull radius.'),
        PullRoleToggle = field('int', 0, 'Toggle pull role.'),
        ChainPull = field('int', 0, 'Chain pull.'),
        ChainPullHP = field('int', 90, 'Chain pull threshold.'),
        PullPause = field('string', '30|2', 'Pause pull.'),
        PullLevel = field('string', '0|0', 'Pull level filter.'),
        PullArcWidth = field('string', '0', 'Arc pull.'),
        PullTwistOn = field('int', 0, 'Twist while pulling.'),
        PullOnReturn = field('int', 0, 'Pull on return.'),
    },
    PullAdvanced = {
        PullLocsOn = field('int', 0, 'Active pull locs.'),
    },
    AFKTools = {
        AFKHelp = field('string', 'AFKGMAction=0 Off, 1 Pause Macro, 2 End Macro, 3 Unload MQ2, 4 Quit Game', 'AFK help.'),
        AFKToolsOn = field('int', 1, 'Enable AFK tools.'),
        AFKGMAction = field('int', 1, 'AFK GM action.'),
        AFKPCRadius = field('int', 500, 'AFK PC radius.'),
        CampOnDeath = field('int', 0, 'Camp on death.'),
        ClickBacktoCamp = field('int', 0, 'Click back to camp.'),
    },
    KConditions = {
        ConOn = field('int', 0, 'Enable KissAssist conditions.'),
        CondSize = field('int', 5, 'Number of conditions.'),
    },
}

schema.key_order = {}
for section, fields in pairs(schema.fields) do
    schema.key_order[section] = {}
    for key in pairs(fields) do
        table.insert(schema.key_order[section], key)
    end
    table.sort(schema.key_order[section])
end

function schema.get_field(section, key)
    return schema.fields[section] and schema.fields[section][key] or nil
end

function schema.default_for(section, key)
    local definition = schema.get_field(section, key)
    if definition then
        return definition.default
    end
    return nil
end

return schema
