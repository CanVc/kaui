local config_manager = require('kaui.config.manager')
local list_config = require('kaui.config.lists')
local mq_helpers = require('kaui.core.mq')

local commands = {}

local function normalize_args(...)
    local args = { ... }
    local parts = {}

    for _, value in ipairs(args) do
        if value ~= nil then
            for part in tostring(value):gmatch('%S+') do
                table.insert(parts, part)
            end
        end
    end

    return parts
end

local function status_line(state)
    local combat = state.combat or {}
    local main_assist = combat.main_assist and combat.main_assist.name or '-'
    local combat_target = combat.current_target and combat.current_target.name or '-'
    local combat_state = combat.in_combat and 'engaged' or (combat.status_code or 'idle')

    return string.format(
        'running=%s paused=%s mode=%s role=%s pulse=%dms pulses=%d me=%s target=%s combat=%s main_assist=%s combat_target=%s',
        tostring(state.running),
        tostring(state.paused),
        tostring(state.mode),
        tostring(state.role),
        state.pulse_ms,
        state.pulse_count,
        state.me.name or '-',
        state.target.name or '-',
        combat_state,
        main_assist,
        combat_target
    )
end

local function rest_as_text(args, start_index)
    local parts = {}
    for index = start_index, #args do
        table.insert(parts, args[index])
    end
    return table.concat(parts, ' ')
end

local function config_document(state, logger)
    if not state.config or not state.config.document then
        logger.warn('No INI config loaded.')
        return nil
    end
    return state.config.document
end

local function ensure_combat_state(state)
    state.combat = state.combat or {}
    return state.combat
end

local function target_type_key(value)
    return tostring(value or ''):lower()
end

local function is_assist_target_type(value)
    local key = target_type_key(value)
    return key == 'pc' or key == 'mercenary' or key == 'pet'
end

local function handle_assist_command(state, logger, args)
    local combat = ensure_combat_state(state)
    local subaction = args[2] and args[2]:lower() or 'status'

    if subaction == 'status' then
        local main_assist = combat.main_assist
        local override = combat.assist_override
        logger.info(string.format(
            'Main assist: %s source=%s override=%s',
            main_assist and (main_assist.name or '-') or '-',
            main_assist and (main_assist.source or '-') or '-',
            override and (override.name or override.id or 'target') or '-'
        ))
        return
    end

    if subaction == 'clear' or subaction == 'reset' then
        combat.assist_override = nil
        combat.main_assist = nil
        combat.last_assist_command = 0
        logger.info('Main assist override cleared.')
        return
    end

    if subaction == 'target' then
        if not mq_helpers.is_available() then
            logger.warn('MacroQuest is not available; target selection cannot be read.')
            return
        end

        local target_id = mq_helpers.target_id()
        local target_name = mq_helpers.target_name()
        local target_type = mq_helpers.target_type()
        if not target_id or target_id == 0 then
            logger.warn('No target selected. Target a PC, mercenary, or pet first.')
            return
        end
        if target_id == mq_helpers.me_id() then
            logger.warn('Current target is self. Use a self-assist role such as Tank, or target another main assist.')
            return
        end
        if not is_assist_target_type(target_type) then
            logger.warn('Current target is not a valid main assist. Target a PC, mercenary, or pet.')
            return
        end

        combat.assist_override = {
            id = target_id,
            name = target_name,
            type = target_type,
            source = 'command',
        }
        combat.main_assist = nil
        logger.info(string.format('Main assist override set from target: %s (%s ID %s)', target_name or '-', target_type or '-', tostring(target_id)))
        return
    end

    local name_start = (subaction == 'set' or subaction == 'name') and 3 or 2
    local name = rest_as_text(args, name_start)
    if name == '' then
        logger.warn('Usage: /kaui assist status | target | clear | <name>')
        return
    end

    combat.assist_override = {
        name = name,
        source = 'command',
    }
    combat.main_assist = nil
    logger.info('Main assist override set: ' .. name)
end

