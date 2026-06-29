local lists = {}

lists.definitions = {
    Buffs = { section = 'Buffs', prefix = 'Buffs', size_key = 'BuffsSize' },
    GoMSpell = { section = 'GoM', prefix = 'GoMSpell', size_key = 'GoMSize' },
    AE = { section = 'AE', prefix = 'AE', size_key = 'AESize' },
    DPS = { section = 'DPS', prefix = 'DPS', size_key = 'DPSSize' },
    Aggro = { section = 'Aggro', prefix = 'Aggro', size_key = 'AggroSize' },
    Heals = { section = 'Heals', prefix = 'Heals', size_key = 'HealsSize' },
    Cures = { section = 'Cures', prefix = 'Cures', size_key = 'CuresSize' },
    PetBuffs = { section = 'Pet', prefix = 'PetBuffs', size_key = 'PetBuffsSize' },
    PetToys = { section = 'Pet', prefix = 'PetToys', size_key = 'PetToysSize' },
    Burn = { section = 'Burn', prefix = 'Burn', size_key = 'BurnSize' },
    PullLocs = { section = nil, prefix = 'PullLocs', size_key = nil },
    Cond = { section = 'KConditions', prefix = 'Cond', size_key = 'CondSize' },
}

local function normalize_name(name)
    return tostring(name or ''):gsub('^%s*(.-)%s*$', '%1')
end

local function copy_entry(entry)
    return {
        index = entry.index,
        key = entry.key,
        raw = entry.raw,
        value = entry.value,
        condition_ref = entry.condition_ref,
        condition_id = entry.condition_id,
    }
end

function lists.definition(name, section_override)
    name = normalize_name(name)
    local definition = lists.definitions[name]

    if not definition then
        local wanted = name:lower()
        for key, candidate in pairs(lists.definitions) do
            if key:lower() == wanted then
                definition = candidate
                break
            end
        end
    end

    if definition then
        local copy = {}
        for key, value in pairs(definition) do
            copy[key] = value
        end
        if section_override then
            copy.section = section_override
        end
        return copy
    end

    return {
        section = section_override or name,
        prefix = name,
        size_key = name .. 'Size',
    }
end

function lists.parse_condition_suffix(raw)
    raw = tostring(raw or '')
    local value, cond = raw:match('^(.-)|[cC][oO][nN][dD](%d+)%s*$')
    if cond then
        return value, 'cond' .. cond, tonumber(cond)
    end
    return raw, nil, nil
end

function lists.compose_value(value, condition_id)
    value = tostring(value or '')
    if condition_id and tonumber(condition_id) then
        return string.format('%s|cond%d', value, tonumber(condition_id))
    end
    return value
end

function lists.max_existing_index(doc, definition)
    local section_data = doc.sections[definition.section]
    if not section_data then
        return 0
    end

    local max_index = 0
    local pattern = '^' .. definition.prefix .. '(%d+)$'
    for key in pairs(section_data.values) do
        local index = tonumber(tostring(key):match(pattern))
        if index and index > max_index then
            max_index = index
        end
    end

    return max_index
end

function lists.size(doc, name, section_override)
    local definition = lists.definition(name, section_override)
    if not definition.section then
        return 0
    end

    local configured = definition.size_key and tonumber(doc:get(definition.section, definition.size_key)) or nil
    local max_existing = lists.max_existing_index(doc, definition)

    if configured and configured > 0 then
        return math.max(configured, max_existing)
    end

    return max_existing
end

function lists.read(doc, name, section_override)
    local definition = lists.definition(name, section_override)
    local result = {}
    local size = lists.size(doc, name, section_override)

    for index = 1, size do
        local key = definition.prefix .. tostring(index)
        local raw = doc:get(definition.section, key)
        if raw ~= nil then
            local value, condition_ref, condition_id = lists.parse_condition_suffix(raw)
            table.insert(result, {
                index = index,
                key = key,
                raw = raw,
                value = value,
                condition_ref = condition_ref,
                condition_id = condition_id,
            })
        end
    end

    return result
end

