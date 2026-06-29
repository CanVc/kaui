local constants = require('kaui.core.constants')
local config_manager = require('kaui.config.manager')

local ui = {}

local UI_ID = 'KAUI'
local WINDOW_TITLE = constants.DISPLAY_NAME .. ' v' .. constants.VERSION .. '###' .. UI_ID

local ui_state = nil
local imgui = nil

local list_config = config_manager.lists

local EDITOR_TABS = {
    {
        id = 'general',
        label = 'General',
        description = 'Core KissAssist behavior, camp, medding and communication settings.',
        panels = {
            { section = 'General', title = 'General settings' },
        },
    },
    {
        id = 'spells',
        label = 'Spells',
        description = 'Spell gem, spell set and casting safety settings. Both [SpellS] and [Spells] are preserved for KissAssist compatibility.',
        panels = {
            { section = 'SpellS', title = 'Spell set settings' },
            { section = 'Spells', title = 'Casting settings' },
        },
    },
    {
        id = 'melee',
        label = 'Melee',
        description = 'Assist, melee, stick and twist settings.',
        panels = {
            { section = 'Melee', title = 'Melee settings' },
        },
    },
    {
        id = 'dps',
        label = 'DPS',
        description = 'DPS settings and ordered DPS entries.',
        panels = {
            { section = 'DPS', title = 'DPS settings' },
        },
        list = {
            name = 'DPS',
            title = 'DPS ordered list',
            help = 'Use the KissAssist DPS entry format. Conditions are saved as a |condN suffix.',
        },
    },
    {
        id = 'buffs',
        label = 'Buffs',
        description = 'Buff settings and ordered buff entries.',
        panels = {
            { section = 'Buffs', title = 'Buff settings' },
        },
        list = {
            name = 'Buffs',
            title = 'Buff ordered list',
            help = 'Use the KissAssist Buffs entry format. Conditions are saved as a |condN suffix.',
        },
    },
    {
        id = 'heals',
        label = 'Heals',
        description = 'Heal settings and ordered heal entries.',
        panels = {
            { section = 'Heals', title = 'Heal settings' },
        },
        list = {
            name = 'Heals',
            title = 'Heal ordered list',
            help = 'Use the KissAssist Heals entry format. Conditions are saved as a |condN suffix.',
        },
    },
}

local FIELD_ORDERS = {
    General = {
        'KissAssistVer',
        'Role',
        'CampRadius',
        'CampRadiusExceed',
        'ReturnToCamp',
        'ChaseAssist',
        'ChaseDistance',
        'MedOn',
        'MedStart',
        'MedStop',
        'MedCombat',
        'LootOn',
        'RezAcceptOn',
        'AcceptInvitesOn',
        'GroupWatchOn',
        'GroupWatchCheck',
        'CorpseRecoveryOn',
        'EQBCOn',
        'DanNetOn',
        'DanNetDelay',
        'IRCOn',
        'CampfireOn',
        'GroupEscapeOn',
        'DPSMeter',
        'ScatterOn',
        'LOSBeforeCombat',
        'UseSpawnMaster',
        'TwistOn',
        'TwistMed',
        'TwistWhat',
    },
    SpellS = {
        'MiscGem',
        'MiscGemLW',
        'MiscGemRemem',
        'LoadSpellSet',
        'SpellSetName',
    },
    Spells = {
        'CastingInterruptOn',
        'CheckStuckGem',
    },
    Melee = {
        'AssistAt',
        'MeleeOn',
        'FaceMobOn',
        'MeleeDistance',
        'StickHow',
        'AutoFireOn',
        'UseMQ2Melee',
        'TargetSwitchingOn',
        'AutoHide',
        'MeleeTwistOn',
        'MeleeTwistWhat',
        'PetTauntOverride',
    },
    DPS = {
        'DPSOn',
        'DPSSize',
        'DPSSkip',
        'DPSInterval',
        'DebuffAllOn',
    },
    Buffs = {
        'BuffsOn',
        'BuffsSize',
        'RebuffOn',
        'CheckBuffsTimer',
        'PowerSource',
    },
    Heals = {
        'Help',
        'HealsOn',
        'HealInterval',
        'AutoRezOn',
        'HealsSize',
        'XTarHeal',
        'XTarHealList',
        'HealGroupPetsOn',
        'RezMeLast',
    },
    KConditions = {
        'ConOn',
        'CondSize',
    },
}

local BOOLEAN_FIELDS = {
    General = {
        ReturnToCamp = true,
        ChaseAssist = true,
        MedOn = true,
        MedCombat = true,
        LootOn = true,
        AcceptInvitesOn = true,
        CorpseRecoveryOn = true,
        IRCOn = true,
        CampfireOn = true,
        GroupEscapeOn = true,
        DPSMeter = true,
        ScatterOn = true,
        LOSBeforeCombat = true,
        UseSpawnMaster = true,
        TwistOn = true,
    },
    SpellS = {
        MiscGemRemem = true,
        LoadSpellSet = true,
    },
    Spells = {
        CastingInterruptOn = true,
        CheckStuckGem = true,
    },
    Melee = {
        MeleeOn = true,
        FaceMobOn = true,
        AutoFireOn = true,
        UseMQ2Melee = true,
        TargetSwitchingOn = true,
        AutoHide = true,
        MeleeTwistOn = true,
        PetTauntOverride = true,
    },
    DPS = {
        DPSOn = true,
        DebuffAllOn = true,
    },
    Buffs = {
        BuffsOn = true,
        RebuffOn = true,
    },
    Heals = {
        HealsOn = true,
        AutoRezOn = true,
        XTarHeal = true,
        HealGroupPetsOn = true,
        RezMeLast = true,
    },
    KConditions = {
        ConOn = true,
    },
}

local function trim(value)
    return tostring(value or ''):match('^%s*(.-)%s*$')
end

local function has_path_separator(path)
    return tostring(path or ''):find('[\\/]') ~= nil
end

local function filename_only(path)
    return config_manager.basename(path)
end

local function truncate(value, max_len)
    value = tostring(value or '')
    max_len = max_len or 60
    if #value <= max_len then
        return value
    end
    return value:sub(1, max_len - 3) .. '...'
end

local function flag_value(group_name, ...)
    local group = rawget(_G, group_name)
    if type(group) ~= 'table' then
        return nil
    end

    for _, name in ipairs({ ... }) do
        if group[name] ~= nil then
            return group[name]
        end
    end

    return nil
end

local function bor_flags(...)
    local result = 0
    for index = 1, select('#', ...) do
        local value = select(index, ...)
        if type(value) == 'number' then
            if bit32 and bit32.bor then
                result = bit32.bor(result, value)
            else
                result = result + value
            end
        end
    end
    return result
end

local function child_border_flag()
    return flag_value('ImGuiChildFlags', 'Border', 'Borders') or true
end

local function safe_set_next_window_size(width, height)
    if not imgui or not imgui.SetNextWindowSize or not rawget(_G, 'ImVec2') then
        return
    end

    local condition = flag_value('ImGuiCond', 'FirstUseEver') or 0
    pcall(imgui.SetNextWindowSize, ImVec2(width, height), condition)

    if imgui.SetNextWindowSizeConstraints then
        pcall(imgui.SetNextWindowSizeConstraints, ImVec2(560, 420), ImVec2(2200, 2200))
    end