local function handle_combat_command(state, logger, args)
    local combat = ensure_combat_state(state)
    local subaction = args[2] and args[2]:lower() or 'status'

    if subaction == 'status' then
        local settings = combat.settings or {}
        local target = combat.current_target
        logger.info(string.format(
            'Combat: state=%s role=%s AssistAt=%s MeleeOn=%s MeleeDistance=%s StickHow=%s',
            combat.in_combat and 'engaged' or (combat.status_code or 'idle'),
            settings.role or state.role or '-',
            tostring(settings.assist_at or '-'),
            tostring(settings.melee_on),
            tostring(settings.melee_distance or '-'),
            settings.stick_how or '-'
        ))
        logger.info(string.format(
            'Combat target: %s reason=%s',
            target and (target.name or tostring(target.id)) or '-',
            combat.status_detail or '-'
        ))
        return
    end

    if subaction == 'assistat' and args[3] then
        local value = tonumber(args[3])
        if value and value >= 1 and value <= 100 then
            combat.assist_at_override = math.floor(value)
            logger.info('AssistAt override set: ' .. tostring(combat.assist_at_override))
        else
            logger.warn('Invalid AssistAt. Use a value from 1 to 100.')
        end
        return
    end

    if subaction == 'reset' then
        combat.assist_at_override = nil
        combat.role_override = nil
        state.role_override = nil
        logger.info('Combat overrides cleared.')
        return
    end

    logger.warn('Usage: /kaui combat status | assistat <1-100> | reset')
end

