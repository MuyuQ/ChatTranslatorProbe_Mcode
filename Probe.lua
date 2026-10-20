local P = McodeChatProbe
local unpack = unpack
P.state = P.NewState()
P.adapters = {}

local originFields = { "origins", "originKeys", "originSeq", "lineTranslated",
    "lineOriginal", "lineFrame", "lineRegion", "lineIsOriginal" }
function P.ResetState()
    -- Settings invalidate processing decisions, but existing chat links still
    -- refer to their original lines. Keep their bounded store and ID sequence.
    P.FlushRecords(P.state,P.db)
    local previous = P.state
    local state = P.NewState()
    if previous then
        for _, key in ipairs(originFields) do state[key] = previous[key] end
    end
    P.state = state
end

function P.Initialize()
    local stored = McodeChatProbeDB
    if type(stored) == "table" and ((tonumber(stored.assistantSchema) or 0) > 1
        or (tonumber(stored.paletteVersion) or 0) > 3) then
        P.db = nil
        if not P.storageError and DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff88ddff聊天助手：|r存档来自更高版本，已保留原数据；请安装对应版本。聊天辅助已暂停。")
        end
        P.storageError = true
        return
    end
    P.storageError = nil
    P.FlushRecords(P.state,P.db)
    if type(McodeChatProbeDB) ~= "table" then McodeChatProbeDB = {} end
    local db = McodeChatProbeDB
    if type(db.labels) ~= "table" then db.labels = {} end
    if type(db.translate) ~= "table" then db.translate = {} end
    if type(db.dedup) ~= "table" then db.dedup = { CHANNEL = true } end
    if type(db.channelDedup) ~= "table" then db.channelDedup = {} end
    if (tonumber(db.assistantSchema) or 0)<1 then
        if db.dedup.YELL == nil then db.dedup.YELL=true end
        db.assistantSchema=1
    end
    if type(db.dedupEnabled)~="boolean" then db.dedupEnabled=true end
    if type(db.crossPublicDedup)~="boolean" then db.crossPublicDedup=true end
    if type(db.hideGuildRecruitment)~="boolean" then db.hideGuildRecruitment=false end
    db.dedupSeconds=P.DedupSeconds(db)
    -- Dedup groups were removed in 0.17.0; scrub their stored fields.
    db.groupedDedup,db.dedupGroups,db.dedupGroupSeq=nil,nil,nil
    if type(db.ads)~="table" then db.ads={} end
    if db.adsMerged~=true then
        -- 0.15.8: the four ad kinds share one switch. An old save with any
        -- kind enabled gets all four, so "ads are ads" holds from the upgrade on.
        if db.ads.gold==true or db.ads.account==true or db.ads.leveling==true or db.ads.boost==true then
            db.ads.gold,db.ads.account,db.ads.leveling,db.ads.boost=true,true,true,true
        end
        db.adsMerged=true
    end
    if db.keywordMerged~=true then
        -- 0.16.0: ads and guild recruitment share one keyword switch; an old
        -- save with either enabled gets both.
        if db.ads.gold==true or db.hideGuildRecruitment==true then
            db.ads.gold,db.ads.account,db.ads.leveling,db.ads.boost=true,true,true,true
            db.hideGuildRecruitment=true
        end
        db.keywordMerged=true
    end
    if type(db.filterChannels)~="table" then db.filterChannels={CHANNEL=true,YELL=true} end
    if type(db.channelFilter)~="table" then db.channelFilter={} end
    for _,key in ipairs({"blockWords","whitelistPlayers","whitelistText"}) do
        if type(db[key])~="table" then db[key]={} end
    end
    if type(db.captureEnabled)~="boolean" then db.captureEnabled=true end
    if type(db.records)~="table" then db.records={} end
    for _,key in ipairs({"missed","blocked"}) do
        P.ValidateRecords(db, key)
        local limit=key=="missed" and 1000 or 100
        while #db.records[key]>limit do table.remove(db.records[key],1) end
    end
    db.inlineReplace = true -- option removed in 0.16.1; demo passes its own db with false
    if type(db.enabled) ~= "boolean" then db.enabled = false end
    if type(db.filterEnabled) ~= "boolean" then db.filterEnabled = true end
    if db.display ~= "mixed" and db.display ~= "annotate" and db.display ~= "terms" then db.display = "mixed" end
    if type(db.hideCommon) ~= "boolean" then db.hideCommon = true end
    if type(db.colorByCategory) ~= "boolean" then db.colorByCategory = true end
    if (tonumber(db.paletteVersion) or 0) < 3 then db.paletteVersion = 3 end
    if type(db.colors) ~= "table" then db.colors = {} end
    for category in pairs(P.defaultColors) do db.colors[category]=P.ColorHex(db,category) end
    P.db = db
end

local function printLocal(text)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff88ddff聊天助手：|r" .. text) end
end

local MODE_CYCLE = { mixed = "annotate", annotate = "terms", terms = "mixed" }
local MODE_NAMES = { mixed = "替换原文", annotate = "注释保留", terms = "术语列表" }

