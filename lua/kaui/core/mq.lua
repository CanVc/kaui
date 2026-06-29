local mq_helpers = {
    mq = nil,
}

function mq_helpers.configure(options)
    options = options or {}
    mq_helpers.mq = options.mq
end

function mq_helpers.is_available()
    return mq_helpers.mq ~= nil
end

local function safe_call(fn)
    if not mq_helpers.mq then
        return nil
    end

    local ok, result = pcall(fn)
    if ok then
        return result
    end

    return nil
end

local function call_path(root, path)
    if not root then
        return nil
    end

    return safe_call(function()
        local current = root
        for index, key in ipairs(path) do
            if current == nil then
                return nil
            end

            if type(current) == 'function' and index > 1 then
                current = current()
                if current == nil then
                    return nil
                end
            end

            current = current[key]
        end

        if type(current) == 'function' then
            return current()
        end

        return current
    end)
end

local function number_or_nil(value)
    local number = tonumber(value)
    if number then
        return number
    end
    return nil
end

local function bool_value(value)
    if value == true then
        return true
    end
    local text = tostring(value or ''):lower()
    return text == 'true' or text == '1' or text == 'yes'
end

function mq_helpers.me()
    return safe_call(function()
        return mq_helpers.mq.TLO.Me
    end)
end

function mq_helpers.target()
    return safe_call(function()
        return mq_helpers.mq.TLO.Target
    end)
end

function mq_helpers.spawn(search)
    return safe_call(function()
        if search then
            return mq_helpers.mq.TLO.Spawn(search)
        end
        return mq_helpers.mq.TLO.Spawn
    end)
end

function mq_helpers.cmd(command)
    if not mq_helpers.mq or not mq_helpers.mq.cmd then
        return false
    end

    local ok = pcall(mq_helpers.mq.cmd, command)
    return ok == true
end

function mq_helpers.delay(ms)
    if not mq_helpers.mq or not mq_helpers.mq.delay then
        return false
    end

    local ok = pcall(mq_helpers.mq.delay, ms)
    return ok == true
end

function mq_helpers.bind(command, callback)
    if not mq_helpers.mq or not mq_helpers.mq.bind then
        return false
    end

    local ok = pcall(mq_helpers.mq.bind, command, callback)
    return ok == true
end

function mq_helpers.unbind(command)
    if not mq_helpers.mq or not mq_helpers.mq.unbind then
        return false
    end

    local ok = pcall(mq_helpers.mq.unbind, command)
    return ok == true
end

function mq_helpers.me_id()
    return number_or_nil(call_path(mq_helpers.me(), { 'ID' }))
end

function mq_helpers.me_name()
    return call_path(mq_helpers.me(), { 'Name' })
end

function mq_helpers.me_clean_name()
    return call_path(mq_helpers.me(), { 'CleanName' }) or mq_helpers.me_name()
end

function mq_helpers.me_type()
    return call_path(mq_helpers.me(), { 'Type' })
end

function mq_helpers.me_combat()
    return bool_value(call_path(mq_helpers.me(), { 'Combat' }))
end

function mq_helpers.me_casting_id()
    return number_or_nil(call_path(mq_helpers.me(), { 'Casting', 'ID' }))
end

function mq_helpers.server_name()
    return safe_call(function()
        if mq_helpers.mq and mq_helpers.mq.TLO and mq_helpers.mq.TLO.EverQuest then
            return mq_helpers.mq.TLO.EverQuest.Server()
        end
        return nil
    end)
end

function mq_helpers.config_dir()
    if not mq_helpers.mq then
        return nil
    end
    return mq_helpers.mq.configDir
end

function mq_helpers.me_class()
    return call_path(mq_helpers.me(), { 'Class', 'ShortName' })
end

function mq_helpers.me_level()
    return number_or_nil(call_path(mq_helpers.me(), { 'Level' }))
end

function mq_helpers.me_pct_hp()
    return number_or_nil(call_path(mq_helpers.me(), { 'PctHPs' }))
end

local function spawn_member(search, path)
    return call_path(mq_helpers.spawn(search), path)
end

function mq_helpers.spawn_id(search)
    return number_or_nil(spawn_member(search, { 'ID' }))
end

function mq_helpers.spawn_name(search)
    return spawn_member(search, { 'Name' })
end

function mq_helpers.spawn_clean_name(search)
    return spawn_member(search, { 'CleanName' }) or mq_helpers.spawn_name(search)
end

function mq_helpers.spawn_type(search)
    return spawn_member(search, { 'Type' })
end

function mq_helpers.spawn_class_short_name(search)
    return spawn_member(search, { 'Class', 'ShortName' })
end

function mq_helpers.spawn_pct_hp(search)
    return number_or_nil(spawn_member(search, { 'PctHPs' }))
end

function mq_helpers.spawn_distance(search)
    return number_or_nil(spawn_member(search, { 'Distance' }))
end

function mq_helpers.spawn_distance3d(search)
    return number_or_nil(spawn_member(search, { 'Distance3D' }))
end

function mq_helpers.spawn_line_of_sight(search)
    return bool_value(spawn_member(search, { 'LineOfSight' }))
end

function mq_helpers.spawn_mezzed_id(search)
    return number_or_nil(spawn_member(search, { 'Mezzed', 'ID' }))
end

function mq_helpers.spawn_target_id(search)
    return number_or_nil(spawn_member(search, { 'TargetOfTarget', 'ID' }))
end

function mq_helpers.target_id()
    return number_or_nil(call_path(mq_helpers.target(), { 'ID' }))
end

function mq_helpers.target_name()
    return call_path(mq_helpers.target(), { 'CleanName' }) or call_path(mq_helpers.target(), { 'Name' })
end

function mq_helpers.target_type()
    return call_path(mq_helpers.target(), { 'Type' })
end

function mq_helpers.target_pct_hp()
    return number_or_nil(call_path(mq_helpers.target(), { 'PctHPs' }))
end

function mq_helpers.target_distance()
    return number_or_nil(call_path(mq_helpers.target(), { 'Distance' }))
end

function mq_helpers.target_distance3d()
    return number_or_nil(call_path(mq_helpers.target(), { 'Distance3D' }))
end

function mq_helpers.target_line_of_sight()
    return bool_value(call_path(mq_helpers.target(), { 'LineOfSight' }))
end

function mq_helpers.target_mezzed_id()
    return number_or_nil(call_path(mq_helpers.target(), { 'Mezzed', 'ID' }))
end

function mq_helpers.group_main_assist_id()
    return number_or_nil(safe_call(function()
        local group = mq_helpers.mq.TLO.Group
        return group and group.MainAssist and group.MainAssist.ID()
    end))
end

function mq_helpers.group_main_assist_name()
    return safe_call(function()
        local group = mq_helpers.mq.TLO.Group
        return group and group.MainAssist and (group.MainAssist.CleanName() or group.MainAssist.Name())
    end)
end

function mq_helpers.me_group_assist_target_id()
    return number_or_nil(call_path(mq_helpers.me(), { 'GroupAssistTarget', 'ID' }))
end

return mq_helpers