local function handle_list_command(state, logger, args)
    local doc = config_document(state, logger)
    if not doc then
        return
    end

    local list_name = args[2]
    if not list_name or list_name == 'status' then
        for _, item in ipairs(list_config.summary(doc)) do
            logger.info(string.format('List %s [%s]: size=%d entries=%d', item.name, item.section, item.size, item.entries))
        end
        return
    end

    local subaction = args[3] and args[3]:lower() or 'status'
    if subaction == 'add' then
        local value = rest_as_text(args, 4)
        local index = list_config.add(doc, list_name, value ~= '' and value or 'NULL')
        logger.info(string.format('List %s: entry added at position %d.', list_name, index))
        return
    end

    if subaction == 'remove' or subaction == 'delete' then
        if list_config.remove(doc, list_name, args[4]) then
            logger.info(string.format('List %s: entry %s removed and list compacted.', list_name, tostring(args[4])))
        else
            logger.warn('Remove failed: invalid index.')
        end
        return
    end

    if subaction == 'move' then
        if list_config.move(doc, list_name, args[4], args[5]) then
            logger.info(string.format('List %s: entry %s moved to %s.', list_name, tostring(args[4]), tostring(args[5])))
        else
            logger.warn('Move failed: invalid index.')
        end
        return
    end

    if subaction == 'compact' then
        local before, after = list_config.compact(doc, list_name)
        logger.info(string.format('List %s compacted: %d -> %d entries.', list_name, before, after))
        return
    end

    local entries = list_config.read(doc, list_name)
    logger.info(string.format('List %s: %d entries, size=%d.', list_name, #entries, list_config.size(doc, list_name)))
    for _, entry in ipairs(entries) do
        local cond = entry.condition_ref and (' ' .. entry.condition_ref) or ''
        logger.info(string.format('  %s=%s%s', entry.key, entry.value, cond))
    end
end

local function handle_condition_command(state, logger, args)
    local doc = config_document(state, logger)
    if not doc then
        return
    end

    local subaction = args[2] and args[2]:lower() or 'status'

    if subaction == 'set' then
        local index = tonumber(args[3])
        local expression = rest_as_text(args, 4)
        if index and expression ~= '' and list_config.set_condition(doc, index, expression) then
            logger.info(string.format('Condition Cond%d updated.', index))
        else
            logger.warn('Usage: /kaui cond set <index> <expression>')
        end
        return
    end

    if subaction == 'missing' or subaction == 'status' then
        local conditions = list_config.read_conditions(doc)
        logger.info(string.format('Conditions: ConOn=%s CondSize=%d entries=%d', tostring(doc:get('KConditions', 'ConOn', '0')), list_config.conditions_size(doc), #conditions))
        if subaction == 'status' then
            for _, condition in ipairs(conditions) do
                logger.info(string.format('  %s=%s', condition.key, condition.raw))
            end
        end

        local missing = list_config.missing_condition_refs(doc)
        if #missing == 0 then
            logger.info('No missing condition references.')
        else
            for _, item in ipairs(missing) do
                logger.warn(string.format('Missing condition: [%s] %s references %s', item.section, item.key, item.condition_ref))
            end
        end
        return
    end

    logger.warn('Usage: /kaui cond status | missing | set <index> <expression>')
end

function commands.handle(state, logger, ...)
    local args = normalize_args(...)
    if args[1] == '/kaui' or args[1] == 'kaui' then
        table.remove(args, 1)
    end
    local action = args[1] and args[1]:lower() or 'status'

    if action == 'stop' or action == 'quit' or action == 'exit' then
        logger.info('Stop requested via /kaui stop.')
        state:stop()
        return
    end

    if action == 'pause' then
        state:pause()
        logger.info('Runtime paused.')
        return
    end

    if action == 'resume' or action == 'start' then
        state:resume()
        logger.info('Runtime resumed.')
        return
    end

    if action == 'mode' and args[2] then
        state.mode = args[2]
        logger.info('Runtime mode: ' .. state.mode)
        return
    end

    if action == 'role' and args[2] then
        local role_name = rest_as_text(args, 2)
        state.role = role_name
        state.role_override = role_name
        local combat = ensure_combat_state(state)
        combat.role_override = role_name
        logger.info('Runtime role override: ' .. state.role)
        return
    end

    if action == 'pulse' and args[2] then
        local value = tonumber(args[2])
        if value and value >= 50 then
            state.pulse_ms = value
            logger.info('Runtime pulse: ' .. state.pulse_ms .. ' ms')
        else
            logger.warn('Invalid pulse. Minimum value: 50 ms.')
        end
        return
    end

    if action == 'show' or action == 'hide' or action == 'toggle' or action == 'ui' then
        local ui_action = action == 'ui' and (args[2] and args[2]:lower() or 'toggle') or action
        if not state.ui then
            logger.warn('ImGui UI unavailable or not initialized.')
            return
        end
        if ui_action == 'show' then
            state.ui.show()
            logger.info('KAUI UI shown.')
        elseif ui_action == 'hide' then
            state.ui.hide()
            logger.info('KAUI UI hidden.')
        elseif ui_action == 'toggle' then
            local visible = state.ui.toggle()
            logger.info('KAUI UI ' .. (visible and 'shown.' or 'hidden.'))
        else
            logger.warn('Usage: /kaui ui [show|hide|toggle]')
        end
        return
    end

    if action == 'config' then
        local subaction = args[2] and args[2]:lower() or 'status'
        if subaction == 'save' then
            local ok, err = config_manager.save(state.config, logger)
            if not ok and err then
                logger.warn(err)
            end
            return
        end
        if state.config then
            logger.info(string.format('INI config: %s (%d keys)', config_manager.basename(state.config.path), state.config.document:count_keys()))
        else
            logger.warn('No INI config loaded.')
        end
        return
    end

    if action == 'assist' or action == 'ma' then
        handle_assist_command(state, logger, args)
        return
    end

    if action == 'combat' then
        handle_combat_command(state, logger, args)
        return
    end

    if action == 'list' then
        handle_list_command(state, logger, args)
        return
    end

    if action == 'cond' or action == 'conditions' then
        handle_condition_command(state, logger, args)
        return
    end

    if action == 'help' then
        logger.info('Commands: /kaui status | show | hide | ui [show|hide|toggle] | pause | resume | stop | mode <name> | role <name> | pulse <ms> | assist [status|target|clear|name] | combat [status|assistat|reset] | config [status|save] | list [name] | cond [status|missing|set]')
        return
    end

    if action ~= 'status' then
        logger.warn('Unknown command: ' .. action)
    end

    logger.info(status_line(state))
end

function commands.bind(mq_helpers, state, logger)
    if not mq_helpers or not mq_helpers.is_available() then
        return false
    end

    return mq_helpers.bind('/kaui', function(...)
        commands.handle(state, logger, ...)
    end)
end

function commands.unbind(mq_helpers)
    if not mq_helpers or not mq_helpers.is_available() then
        return false
    end

    return mq_helpers.unbind('/kaui')
end

return commands
