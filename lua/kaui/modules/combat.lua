local combat = {
    name = 'combat_assist',
    enabled = true,
}

local SELF_ASSIST_ROLES = {
    tank = true,
    pullertank = true,
    pettank = true,
    pullerpettank = true,
    hunter = true,
    hunterpettank = true,
}

local VALID_ROLES = {
    assist = 'Assist',
    manual = 'Manual',
    offtank = 'OffTank',
    tank = 'Tank',
    puller = 'Puller',
    pullertank = 'PullerTank',
    pettank = 'PetTank',
    petassist = 'PetAssist',
    pullerpettank = 'PullerPetTank',
    hunter = 'Hunter',
    hunterpettank = 'HunterPetTank',
}

local ASSIST_SPAWN_TYPES = {
    pc = true,
    mercenary = true,
    pet = true,
}

local NON_ATTACKABLE_TYPES = {
    pc = true,
    mercenary = true,
    corpse = true,
}

local ASSIST_COMMAND_INTERVAL = 1.5
local ATTACK_COMMAND_INTERVAL = 1.0
local STICK_REFRESH_INTERVAL = 5.0
local STATUS_REPEAT_INTERVAL = 10.0

local function now()
    return os.time()
end

local function trim(value)
    return tostring(value or ''):match('^%s*(.-)%s*$')
end

local function lower(value)
    return trim(value):lower()
end

local function role_key(value)
    return lower(value):gsub('%s+', '')
end

local function is_blank(value)
    local text = trim(value)
    return text == '' or text:lower() == 'null' or text:lower() == 'none'
end

local function to_int(value, default)
    local number = tonumber(value)
    if not number then
        return default
    end
    return math.floor(number)
end

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

local function to_bool(value, default)
    if value == nil then
        return default == true
    end

    local text = lower(value)
    if text == '' then
        return default == true
    end
    if text == '0' or text == 'false' or text == 'off' or text == 'no' then
        return false
    end
    return true
end

local function same_text(a, b)
    return lower(a) == lower(b)
end

local function doc_get(state, section, key, default)
    local doc = state.config and state.config.document
    if not doc then
        return default
    end
    return doc:get(section, key, default)
end

local function ensure_combat_state(state)
    state.combat = state.combat or {}
    local state_combat = state.combat
    state_combat.settings = state_combat.settings or {}
    state_combat.current_target = state_combat.current_target or nil
    state_combat.timers = state_combat.timers or {}
    return state_combat
end

local function read_ini_main_assist(state)
    local candidates = {
        { 'General', 'MainAssist' },
        { 'General', 'MainAssistName' },
        { 'General', 'MA' },
        { 'Melee', 'MainAssist' },
    }

    for _, candidate in ipairs(candidates) do
        local value = doc_get(state, candidate[1], candidate[2], nil)
        if not is_blank(value) then
            return trim(value), candidate[1] .. '.' .. candidate[2]
        end
    end

    return nil, nil
end

local function parse_launch_args(state_combat, args, logger)
    if state_combat.launch_args_parsed then
        return
    end

    state_combat.launch_args_parsed = true
    if type(args) ~= 'table' or #args == 0 then
        return
    end

    local index = 1
    while index <= #args do
        local token = tostring(args[index] or '')
        local key = role_key(token)

        if VALID_ROLES[key] then
            state_combat.role_override = VALID_ROLES[key]
            logger.info('Combat role override from launch command: ' .. state_combat.role_override)
            index = index + 1
        elseif key == 'ma' or key == 'mainassist' or key == 'assist' then
            local value = args[index + 1]
            if value and not is_blank(value) then
                state_combat.assist_override = {
                    name = trim(value),
                    source = 'command',
                }
                logger.info('Main assist override from launch command: ' .. state_combat.assist_override.name)
                index = index + 2
            else
                index = index + 1
            end
        elseif key == 'assistat' then
            local value = tonumber(args[index + 1])
            if value then
                state_combat.assist_at_override = clamp(math.floor(value), 1, 100)
                logger.info('AssistAt override from launch command: ' .. tostring(state_combat.assist_at_override))
                index = index + 2
            else
                index = index + 1
            end
        else
            local numeric = tonumber(token)
            if numeric and numeric >= 1 and numeric <= 100 then
                state_combat.assist_at_override = clamp(math.floor(numeric), 1, 100)
                logger.info('AssistAt override from launch command: ' .. tostring(state_combat.assist_at_override))
            elseif not is_blank(token) then
                state_combat.assist_override = {
                    name = trim(token),
                    source = 'command',
                }
                logger.info('Main assist override from launch command: ' .. state_combat.assist_override.name)
            end
            index = index + 1
        end
    end
