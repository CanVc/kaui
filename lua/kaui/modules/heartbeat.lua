local heartbeat = {
    name = 'core_heartbeat',
    enabled = true,
}

function heartbeat.onInit(context)
    context.runtime.timers.heartbeat_started_at = os.time()
end

function heartbeat.onPulse(context)
    context.runtime.timers.heartbeat_last_pulse = os.time()
end

function heartbeat.onShutdown(context)
    context.runtime.timers.heartbeat_stopped_at = os.time()
end

return function()
    return heartbeat
end