local function write_entries(doc, definition, entries)
    local old_size = lists.size(doc, definition.prefix, definition.section)

    for index = 1, old_size do
        doc:delete(definition.section, definition.prefix .. tostring(index))
    end

    for index, entry in ipairs(entries) do
        local raw = entry.raw
        if raw == nil then
            raw = lists.compose_value(entry.value, entry.condition_id)
        end
        doc:set(definition.section, definition.prefix .. tostring(index), raw)
    end

    if definition.size_key then
        doc:set(definition.section, definition.size_key, math.max(old_size, #entries))
    end
end

function lists.write(doc, name, entries, section_override)
    local definition = lists.definition(name, section_override)
    write_entries(doc, definition, entries or {})
end

function lists.add(doc, name, value, condition_id, section_override)
    local entries = lists.read(doc, name, section_override)
    table.insert(entries, {
        value = tostring(value or 'NULL'),
        condition_id = condition_id,
    })
    lists.write(doc, name, entries, section_override)
    return #entries
end

function lists.remove(doc, name, index, section_override)
    index = tonumber(index)
    if not index or index < 1 then
        return false
    end

    local entries = lists.read(doc, name, section_override)
    if index > #entries then
        return false
    end

    table.remove(entries, index)
    lists.write(doc, name, entries, section_override)
    return true
end

function lists.move(doc, name, from_index, to_index, section_override)
    from_index = tonumber(from_index)
    to_index = tonumber(to_index)
    if not from_index or not to_index then
        return false
    end

    local entries = lists.read(doc, name, section_override)
    if from_index < 1 or from_index > #entries or to_index < 1 or to_index > #entries then
        return false
    end

    local item = table.remove(entries, from_index)
    table.insert(entries, to_index, item)
    lists.write(doc, name, entries, section_override)
    return true
end

function lists.compact(doc, name, section_override)
    local entries = lists.read(doc, name, section_override)
    local compacted = {}

    for _, entry in ipairs(entries) do
        local raw = tostring(entry.raw or '')
        if raw ~= '' then
            table.insert(compacted, copy_entry(entry))
        end
    end

    lists.write(doc, name, compacted, section_override)
    return #entries, #compacted
end

function lists.conditions_enabled(doc)
    return tostring(doc:get('KConditions', 'ConOn', '0')) ~= '0'
end

function lists.conditions_size(doc)
    return lists.size(doc, 'Cond')
end

function lists.read_conditions(doc)
    return lists.read(doc, 'Cond')
end

function lists.set_condition(doc, index, expression)
    index = tonumber(index)
    if not index or index < 1 then
        return false
    end

    doc:ensure_section('KConditions')
    local size = math.max(lists.conditions_size(doc), index)
    doc:set('KConditions', 'Cond' .. tostring(index), tostring(expression or 'TRUE'))
    doc:set('KConditions', 'CondSize', size)
    return true
end

function lists.condition_exists(doc, condition_id)
    condition_id = tonumber(condition_id)
    if not condition_id or condition_id < 1 then
        return false
    end

    local value = doc:get('KConditions', 'Cond' .. tostring(condition_id))
    return value ~= nil and tostring(value) ~= ''
end

function lists.missing_condition_refs(doc)
    local missing = {}

    for list_name, definition in pairs(lists.definitions) do
        if list_name ~= 'Cond' and definition.section and doc:has_section(definition.section) then
            for _, entry in ipairs(lists.read(doc, list_name)) do
                if entry.condition_id and not lists.condition_exists(doc, entry.condition_id) then
                    table.insert(missing, {
                        list = list_name,
                        section = definition.section,
                        key = entry.key,
                        condition_id = entry.condition_id,
                        condition_ref = entry.condition_ref,
                        raw = entry.raw,
                    })
                end
            end
        end
    end

    table.sort(missing, function(a, b)
        if a.section == b.section then
            return a.key < b.key
        end
        return a.section < b.section
    end)

    return missing
end

function lists.summary(doc)
    local result = {}

    for name, definition in pairs(lists.definitions) do
        if definition.section and doc:has_section(definition.section) then
            local entries = lists.read(doc, name)
            table.insert(result, {
                name = name,
                section = definition.section,
                size = lists.size(doc, name),
                entries = #entries,
            })
        end
    end

    table.sort(result, function(a, b)
        return a.name < b.name
    end)

    return result
end

return lists