end

local function content_region_avail(ImGui)
    if not ImGui.GetContentRegionAvail then
        return 0, 0
    end

    local x, y = ImGui.GetContentRegionAvail()
    if type(x) == 'table' then
        return tonumber(x.x or x[1] or 0) or 0, tonumber(x.y or x[2] or 0) or 0
    end

    return tonumber(x or 0) or 0, tonumber(y or 0) or 0
end

local function text_wrapped(ImGui, text)
    if ImGui.TextWrapped then
        ImGui.TextWrapped(tostring(text or ''))
    else
        ImGui.Text(tostring(text or ''))
    end
end

local function tooltip(ImGui, text)
    text = tostring(text or '')
    if text == '' or not ImGui.IsItemHovered or not ImGui.IsItemHovered() then
        return
    end

    if ImGui.BeginTooltip and ImGui.EndTooltip then
        ImGui.BeginTooltip()
        text_wrapped(ImGui, text)
        ImGui.EndTooltip()
    else
        ImGui.SetTooltip(text)
    end
end

local function push_style_color(ImGui, color_name, r, g, b, a)
    local colors = rawget(_G, 'ImGuiCol')
    local color_id = type(colors) == 'table' and colors[color_name] or nil
    if color_id ~= nil and ImGui.PushStyleColor then
        ImGui.PushStyleColor(color_id, r, g, b, a)
        return true
    end
    return false
end

local function pop_style_color(ImGui, count)
    count = count or 1
    if ImGui.PopStyleColor then
        ImGui.PopStyleColor(count)
    end
end

local function button_sized(ImGui, label, width, height)
    if width and height then
        local ok, clicked = pcall(ImGui.Button, label, width, height)
        if ok then
            return clicked
        end

        if rawget(_G, 'ImVec2') then
            local ok_vec, clicked_vec = pcall(ImGui.Button, label, ImVec2(width, height))
            if ok_vec then
                return clicked_vec
            end
        end
    end

    return ImGui.Button(label)
end

local function small_button(ImGui, label)
    if ImGui.SmallButton then
        return ImGui.SmallButton(label)
    end
    return ImGui.Button(label)
end

local function selectable_clicked(ImGui, label, selected)
    local value, clicked = ImGui.Selectable(label, selected)
    if clicked ~= nil then
        return clicked == true
    end
    return value == true
end

local function collapsing_header(ImGui, label, default_open)
    if not ImGui.CollapsingHeader then
        ImGui.Text(label:gsub('##.*$', ''))
        return true
    end

    local flags = default_open and (flag_value('ImGuiTreeNodeFlags', 'DefaultOpen') or 0) or 0
    if flags ~= 0 then
        return ImGui.CollapsingHeader(label, flags)
    end
    return ImGui.CollapsingHeader(label)
end

local function set_status(message)
    if not ui_state then
        return
    end
    ui_state.status = tostring(message or '')
    ui_state.last_error = nil
end

local function set_error(logger, message)
    message = tostring(message or 'Unknown error')
    if ui_state then
        ui_state.last_error = message
        ui_state.status = 'Error'
    end
    if logger then
        logger.error(message)
    end
end

local function structured_dirty(context)
    local config_state = context and context.runtime and context.runtime.config or nil
    return config_state and config_state.document and config_state.document.dirty == true
end

local function any_dirty(context)
    return (ui_state and ui_state.raw_dirty == true) or structured_dirty(context)
end

local function dirty_label(context)
    if ui_state and ui_state.raw_dirty then
        return 'Raw INI modified', 1, 1, 0, 1
    end
    if structured_dirty(context) then
        return 'Unsaved config changes', 1, 1, 0, 1
    end
    return 'Saved', 0.2, 1, 0.2, 1
end

local function mark_config_changed(context, message, log_it)
    set_status(message or 'Configuration modified.')
    if log_it and context and context.logger then
        context.logger.info(message or 'Configuration modified from UI.')
    end
end

local function normalize_path(context, value)
    local path = trim(value)
    if path == '' then
        return nil, 'No INI file selected.'
    end

    if not path:lower():match('%.ini$') then
        path = path .. '.ini'
    end

    if not has_path_separator(path) then
        if ui_state and ui_state.active_path and filename_only(ui_state.active_path) == path then
            return ui_state.active_path
        end

        if context and context.mq and context.mq.config_dir then
            local config_dir = context.mq.config_dir()
            if config_dir and config_dir ~= '' then
                path = config_manager.join_path(config_dir, path)
            end
        end
    end

    return path
end

local function refresh_identity(context)
    if not ui_state then
        return
    end

    local character, server = config_manager.resolve_character(context and context.mq or nil)
    ui_state.character = character or (context and context.runtime and context.runtime.me.name) or '-'
    ui_state.server = server or '-'
end

local function refresh_detected_path(context)
    if not ui_state then
        return nil
    end

    local path, server_specific, err = config_manager.resolve_path(context and context.mq or nil, {})
    ui_state.detected_path = path
    ui_state.detected_server_specific = server_specific
    ui_state.detect_error = err
    return path, server_specific, err
end

local function read_raw_into_state(context, path, silent)
    local contents, err = config_manager.read_raw(path)
    if contents == nil then
        ui_state.raw_buffer = ui_state.raw_buffer or ''
        ui_state.raw_loaded = false
        if not silent then
            set_error(context.logger, err)
        end
        return false, err
    end

    ui_state.raw_buffer = contents
    ui_state.raw_loaded = true
    ui_state.raw_dirty = false
    ui_state.last_raw_path = path
    if not silent then
        set_status('Raw INI loaded from disk.')
    end
    return true
end

local function apply_config_state(context, config_state, created, source_label)
    context.runtime.config = config_state
    context.runtime.config_error = config_state and config_state.last_error or nil

    if config_state then
        ui_state.active_path = config_state.path
        ui_state.path_input = filename_only(config_state.path) or ui_state.path_input or ''
        read_raw_into_state(context, config_state.path, true)
        refresh_identity(context)
        refresh_detected_path(context)
        local action = created and 'created' or 'loaded'
        set_status(string.format('INI %s%s: %s', action, source_label and (' (' .. source_label .. ')') or '', filename_only(config_state.path)))
        if config_state.last_error then
            ui_state.last_error = config_state.last_error
        end
        return true
    end

    return false
end

local function load_selected_ini(context, source_label)
    local path, path_err = normalize_path(context, ui_state.path_input)
    if not path then
        set_error(context.logger, path_err)
        return false
    end

    local config_state, created, err = config_manager.load_or_create(context.mq, context.logger, { path = path })
    if not config_state then
        set_error(context.logger, err or 'Unable to load INI.')
        return false
    end

    return apply_config_state(context, config_state, created, source_label)
end

local function detect_ini(context)
    refresh_identity(context)
    local path, server_specific, err = refresh_detected_path(context)
    if not path then
        set_error(context.logger, err or 'Unable to detect the INI file.')
        return false
    end

    ui_state.active_path = path
    ui_state.path_input = filename_only(path)
    set_status(string.format('Detected file (%s): %s', server_specific and 'server-specific' or 'character', filename_only(path)))
    return true
end