end

local function read_settings(state, state_combat, logger)
    local ini_role = doc_get(state, 'General', 'Role', nil)
    local role = state_combat.role_override or state.role_override or ini_role or state.role or 'Assist'
    if is_blank(role) or lower(role) == 'unknown' then
        role = 'Assist'
    end

    local assist_at = state_combat.assist_at_override or to_int(doc_get(state, 'Melee', 'AssistAt', 95), 95)
    local melee_distance = to_int(doc_get(state, 'Melee', 'MeleeDistance', 75), 75)
    local stick_how = trim(doc_get(state, 'Melee', 'StickHow', 'snaproll'))
    if stick_how == '' or lower(stick_how) == 'null' then
        stick_how = '0'
    elseif lower(stick_how) == 'auto' then
        stick_how = 'snaproll'
    end

    local settings = {
        role = role,
        role_key = role_key(role),
        assist_at = clamp(assist_at, 1, 100),
        melee_on = to_bool(doc_get(state, 'Melee', 'MeleeOn', 0), false),
        melee_distance = math.max(0, melee_distance),
        stick_how = stick_how,
        stick_enabled = not (lower(stick_how) == '0' or lower(stick_how) == 'i' or lower(stick_how) == 'off' or lower(stick_how) == 'none' or stick_how == ''),
        face_mob = to_bool(doc_get(state, 'Melee', 'FaceMobOn', 1), true),
        los_before_combat = to_bool(doc_get(state, 'General', 'LOSBeforeCombat', 0), false),
    }
    settings.enabled = settings.role_key ~= 'manual'
    settings.self_assist = SELF_ASSIST_ROLES[settings.role_key] == true

    state_combat.settings = settings
    state.role = settings.role

    local signature = table.concat({
        settings.role,
        tostring(settings.assist_at),
        tostring(settings.melee_on),
        tostring(settings.melee_distance),
        settings.stick_how,
        tostring(settings.face_mob),
    }, '|')

    if state_combat.settings_signature ~= signature then
        state_combat.settings_signature = signature
        logger.info(string.format(
            'Combat settings: role=%s AssistAt=%d MeleeOn=%s MeleeDistance=%d StickHow=%s',
            settings.role,
            settings.assist_at,
            tostring(settings.melee_on),
            settings.melee_distance,
            settings.stick_how
        ))
    end

    return settings
end

local function spawn_info(mq_helpers, search)
    if not search or search == '' then
        return nil
    end

    local id = mq_helpers.spawn_id(search)
    if not id or id == 0 then
        return nil
    end

    return {
        id = id,
        name = mq_helpers.spawn_clean_name(search) or mq_helpers.spawn_name(search),
        type = mq_helpers.spawn_type(search),
        class = mq_helpers.spawn_class_short_name(search),
        distance = mq_helpers.spawn_distance(search),
    }
end

local function self_assist(mq_helpers, source)
    local id = mq_helpers.me_id()
    if not id or id == 0 then
        return nil
    end

    return {
        id = id,
        name = mq_helpers.me_clean_name() or mq_helpers.me_name() or 'Me',
        type = mq_helpers.me_type() or 'PC',
        class = mq_helpers.me_class(),
        source = source or 'role',
        is_self = true,
    }
end

local function find_spawn_by_name(mq_helpers, name)
    name = trim(name)
    if name == '' then
        return nil
    end

    local searches = {
        '=' .. name .. ' pc',
        '=' .. name .. ' mercenary',
        '=' .. name .. ' pet',
        '=' .. name,
    }

    for _, search in ipairs(searches) do
        local info = spawn_info(mq_helpers, search)
        if info then
            return info
        end
    end

    return nil
end

local function assist_from_reference(mq_helpers, reference, source)
    if not reference then
        return nil
    end

    local me_id = mq_helpers.me_id()
    local me_name = mq_helpers.me_clean_name() or mq_helpers.me_name()
    local info = nil

    if reference.id then
        info = spawn_info(mq_helpers, 'id ' .. tostring(reference.id))
    end

    if not info and reference.name and not is_blank(reference.name) then
        info = find_spawn_by_name(mq_helpers, reference.name)
    end

    if info then
        info.source = source or reference.source or 'unknown'
        info.is_self = me_id ~= nil and info.id == me_id
        if not info.is_self and not ASSIST_SPAWN_TYPES[lower(info.type)] then
            info.invalid = true
        end
        return info
    end

    if reference.name and me_name and same_text(reference.name, me_name) then
        return self_assist(mq_helpers, source or reference.source or 'command')
    end

    if reference.name and not is_blank(reference.name) then
        return {
            id = reference.id,
            name = trim(reference.name),
            type = reference.type,
            source = source or reference.source or 'unknown',
            is_self = false,
            unresolved = true,
        }
    end

    return nil
