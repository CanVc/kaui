local constants = require('kaui.core.constants')

local logger = {
    mq = nil,
}

function logger.configure(options)
    options = options or {}
    logger.mq = options.mq
end

local function emit(level, message)
    local line = string.format('[%s][%s] %s', constants.APP_NAME, level, tostring(message))

    if logger.mq and logger.mq.cmd then
        local ok = pcall(logger.mq.cmd, '/echo ' .. line)
        if ok then
            return
        end
    end

    print(line)
end

function logger.info(message)
    emit('INFO', message)
end

function logger.warn(message)
    emit('WARN', message)
end

function logger.error(message)
    emit('ERROR', message)
end

return logger