local function reload_ini(context)
    if not load_selected_ini(context, 'reload') then
        return false
    end
    set_status('INI reloaded from disk.')
    return true
end

local function save_raw_buffer(context)
    local path, path_err = normalize_path(context, ui_state.path_input)
    if not path then
        set_error(context.logger, path_err)
        return false
    end

    local ok, err = config_manager.write_raw(path, ui_state.raw_buffer or '')
    if not ok then
        set_error(context.logger, err)
        return false
    end

    local config_state, created, load_err = config_manager.load_or_create(context.mq, context.logger, { path = path })
    if not config_state then
        set_error(context.logger, load_err or 'Raw INI saved, but parser reload failed.')
        return false
    end

    apply_config_state(context, config_state, created, 'raw')
    ui_state.raw_dirty = false
    ui_state.raw_loaded = true
    ui_state.last_raw_path = path
    set_status('Raw INI saved: ' .. filename_only(path))
    return true
end

local function save_ini(context)
    if ui_state.raw_dirty then
        return save_raw_buffer(context)
    end

    local ok, err = config_manager.save(context.runtime.config, context.logger)
    if not ok then
        set_error(context.logger, err)
        return false
    end

    ui_state.active_path = context.runtime.config.path
    ui_state.path_input = filename_only(context.runtime.config.path)
    read_raw_into_state(context, context.runtime.config.path, true)
    set_status('INI saved: ' .. filename_only(context.runtime.config.path))
    return true
end

local function backup_ini(context)
    local path, path_err = normalize_path(context, ui_state.path_input)
    if not path then
        set_error(context.logger, path_err)
        return false
    end

    local backup_path, err = config_manager.backup(path)
    if not backup_path then
        set_error(context.logger, err)
        return false
    end

    ui_state.last_backup_path = backup_path
    set_status('Backup created: ' .. filename_only(backup_path))
    if context.logger then
        context.logger.info('INI backup created: ' .. filename_only(backup_path))
    end
    return true
end

local function progress_bar(ImGui, id, fraction, overlay, width, height)
    fraction = math.max(0, math.min(1, tonumber(fraction or 0) or 0))
    overlay = overlay or string.format('%d%%', math.floor(fraction * 100))

    if ImGui.ProgressBar then
        if rawget(_G, 'ImVec2') then
            local ok = pcall(ImGui.ProgressBar, fraction, ImVec2(width or -1, height or 18), overlay)
            if ok then
                return
            end
        end

        local ok_plain = pcall(ImGui.ProgressBar, fraction, width or -1, height or 18, overlay)
        if ok_plain then
            return
        end
    end

    ImGui.Text(string.format('%s %s', id or '', overlay))
end

local function draw_status_line(context)
    local runtime = context.runtime
    local ImGui = imgui

    if runtime.running and not runtime.paused then
        ImGui.TextColored(0, 1, 0, 1, 'RUNNING')
    elseif runtime.paused then
        ImGui.TextColored(1, 1, 0, 1, 'PAUSED')
    else
        ImGui.TextColored(1, 0, 0, 1, 'STOPPED')
    end

    ImGui.SameLine()
    ImGui.Text(string.format('mode=%s role=%s pulse=%dms pulses=%d', tostring(runtime.mode), tostring(runtime.role), runtime.pulse_ms, runtime.pulse_count))
end

local function draw_main_action(context)
    local runtime = context.runtime
    local ImGui = imgui
    local width = content_region_avail(ImGui)
    if type(width) ~= 'number' or width < 100 then
        width = 700
    end

    local label = 'Stopped'
    local color = { 0.55, 0.12, 0.12, 1 }
    local hover = { 0.75, 0.18, 0.18, 1 }
    if runtime.running and not runtime.paused then
        label = 'Running'
        color = { 0.2, 0.65, 0.22, 1 }
        hover = { 0.28, 0.78, 0.30, 1 }
    elseif runtime.paused then
        label = 'Paused'
        color = { 0.75, 0.58, 0.14, 1 }
        hover = { 0.90, 0.70, 0.22, 1 }
    end

    local pushed = 0
    if push_style_color(ImGui, 'Button', color[1], color[2], color[3], color[4]) then
        pushed = pushed + 1
    end
    if push_style_color(ImGui, 'ButtonHovered', hover[1], hover[2], hover[3], hover[4]) then
        pushed = pushed + 1
    end

    local clicked = button_sized(ImGui, label .. '##KAUIMainAction', math.max(120, width - 10), 36)
    if pushed > 0 then
        pop_style_color(ImGui, pushed)
    end

    tooltip(ImGui, runtime.paused and 'Resume the KAUI runtime loop.' or 'Pause the KAUI runtime loop.')

    if clicked and runtime.running then
        if runtime.paused then
            runtime:resume()
            set_status('Runtime resumed.')
            if context.logger then
                context.logger.info('Runtime resumed from UI.')
            end
        else
            runtime:pause()
            set_status('Runtime paused.')
            if context.logger then
                context.logger.info('Runtime paused from UI.')
            end
        end
    end
end

