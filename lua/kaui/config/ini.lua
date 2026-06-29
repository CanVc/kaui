local ini = {}

local function trim(value)
    return tostring(value or ''):match('^%s*(.-)%s*$')
end

local function stringify(value)
    if value == nil then
        return ''
    end
    if value == true then
        return '1'
    end
    if value == false then
        return '0'
    end
    return tostring(value)
end

local function exists(path)
    local file = io.open(path, 'r')
    if file then
        file:close()
        return true
    end
    return false
end

local function clone_default(value)
    if type(value) ~= 'table' then
        return value
    end

    local copy = {}
    for key, item in pairs(value) do
        copy[key] = clone_default(item)
    end
    return copy
end

local document = {}
document.__index = document

function ini.new()
    return setmetatable({
        sections = {},
        section_order = {},
        source_path = nil,
        dirty = false,
    }, document)
end

function document:has_section(section)
    return self.sections[section] ~= nil
end

function document:ensure_section(section)
    if not self.sections[section] then
        self.sections[section] = {
            values = {},
            key_order = {},
        }
        table.insert(self.section_order, section)
        self.dirty = true
    end

    return self.sections[section]
end

function document:get(section, key, default)
    local section_data = self.sections[section]
    if not section_data or section_data.values[key] == nil then
        return default
    end
    return section_data.values[key]
end

function document:set(section, key, value)
    local section_data = self:ensure_section(section)
    if section_data.values[key] == nil then
        table.insert(section_data.key_order, key)
    end
    section_data.values[key] = stringify(value)
    self.dirty = true
end

function document:delete(section, key)
    local section_data = self.sections[section]
    if not section_data or section_data.values[key] == nil then
        return false
    end

    section_data.values[key] = nil
    for index = #section_data.key_order, 1, -1 do
        if section_data.key_order[index] == key then
            table.remove(section_data.key_order, index)
        end
    end
    self.dirty = true
    return true
end

function document:apply_defaults(schema)
    if not schema or not schema.sections then
        return
    end

    for _, section in ipairs(schema.sections) do
        self:ensure_section(section)
        local fields = schema.fields and schema.fields[section] or nil
        if fields then
            for key, definition in pairs(fields) do
                if self:get(section, key) == nil then
                    self:set(section, key, clone_default(definition.default))
                end
            end
        end
    end
end

function document:to_table()
    local data = {}
    for section, section_data in pairs(self.sections) do
        data[section] = {}
        for key, value in pairs(section_data.values) do
            data[section][key] = value
        end
    end
    return data
end

function document:count_keys()
    local count = 0
    for _, section_data in pairs(self.sections) do
        for _ in pairs(section_data.values) do
            count = count + 1
        end
    end
    return count
end

local function add_key(section_data, key, value)
    if section_data.values[key] == nil then
        table.insert(section_data.key_order, key)
    end
    section_data.values[key] = value
end

function ini.load(path)
    local doc = ini.new()
    doc.source_path = path

    local file = assert(io.open(path, 'r'), 'Unable to read INI: ' .. tostring(path))
    local current_section = nil

    for line in file:lines() do
        local section = line:match('^%s*%[([^%[%]]+)%]%s*$')
        if section then
            current_section = trim(section)
            doc:ensure_section(current_section)
            doc.dirty = false
        else
            local key, value = line:match('^%s*([^=;#][^=]-)%s*=%s*(.-)%s*$')
            if key and current_section then
                add_key(doc.sections[current_section], trim(key), value or '')
            end
        end
    end

    file:close()
    doc.dirty = false
    return doc
end

local function section_index_map(doc)
    local map = {}
    for index, section in ipairs(doc.section_order) do
        map[section] = index
    end
    return map
end

local function ordered_sections(doc, schema)
    local result = {}
    local seen = {}

    if schema and schema.sections then
        for _, section in ipairs(schema.sections) do
            if doc.sections[section] then
                table.insert(result, section)
                seen[section] = true
            end
        end
    end

    for _, section in ipairs(doc.section_order) do
        if not seen[section] then
            table.insert(result, section)
            seen[section] = true
        end
    end

    local known = section_index_map(doc)
    for section in pairs(doc.sections) do
        if not seen[section] then
            table.insert(result, section)
            seen[section] = true
        end
    end

    table.sort(result, function(a, b)
        local ai = known[a]
        local bi = known[b]
        if ai and bi then
            return ai < bi
        end
        if ai then
            return true
        end
        if bi then
            return false
        end
        return a < b
    end)

    if schema and schema.sections then
        local schema_index = {}
        for index, section in ipairs(schema.sections) do
            schema_index[section] = index
        end
        table.sort(result, function(a, b)
            local ai = schema_index[a]
            local bi = schema_index[b]
            if ai and bi then
                return ai < bi
            end
            if ai then
                return true
            end
            if bi then
                return false
            end
            local oi = known[a]
            local oj = known[b]
            if oi and oj then
                return oi < oj
            end
            return a < b
        end)
    end

    return result
end

local function ordered_keys(section, section_data, schema)
    local result = {}
    local seen = {}

    local schema_keys = schema and schema.key_order and schema.key_order[section] or nil
    if schema_keys then
        for _, key in ipairs(schema_keys) do
            if section_data.values[key] ~= nil then
                table.insert(result, key)
                seen[key] = true
            end
        end
    end

    for _, key in ipairs(section_data.key_order) do
        if not seen[key] and section_data.values[key] ~= nil then
            table.insert(result, key)
            seen[key] = true
        end
    end

    local rest = {}
    for key in pairs(section_data.values) do
        if not seen[key] then
            table.insert(rest, key)
        end
    end
    table.sort(rest)
    for _, key in ipairs(rest) do
        table.insert(result, key)
    end

    return result
end

function ini.save(path, doc, schema)
    assert(type(path) == 'string', 'path required')
    assert(type(doc) == 'table', 'INI document required')

    local file = assert(io.open(path, 'w+b'), 'Unable to write INI: ' .. tostring(path))

    for _, section in ipairs(ordered_sections(doc, schema)) do
        local section_data = doc.sections[section]
        if section_data then
            file:write(string.format('[%s]\n', section))
            for _, key in ipairs(ordered_keys(section, section_data, schema)) do
                file:write(string.format('%s=%s\n', key, stringify(section_data.values[key])))
            end
            file:write('\n')
        end
    end

    file:close()
    doc.source_path = path
    doc.dirty = false
end

function ini.load_or_new(path, schema)
    local doc
    local created = false

    if exists(path) then
        doc = ini.load(path)
    else
        doc = ini.new()
        doc.source_path = path
        created = true
    end

    if schema then
        doc:apply_defaults(schema)
    end

    return doc, created
end

ini.exists = exists
ini.trim = trim
ini.stringify = stringify

return ini