-- Intervals are picked from presets, never typed. A saved value outside the
-- list still displays; the first click snaps into the list.
local UNIFIED_SECONDS = { 10, 30, 60, 120, 180, 240, 300 }
local GROUP_SECONDS = { 10, 30, 60, 120, 300, 600, 1800, 3600 }
local function cycleSeconds(current, presets)
    for index, value in ipairs(presets) do
        if value == current then return presets[index % #presets + 1] end
    end
    return presets[1]
end

function P.RefreshOptions()
    if not P.options or not P.db then return end
    P.options.enabled:SetChecked(P.db.enabled)
    if P.options.modeButton then
        local modeButton = P.options.modeButton
        modeButton:SetText("显示方式：" .. (MODE_NAMES[P.db.display] or "替换原文") .. "（点击切换）")
        -- CJK text runs wider than the built-in font metrics assume.
        if modeButton.GetTextWidth then
            modeButton:SetWidth(math.max(modeButton:GetTextWidth() + 32, 210))
        end
    end
    if P.options.colored then P.options.colored:SetChecked(P.db.colorByCategory) end
    for _,control in ipairs(P.options.extraChecks or {}) do control:SetChecked(control.get()) end
    if P.options.recordSummary then
        P.options.recordSummary:SetText("漏译样本 "..#P.db.records.missed.." / 1000；屏蔽样本 "..#P.db.records.blocked.." / 100"
            .. (P.db.records.invalid and "；已隔离异常记录 "..#P.db.records.invalid or ""))
    end
    if P.options.unifiedSeconds then
        P.options.unifiedSeconds:SetText("统一间隔：" .. tostring(P.db.dedupSeconds) .. " 秒（点击切换）")
    end
    for category,button in pairs(P.options.colorButtons or {}) do
        button:SetText("|cff"..P.ColorHex(P.db,category)..button.caption.."|r")
    end
    if P.options.preview then
        local db={display="mixed",labels=P.db.labels,colors=P.db.colors,colorByCategory=P.db.colorByCategory}
        local sample="LFM ICC need disc tank"
        local base="|cff"..P.ColorHex(db,"other")
        -- Drop the engine's "→ …：" prefix so the example reads one line per mode.
        local function plain(value) return (value:gsub("^→ [^：]+：","")) end
        local mixed=plain(P.Translate(sample,db) or sample)
        db.display="annotate"
        local annotated=plain(P.Translate(sample,db) or sample)
        local preview=P.options.preview
        preview:SetText(base.."替换原文："..mixed.."|r\n"..base.."注释保留："..annotated.."|r")
        preview:SetTextColor(P.ColorRGB(db,"other"))
        -- CJK font metrics differ from the built-ins; size the box to its text
        -- instead of assuming line heights.
        preview:SetHeight(0)
        preview:SetHeight(math.min(math.max(preview:GetStringHeight(), 28), 52))
    end
end

function P.OpenColorPicker(category)
    if not P.defaultColors[category] or not ColorPickerFrame then return end
    local picker=ColorPickerFrame
    -- Finish an open picker first so its callbacks cannot apply to this category.
    if picker:IsShown() then HideUIPanel(picker) end
    local previous=P.ColorHex(P.db,category)
    local function set(hex)
        P.db.colors[category]=hex; P.ResetState(); P.RefreshOptions()
    end
    picker.func=nil; picker.opacityFunc=nil; picker.cancelFunc=nil
    picker.hasOpacity=false
    picker:SetColorRGB(P.ColorRGB(P.db,category))
    picker.func=function()
        local r,g,b=picker:GetColorRGB()
        local function byte(value) return math.floor(math.max(0,math.min(1,value))*255+0.5) end
        set(string.format("%02X%02X%02X",byte(r),byte(g),byte(b)))
    end
    picker.cancelFunc=function() set(previous) end
    picker:SetFrameStrata("FULLSCREEN_DIALOG")
    ShowUIPanel(picker)
end

function P.ResetColors()
    if ColorPickerFrame and ColorPickerFrame:IsShown() then
        ColorPickerFrame.func=nil; ColorPickerFrame.cancelFunc=nil; ColorPickerFrame.opacityFunc=nil
        HideUIPanel(ColorPickerFrame)
    end
    P.db.colors={}
    for category,hex in pairs(P.defaultColors) do P.db.colors[category]=hex end
    P.ResetState(); P.RefreshOptions()
end

-- One step smaller than GameFontHighlightSmall for list captions. Built once
-- and fully guarded: a copy failure must never abort this file's load.
local tinyFont
if type(CreateFont) == "function" then
    local font = CreateFont("McodeChatTinyFont")
    if font then
        local ok = false
        if font.CopyFontObject and type(GameFontHighlightSmall) == "table" then
            ok = (pcall(font.CopyFontObject, font, GameFontHighlightSmall) or false)
        end
        if not ok and font.SetFontObject then
            ok = (pcall(font.SetFontObject, font, "GameFontHighlightSmall") or false)
        end
        if ok and font.SetHeight then
            pcall(font.SetHeight, font, 10)
            tinyFont = font
        end
    end
end

local channelChoices={{"CHANNEL","公共频道"},{"YELL","喊话"},{"SAY","说话"},{"WHISPER","私聊"},
    {"PARTY","小队"},{"RAID","团队"},{"RAID_WARNING","团队警告"},{"GUILD","公会"},
    {"OFFICER","官员"},{"BATTLEGROUND","战场"}}

function P.ParseRules(value)
    local rules,seen={},{}
    for line in (value or ""):gmatch("[^\r\n]+") do
        line=line:match("^%s*(.-)%s*$")
        if #line>120 or line:find("|",1,true) then return nil,"每条最多120字节，不能包含颜色或链接控制符。" end
        if line~="" and not seen[line:lower()] then rules[#rules+1]=line; seen[line:lower()]=true end
        if #rules>100 then return nil,"每组最多100条规则。" end
    end
    return rules
end

function P.RefreshRecords()
    if not P.options or not P.options.recordText then return end
    P.FlushRecords(P.state,P.db)
    local kind=P.options.recordKind or "missed"
    local records=P.db.records[kind] or {}
    local out={kind=="missed" and "最近20条漏译样本" or "最近20条屏蔽样本"}
    for index=#records,math.max(1,#records-19),-1 do
        local item=records[index]
        out[#out+1]="\n["..tostring(item.author).."] "..tostring(item.channel or item.category).." ×"..tostring(item.count)
        if item.reason then out[#out+1]="原因："..item.reason end
        out[#out+1]=tostring(item.raw):gsub("|","||")
    end
    if #records==0 then out[#out+1]="\n暂无记录。新消息进入后会自动保存样本。" end
    local fs=P.options.recordText
    fs:SetText(table.concat(out,"\n")); fs:SetHeight(0)
    local height=math.max(220,fs:GetStringHeight()+12)
    fs:SetHeight(height); P.options.recordChild:SetHeight(height)
    P.options.recordScroll:UpdateScrollChildRect()
    P.options.recordScroll:SetVerticalScroll(0)
    P.RefreshOptions()
end


function P.CreateOptions()
    if P.options or type(InterfaceOptions_AddCategory) ~= "function" then return end
    local parent = InterfaceOptionsFramePanelContainer or UIParent

    P.options = { panel = nil, extraChecks = {}, pages = {} }
    local options = P.options

    local function text(target, value, x, y, width, height, font)
        local fs = target:CreateFontString(nil, "ARTWORK", font or "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", x, y); fs:SetWidth(width); fs:SetHeight(height)
        fs:SetJustifyH("LEFT"); fs:SetJustifyV("TOP"); fs:SetText(value)
        return fs
    end
    local function check(target, name, caption, x, y, get, set, labelWidth)
        local box = CreateFrame("CheckButton", name, target, "UICheckButtonTemplate")
        box:SetWidth(24); box:SetHeight(24); box:SetPoint("TOPLEFT", x, y)
        local label = box:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetPoint("LEFT", box, "RIGHT", 2, 0); label:SetWidth(labelWidth or 160)
        label:SetJustifyH("LEFT"); label:SetText(caption)
        box.labelWidth = labelWidth or 160
        box.get = get
        box:SetScript("OnClick", function(self)
            set(self:GetChecked() and true or false)
            P.ResetState(); P.RefreshOptions()
        end)
        options.extraChecks[#options.extraChecks + 1] = box
        return box
    end
    local function button(target, caption, x, y, width, callback)
        local b = CreateFrame("Button", nil, target, "UIPanelButtonTemplate")
        b:SetPoint("TOPLEFT", x, y); b:SetWidth(width); b:SetHeight(24)
        b:SetText(caption); b:SetScript("OnClick", callback); return b
    end
    -- Scrollbars of the plain scroll template float without a track; a dark
    -- backdrop gives the list column (and the scrollbar inside it) a visible
    -- background, matching the keyword edit box.
    local function shade(frame)
        frame:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground"})
        frame:SetBackdropColor(0, 0, 0, 0.35)
    end

    local function channels(target, key, y, spacing, cols)
        local step = spacing or 28
        local columns = cols or 2
        local offset = columns == 3 and 124 or 194
        local labelWidth = columns == 3 and 96 or nil
        for index, item in ipairs(channelChoices) do
            local category = item[1]
            check(target, nil, item[2], 16+((index-1)%columns)*offset, y-math.floor((index-1)/columns)*step,
                function() return P.db[key][category] == true end,
                function(value) P.db[key][category] = value end, labelWidth)
        end
    end

    ---- 主页：各子页指引 ----
    local panel = CreateFrame("Frame", "McodeChatProbeOptions", parent)
    panel:SetAllPoints(parent); panel:Hide()
    panel.name = "聊天助手"
    options.panel = panel
    text(panel, "聊天助手（ChatTranslatorProbe_Mcode）", 16, -16, 380, 24, "GameFontNormalLarge")
    text(panel, "版本 " .. P.version .. "。设置立即生效；账号内所有角色共用。", 16, -45, 380, 22)
    text(panel, "启用与显示方式：见“翻译设置”子页。", 16, -80, 380, 22)
    text(panel, "屏蔽、白名单与去重：见“屏蔽与过滤”子页。", 16, -102, 380, 22)
    text(panel, "漏译与屏蔽样本：见“本地记录”子页。", 16, -124, 380, 22)
    panel:SetScript("OnShow", P.RefreshOptions)
    InterfaceOptions_AddCategory(panel)
    options.pages[#options.pages + 1] = panel

    ---- 翻译设置子页 ----
    local translate = CreateFrame("Frame", nil, parent)
    translate:SetAllPoints(parent); translate:Hide()
    translate.name = "翻译设置"; translate.parent = panel.name
    local function ttext(value, x, y, width, height)
        return text(translate, value, x, y, width, height)
    end
    local function tcheck(name, caption, x, y, get, set, labelWidth)
        return check(translate, name, caption, x, y, get, set, labelWidth)
    end
    text(translate, "翻译设置", 16, -16, 380, 24, "GameFontNormalLarge")
    local enabled = tcheck("McodeChatProbeEnabled", "开启聊天翻译", 16, -46,
        function() return P.db.enabled end,
        function(value) P.db.enabled = value; if value then P.Install() end end)
    local modeButton = CreateFrame("Button", "McodeChatProbeMode", translate, "UIPanelButtonTemplate")
    modeButton:SetPoint("TOPLEFT", 16, -76); modeButton:SetWidth(285); modeButton:SetHeight(24)
    modeButton:SetScript("OnClick", function()
        P.db.display = MODE_CYCLE[P.db.display] or "mixed"
        P.ResetState(); P.RefreshOptions()
    end)
    ttext("对照示例（同一句话，两种模式）：", 16, -106, 380, 16)
    local preview = ttext("", 16, -124, 380, 48)
    local colored = tcheck("McodeChatProbeColored", "按类别着色（点击下方按钮修改颜色）", 16, -182,
        function() return P.db.colorByCategory end, function(value) P.db.colorByCategory = value end, 330)
    local colorButtons = {}
    for index, item in ipairs({{"dungeon","副本相关"},{"role","职业／职责"},{"other","其他文本"}}) do
        local category, caption = item[1], item[2]
        local button = CreateFrame("Button", nil, translate, "UIPanelButtonTemplate")
        button:SetPoint("TOPLEFT", 16+(index-1)*130, -212); button:SetWidth(122); button:SetHeight(26)
        button.caption = caption; button:SetScript("OnClick", function() P.OpenColorPicker(category) end)
        colorButtons[category] = button
    end
    local resetColors = CreateFrame("Button", "McodeChatProbeResetColors", translate, "UIPanelButtonTemplate")
    resetColors:SetPoint("TOPLEFT", 16, -244); resetColors:SetWidth(142); resetColors:SetHeight(24)
    resetColors:SetText("恢复默认颜色"); resetColors:SetScript("OnClick", P.ResetColors)
    local demo = CreateFrame("Button", "McodeChatProbeDemo", translate, "UIPanelButtonTemplate")
    demo:SetPoint("TOPLEFT", 174, -244); demo:SetWidth(142); demo:SetHeight(24)
    demo:SetText("显示本地样例"); demo:SetScript("OnClick", function() P.Demo() end)
    translate:SetScript("OnShow", P.RefreshOptions)
    InterfaceOptions_AddCategory(translate)
    options.pages[#options.pages + 1] = translate
    options.enabled = enabled; options.modeButton = modeButton; options.preview = preview
    options.colored = colored
    options.colorButtons = colorButtons; options.resetColors = resetColors

    ---- 屏蔽与过滤子页（页内五标签）----
    local filter = CreateFrame("Frame", nil, parent)
    filter:SetAllPoints(parent); filter:Hide()
    filter.name = "屏蔽与过滤"; filter.parent = panel.name
    text(filter, "屏蔽与过滤", 16, -16, 380, 24, "GameFontNormalLarge")
    local filterEnabled = check(filter, "McodeChatProbeFilter",
        "启用屏蔽与过滤（总开关）", 16, -44,
        function() return P.db.filterEnabled end, function(value) P.db.filterEnabled = value end, 200)
    -- Common-language hiding is a blocking rule independent of the master switch.
    local hideCommonBox = check(filter, "McodeChatProbeHideCommon", "屏蔽通用语", 264, -44,
        function() return P.db.hideCommon end, function(value) P.db.hideCommon = value end, 100)
    text(filter, "总开关停用关键字、屏蔽词与去重；通用语屏蔽不受影响。通用语原文不进入 ElvUI 历史与漏译分析。",
        16, -72, 380, 30)
    local tabButtons, tabLayers, tabOrder = {}, {}, {}
    local tabX = 12
    local currentTab = "屏蔽"
    local function ShowFilterTab(name)
        currentTab = name
        for tabName, layer in pairs(tabLayers) do
            if tabName == name then layer:Show() else layer:Hide() end
            tabButtons[tabName]:SetText(tabName == name and "|cFFFFD100"..tabName.."|r" or tabName)
        end
    end
    -- CJK tab labels are wider than a fixed step; measure the small-font text
    -- and lay the tabs out edge to edge. Plain text tabs: the
    -- CharacterFrameTabButton template draws fixed-size latin tab textures that
    -- render as misaligned partial blobs under CJK labels.
    local function tabGlyphWidth(text)
        local ascii = 0
        for i = 1, #text do
            if text:byte(i) < 128 then ascii = ascii + 1 end
        end
        return (#text - ascii) / 3 * 12 + ascii * 6 + 10
    end
    local function TabLayer(name)
        local layer = CreateFrame("Frame", nil, filter)
        layer:SetAllPoints(filter); layer:Hide()
        tabLayers[name] = layer
        local tabButton = CreateFrame("Button", nil, filter)
        tabButton:SetText(name)
        if tabButton.SetNormalFontObject then
            tabButton:SetNormalFontObject("GameFontNormalSmall")
            tabButton:SetHighlightFontObject("GameFontHighlightSmall")
        end
        local width = tabGlyphWidth(name) + 6
        local font = tabButton.GetFontString and tabButton:GetFontString()
        if font and font.GetStringWidth then
            width = math.max(width, font:GetStringWidth() + 8)
        end
        tabButton:SetWidth(width)
        tabButton:SetHeight(20)
        tabButton:SetPoint("TOPLEFT", tabX, -108)
        tabX = tabX + width + 6
        tabButton:SetScript("OnClick", function() ShowFilterTab(name) end)
        tabButtons[name] = tabButton
        local content = CreateFrame("Frame", nil, layer)
        content:SetPoint("TOPLEFT", 0, -134); content:SetWidth(380); content:SetHeight(294)
        return content
    end
    filter:SetScript("OnShow", function() ShowFilterTab(currentTab); P.RefreshOptions() end)

    options.listInputs = {}; options.listAdds = {}; options.listDeletes = {}; options.listRows = {}
    local function EscapeEntry(value) return (value:gsub("|","||")) end
    local function AddListEntry(key, value)
        value = value:match("^%s*(.-)%s*$") or ""
        if value == "" then return "内容为空。" end
        if #value > 120 then return "每条最多120字节。" end
        if value:find("|", 1, true) then return "不能包含颜色或链接控制符。" end
        local lowered = value:lower()
        for _, existing in ipairs(P.db[key]) do
            if existing:lower() == lowered then return "该条目已存在。" end
        end
        if #P.db[key] >= 100 then return "每组最多100条。" end
        P.db[key][#P.db[key] + 1] = value
        return nil
    end
    -- One entry list: the label line doubles as feedback; input row; scroll.
    local function buildList(target, key, label, hintY, listHeight)
        local noteLine = text(target, label, 16, hintY, 380, 14)
        -- CreateFontString's template argument takes a NAME, not an object;
        -- swap the font afterwards so the tiny size actually applies.
        if tinyFont then noteLine:SetFontObject(tinyFont) end
        local function note(msg)
            noteLine:SetText(msg and ("|cFFFF5555"..msg.."|r") or label)
        end
        local input = CreateFrame("EditBox", "McodeChatListInput"..key, target, "InputBoxTemplate")
        input:SetPoint("TOPLEFT", 16, hintY-16); input:SetWidth(170); input:SetHeight(24)
        input:SetAutoFocus(false)
        options.listInputs[key] = input
        local selected = nil
        local rows = { content = nil, buttons = {}, selected = nil }
        options.listRows[key] = rows
        local function render()
            local entries = P.db[key]
            rows.selected = selected
            for i = 1, #rows.buttons do rows.buttons[i]:Hide() end
            for i = 1, #entries do
                local entryBtn = rows.buttons[i]
                if not entryBtn then
                    -- Plain text rows: no button chrome; the dark scroll
                    -- backdrop plus a hairline separator carry the structure.
                    entryBtn = CreateFrame("Button", nil, rows.content)
                    entryBtn:SetWidth(336); entryBtn:SetHeight(18)
                    if entryBtn.SetNormalFontObject then
                        entryBtn:SetNormalFontObject("GameFontHighlightSmall")
                        entryBtn:SetHighlightFontObject("GameFontNormalSmall")
                    end
                    if rows.content.CreateTexture then
                        local line = rows.content:CreateTexture(nil, "ARTWORK")
                        line:SetHeight(1)
                        line:SetPoint("BOTTOMLEFT", entryBtn, "BOTTOMLEFT", 0, -1)
                        line:SetTexture(0.32, 0.32, 0.32, 0.45)
                    end
                    entryBtn:SetScript("OnClick", function()
                        selected = (selected == entryBtn.rowIndex) and nil or entryBtn.rowIndex
                        render()
                    end)
                    rows.buttons[i] = entryBtn
                end
                local display = entries[i]
                if #display > 52 then display = display:sub(1, 52) .. "…" end
                entryBtn.rowIndex = i
                if selected == i then
                    entryBtn:SetText("|cFFFFD100▸ "..EscapeEntry(display).."|r")
                else
                    entryBtn:SetText(EscapeEntry(display))
                end
                entryBtn:SetPoint("TOPLEFT", 0, -(i-1)*20)
                entryBtn:Show()
            end
            rows.content:SetHeight(math.max(#entries * 20, 10))
            rows.scroll:UpdateScrollChildRect()
        end
        options.listAdds[key] = button(target, "添加", 192, hintY-14, 84, function()
            local err = AddListEntry(key, input:GetText() or "")
            if err then note(err) else input:SetText(""); input:ClearFocus(); note(nil) end
            render()
        end)
        options.listDeletes[key] = button(target, "删除", 282, hintY-14, 86, function()
            if not selected then note("先点击列表里要删除的条目。", true); return end
            table.remove(P.db[key], selected)
            selected = nil
            P.ResetState(); render()
        end)
        local scroll = CreateFrame("ScrollFrame", "McodeChatListScroll"..key, target, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 16, hintY-44); scroll:SetWidth(352); scroll:SetHeight(listHeight)
        shade(scroll)
        local content = CreateFrame("Frame", nil, scroll)
        content:SetWidth(352); content:SetHeight(10)
        scroll:SetScrollChild(content)
        rows.content = content; rows.scroll = scroll
        return { reset = function() selected = nil; render(); note(nil) end }
    end

    -- 屏蔽 tab: built-in keyword blocking plus the user's own block-word list.
    local blockTab = TabLayer("屏蔽")
    options.keywordEnabled = check(blockTab, "McodeChatProbeKeywords", "关键字屏蔽", 16, -4,
        function() return P.db.ads.gold == true end,
        function(value)
            for _,kind in ipairs({"gold","account","leveling","boost"}) do P.db.ads[kind] = value end
            P.db.hideGuildRecruitment = value
        end)
    text(blockTab, "命中出售金币、出售账号、代练、付费代刷或公会招募招新时隐藏；只在下方勾选的频道生效。",
        44, -32, 350, 30)
    local blockList = buildList(blockTab, "blockWords",
        "屏蔽词：英文按整词或短语，中文按连续文本；每条最多120字节，最多100条。", -64, 70)
    text(blockTab, "屏蔽生效频道", 16, -182, 380, 14)
    channels(blockTab, "filterChannels", -200, 22, 3)
    blockTab:SetScript("OnShow", function() blockList.reset() end)

    -- 白名单 tab: players and text phrases, one list each.
    local whiteTab = TabLayer("白名单")
    local playerList = buildList(whiteTab, "whitelistPlayers",
        "白名单玩家：完整姓名含服务器后缀，优先放行屏蔽", -4, 108)
    local phraseList = buildList(whiteTab, "whitelistText",
        "白名单文本：词或短语，优先放行屏蔽", -160, 88)
    whiteTab:SetScript("OnShow", function() playerList.reset(); phraseList.reset() end)

    local dedup = TabLayer("重复消息过滤")
    options.dedupEnabled = check(dedup, nil, "开启重复消息去重", 16, -6,
        function() return P.db.dedupEnabled end, function(value) P.db.dedupEnabled = value end)
    options.crossPublic = check(dedup, "McodeChatProbeCrossPublic", "合并公共频道与喊话", 16, -34,
        function() return P.db.crossPublicDedup end, function(value) P.db.crossPublicDedup=value end)
    text(dedup, "只去重完全相同的原文。",16,-62,380,18)
    options.unifiedSeconds = button(dedup, "统一间隔：30 秒（点击切换）", 16, -88, 196, function()
        P.db.dedupSeconds = cycleSeconds(P.db.dedupSeconds, UNIFIED_SECONDS)
        P.ResetState(); P.RefreshOptions()
    end)
    channels(dedup, "dedup", -116, 22)
    dedup:SetScript("OnShow", function() P.RefreshOptions() end)


    ShowFilterTab("屏蔽")
    InterfaceOptions_AddCategory(filter)
    options.pages[#options.pages + 1] = filter
    options.filterEnabled = filterEnabled
    options.common = hideCommonBox


    ---- 本地记录子页 ----
    local records = CreateFrame("Frame", nil, parent)
    records:SetAllPoints(parent); records:Hide()
    records.name = "本地记录"; records.parent = panel.name
    text(records, "本地记录", 16, -16, 380, 24, "GameFontNormalLarge")
    check(records, nil, "采集漏译与屏蔽样本", 16, -46,
        function() return P.db.captureEnabled end, function(value) P.db.captureEnabled = value end)
    options.recordSummary = text(records, "", 16, -76, 380, 18)
    options.recordKind = "missed"
    button(records, "查看漏译", 16, -100, 110, function() options.recordKind = "missed"; P.RefreshRecords() end)
    button(records, "查看屏蔽", 138, -100, 110, function() options.recordKind = "blocked"; P.RefreshRecords() end)
    options.clearRecords = button(records, "清空当前记录", 260, -100, 122, function()
        P.db.records[options.recordKind] = {}; P.RefreshRecords()
    end)
    local recordScroll = CreateFrame("ScrollFrame", "McodeChatAssistantRecords", records, "UIPanelScrollFrameTemplate")
    recordScroll:SetPoint("TOPLEFT", 16, -132); recordScroll:SetWidth(356); recordScroll:SetHeight(244)
    shade(recordScroll)
    local child = CreateFrame("Frame", nil, recordScroll); child:SetWidth(340); child:SetHeight(220)
    options.recordText = text(child, "", 0, 0, 338, 220)
    recordScroll:SetScrollChild(child); options.recordChild = child; options.recordScroll = recordScroll
    text(records, "通用语始终不记录。每个样本累计出现次数，容量满时淘汰最久未出现的样本。", 16, -382, 380, 36)
    records:SetScript("OnShow", P.RefreshRecords)
    InterfaceOptions_AddCategory(records)
    options.pages[#options.pages + 1] = records

    P.RefreshOptions()
end

function P.OpenOptions()
    P.CreateOptions()
    if P.options and type(InterfaceOptionsFrame_OpenToCategory) == "function" then
        InterfaceOptionsFrame_OpenToCategory(P.options.panel)
        InterfaceOptionsFrame_OpenToCategory(P.options.panel)
    else printLocal("请从 ESC → 界面 → 插件 → 聊天助手 打开设置。") end
end

local function bypassChat(db,event,language)
    if not P.categories[event] then return true end
    if not db or db.enabled~=false or db.captureEnabled==true then return false end
    if db.hideCommon and P.IsCommonLanguage(language) then return false end
    if db.filterEnabled~=false then
        if db.dedupEnabled~=false then return false end
        local ads=db.ads or {}
        if db.hideGuildRecruitment or #(db.blockWords or {})>0
            or ads.gold or ads.account or ads.leveling or ads.boost then return false end
    end
    return true
end

local function install(owner, method, kind)
    local current = owner[method]
    local previous = P.adapters[kind]
    if type(current) ~= "function" or (previous and current == previous.wrapper) then return end
    local wrapper
    if kind == "itemref" then
        wrapper = function(link, text, button, chatFrame)
            local id = type(link) == "string" and link:match("^mcodeorig:(%d+)")
            if id then P.ToggleOriginal(id, chatFrame, text) return end
            return current(link, text, button, chatFrame)
        end
    elseif kind == "elvui-history" then
        wrapper = function(module, event, ...)
            if not P.categories[event] then return current(module,event,...) end
            if P.categories[event] and not P.ShouldRecordLanguage(select(3, ...)) then return end
            if P.EventBlockReason(P.state,P.db,event,P.Pack(...),false,GetTime()) then return end
            return current(module, event, ...)
        end
    elseif kind == "default" then
        wrapper = function(frame, event, ...)
            if bypassChat(P.db,event,select(3,...)) then return current(frame,event,...) end
            local args = P.Pack(...)
            return P.Run(P.state, P.db, frame, event, args, false,
                function() return current(frame, event, unpack(args, 1, args.n)) end, GetTime)
        end
    else
        wrapper = function(module, frame, event, ...)
            if bypassChat(P.db,event,select(3,...)) then return current(module,frame,event,...) end
            local args = P.Pack(...)
            local history = args[14] == "ElvUI_ChatHistory"
            return P.Run(P.state, P.db, frame, event, args, history,
                function() return current(module, frame, event, unpack(args, 1, args.n)) end, GetTime)
        end
    end
    owner[method] = wrapper
    P.adapters[kind] = { owner = owner, method = method, wrapper = wrapper }
end

function P.Install()
    if not P.db then P.Initialize() end
    if P.storageError then return end
    install(_G, "ChatFrame_MessageEventHandler", "default")
    install(_G, "SetItemRef", "itemref")
    for index = 1, 10 do
        local chatFrame = _G["ChatFrame" .. index]
        if chatFrame and type(chatFrame.HookScript) == "function" and not chatFrame._mcodeHoverHooked then
            chatFrame._mcodeHoverHooked = true
            chatFrame:HookScript("OnHyperlinkEnter", function(_, link)
                if type(link) == "string" then
                    local id = link:match("^mcodeorig:(%d+)")
                    if id then P.ShowOriginal(id) end
                end
            end)
            chatFrame:HookScript("OnHyperlinkLeave", function()
                if GameTooltip then GameTooltip:Hide() end
            end)
        end
    end
    local engine = type(ElvUI) == "table" and ElvUI[1]
    if engine and type(engine.GetModule) == "function" then
        local ok, module = pcall(engine.GetModule, engine, "Chat", true)
        if ok and module then
            install(module, "ChatFrame_MessageEventHandler", "elvui")
            install(module, "SaveChatHistory", "elvui-history")
        end
    end
    P.CreateOptions()
end

function P.Status()
    local active = {}
    for kind, adapter in pairs(P.adapters) do
        active[#active + 1] = kind .. (adapter.owner[adapter.method] == adapter.wrapper and " 已接入" or " 被其他插件替换")
    end
    table.sort(active)
    local s = P.state.stats
    printLocal(P.version .. "；翻译" .. (P.db.enabled and "已开启" or "已关闭")
        .. "；" .. (MODE_NAMES[P.db.display] or "替换原文") .. "；" .. table.concat(active, "；"))
    printLocal("行内替换 " .. s.replaced .. " 条；")
    printLocal("窗口原文显示 " .. s.shown .. "，提示 " .. s.hints .. "，重复隐藏 " .. s.hidden
        .. "，无法关联事件 " .. s.noID .. "，未识别显示路径 " .. s.unmatched .. "，错误 " .. s.errors)
    printLocal("处理次数 " .. s.calls .. "，显示但无提示 " .. s.withoutHint
        .. "（含游戏内未掌握语言 " .. s.foreignLanguage .. "）；去重"..(P.db.dedupEnabled and "开启" or "关闭")
        .. ("，统一间隔 "..P.DedupSeconds(P.db).." 秒。").."计数按窗口计算。")
    printLocal("通用语屏蔽：" .. (P.db.hideCommon and "开启" or "关闭") .. "，拦截次数 " .. s.blockedCommon
        .. "；通用语不进入新增聊天历史和漏译分析。")
    printLocal("关键字屏蔽"..(P.db.ads.gold==true and "已开启" or "已关闭").."；屏蔽词 "..#P.db.blockWords
        .." 条；拦截：广告 "..s.blockedAds.."、公会招募 "..s.blockedGuild
        .."；合并公共频道与喊话："..(P.db.crossPublicDedup and "开启" or "关闭").."；重复消息复用分析 "..s.reusedAnalysis.." 次。")
    printLocal("公共译文缓存：复用 "..s.reusedTranslation.." 次，当前保留 "..P.state.publicTranslations.count.." 条。")
    printLocal("采集"..(P.db.captureEnabled and "开启" or "关闭").."；漏译样本 "..#P.db.records.missed.."，屏蔽样本 "..#P.db.records.blocked.."。")
end

-- Click on [orig]: swap that chat line in place between the translated and
-- the original wording. Chat frames recycle their FontStrings, so the swap
-- only happens when the region still displays one of our two renderings;
-- otherwise (or for old sessions) fall back to the tooltip.
-- Click on [orig]: swap that chat line in place between the translated and
-- the original wording. The first click locates the FontString; later clicks
-- reuse the stored region and flip by intent -- real clients may not return
-- the exact text a SetText wrote, so the body is only verified loosely.
function P.ToggleOriginal(id, chatFrame, clickedText)
    local state = P.state
    if not state or not state.lineTranslated or not state.lineTranslated[id] then
        return P.ShowOriginal(id)
    end
    local function linkMarkup(toOriginal)
        -- The label says what clicking shows next: [orig] on the Chinese
        -- line, [translation] once the line shows the English original.
        return " |Hmcodeorig:" .. id .. "|h|cff777777[" .. (toOriginal and "译文" or "原文") .. "]|r|h"
    end
    local translated = state.lineTranslated[id] .. linkMarkup(false)
    local original = state.lineOriginal[id] .. linkMarkup(true)

    local function swap(region, toOriginal)
        region:SetText(toOriginal and original or translated)
        state.lineRegion[id] = region
        state.lineIsOriginal[id] = toOriginal and true or false
    end

    -- Later clicks: the stored region, verified loosely by its message body
    -- (either wording contains it) so engine-side text normalization cannot
    -- strand the toggle, while a recycled region still fails the check.
    local stored = state.lineRegion[id]
    if stored and stored.GetObjectType and stored.GetObjectType(stored) == "FontString" and stored.GetText then
        local ok, current = pcall(stored.GetText, stored)
        if ok and type(current) == "string"
            and (current:find(state.lineOriginal[id], 1, true)
                or current:find(state.lineTranslated[id], 1, true)) then
            swap(stored, not state.lineIsOriginal[id])
            return
        end
        state.lineRegion[id] = nil
    end

    local frame = state.lineFrame[id] or chatFrame
    if not frame or not frame.GetRegions then return P.ShowOriginal(id) end
    -- First click: prefer the exact clicked line, then the translated wording.
    local clickedBase = type(clickedText) == "string" and clickedText or nil
    for _, region in ipairs({ frame:GetRegions() }) do
        if region.GetObjectType and region.GetObjectType(region) == "FontString" and region.GetText then
            local ok, current = pcall(region.GetText, region)
            if ok and type(current) == "string" then
                if clickedBase and (current == clickedBase .. linkMarkup(false) or current == clickedBase .. linkMarkup(true)) then
                    swap(region, current == clickedBase .. linkMarkup(false))
                    return
                elseif current == translated then
                    swap(region, true)
                    return
                end
            end
        end
    end
    P.ShowOriginal(id)
end

function P.ShowOriginal(id)
    if not GameTooltip then return end
    local raw = P.state and P.state.origins and P.state.origins[tostring(id)]
    GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
    local shown
    if raw then
        shown = pcall(GameTooltip.SetText, GameTooltip, "|cff88ddff聊天助手原文：|r" .. raw)
    end
    if not shown then
        GameTooltip:SetText("原文已失效（界面重载或超过保留条数后不保存）", 1, 1, 1)
    end
    GameTooltip:Show()
end

-- Demo writes only to local chat, using a separate state and clock; it sends no server messages.
function P.Demo()
    if not DEFAULT_CHAT_FRAME then return end
    local demo = P.NewState()
    local db = { enabled = true, dedup = { CHANNEL = true }, channelDedup = { probe = true },
        labels = P.db.labels, display = P.db.display, hideCommon = P.db.hideCommon,
        colors=P.db.colors,colorByCategory=P.db.colorByCategory, inlineReplace=false }
    local now, serial = 0, 800000
    local function show(text, at, language)
        now, serial = at, serial + 1
        local args = P.Pack(text, "ChatProbe", language or "Universal", "1. Probe", "", "", 0, 1, "Probe", 0, serial, "")
        P.Run(demo, db, DEFAULT_CHAT_FRAME, "CHAT_MSG_CHANNEL", args, false, function()
            DEFAULT_CHAT_FRAME:AddMessage("[本地样例 " .. at .. " 秒] |Hplayer:ChatProbe:" .. serial
                .. "|h[ChatProbe]|h: " .. text)
        end, function() return now end)
    end
    printLocal("以下是本地合成样例，不代表真实服务器事件已通过验收。")
    show("LFM disc", 0); show("LFM disc", 10); show("LFM disc", 29); show("LFM disc", 30)
    show("LFM discipline priest", 31); show("LFG disc priest", 32)
    show("LFM disc, no loot", 33); show("don't pull until xxx", 34)
    show("don't pull yet", 35)
    show("|Hitem:123:disc|h[discipline priest]|h", 36)
    show("LFM RS 25nm need 2Tank RDPS MDPS 5.8 (STS ress) 18/25", 37)
    show("LFM ICC 10 NEED RSHAM BOOMY SP RET GS +6K SOLO HEAL SOLO TANK", 38)
    show("LFM icc25hc Need 1xDisco 1x Sp (BOE+sfs)RESS 20/25", 39)
    show("LFM #3 ToC25N - Need, 1 Tank (BDK), 3 Healer, 6 Melee, 7 Ranged - Min 5.3+ Inspect (Only B+O+P Ress) (8/25)", 40)
    show("[通用语] 本地屏蔽样例", 41, "通用语")
    show("ICC priest PS; stop dps; do not dispel Necrotic Plague until 5 stacks", 42)
    show("buff BoK MotW AI; shaman BL", 43)
    show("paladin DP / hunter SS", 44)
    printLocal("合成样例完成：原文显示 " .. demo.stats.shown .. "，重复隐藏 " .. demo.stats.hidden
        .. "，通用语拦截 " .. demo.stats.blockedCommon .. "。")
end

function P.PerfReport()
    local report=P.PerfSnapshot()
    if not report then printLocal("性能诊断未运行。用 /ctprobe perf on 开始采样。") return end
    printLocal("性能诊断"..(report.enabled and "采样中" or "已停止")..string.format("；%.1f秒；",report.seconds)..report.timerLabel)
    printLocal(string.format("实时窗口处理 %d，历史回放 %d，嵌套入口 %d，入口错误 %d。跳过插件处理的事件不计入。",
        report.live,report.history,report.nested,report.errors))
    local names={entry="聊天入口",filter="过滤判断",group="分组判断",translate="实际翻译",
        record="日志采集",flush="日志顺序整理",cleanup="缓存清理",publicCache="公共译文查找"}
    for _,stage in ipairs(P.perfStages) do
        local row=report.stages[stage]
        local timings=row.timed>0 and string.format("累计 %.3fms，平均 %.3fms，最高 %.3fms",row.ms,row.ms/row.timed,row.max)
            or "无有效计时样本"
        printLocal(names[stage]..string.format("：%d次；",row.calls)..timings..string.format("；有效/无效 %d/%d",row.timed,row.invalid))
    end
    local function percent(count,total)
        return total>0 and string.format("%.1f%%",count/total*100) or "无样本"
    end
    printLocal(string.format("公共译文命中 %d，未命中 %d，命中率 %s；隐藏同文分析复用 %d。",
        report.cacheHits,report.cacheMisses,percent(report.cacheHits,report.cacheHits+report.cacheMisses),report.analysisHits))
    printLocal(string.format("重复隐藏 %d，占实时窗口处理 %s；通用语 %d，公会招募 %d，广告 %d。",
        report.hidden,percent(report.hidden,report.live),report.common,report.guild,report.ads))
    local c=report.cache
    printLocal(string.format("当前缓存：译文 %d/256（文本 %d/524288字节），事件 %d/1024，过滤 %d/1024，去重 %d/4096，到期队列 %d/4096，分析 %d/1024，采集去重 %d/1024。",
        c.translations,c.textBytes,c.events,c.filters,c.dedup,c.expiry,c.analysis,c.observed))
    printLocal("入口耗时含原聊天处理和诊断开销；多个窗口分别计数，嵌套入口耗时计入外层。阶段可嵌套，累计耗时不能相加。")
end

SlashCmdList = SlashCmdList or {}
SLASH_MCODECHATPROBE1 = "/ctprobe"
SLASH_MCODECHATPROBE2 = "/chatassist"
SlashCmdList.MCODECHATPROBE = function(text)
    if not P.db then P.Initialize() end
    if P.storageError then printLocal("存档来自更高版本，辅助已暂停；请安装对应版本。"); return end
    local command, rest = (text or ""):match("^%s*(%S*)%s*(.-)%s*$")
    command = command:lower()
    if command == "perf" then
        rest=rest:lower()
        if rest=="on" then
            P.PerfStart(); printLocal("性能诊断已开启，本次计数已清零。玩一会儿后用 /ctprobe perf report 查看；/ctprobe perf off 停止并保留报告。")
        elseif rest=="off" then P.PerfStop(); printLocal("性能诊断已关闭；已有报告保留到下次采样或重载。")
        elseif rest=="report" then P.PerfReport()
        else printLocal("用法：/ctprobe perf on|off|report；默认关闭，on 重新开始采样。") end
        return -- The settings preview is not part of a chat diagnostic session.
    elseif command == "on" then
        P.db.enabled = true; P.ResetState(); P.Install(); P.Status()
    elseif command == "off" then
        P.db.enabled = false; P.ResetState(); P.Status()
    elseif command == "demo" then P.Demo()
    elseif command == "mode" then
        rest = rest:lower()
        if rest == "mixed" or rest == "annotate" or rest == "terms" then
            P.db.display = rest; P.ResetState()
            printLocal(rest == "mixed" and "已改为替换原文：译文取代原句。"
                or rest == "annotate" and "已改为注释保留：原句不动，认出的词后面加（中文）。"
                or "已改为术语列表。")
        else printLocal("用法：/ctprobe mode mixed（替换原文）| annotate（注释保留）| terms（术语列表）。") end
    elseif command == "label" then
        if rest == "" or rest:find("[|\r\n]") or #rest > 120 then
            printLocal("用法：/ctprobe label 戒牧；不接受颜色控制符、换行或超过 120 字节的文字。")
        else
            P.db.labels.disc = rest; P.ResetState()
            printLocal("戒牧及全部别名的解释改为：" .. rest)
        end
    elseif command == "resetlabel" then
        P.db.labels.disc = nil; P.ResetState(); printLocal("已恢复戒律牧师的内置解释。")
    elseif command == "status" then P.Status()
    elseif command == "" or command == "config" or command == "options" then P.OpenOptions()
    else printLocal("/ctprobe config | on | off | status | demo | mode mixed/terms | label 中文解释 | resetlabel | perf on/off/report") end
    P.RefreshOptions()
end

local listener = CreateFrame("Frame")
listener:RegisterEvent("ADDON_LOADED")
listener:RegisterEvent("PLAYER_LOGIN")
listener:RegisterEvent("PLAYER_LOGOUT")
listener:SetScript("OnEvent", function(_, event, name)
    if event=="PLAYER_LOGOUT" then P.FlushRecords(P.state,P.db); return end
    if event == "ADDON_LOADED" and name == "ChatTranslatorProbe_Mcode" then P.Initialize() end
    if event == "PLAYER_LOGIN" or (event == "ADDON_LOADED" and name == "ElvUI") then
        P.Initialize(); P.Install()
    end
end)