end

local function target_assist(mq_helpers, source)
    local id = mq_helpers.target_id()
    if not id or id == 0 then
        return nil
    end

    local me_id = mq_helpers.me_id()
    if me_id and id == me_id then
        return nil
    end

    local target_type = lower(mq_helpers.target_type())
    if not ASSIST_SPAWN_TYPES[target_type] then
        return nil
    end

    return {
        id = id,
        name = mq_helpers.target_name(),
        type = mq_helpers.target_type(),
        source = source or 'target',
        is_self = false,
    }
end

local function group_assist(mq_helpers)
    local id = tonumber(mq_helpers.group_main_assist_id())
    local name = mq_helpers.group_main_assist_name()
    if not id and is_blank(name) then
        return nil
    end

    return assist_from_reference(mq_helpers, {
        id = id,
        name = name,
        source = 'group',
    }, 'group')
end

local function assist_changed(previous, current)
    if not previous and not current then
        return false
    end
    if not previous or not current then
        return true
    end
    return (previous.id or 0) ~= (current.id or 0)
        or lower(previous.name) ~= lower(current.name)
        or lower(previous.source) ~= lower(current.source)
end

local function set_main_assist(state_combat, logger, assist)
    local previous = state_combat.main_assist
    state_combat.main_assist = assist

    if assist_changed(previous, assist) then
        if assist then
            local id_text = assist.id and (' ID ' .. tostring(assist.id)) or ' unresolved'
            local type_text = assist.type and (' ' .. tostring(assist.type)) or ''
            logger.info(string.format('Main assist set from %s: %s%s%s', assist.source or 'unknown', assist.name or '-', type_text, id_text))
        elseif previous then
            logger.info('Main assist cleared.')
        end
    end
end

local function resolve_main_assist(state, state_combat, mq_helpers, logger, settings)
    if settings.self_assist then
        set_main_assist(state_combat, logger, self_assist(mq_helpers, 'role'))
        return state_combat.main_assist
    end

    if state_combat.assist_override and not state_combat.assist_override.clear then
        set_main_assist(state_combat, logger, assist_from_reference(mq_helpers, state_combat.assist_override, 'command'))
        return state_combat.main_assist
    end

    local ini_assist, ini_source = read_ini_main_assist(state)
    if ini_assist then
        set_main_assist(state_combat, logger, assist_from_reference(mq_helpers, { name = ini_assist }, 'ini ' .. ini_source))
        return state_combat.main_assist
    end

    if state_combat.main_assist and state_combat.main_assist.name and state_combat.main_assist.source ~= 'group' then
        set_main_assist(state_combat, logger, assist_from_reference(mq_helpers, state_combat.main_assist, state_combat.main_assist.source))
        return state_combat.main_assist
    end

    local from_target = target_assist(mq_helpers, 'target')
    if from_target then
        set_main_assist(state_combat, logger, from_target)
        return state_combat.main_assist
    end

    local from_group = group_assist(mq_helpers)
    if from_group then
        set_main_assist(state_combat, logger, from_group)
        return state_combat.main_assist
    end

    set_main_assist(state_combat, logger, nil)
    return nil
end

local function current_target(mq_helpers)
    local id = mq_helpers.target_id()
    if not id or id == 0 then
        return nil
    end

    return {
        id = id,
        name = mq_helpers.target_name() or ('ID ' .. tostring(id)),
        type = mq_helpers.target_type(),
        pct_hp = mq_helpers.target_pct_hp(),
        distance = mq_helpers.target_distance3d() or mq_helpers.target_distance(),
        line_of_sight = mq_helpers.target_line_of_sight(),
        mezzed_id = mq_helpers.target_mezzed_id(),
    }
end

local function target_description(target)
    if not target then
        return '-'
    end

    local parts = { target.name or ('ID ' .. tostring(target.id or 0)) }
    if target.id then
        table.insert(parts, '(ID ' .. tostring(target.id) .. ')')
    end
    if target.pct_hp then
        table.insert(parts, string.format('%.0f%%', target.pct_hp))
    end
    if target.distance then
        table.insert(parts, string.format('%.1f', target.distance))
    end
    return table.concat(parts, ' ')
end

