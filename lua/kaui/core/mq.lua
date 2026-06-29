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

function mq_helpers.me_name()
    local me = mq_helpers.me()
    return safe_call(function()
        return me and me.Name()
    end)
end

function mq_helpers.me_clean_name()
    local me = mq_helpers.me()
    return safe_call(function()
        if me and me.CleanName then
            return me.CleanName()
        end
        return me and me.Name()
    end)
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
    local me = mq_helpers.me()
    return safe_call(function()
        return me and me.Class.ShortName()
    end)
end

function mq_helpers.me_level()
    local me = mq_helpers.me()
    return safe_call(function()
        return me and me.Level()
    end)
end

function mq_helpers.me_pct_hp()
    local me = mq_helpers.me()
    return safe_call(function()
        return me and me.PctHPs()
    end)
end

function mq_helpers.target_id()
    local target = mq_helpers.target()
    return safe_call(function()
        return target and target.ID()
    end)
end

function mq_helpers.target_name()
    local target = mq_helpers.target()
    return safe_call(function()
        return target and target.CleanName()
    end)
end

function mq_helpers.target_pct_hp()
    local target = mq_helpers.target()
    return safe_call(function()
        return target and target.PctHPs()
    end)
end

return mq_helpers
