local ini = require('kaui.config.ini')
local lists = require('kaui.config.lists')
local schema = require('kaui.config.schema')

local manager = {}

local function sanitize_name(value)
    value = tostring(value or '')
    value = value:gsub('[^%w_%- ]', '')
    value = value:gsub('%s+', '')
    return value
end

local function filename_for(character, server)
    character = sanitize_name(character)
    server = sanitize_name(server)

    if server and server ~= '' then
        return string.format('KissAssist_%s_%s.ini', server, character)
    end

    return string.format('KissAssist_%s.ini', character)
end

local function join_path(base_dir, file_name)
    if not base_dir or base_dir == '' then
        return file_name
    end

    base_dir = tostring(base_dir):gsub('\\', '/')
    if base_dir:sub(-1) == '/' then
        return base_dir .. file_name
    end

    return base_dir .. '/' .. file_name
end

local function basename(path)
    local normalized = tostring(path or ''):gsub('\\', '/')
    return normalized:match('([^/]+)$') or normalized
end

local function read_file(path)
    local file, err = io.open(path, 'rb')
    if not file then
        return nil, string.format('Unable to read %s: %s', tostring(path), tostring(err))
    end

    local ok, contents = pcall(function()
        return file:read('*a')
    end)
    file:close()

    if not ok then
        return nil, string.format('Unable to read %s: %s', tostring(path), tostring(contents))
    end

    return contents or ''
end

local function write_file(path, contents)
    local file, err = io.open(path, 'wb')
    if not file then
        return false, string.format('Unable to write %s: %s', tostring(path), tostring(err))
    end

    local ok, write_err = pcall(function()
        file:write(contents or '')
    end)
    local close_ok, close_err = pcall(function()
        file:close()
    end)

    if not ok then
        return false, string.format('Unable to write %s: %s', tostring(path), tostring(write_err))
    end
    if not close_ok then
        return false, string.format('Unable to close %s: %s', tostring(path), tostring(close_err))
    end

    return true
end

local function copy_file(source, destination)
    local contents, read_err = read_file(source)
    if contents == nil then
        return false, read_err
    end

    return write_file(destination, contents)
end

function manager.resolve_character(mq_helpers)
    if not mq_helpers or not mq_helpers.is_available() then
        return nil, nil
    end

    local character = mq_helpers.me_clean_name() or mq_helpers.me_name()
    local server = mq_helpers.server_name()

    if character == nil or character == '' then
        return nil, server
    end

    return character, server
end

function manager.resolve_path(mq_helpers, options)
    options = options or {}

    if options.path and options.path ~= '' then
        return options.path, false
    end

    local character = options.character
    local server = options.server

    if not character or character == '' then
        character, server = manager.resolve_character(mq_helpers)
    end

    if not character or character == '' then
        return nil, false, 'Unable to resolve character for the KissAssist file.'
    end

    local config_dir = options.config_dir
    if (not config_dir or config_dir == '') and mq_helpers and mq_helpers.config_dir then
        config_dir = mq_helpers.config_dir()
    end

    local server_file = filename_for(character, server)
    local character_file = filename_for(character)
    local server_path = join_path(config_dir, server_file)
    local character_path = join_path(config_dir, character_file)

    if server and server ~= '' and ini.exists(server_path) then
        return server_path, true
    end

    if ini.exists(character_path) then
        return character_path, false
    end

    return character_path, false
end

function manager.load_or_create(mq_helpers, logger, options)
    options = options or {}

    local path, server_specific, err = manager.resolve_path(mq_helpers, options)
    if not path then
        if logger then
            logger.warn(err or 'KissAssist configuration could not be resolved.')
        end
        return nil, false, err
    end

    local ok, doc, created = pcall(ini.load_or_new, path, schema)
    if not ok then
        local message = string.format('Error loading KissAssist INI %s: %s', path, tostring(doc))
        if logger then
            logger.error(message)
        end
        return nil, false, message
    end

    local config_state = {
        path = path,
        document = doc,
        schema = schema,
        server_specific = server_specific,
        created = created,
        last_error = nil,
    }

    if created then
        local save_ok, save_err = pcall(ini.save, path, doc, schema)
        if not save_ok then
            config_state.last_error = string.format('INI created in memory but not written (%s): %s', path, tostring(save_err))
        end
    end

    if logger then
        local action = created and 'created' or 'loaded'
        local flavor = server_specific and 'server-specific' or 'character'
        logger.info(string.format('KissAssist INI %s (%s): %s', action, flavor, basename(path)))
        logger.info(string.format('INI sections: %d, keys: %d', #doc.section_order, doc:count_keys()))
        if config_state.last_error then
            logger.warn(config_state.last_error)
        end
        local missing = lists.missing_condition_refs(doc)
        if #missing > 0 then
            logger.warn(string.format('%d missing condition reference(s). See /kaui cond status.', #missing))
        end
    end

    return config_state, created, config_state.last_error
end

function manager.save(config_state, logger)
    if not config_state or not config_state.path or not config_state.document then
        return false, 'No configuration loaded.'
    end

    local ok, err = pcall(ini.save, config_state.path, config_state.document, config_state.schema or schema)
    if not ok then
        local message = string.format('Error saving KissAssist INI %s: %s', tostring(config_state.path), tostring(err))
        config_state.last_error = message
        if logger then
            logger.error(message)
        end
        return false, message
    end

    config_state.last_error = nil

    if logger then
        logger.info('KissAssist INI saved: ' .. basename(config_state.path))
    end

    return true
end

function manager.read_raw(path)
    return read_file(path)
end

function manager.write_raw(path, contents)
    return write_file(path, contents)
end

function manager.backup(path_or_config, suffix)
    local path = path_or_config
    if type(path_or_config) == 'table' then
        path = path_or_config.path
    end

    if not path or path == '' then
        return nil, 'No INI file available to back up.'
    end

    if not ini.exists(path) then
        return nil, 'Backup failed: file does not exist (' .. tostring(path) .. ').'
    end

    local backup_path = tostring(path) .. (suffix or ('.bak-' .. os.date('%Y%m%d-%H%M%S')))
    local ok, err = copy_file(path, backup_path)
    if not ok then
        return nil, err
    end

    return backup_path
end

manager.filename_for = filename_for
manager.join_path = join_path
manager.basename = basename
manager.schema = schema
manager.ini = ini
manager.lists = lists

return manager