local function evaluate_target(target, settings, mq_helpers)
    if not target then
        return false, 'no_target', 'Waiting for an assist target.'
    end

    local me_id = mq_helpers.me_id()
    if me_id and target.id == me_id then
        return false, 'self_target', 'Target is self.'
    end

    local target_type = lower(target.type)
    if target_type == 'corpse' then
        return false, 'dead_target', 'Target is a corpse.'
    end
    if NON_ATTACKABLE_TYPES[target_type] then
        return false, 'invalid_target', 'Target is not attackable: ' .. tostring(target.type)
    end

    if target.pct_hp == nil then
        return false, 'invalid_target', 'Target HP is unavailable.'
    end
    if target.pct_hp <= 0 then
        return false, 'dead_target', 'Target is dead.'
    end
    if target.mezzed_id and target.mezzed_id > 0 then
        return false, 'mezzed_target', 'Target is mezzed.'
    end
    if settings.los_before_combat and not target.line_of_sight then
        return false, 'no_los', 'Target is not in line of sight.'
    end
    if settings.melee_distance > 0 and target.distance and target.distance > settings.melee_distance then
        return false, 'out_of_range', string.format('Target is out of range: %.1f > %d.', target.distance, settings.melee_distance)
    end
    if target.pct_hp > settings.assist_at then
        return false, 'assist_threshold', string.format('Waiting for AssistAt: %.0f%% > %d%%.', target.pct_hp, settings.assist_at)
    end

    return true, 'engage', 'Target is ready.'
end

local function log_status(state_combat, logger, code, detail, target, force)
    local time_now = now()
    local target_id = target and target.id or 0
    local should_log = force
        or state_combat.status_code ~= code
        or (state_combat.status_target_id or 0) ~= target_id
        or (time_now - (state_combat.last_status_log or 0)) >= STATUS_REPEAT_INTERVAL

    state_combat.status_code = code
    state_combat.status_detail = detail
    state_combat.status_target_id = target_id

    if should_log then
        state_combat.last_status_log = time_now
        logger.info(detail)
    end
end

local function maybe_assist(state_combat, mq_helpers, main_assist)
    if not main_assist or main_assist.is_self then
        return false
    end

    local time_now = now()
    if (time_now - (state_combat.last_assist_command or 0)) < ASSIST_COMMAND_INTERVAL then
        return false
    end

    if main_assist.name and not is_blank(main_assist.name) then
        mq_helpers.cmd('/squelch /assist ' .. main_assist.name)
        state_combat.last_assist_command = time_now
        return true
    end

    if main_assist.id then
        mq_helpers.cmd('/squelch /assist id ' .. tostring(main_assist.id))
        state_combat.last_assist_command = time_now
        return true
    end

    return false
end

local function clear_dead_target(state_combat, mq_helpers, target, code)
    if not target or not target.id then
        return
    end

    if code ~= 'dead_target' then
        return
    end

    if state_combat.last_cleared_target_id == target.id then
        return
    end

    mq_helpers.cmd('/squelch /target clear')
    state_combat.last_cleared_target_id = target.id
end

local function stop_movement(state_combat, mq_helpers)
    if state_combat.stick_active then
        mq_helpers.cmd('/squelch /stick off')
    end
    state_combat.stick_active = false
    state_combat.stick_target_id = nil
end

local function stop_attack(state_combat, mq_helpers, logger, reason)
    local time_now = now()
    if (state_combat.attack_on or mq_helpers.me_combat()) and (time_now - (state_combat.last_attack_off or 0)) >= ATTACK_COMMAND_INTERVAL then
        mq_helpers.cmd('/squelch /attack off')
        state_combat.last_attack_off = time_now
        if state_combat.attack_on then
            logger.info('Melee attack off: ' .. (reason or 'combat stopped'))
        end
    end

    state_combat.attack_on = false
    state_combat.attack_target_id = nil
    stop_movement(state_combat, mq_helpers)
end

local function refresh_stick(state_combat, mq_helpers, settings, target)
    if not settings.stick_enabled or not target or not target.id then
        stop_movement(state_combat, mq_helpers)
        return
    end

    local time_now = now()
    if state_combat.stick_target_id ~= target.id or (time_now - (state_combat.last_stick_command or 0)) >= STICK_REFRESH_INTERVAL then
        mq_helpers.cmd(string.format('/squelch /stick id %d %s', target.id, settings.stick_how))
        state_combat.stick_active = true
        state_combat.stick_target_id = target.id
        state_combat.last_stick_command = time_now
    end
end