local function draw_target_config_bar(context)
    local ImGui = imgui
    local runtime = context.runtime
    local target_name = runtime.target and runtime.target.name or nil
    local target_hp = runtime.target and tonumber(runtime.target.pct_hp or 0) or 0
    local current_path = runtime.config and filename_only(runtime.config.path) or '-'
    local dirty_text, r, g, b, a = dirty_label(context)

    if target_name and target_name ~= '' then
        ImGui.Text(string.format('Target: %s HP: %d%%', target_name, target_hp))
    else
        ImGui.Text('Target: No target')
    end

    local width = content_region_avail(ImGui)
    if type(width) ~= 'number' or width < 100 then
        width = 700
    end
    progress_bar(ImGui, '##KAUITargetHP', target_hp / 100, string.format('%d%%', target_hp), math.max(120, width - 10), 18)

    ImGui.Text('Config: ' .. tostring(current_path))
    ImGui.SameLine()
    ImGui.TextColored(r, g, b, a, dirty_text)

    if runtime.config then
        ImGui.SameLine()
        ImGui.Text(string.format('(%s, %d sections, %d keys)', runtime.config.server_specific and 'server-specific' or 'character', #runtime.config.document.section_order, runtime.config.document:count_keys()))
    end
end

local function draw_header(context)
    local ImGui = imgui
    refresh_identity(context)

    ImGui.TextColored(0.2, 0.8, 1, 1, constants.DISPLAY_NAME)
    ImGui.SameLine()
    ImGui.Text('v' .. constants.VERSION)
    draw_status_line(context)

    ImGui.Text('Character: ' .. tostring(ui_state.character or '-'))
    ImGui.SameLine()
    ImGui.Text('Server: ' .. tostring(ui_state.server or '-'))

    ImGui.Text('INI file name:')
    ImGui.SameLine()
    local width = content_region_avail(ImGui)
    if type(width) == 'number' and width > 20 then
        ImGui.PushItemWidth(width - 10)
    else
        ImGui.PushItemWidth(500)
    end
    local new_path = ImGui.InputText('##KAUIPathInput', ui_state.path_input or '')
    ImGui.PopItemWidth()
    if new_path ~= nil then
        ui_state.path_input = new_path
    end

    draw_main_action(context)
    draw_target_config_bar(context)
end

local function draw_toolbar(context)
    local ImGui = imgui
    local dirty = any_dirty(context)

    if ImGui.Button('Detect') then
        detect_ini(context)
    end
    ImGui.SameLine()
    if ImGui.Button('Load') then
        load_selected_ini(context, 'UI')
    end
    ImGui.SameLine()

    local pushed = 0
    if dirty and push_style_color(ImGui, 'Button', 0.72, 0.55, 0.08, 1) then
        pushed = pushed + 1
    end
    if dirty and push_style_color(ImGui, 'ButtonHovered', 0.88, 0.68, 0.12, 1) then
        pushed = pushed + 1
    end
    if ImGui.Button(dirty and 'Save *' or 'Save') then
        save_ini(context)
    end
    if pushed > 0 then
        pop_style_color(ImGui, pushed)
    end

    ImGui.SameLine()
    if ImGui.Button('Reload') then
        reload_ini(context)
    end
    ImGui.SameLine()
    if ImGui.Button('Backup') then
        backup_ini(context)
    end

    if ui_state.last_error then
        ImGui.TextColored(1, 0, 0, 1, 'Error: ' .. tostring(ui_state.last_error))
    elseif context.runtime.config_error then
        ImGui.TextColored(1, 0.6, 0, 1, 'Warning: ' .. tostring(context.runtime.config_error))
    elseif ui_state.status and ui_state.status ~= '' then
        ImGui.TextColored(0.2, 1, 0.2, 1, 'Status: ' .. tostring(ui_state.status))
    end

    if structured_dirty(context) then
        ImGui.TextColored(1, 1, 0, 1, 'Config modified: click Save to write the INI file.')
    end
    if ui_state.raw_dirty then
        ImGui.TextColored(1, 1, 0, 1, 'Raw INI modified: click Save or Save raw.')
    end

    if ui_state.last_backup_path then
        ImGui.Text('Last backup: ' .. tostring(filename_only(ui_state.last_backup_path)))
    end

    ImGui.Separator()
end

local function draw_summary_tab(context)
    local ImGui = imgui
    local config_state = context.runtime.config

    ImGui.TextColored(0.2, 0.8, 1, 1, 'Home')
    ImGui.SameLine()
    local dirty_text, r, g, b, a = dirty_label(context)
    ImGui.TextColored(r, g, b, a, dirty_text)
    ImGui.Separator()

    if not config_state then
        ImGui.TextColored(1, 0.6, 0, 1, 'No INI loaded.')
        if context.runtime.config_error then
            ImGui.TextColored(1, 0, 0, 1, context.runtime.config_error)
        end
        text_wrapped(ImGui, 'Use Detect then Load, or enter an INI path. Missing files are created with the KissAssist schema.')
        return
    end

    local missing_conditions = list_config.missing_condition_refs(config_state.document)
    local table_flags = bor_flags(
        flag_value('ImGuiTableFlags', 'BordersInner'),
        flag_value('ImGuiTableFlags', 'RowBg'),
        flag_value('ImGuiTableFlags', 'SizingFixedFit')
    )

    if ImGui.BeginTable and ImGui.BeginTable('KAUIStatusCards', 2, table_flags) then
        ImGui.TableNextColumn()
        ImGui.Text('Type')
        ImGui.TableNextColumn()
        ImGui.Text(config_state.server_specific and 'server-specific' or 'character')
        ImGui.TableNextColumn()
        ImGui.Text('Sections')
        ImGui.TableNextColumn()
        ImGui.Text(tostring(#config_state.document.section_order))
        ImGui.TableNextColumn()
        ImGui.Text('Keys')
        ImGui.TableNextColumn()
        ImGui.Text(tostring(config_state.document:count_keys()))
        ImGui.TableNextColumn()
        ImGui.Text('Missing conditions')
        ImGui.TableNextColumn()
        if #missing_conditions > 0 then
            ImGui.TextColored(1, 0.6, 0, 1, tostring(#missing_conditions))
        else
            ImGui.TextColored(0.2, 1, 0.2, 1, '0')
        end
        ImGui.TableNextColumn()
        ImGui.Text('Unsaved')
        ImGui.TableNextColumn()
        ImGui.TextColored(r, g, b, a, dirty_text)
        ImGui.EndTable()
    else
        ImGui.Text('Type: ' .. (config_state.server_specific and 'server-specific' or 'character'))
        ImGui.Text(string.format('Sections: %d', #config_state.document.section_order))
        ImGui.Text(string.format('Keys: %d', config_state.document:count_keys()))
    end

    text_wrapped(ImGui, 'File: ' .. tostring(filename_only(config_state.path)))

    if #missing_conditions > 0 then
        ImGui.TextColored(1, 0.6, 0, 1, 'Missing condition references:')
        for _, item in ipairs(missing_conditions) do
            ImGui.Text(string.format('  [%s] %s -> %s', item.section, item.key, item.condition_ref))
        end
    end

    ImGui.Separator()
    if collapsing_header(ImGui, 'Document sections##KAUISectionSummaryHeader', true) then
        if ImGui.BeginChild('KAUISectionSummary', 0, 0, child_border_flag()) then
            for _, section in ipairs(config_state.document.section_order) do
                local section_data = config_state.document.sections[section]
                local count = 0
                if section_data then
                    for _ in pairs(section_data.values) do
                        count = count + 1
                    end
                end
                ImGui.Text(string.format('[%s] %d key(s)', section, count))
            end
        end
        ImGui.EndChild()
    end
end

local function is_bool_field(section, key, definition)
    if definition and definition.type == 'bool' then
        return true
    end
    return BOOLEAN_FIELDS[section] and BOOLEAN_FIELDS[section][key] == true
end

local function is_truthy(value)
    local lowered = tostring(value or ''):lower()
    return not (lowered == '' or lowered == '0' or lowered == 'false' or lowered == 'off' or lowered == 'no' or lowered == 'null')
end

local function is_managed_list_key(section, key)
    key = tostring(key or '')
    for _, definition in pairs(list_config.definitions) do
        if definition.section == section and key:match('^' .. definition.prefix .. '%d+$') then
            return true
        end
    end
    return false
end

local function is_help_key(key)
    key = tostring(key or '')
    return key == 'Help' or key:match('Help$') ~= nil
end

local function section_help_entries(config_state, section)
    local schema = config_state.schema or config_manager.schema
    local fields = schema.fields and schema.fields[section] or {}
    local doc = config_state.document
    local section_data = doc.sections[section]
    local result = {}
    local seen = {}

    local function append(key)
        if seen[key] or not is_help_key(key) then
            return
        end

        local value = doc:get(section, key)
        if value == nil and fields[key] then
            value = fields[key].default
        end
        value = tostring(value or '')
        if value == '' then
            return
        end

        table.insert(result, {
            key = key,
            value = value,
        })
        seen[key] = true
    end

    for _, key in ipairs(FIELD_ORDERS[section] or {}) do
        append(key)
    end
    for _, key in ipairs(schema.key_order and schema.key_order[section] or {}) do
        append(key)
    end
    if section_data then
        for _, key in ipairs(section_data.key_order or {}) do
            append(key)
        end
        for key in pairs(section_data.values) do
            append(key)
        end
    end

    return result
end

local function draw_section_help_mouseover(ImGui, entries)
    if not entries or #entries == 0 then
        return
    end

    ImGui.TextColored(0.35, 0.75, 1, 1, 'Help (?)')
    if ImGui.IsItemHovered and ImGui.IsItemHovered() then
        if ImGui.BeginTooltip and ImGui.EndTooltip then
            ImGui.BeginTooltip()
            ImGui.Text('Section help')
            if ImGui.Separator then
                ImGui.Separator()
            end
            for _, entry in ipairs(entries) do
                ImGui.TextColored(0.35, 0.75, 1, 1, entry.key)
                text_wrapped(ImGui, entry.value)
            end
            ImGui.EndTooltip()
        elseif ImGui.SetTooltip then
            local lines = { 'Section help' }
            for _, entry in ipairs(entries) do
                table.insert(lines, entry.key .. ': ' .. entry.value)
            end
            ImGui.SetTooltip(table.concat(lines, '\n'))
        end
    end
    ImGui.SameLine()
    ImGui.TextColored(0.65, 0.65, 0.65, 1, 'Hover Help for KissAssist format notes.')
end

local function ordered_field_keys(config_state, section)
    local schema = config_state.schema or config_manager.schema
    local fields = schema.fields and schema.fields[section] or {}
    local section_data = config_state.document.sections[section]
    local result = {}
    local seen = {}

    for _, key in ipairs(FIELD_ORDERS[section] or {}) do
        if fields[key] and not is_help_key(key) then
            table.insert(result, key)
            seen[key] = true
        end
    end

    for _, key in ipairs(schema.key_order and schema.key_order[section] or {}) do
        if not seen[key] and fields[key] and not is_help_key(key) then
            table.insert(result, key)
            seen[key] = true
        end
    end

    if section_data then
        for _, key in ipairs(section_data.key_order or {}) do
            if not seen[key] and not is_help_key(key) and not is_managed_list_key(section, key) then
                table.insert(result, key)
                seen[key] = true
            end
        end

        local extras = {}
        for key in pairs(section_data.values) do
            if not seen[key] and not is_help_key(key) and not is_managed_list_key(section, key) then
                table.insert(extras, key)
            end
        end
        table.sort(extras)
        for _, key in ipairs(extras) do
            table.insert(result, key)
        end
    end

    return result
end

local function set_doc_value(context, section, key, value, message)
    local config_state = context.runtime.config
    local doc = config_state and config_state.document or nil
    if not doc then
        return
    end

    local old_value = doc:get(section, key, '')
    if tostring(old_value) == tostring(value) then
        return
    end

    doc:set(section, key, value)
    mark_config_changed(context, message or string.format('[%s] %s updated.', section, key), false)
end

local function draw_field_editor(context, section, key, definition)
    local ImGui = imgui
    local config_state = context.runtime.config
    local doc = config_state.document
    local value = doc:get(section, key)
    if value == nil and definition then
        value = definition.default
    end
    value = tostring(value or '')

    if is_bool_field(section, key, definition) then
        local current = is_truthy(value)
        local new_value, changed = ImGui.Checkbox('##' .. section .. '_' .. key, current)
        if changed == nil then
            changed = new_value ~= nil and new_value ~= current
        end
        if changed then
            set_doc_value(context, section, key, new_value and '1' or '0')
        end
        return
    end

    if definition and definition.type == 'int' then
        local current = tonumber(value) or 0
        local new_value, changed = ImGui.InputInt('##' .. section .. '_' .. key, current, 1, 10, flag_value('ImGuiInputTextFlags', 'None') or 0)
        if changed == nil then
            changed = tonumber(new_value) ~= current
        end
        if changed and new_value ~= nil then
            set_doc_value(context, section, key, tostring(math.floor(tonumber(new_value) or 0)))
        end
        return
    end

    local width = content_region_avail(ImGui)
    if type(width) == 'number' and width > 80 then
        ImGui.PushItemWidth(math.max(120, width - 20))
    end
    local new_value, changed = ImGui.InputText('##' .. section .. '_' .. key, value)
    if type(width) == 'number' and width > 80 then
        ImGui.PopItemWidth()
    end
    if changed == nil then
        changed = new_value ~= nil and tostring(new_value) ~= value
    end
    if changed and new_value ~= nil then
        set_doc_value(context, section, key, tostring(new_value))
    end
end

local function draw_section_fields(context, section)
    local ImGui = imgui
    local config_state = context.runtime.config
    local schema = config_state.schema or config_manager.schema
    local fields = schema.fields and schema.fields[section] or {}
    local doc = config_state.document

    doc:ensure_section(section)

    draw_section_help_mouseover(ImGui, section_help_entries(config_state, section))

    local keys = ordered_field_keys(config_state, section)
    if #keys == 0 then
        ImGui.TextColored(1, 0.6, 0, 1, 'No editable keys found in this section.')
        return
    end

    local table_flags = bor_flags(
        flag_value('ImGuiTableFlags', 'BordersInner'),
        flag_value('ImGuiTableFlags', 'RowBg'),
        flag_value('ImGuiTableFlags', 'Resizable')
    )

    if ImGui.BeginTable and ImGui.BeginTable('KAUIFields_' .. section, 3, table_flags) then
        if ImGui.TableSetupColumn then
            ImGui.TableSetupColumn('Key')
            ImGui.TableSetupColumn('Value')
            ImGui.TableSetupColumn('Help')
            if ImGui.TableHeadersRow then
                ImGui.TableHeadersRow()
            end
        end

        for _, key in ipairs(keys) do
            local definition = fields[key] or { type = 'string', default = '', description = 'Custom INI key.' }
            ImGui.TableNextColumn()
            ImGui.Text(key)
            tooltip(ImGui, definition.description)
            ImGui.TableNextColumn()
            draw_field_editor(context, section, key, definition)
            ImGui.TableNextColumn()
            if definition.default ~= nil then
                ImGui.TextColored(0.65, 0.65, 0.65, 1, 'Default: ' .. tostring(definition.default))
            end
            if definition.description and definition.description ~= '' then
                text_wrapped(ImGui, definition.description)
            end
        end

        ImGui.EndTable()
    else
        for _, key in ipairs(keys) do
            local definition = fields[key] or { type = 'string', default = '', description = 'Custom INI key.' }
            ImGui.Text(key)
            ImGui.SameLine()
            draw_field_editor(context, section, key, definition)
        end
    end
end

local function next_condition_id(doc)
    local size = math.max(list_config.conditions_size(doc), 1)
    for index = 1, size do
        if not list_config.condition_exists(doc, index) then
            return index
        end
    end
    return size + 1
end

local function create_condition(context, requested_id)
    local doc = context.runtime.config and context.runtime.config.document or nil
    if not doc then
        return nil
    end

    local expression = trim(ui_state.condition_expression or '')
    if expression == '' then
        expression = 'TRUE'
    end

    local index = tonumber(requested_id) or next_condition_id(doc)
    list_config.set_condition(doc, index, expression)
    doc:set('KConditions', 'ConOn', '1')
    mark_config_changed(context, string.format('Condition Cond%d created.', index), true)
    return index
end

local function condition_preview(doc, condition_id)
    condition_id = tonumber(condition_id)
    if not condition_id or condition_id <= 0 then
        return 'None'
    end

    local value = doc:get('KConditions', 'Cond' .. tostring(condition_id))
    if value == nil or tostring(value) == '' then
        return string.format('Cond%d (missing)', condition_id)
    end

    return string.format('Cond%d: %s', condition_id, truncate(value, 48))
end

local function condition_options(doc, current_id)
    local options = {
        { id = 0, label = 'None' },
    }
    local seen = { [0] = true }

    for _, condition in ipairs(list_config.read_conditions(doc)) do
        local id = tonumber(condition.index)
        if id then
            table.insert(options, {
                id = id,
                label = condition_preview(doc, id),
            })
            seen[id] = true
        end
    end

    current_id = tonumber(current_id)
    if current_id and current_id > 0 and not seen[current_id] then
        table.insert(options, {
            id = current_id,
            label = condition_preview(doc, current_id),
        })
    end

    table.sort(options, function(a, b)
        return a.id < b.id
    end)

    return options
end

local function draw_condition_combo(context, doc, combo_id, current_id, on_change)
    local ImGui = imgui
    current_id = tonumber(current_id) or 0
    local preview = condition_preview(doc, current_id)

    if ImGui.BeginCombo then
        if ImGui.BeginCombo(combo_id, preview) then
            for _, option in ipairs(condition_options(doc, current_id)) do
                local selected = option.id == current_id
                if selectable_clicked(ImGui, option.label .. '##' .. combo_id .. '_' .. tostring(option.id), selected) then
                    on_change(option.id > 0 and option.id or nil)
                end
                if selected and ImGui.SetItemDefaultFocus then
                    ImGui.SetItemDefaultFocus()
                end
            end
            ImGui.EndCombo()
        end
    else
        local new_id, changed = ImGui.InputInt(combo_id, current_id, 1, 10, flag_value('ImGuiInputTextFlags', 'None') or 0)
        if changed == nil then
            changed = tonumber(new_id) ~= current_id
        end
        if changed then
            new_id = tonumber(new_id) or 0
            on_change(new_id > 0 and new_id or nil)
        end
    end
end

local function update_list_entry(context, list_name, row_index, updates)
    local doc = context.runtime.config and context.runtime.config.document or nil
    if not doc then
        return false
    end

    local entries = list_config.read(doc, list_name)
    local entry = entries[row_index]
    if not entry then
        return false
    end

    if updates.value ~= nil then
        entry.value = tostring(updates.value)
    end
    if updates.condition_id ~= nil or updates.clear_condition then
        entry.condition_id = updates.condition_id
    end
    entry.raw = nil

    list_config.write(doc, list_name, entries)
    mark_config_changed(context, string.format('%s entry %d updated.', list_name, row_index), false)
    return true
end

local function draw_condition_attach_tools(context, doc, id, current_id, on_change)
    local ImGui = imgui

    draw_condition_combo(context, doc, '##cond_' .. id, current_id, on_change)
    ImGui.SameLine()
    if small_button(ImGui, 'New##new_cond_' .. id) then
        local new_id = create_condition(context)
        if new_id then
            on_change(new_id)
        end
    end
    tooltip(ImGui, 'Create a new condition and attach it here.')

    current_id = tonumber(current_id)
    if current_id and current_id > 0 and not list_config.condition_exists(doc, current_id) then
        ImGui.SameLine()
        if small_button(ImGui, 'Create##create_missing_cond_' .. id) then
            create_condition(context, current_id)
        end
        tooltip(ImGui, 'Create the missing referenced condition.')
    end
end

local function draw_list_editor(context, list_info)
    local ImGui = imgui
    local config_state = context.runtime.config
    local doc = config_state.document
    local list_name = list_info.name
    local entries = list_config.read(doc, list_name)
    local size = list_config.size(doc, list_name)

    if not collapsing_header(ImGui, list_info.title .. '##list_' .. list_name, true) then
        return
    end

    text_wrapped(ImGui, list_info.help or '')
    ImGui.Text(string.format('Entries: %d  Size key: %d', #entries, size))

    ui_state.list_new_values[list_name] = ui_state.list_new_values[list_name] or ''
    ui_state.list_new_conditions[list_name] = ui_state.list_new_conditions[list_name] or 0

    local width = content_region_avail(ImGui)
    local input_width = math.max(220, math.floor((width > 0 and width or 700) * 0.46))

    ImGui.Text('New entry')
    ImGui.SameLine()
    ImGui.PushItemWidth(input_width)
    local new_value, changed = ImGui.InputText('##new_entry_' .. list_name, ui_state.list_new_values[list_name])
    ImGui.PopItemWidth()
    if changed == nil then
        changed = new_value ~= nil and tostring(new_value) ~= ui_state.list_new_values[list_name]
    end
    if changed and new_value ~= nil then
        ui_state.list_new_values[list_name] = tostring(new_value)
    end

    ImGui.SameLine()
    ImGui.PushItemWidth(190)
    draw_condition_combo(context, doc, '##new_cond_combo_' .. list_name, ui_state.list_new_conditions[list_name], function(condition_id)
        ui_state.list_new_conditions[list_name] = condition_id or 0
    end)
    ImGui.PopItemWidth()

    ImGui.SameLine()
    if small_button(ImGui, 'New condition##new_list_cond_' .. list_name) then
        local new_id = create_condition(context)
        if new_id then
            ui_state.list_new_conditions[list_name] = new_id
        end
    end

    ImGui.SameLine()
    if small_button(ImGui, 'Add##add_' .. list_name) then
        local value = trim(ui_state.list_new_values[list_name])
        if value == '' then
            value = 'NULL'
        end
        local condition_id = tonumber(ui_state.list_new_conditions[list_name])
        local index = list_config.add(doc, list_name, value, condition_id and condition_id > 0 and condition_id or nil)
        ui_state.list_new_values[list_name] = ''
        mark_config_changed(context, string.format('%s entry added at position %d.', list_name, index), true)
    end

    ImGui.SameLine()
    if small_button(ImGui, 'Compact##compact_' .. list_name) then
        local before, after = list_config.compact(doc, list_name)
        mark_config_changed(context, string.format('%s compacted: %d -> %d entries.', list_name, before, after), true)
    end

    local table_flags = bor_flags(
        flag_value('ImGuiTableFlags', 'Borders'),
        flag_value('ImGuiTableFlags', 'RowBg'),
        flag_value('ImGuiTableFlags', 'Resizable')
    )

    if #entries == 0 then
        ImGui.TextColored(1, 0.6, 0, 1, 'No entries yet. Add one above.')
        return
    end

    if ImGui.BeginTable and ImGui.BeginTable('KAUIList_' .. list_name, 4, table_flags) then
        if ImGui.TableSetupColumn then
            ImGui.TableSetupColumn('#')
            ImGui.TableSetupColumn('Entry')
            ImGui.TableSetupColumn('Condition')
            ImGui.TableSetupColumn('Actions')
            if ImGui.TableHeadersRow then
                ImGui.TableHeadersRow()
            end
        end

        for row_index, entry in ipairs(entries) do
            ImGui.TableNextColumn()
            ImGui.Text(tostring(row_index))
            if entry.index ~= row_index then
                tooltip(ImGui, string.format('Original INI key: %s', entry.key or '-'))
            end

            ImGui.TableNextColumn()
            ImGui.PushItemWidth(-1)
            local edited_value, value_changed = ImGui.InputText('##' .. list_name .. '_value_' .. tostring(row_index), entry.value or '')
            ImGui.PopItemWidth()
            if value_changed == nil then
                value_changed = edited_value ~= nil and tostring(edited_value) ~= tostring(entry.value or '')
            end
            if value_changed and edited_value ~= nil then
                update_list_entry(context, list_name, row_index, { value = edited_value })
            end

            ImGui.TableNextColumn()
            ImGui.PushItemWidth(190)
            draw_condition_attach_tools(context, doc, list_name .. '_' .. tostring(row_index), entry.condition_id, function(condition_id)
                update_list_entry(context, list_name, row_index, {
                    condition_id = condition_id,
                    clear_condition = condition_id == nil,
                })
            end)
            ImGui.PopItemWidth()

            ImGui.TableNextColumn()
            if row_index > 1 then
                if small_button(ImGui, 'Up##' .. list_name .. '_' .. tostring(row_index)) then
                    if list_config.move(doc, list_name, row_index, row_index - 1) then
                        mark_config_changed(context, string.format('%s entry %d moved up.', list_name, row_index), true)
                    end
                end
                ImGui.SameLine()
            end
            if row_index < #entries then
                if small_button(ImGui, 'Down##' .. list_name .. '_' .. tostring(row_index)) then
                    if list_config.move(doc, list_name, row_index, row_index + 1) then
                        mark_config_changed(context, string.format('%s entry %d moved down.', list_name, row_index), true)
                    end
                end
                ImGui.SameLine()
            end
            if small_button(ImGui, 'Delete##' .. list_name .. '_' .. tostring(row_index)) then
                if list_config.remove(doc, list_name, row_index) then
                    mark_config_changed(context, string.format('%s entry %d deleted.', list_name, row_index), true)
                end
            end
        end

        ImGui.EndTable()
    else
        for row_index, entry in ipairs(entries) do
            ImGui.Text(string.format('%d. %s', row_index, entry.raw or ''))
        end
    end
end

local function draw_conditions_panel(context, default_open)
    local ImGui = imgui
    local config_state = context.runtime.config
    if not config_state then
        ImGui.TextColored(1, 0.6, 0, 1, 'No INI loaded.')
        return
    end

    local doc = config_state.document
    doc:ensure_section('KConditions')

    if collapsing_header(ImGui, 'Condition settings##condition_settings', default_open) then
        draw_section_fields(context, 'KConditions')
    end

    if not collapsing_header(ImGui, 'Condition list##condition_list', true) then
        return
    end

    ui_state.condition_expression = ui_state.condition_expression or 'TRUE'
    ImGui.Text('New condition expression')
    ImGui.SameLine()
    ImGui.PushItemWidth(math.max(220, (content_region_avail(ImGui) or 700) - 180))
    local expression, expression_changed = ImGui.InputText('##new_condition_expression', ui_state.condition_expression)
    ImGui.PopItemWidth()
    if expression_changed == nil then
        expression_changed = expression ~= nil and tostring(expression) ~= ui_state.condition_expression
    end
    if expression_changed and expression ~= nil then
        ui_state.condition_expression = tostring(expression)
    end

    ImGui.SameLine()
    if small_button(ImGui, 'Add condition##add_condition') then
        create_condition(context)
    end

    local missing = list_config.missing_condition_refs(doc)
    if #missing > 0 then
        ImGui.TextColored(1, 0.6, 0, 1, 'Missing references:')
        for _, item in ipairs(missing) do
            ImGui.Text(string.format('[%s] %s -> %s', item.section, item.key, item.condition_ref))
            ImGui.SameLine()
            if small_button(ImGui, 'Create##missing_' .. item.section .. '_' .. item.key) then
                create_condition(context, item.condition_id)
            end
        end
    end

    local conditions = list_config.read_conditions(doc)
    if #conditions == 0 then
        ImGui.TextColored(1, 0.6, 0, 1, 'No conditions defined yet.')
        return
    end

    local table_flags = bor_flags(
        flag_value('ImGuiTableFlags', 'Borders'),
        flag_value('ImGuiTableFlags', 'RowBg'),
        flag_value('ImGuiTableFlags', 'Resizable')
    )

    if ImGui.BeginTable and ImGui.BeginTable('KAUIConditionsTable', 3, table_flags) then
        if ImGui.TableSetupColumn then
            ImGui.TableSetupColumn('Condition')
            ImGui.TableSetupColumn('Expression')
            ImGui.TableSetupColumn('Notes')
            if ImGui.TableHeadersRow then
                ImGui.TableHeadersRow()
            end
        end

        for _, condition in ipairs(conditions) do
            local id = tonumber(condition.index) or 0
            ImGui.TableNextColumn()
            ImGui.Text('Cond' .. tostring(id))
            ImGui.TableNextColumn()
            ImGui.PushItemWidth(-1)
            local new_value, changed = ImGui.InputText('##condition_' .. tostring(id), condition.raw or '')
            ImGui.PopItemWidth()
            if changed == nil then
                changed = new_value ~= nil and tostring(new_value) ~= tostring(condition.raw or '')
            end
            if changed and new_value ~= nil then
                list_config.set_condition(doc, id, tostring(new_value))
                mark_config_changed(context, string.format('Cond%d updated.', id), false)
            end
            ImGui.TableNextColumn()
            ImGui.Text('Referenced as |cond' .. tostring(id))
        end

        ImGui.EndTable()
    else
        for _, condition in ipairs(conditions) do
            ImGui.Text(string.format('%s=%s', condition.key, condition.raw))
        end
    end
end

local function draw_editor_section_tab(context, tab)
    local ImGui = imgui
    local config_state = context.runtime.config

    ImGui.TextColored(0.2, 0.8, 1, 1, tab.label)
    if tab.description then
        text_wrapped(ImGui, tab.description)
    end
    ImGui.Separator()

    if not config_state then
        ImGui.TextColored(1, 0.6, 0, 1, 'No INI loaded.')
        text_wrapped(ImGui, 'Load or create a KissAssist INI before editing sections.')
        return
    end

    if ui_state.raw_dirty then
        ImGui.TextColored(1, 0.6, 0, 1, 'Raw INI edits are pending.')
        text_wrapped(ImGui, 'Save raw changes or reparse the raw INI before using structured editors. This prevents accidental overwrites.')
        return
    end

    for index, panel in ipairs(tab.panels or {}) do
        if collapsing_header(ImGui, panel.title .. '##settings_' .. panel.section, index == 1) then
            draw_section_fields(context, panel.section)
        end
    end

    if tab.list then
        draw_list_editor(context, tab.list)
        draw_conditions_panel(context, false)
    end
end

local function draw_raw_tab(context)
    local ImGui = imgui

    if ImGui.Button('Refresh raw') then
        local path, path_err = normalize_path(context, ui_state.path_input)
        if path then
            read_raw_into_state(context, path, false)
        else
            set_error(context.logger, path_err)
        end
    end
    ImGui.SameLine()
    if ImGui.Button('Save raw') then
        save_raw_buffer(context)
    end
    ImGui.SameLine()
    if ImGui.Button('Reparse raw') then
        local path, path_err = normalize_path(context, ui_state.path_input)
        if path then
            local config_state, created, err = config_manager.load_or_create(context.mq, context.logger, { path = path })
            if config_state then
                apply_config_state(context, config_state, created, 'parser')
            else
                set_error(context.logger, err or 'Unable to reparse raw INI.')
            end
        else
            set_error(context.logger, path_err)
        end
    end

    if structured_dirty(context) and not ui_state.raw_dirty then
        ImGui.TextColored(1, 0.6, 0, 1, 'Structured editor changes are pending.')
        text_wrapped(ImGui, 'Save or Reload before raw editing. Raw editing is locked to prevent overwriting unsaved structured changes.')
        return
    end

    local x, y = content_region_avail(ImGui)
    if type(x) ~= 'number' or x < 100 then
        x = 700
    end
    if type(y) ~= 'number' or y < 120 then
        y = 350
    end

    local before = ui_state.raw_buffer or ''
    local after, changed = ImGui.InputTextMultiline('##KAUIRawINI', before, x - 10, y - 10)
    if changed == nil then
        changed = after ~= nil and after ~= before
    end
    if changed and after ~= nil then
        ui_state.raw_buffer = after
        ui_state.raw_dirty = true
        ui_state.raw_loaded = true
    end
end

local function draw_main_tabs(context)
    local ImGui = imgui
    local flags = flag_value('ImGuiTabBarFlags', 'Reorderable') or 0

    if ImGui.BeginTabBar and ImGui.BeginTabBar('KAUIMainTabs', flags) then
        if ImGui.BeginTabItem('Home') then
            draw_summary_tab(context)
            ImGui.EndTabItem()
        end

        for _, tab in ipairs(EDITOR_TABS) do
            if ImGui.BeginTabItem(tab.label) then
                draw_editor_section_tab(context, tab)
                ImGui.EndTabItem()
            end
        end

        if ImGui.BeginTabItem('Conditions') then
            draw_conditions_panel(context, true)
            ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem('Raw INI') then
            draw_raw_tab(context)
            ImGui.EndTabItem()
        end

        ImGui.EndTabBar()
    else
        draw_summary_tab(context)
        ImGui.Separator()
        for _, tab in ipairs(EDITOR_TABS) do
            if collapsing_header(ImGui, tab.label .. '##fallback_' .. tab.id, false) then
                draw_editor_section_tab(context, tab)
            end
        end
        if collapsing_header(ImGui, 'Conditions##fallback_conditions', false) then
            draw_conditions_panel(context, true)
        end
        if collapsing_header(ImGui, 'Raw INI##fallback_raw', false) then
            draw_raw_tab(context)
        end
    end
end

local function render(context)
    if not ui_state or not imgui then
        return
    end

    if not ui_state.open then
        return
    end

    local ImGui = imgui
    safe_set_next_window_size(920, 680)
    local window_flags = flag_value('ImGuiWindowFlags', 'NoFocusOnAppearing') or 0
    local open, should_draw
    if window_flags ~= 0 then
        open, should_draw = ImGui.Begin(WINDOW_TITLE, ui_state.open, window_flags)
    else
        open, should_draw = ImGui.Begin(WINDOW_TITLE, ui_state.open)
    end
    ui_state.open = open
    ui_state.should_draw = should_draw

    if should_draw then
        if ui_state.initial_run then
            if ImGui.GetWindowHeight and ImGui.GetWindowWidth and ImGui.SetWindowSize then
                local height = ImGui.GetWindowHeight()
                local width = ImGui.GetWindowWidth()
                if (height == 38 and width == 32) or (height == 500 and width == 500) then
                    ImGui.SetWindowSize(920, 680)
                end
            end
            ui_state.initial_run = false
        end

        draw_header(context)
        draw_toolbar(context)
        draw_main_tabs(context)
    end

    ImGui.End()
end

function ui.show()
    if ui_state then
        ui_state.open = true
        return true
    end
    return false
end

function ui.hide()
    if ui_state then
        ui_state.open = false
        return true
    end
    return false
end

function ui.toggle()
    if ui_state then
        ui_state.open = not ui_state.open
        return ui_state.open
    end
    return false
end

function ui.is_available()
    return ui_state ~= nil and ui_state.initialized == true
end

function ui.start(context)
    if ui_state and ui_state.initialized then
        return true
    end

    if not context or not context.runtime or not context.runtime.mq then
        if context and context.logger then
            context.logger.warn('ImGui UI not initialized: MacroQuest is unavailable.')
        end
        return false
    end

    local ok_imgui, imgui_module = pcall(require, 'ImGui')
    imgui = rawget(_G, 'ImGui') or imgui_module
    if not ok_imgui or not imgui then
        if context.logger then
            context.logger.warn('ImGui UI not initialized: ImGui module is unavailable.')
        end
        imgui = nil
        return false
    end

    local mq = context.runtime.mq
    if not mq.imgui or not mq.imgui.init then
        if context.logger then
            context.logger.warn('ImGui UI not initialized: mq.imgui is unavailable.')
        end
        return false
    end

    ui_state = {
        open = true,
        should_draw = true,
        initial_run = true,
        initialized = true,
        active_path = context.runtime.config and context.runtime.config.path or nil,
        path_input = context.runtime.config and filename_only(context.runtime.config.path) or '',
        detected_path = nil,
        detected_server_specific = false,
        detect_error = nil,
        character = nil,
        server = nil,
        raw_buffer = '',
        raw_loaded = false,
        raw_dirty = false,
        last_raw_path = nil,
        last_error = context.runtime.config_error,
        status = 'Ready.',
        last_backup_path = nil,
        list_new_values = {},
        list_new_conditions = {},
        condition_expression = 'TRUE',
    }

    refresh_identity(context)
    refresh_detected_path(context)

    if context.runtime.config and context.runtime.config.path then
        read_raw_into_state(context, context.runtime.config.path, true)
    elseif ui_state.detected_path then
        ui_state.active_path = ui_state.detected_path
        ui_state.path_input = filename_only(ui_state.detected_path)
    end

    context.runtime.ui = {
        show = ui.show,
        hide = ui.hide,
        toggle = ui.toggle,
        is_available = ui.is_available,
    }

    local ok, err = pcall(mq.imgui.init, UI_ID, function()
        render(context)
    end)

    if not ok then
        context.runtime.ui = nil
        ui_state.initialized = false
        set_error(context.logger, 'ImGui initialization failed: ' .. tostring(err))
        return false
    end

    if context.logger then
        context.logger.info('ImGui UI initialized: /kaui show | /kaui hide')
    end

    return true
end

function ui.stop(context)
    local mq = context and context.runtime and context.runtime.mq or nil
    if mq and mq.imgui and mq.imgui.destroy then
        pcall(mq.imgui.destroy, UI_ID)
    end

    if context and context.runtime then
        context.runtime.ui = nil
    end

    if ui_state then
        ui_state.initialized = false
    end
end

function ui.create_module()
    return {
        name = 'ui_imgui',
        enabled = true,
        onInit = function(context)
            ui.start(context)
        end,
        onShutdown = function(context)
            ui.stop(context)
        end,
    }
end

return ui
