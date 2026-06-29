local config_manager = require('kaui.config.manager')
local list_config = require('kaui.config.lists')

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
    return string.format(
        'running=%s paused=%s mode=%s role=%s pulse=%dms pulses=%d me=%s target=%s',
        tostring(state.running),
        tostring(state.paused),
        tostring(state.mode),
        tostring(state.role),
        state.pulse_ms,
        state.pulse_count,
        state.me.name or '-',
        state.target.name or '-'
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
        state.role = args[2]
        logger.info('Runtime role: ' .. state.role)
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

    if action == 'list' then
        handle_list_command(state, logger, args)
        return
    end

    if action == 'cond' or action == 'conditions' then
        handle_condition_command(state, logger, args)
        return
    end

    if action == 'help' then
        logger.info('Commands: /kaui status | show | hide | ui [show|hide|toggle] | pause | resume | stop | mode <name> | role <name> | pulse <ms> | config [status|save] | list [name] | cond [status|missing|set]')
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