local function start_attack(state_combat, mq_helpers, logger, settings, target)
    refresh_stick(state_combat, mq_helpers, settings, target)

    local time_now = now()
    if settings.face_mob and (time_now - (state_combat.last_face_command or 0)) >= 1.0 then
        mq_helpers.cmd('/squelch /face fast')
        state_combat.last_face_command = time_now
    end

    local retry_attack = state_combat.attack_on
        and state_combat.attack_target_id == target.id
        and not mq_helpers.me_combat()
        and (time_now - (state_combat.last_attack_on or 0)) >= STICK_REFRESH_INTERVAL
    local target_changed = state_combat.attack_target_id ~= target.id

    if (not state_combat.attack_on or target_changed or retry_attack)
        and (time_now - (state_combat.last_attack_on or 0)) >= ATTACK_COMMAND_INTERVAL then
        mq_helpers.cmd('/squelch /attack on')
        state_combat.attack_on = true
        state_combat.attack_target_id = target.id
        state_combat.last_attack_on = time_now
        if not retry_attack then
            logger.info('Melee attack on: ' .. target_description(target))
        end
    end
end

local function set_engaged(state_combat, logger, target)
    local changed = not state_combat.in_combat or not state_combat.current_target or state_combat.current_target.id ~= target.id
    state_combat.in_combat = true
    state_combat.current_target = target
    state_combat.status_code = 'engaged'
    state_combat.status_detail = 'Combat engaged.'

    if changed then
        logger.info('Combat engaged: ' .. target_description(target))
    end
end

local function set_idle(state_combat, logger, code, detail, target)
    if state_combat.in_combat then
        logger.info('Combat ended: ' .. detail)
    end

    state_combat.in_combat = false
    state_combat.current_target = target
    log_status(state_combat, logger, code, detail, target, false)
end

function combat.onInit(context)
    local state_combat = ensure_combat_state(context.runtime)
    parse_launch_args(state_combat, context.runtime.args, context.logger)
    read_settings(context.runtime, state_combat, context.logger)

    if context.mq and context.mq.is_available() then
        resolve_main_assist(context.runtime, state_combat, context.mq, context.logger, state_combat.settings)
    end
end

function combat.onPulse(context)
    local runtime = context.runtime
    local logger = context.logger
    local mq_helpers = context.mq
    local state_combat = ensure_combat_state(runtime)

    if not mq_helpers or not mq_helpers.is_available() then
        return
    end

    local settings = read_settings(runtime, state_combat, logger)
    local main_assist = resolve_main_assist(runtime, state_combat, mq_helpers, logger, settings)

    if not settings.enabled then
        stop_attack(state_combat, mq_helpers, logger, 'combat disabled')
        set_idle(state_combat, logger, 'disabled', 'Combat disabled by role.', nil)
        return
    end

    if not settings.melee_on then
        stop_attack(state_combat, mq_helpers, logger, 'MeleeOn is disabled')
        set_idle(state_combat, logger, 'melee_disabled', 'MeleeOn is disabled.', nil)
        return
    end

    if not main_assist then
        stop_attack(state_combat, mq_helpers, logger, 'no main assist')
        set_idle(state_combat, logger, 'no_main_assist', 'No main assist resolved. Use /kaui assist <name> or target a PC/merc/pet before starting.', nil)
        return
    end

    if main_assist.invalid then
        stop_attack(state_combat, mq_helpers, logger, 'main assist invalid')
        set_idle(state_combat, logger, 'main_assist_invalid', 'Main assist must be a PC, mercenary, or pet: ' .. tostring(main_assist.name), nil)
        return
    end

    if main_assist.unresolved then
        stop_attack(state_combat, mq_helpers, logger, 'main assist unresolved')
        set_idle(state_combat, logger, 'main_assist_unresolved', 'Main assist is not in zone: ' .. tostring(main_assist.name), nil)
        return
    end

    local target = current_target(mq_helpers)
    local ok, code, detail = evaluate_target(target, settings, mq_helpers)

    if not ok then
        maybe_assist(state_combat, mq_helpers, main_assist)
        clear_dead_target(state_combat, mq_helpers, target, code)
        stop_attack(state_combat, mq_helpers, logger, detail)
        set_idle(state_combat, logger, code, detail, target)
        return
    end

    set_engaged(state_combat, logger, target)
    start_attack(state_combat, mq_helpers, logger, settings, target)
end

function combat.onShutdown(context)
    local state_combat = ensure_combat_state(context.runtime)
    if context.mq and context.mq.is_available() then
        stop_attack(state_combat, context.mq, context.logger, 'shutdown')
    end
end

return function()
    return combat
end
