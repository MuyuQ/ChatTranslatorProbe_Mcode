-- Lua 5.1. Supported recruitment terms do not imply complete sentence coverage.
McodeChatProbe = McodeChatProbe or {}
local P = McodeChatProbe
local unpack = unpack
local function pack(...) return { n = select("#", ...), ... } end
P.Pack = pack
P.version = "0.17.13"

-- Use the event language field, never words in the player's message body.
function P.IsCommonLanguage(language)
    return type(language) == "string" and (language:lower() == "common"
        or language == "通用语" or language == "通用語")
end

function P.ShouldRecordLanguage(language)
    return not P.IsCommonLanguage(language)
end

P.concepts = {
    dktank = { label = "DK坦克", aliases = { "dk tank", "dktank", "dk tanks" }, guard = "roster", role = true },
    seekjewelcrafter = { label = "寻找珠宝加工师", aliases = { "need jewelcrafting", "need jawelcrafting", "lf jewelcrafter", "lf jewelcrafting" } },
    seektailor = { label = "寻找裁缝", aliases = { "lf tailoring", "lf tailor", "lf tairloing" } },
    neckslot = { label = "项链", aliases = { "necklace", "neck", "necklaces" }, guard = "trade" },
    shoulderslot = { label = "肩部装备", aliases = { "shoulders", "shoulder" }, guard = "trade" },
    handslot = { label = "手套", aliases = { "hands", "hand" }, guard = "trade" },
    beltslot = { label = "腰带", aliases = { "belt", "waist", "belts" }, guard = "trade" },
    wristslot = { label = "护腕", aliases = { "wrists", "wrist" }, guard = "trade" },
    feetslot = { label = "鞋子", aliases = { "feet", "foot" }, guard = "trade" },
    tradebudget = { label = "预算", aliases = { "budget" }, guard = "trade" },
    tradeincluding = { label = "包含", aliases = { "including" }, guard = "trade" },
    tradenegotiable = { label = "可议价", aliases = { "negotiable", "negotiation" }, guard = "trade" },
    tradecanremove = { label = "可移除物品", aliases = { "can remove items", "can remove item" }, guard = "trade" },
    guildmembers = { label = "成员", aliases = { "members", "member" }, guard = "guild" },
    guildraiders = { label = "团本玩家", aliases = { "raiders", "raider" }, guard = "guild" },
    vocab_guild = { label = "公会", aliases = { "guilds", "guild" } },
    vocab_pve = { label = "副本玩法", aliases = { "pve" } },
    vocab_pvp = { label = "玩家对战", aliases = { "pvp" } },
    vocab_items = { label = "物品", aliases = { "items", "item" }, guard = "vocabulary" },
    vocab_players = { label = "玩家", aliases = { "players", "player", "people", "ppl" }, guard = "vocabulary" },
    vocab_raid = { label = "团队副本", aliases = { "raids", "raid" }, guard = "vocabulary" },
    vocab_group = { label = "队伍", aliases = { "groups", "group" }, guard = "vocabulary" },
    vocab_offline = { label = "离线", aliases = { "offline" } },
    vocab_replace = { label = "替换", aliases = { "replacing", "replace" }, guard = "vocabulary" },
    vocab_equipment = { label = "装备", aliases = { "equipment", "gear" }, guard = "vocabulary" },
    vocab_information = { label = "详情", aliases = { "information", "info" }, guard = "vocabulary" },
    vocab_requirements = { label = "要求", aliases = { "requirements", "requirement", "required" }, guard = "vocabulary" },
    vocab_experience = { label = "经验", aliases = { "experience" }, guard = "vocabulary" },
    vocab_roster = { label = "团队名单", aliases = { "rosters", "roster" }, guard = "vocabulary" },
    vocab_inviteme = { label = "请组我", aliases = { "invite me", "inve me", "inv me" } },
    vocab_fullgroup = { label = "已经满员", aliases = { "full guys", "we full", "we are full", "group is full" } },
    vocab_noneed = { label = "不需要", aliases = { "do not need", "don't need", "no need" } },
    vocab_nodiscord = { label = "不要求Discord", aliases = { "no discord" }, guard = "vocabulary" },
    vocab_welcome = { label = "欢迎", aliases = { "welcome" }, guard = "vocabulary" },
    vocab_dedicated = { label = "投入的", aliases = { "dedicated" }, guard = "vocabulary" },
    vocab_coreteam = { label = "主力团队", aliases = { "core raid team", "core team" }, guard = "vocabulary" },
    disc = { label = "戒牧", aliases = { "discipline priest", "disc priest", "discpriest", "disciplinepriest", "disco", "disci", "discp", "disc", "disc priests", "discipline priests" }, role = true, guard = "disc" },
    shadow = { label = "暗牧", aliases = { "shadow priest", "shadowpriest", "spriest", "sh priest", "shp", "sp", "sh priests", "shadow priests" }, role = true, guard = "shadow" },
    rsham = { label = "奶萨", aliases = { "restoration shaman", "restro", "resto shaman", "restoshaman", "restorationshaman", "rshaman", "rshammy", "rshama", "rshamnmy", "rshamy", "rshami", "rshmy", "rsham", "rcham", "rshamm", "rshamn", "resto shamans", "restoration shamans" }, role = true },
    shaman = { label = "萨满", aliases = { "shaman", "shammy", "shama", "chaman", "chamy", "cham", "sham", "shamy", "shamans" }, role = true, guard = "roster" },
    balance = { label = "鸟德", aliases = { "balance druid", "boomkin", "boomie", "boomy", "bommie", "boomi", "bomie", "bmmie", "bommier", "boomky", "bomy", "boom", "balance", "bala", "bommy", "balance druids" }, role = true, guard = "balance" },
    rdudu = { label = "奶德", aliases = { "restoration druid", "resto druid", "restodruid", "restorationdruid", "rdruid", "rdudu", "rdude", "rdudud", "tree", "resto druids", "restoration druids" }, role = true, guard = "restodruid" },
    ret = { label = "惩戒骑", aliases = { "retribution paladin", "ret paladin", "ret pally", "retpala", "retpally", "retpaladin", "retributionpaladin", "rpala", "rpally", "rpaladin", "retri", "retry", "ret", "ret paladins", "retribution paladins" }, role = true, guard = "recruit" },
    hpala = { label = "奶骑", aliases = { "holy paladin", "holy pally", "holypala", "holypally", "holypaladin", "hpaladin", "hpally", "hpala", "hpall", "hpal", "holy pala", "holy paladins" }, role = true },
    demo = { label = "恶魔术", aliases = { "demonology warlock", "demo lock", "demo warlock", "demolock", "demowarlock", "demonologywarlock", "demon", "demo", "demo warlocks", "demonology warlocks" }, role = true, guard = "demo" },
    fury = { label = "狂暴战", aliases = { "fury warrior", "fury war", "fwarr", "fwar", "fury", "fury warriors" }, role = true, guard = "roster" },
    bdk = { label = "血DK", aliases = { "blood death knight", "blood dk", "bdk", "blood death knights" }, role = true, guard = "roster" },
    udk = { label = "邪DK", aliases = { "unholy death knight", "unholy dk", "unholy", "undk", "uh dk", "uhdk", "udk", "unh", "unholy death knights" }, role = true, guard = "roster" },
    enh = { label = "增强萨", aliases = { "enhancement shaman", "enh shaman", "enhshaman", "enhancementshaman", "enha", "enh", "enh shamans", "enhancement shamans" }, role = true, guard = "enh" },
    ppala = { label = "防骑", aliases = { "protection paladin", "prot paladin", "prot pally", "prot pala", "protpala", "protpally", "protpaladin", "protectionpaladin", "ppaladin", "propala", "ppla", "pala tank", "pprot", "ppala", "ppal", "pala tanks", "prot paladins", "protection paladins" }, role = true, guard = "roster" },
    dk = { label = "DK", aliases = { "death knight", "dk", "death knights" }, role = true, guard = "roster" },
    warrior = { label = "战士", aliases = { "warrior", "warr", "war", "warior", "warriors" }, role = true, guard = "roster" },
    warlock = { label = "术士", aliases = { "warlock", "wlock", "lok", "lock", "warlocks" }, role = true, guard = "roster" },
    mage = { label = "法师", aliases = { "mage", "mag", "mages" }, role = true, guard = "roster" },
    hunter = { label = "猎人", aliases = { "hunter", "huntr", "hunt", "hunters" }, role = true, guard = "roster" },
    rogue = { label = "盗贼", aliases = { "rogue", "rouge", "rog", "roge", "rougue", "rogues" }, role = true, guard = "roster" },
    dps = { label = "输出", aliases = { "dpss", "dps", "dmg" }, role = true, guard = "recruit" },
    mt = { label = "主T", aliases = { "main tank", "mt", "main tanks" }, role = true, guard = "roster" },
    tank = { label = "坦克", aliases = { "tanks", "tank", "tnk" }, role = true, guard = "recruit" },
    healer = { label = "治疗", aliases = { "healers", "healer", "healr", "heller", "heler", "heals", "hael", "heal", "helers" }, role = true, guard = "recruit" },
    ranged = { label = "远程", aliases = { "ranged dps", "rdps", "ranged", "range" }, role = true, guard = "recruit" },
    melee = { label = "近战", aliases = { "melee dps", "mdps", "melee" }, role = true, guard = "recruit" },
    lfm = { label = "队伍招人", aliases = { "looking for more", "lf5m", "lf4m", "lf3m", "lf2m", "lf1m", "lfm", "lf", "lmf", "llfm" } },
    lfg = { label = "玩家求组", aliases = { "looking for group", "lfg", "lf" } },
    wts = { label = "出售", aliases = { "want to sell", "wts" }, guard = "trade" },
    wtb = { label = "求购", aliases = { "want to buy", "buy all", "buying", "wtb", "buy" }, guard = "trade" },
    lfall = { label = "各位置都缺", aliases = { "lf all" }, guard = "recruit" },
    needall = { label = "各位置都缺", aliases = { "need all", "all", "neeed all" }, guard = "recruit" },
    need = { label = "需要", aliases = { "need", "nedd", "ned", "neeed" }, guard = "recruit" },
    minimum = { label = "最低", aliases = { "minimum", "mini", "min" }, guard = "recruit" },
    inspect = { label = "检查装备", aliases = { "inspect", "insp" }, guard = "recruit" },
    only = { label = "仅", aliases = { "only", "onlyy" }, guard = "recruit" },
    pull = { label = "开怪", aliases = { "pull" }, guard = "pull" },
    icc = { label = "冰冠堡垒", aliases = { "icecrown citadel", "icc", "lcc" }, guard = "recruit" },
    rs = { label = "红玉圣殿", aliases = { "ruby sanctum", "ruby", "rs" }, guard = "rubyraid" },
    bt = { label = "黑暗神殿", aliases = { "black temple" } },
    togc = { label = "大十字军的试炼", aliases = { "trial of the grand crusader", "togc" } },
    toc = { label = "十字军的试炼", aliases = { "trial of the crusader", "toc" }, guard = "tocraid" },
    hor = { label = "映像大厅", aliases = { "halls of reflection", "hor" }, guard = "recruit" },
    eof = { label = "寒冰牌子", aliases = { "emblem of frost", "eofs", "eof" }, guard = "advert" },
    eofrun = { label = "寒冰牌子团", aliases = { "eof run" }, guard = "advert" },
    lk = { label = "巫妖王", aliases = { "lich king", "lk" }, guard = "recruit" },
    sindy = { label = "辛达苟萨", aliases = { "sindragosa", "sindy", "sindi" }, guard = "sindy" },
    hc = { label = "英雄难度", aliases = { "heroic", "hc", "h" }, guard = "recruit" },
    nm = { label = "普通难度", aliases = { "normal", "nm" }, guard = "recruit" },
    n = { label = "普通难度", aliases = { "n" }, guard = "difficulty" },
    gs = { label = "装备评分", aliases = { "gearscore", "gear score", "gs" }, guard = "recruit" },
    boe = { label = "装绑", aliases = { "bind on equip", "boes", "boe", "boee" }, guard = "advert" },
    sfs = { label = "影霜碎片", aliases = { "shadowfrost shards", "sfs" } },
    primo = { label = "源生萨隆邪铁", aliases = { "primordial saronite", "primos", "primo", "primordials" }, guard = "advert" },
    sts = { label = "锐锋暮光龙鳞", aliases = { "sharpened twilight scale", "sts" }, guard = "advert" },
    reserved = { label = "不分", aliases = { "reserved", "reserve", "resv", "rezz", "ress", "res", "rez", "rress", "rezerved" }, guard = "reserve" },
    tocreserved = { label = "装绑物品、十字军宝珠和专业图纸不分",
        aliases = { "b+o+p ress", "b+o+p res", "b+o+p reserved",
            "b + o + p ress", "b + o + p res", "b + o + p reserved",
            "b+o+p boe ress", "b+o+p boe res", "b+o+p boe reserved", "bop ress", "bop res", "bop reserved", "b.o.p ress", "b.o.p res", "b.o.p reserved", "b+p+o=res", "b+p+o ress", "b+p+o res" }, guard = "tocloot" },
    noreserved = { label = "无预留", aliases = { "nothing reserve", "nothing reserved", "nothing resss", "nothing ress", "nothing res",
        "no items reserved", "no loot reserved", "no res", "no ress", "no reserved", "noth res", "noth ress", "noting ress", "noting res", "nothing rress" }, guard = "lootnegative" },
    tmog = { label = "幻化外观", aliases = { "transmog", "tmog", "mog" } },
    achievement = { label = "成就", aliases = { "achievement", "achievements", "achiv", "achviv", "achievments", "achiev", "achie", "achi", "ach", "acho", "achive", "achieve", "achivement", "achivment", "acihvment", "achv", "achvie", "achivs", "acv" }, guard = "advert" },
    linkachievement = { label = "发成就", aliases = { "link achievement", "link achievements", "link achviv", "link achiv", "link achiev", "link achie", "link achi", "link achive", "link achieve", "link achivement", "link me your achive", "link me your achievement", "link me your achiv", "link me ur achive", "link me ur achiv", "link acv" }, guard = "recruit" },
    solotank = { label = "单坦克", aliases = { "solo tank" }, guard = "recruit" },
    soloheal = { label = "单治疗", aliases = { "solo heal" }, guard = "recruit" },
    fullrun = { label = "全程团", aliases = { "full runs", "full run" }, guard = "recruit" },
    altrun = { label = "小号团", aliases = { "alt run", "alt runs" }, guard = "recruit" },
    freshrun = { label = "从头开打的团", aliases = { "fresh run", "fresh" }, guard = "recruit" },
    fastrun = { label = "速刷团", aliases = { "speed runs", "speed run", "fast runs", "fast run", "quick runs", "quick run", "fast clear", "fast" }, guard = "recruit" },
    lastspot = { label = "最后一个位置", aliases = { "lasts spots", "last slots", "last stop", "last spot", "last slot" }, guard = "recruit" },
    lastneed = { label = "最后还缺", aliases = { "last" }, guard = "lastneed" },
    restdps = { label = "其余招输出", aliases = { "rest dps" }, guard = "recruit" },
    bane = { label = "10人英雄巫妖王成就团", aliases = { "bane run" }, guard = "bane" },
    spec = { label = "专精", aliases = { "spec" }, guard = "recruit" },
    forsale = { label = "出售", aliases = { "for sale", "for sell", "on sell" }, guard = "advert" },
    discordmandatory = { label = "必须用Discord", aliases = { "discord mandatory", "discord required", "discord req" }, guard = "recruit" },
    raidtime = { label = "团队活动时间", aliases = { "raid time is", "raid time" }, guard = "recruit" },
    experienced = { label = "有经验的玩家", aliases = { "experienced players" }, guard = "recruit" },
    servertime = { label = "服务器时间", aliases = { "server time", "svt", "st" }, guard = "servertime" },
    quest = { label = "任务", aliases = { "quest" }, guard = "recruit" },
    onboss = { label = "首领掉落", aliases = { "on boss", "on-boss" }, guard = "bossloot" },
    whisper = { label = "私聊我", aliases = { "/w me", "w/me", "w.me", "whisper me", "whisp me", "wisp me", "wiss me", "wis me", "whis me", "wisper", "dm me", "pst", "wisper me" }, guard = "advert" },
    whispergear = { label = "私聊发装备评分", aliases = { "w/gs" }, guard = "recruit" },
    whisperinvite = { label = "私聊申请进组", aliases = { "whisp for inv", "whisper for inv", "pst for inv" }, guard = "recruit" },
    whisperrequest = { label = "私聊发", aliases = { "/w", "w/", "wisp", "whisp", "wis", "whis", "wiss", "w", "whisper" }, guard = "whisperrequest" },
    guildrecruit = { label = "公会招募", aliases = { "guild recruiting", "guild is recruiting" } },
    activeplayers = { label = "活跃玩家", aliases = { "active players" }, guard = "recruit" },
    characters = { label = "角色", aliases = { "characters", "chars", "character" }, guard = "recruit" },
    atleast = { label = "至少", aliases = { "at least", "atleast" }, guard = "recruit" },
    perweek = { label = "每周", aliases = { "per week", "every week" }, guard = "recruit" },
    raidactivity = { label = "团队活动", aliases = { "raids activity", "raid activity" }, guard = "recruit" },
    applyguild = { label = "申请加入公会", aliases = { "apply for guild" }, guard = "recruit" },
    dkp = { label = "DKP 积分分配", aliases = { "dkp" } },
    guildverb = { label = "招募", aliases = { "we are recruiting", "is recruiting", "recruiting", "seeking", "looking for raiders" }, guard = "guild" },
    endguild = { label = "高端公会", aliases = { "end-game guild", "end game guild" }, guard = "guild" },
    internationalguild = { label = "国际高端公会", aliases = { "international end game guild" }, guard = "guild" },
    progressionguild = { label = "PvE开荒公会", aliases = { "progression pve guild" }, guard = "guild" },
    skilledmembers = { label = "熟练玩家", aliases = { "skilled members", "skilled players" }, guard = "guild" },
    currentraids = { label = "当前团本安排", aliases = { "current raids" }, guard = "guild" },
    alts = { label = "小号", aliases = { "alts" }, guard = "recruit" },
    goodgeared = { label = "装备良好", aliases = { "good geared" }, guard = "recruit" },
    guildrun = { label = "公会团", aliases = { "guild run" }, guard = "recruit" },
    fullclear = { label = "通关全本", aliases = { "full clear" }, guard = "recruit" },
    clearing = { label = "通关", aliases = { "clearing" }, guard = "recruit" },
    weekly = { label = "周常任务", aliases = { "weekly", "weekley" }, guard = "weekly" },
    guildweekly = { label = "每周", aliases = { "weekly" }, guard = "guildweekly" },
    lod = { label = "25人英雄巫妖王（黎明之光）", aliases = { "light of dawn", "lods", "lod", "the light of dawn" }, guard = "raidachievement", category = "首领/icc" },
    iccbane = { label = "10人英雄巫妖王成就", aliases = { "bane of the fallen king", "bane" }, guard = "iccbane", category = "首领/icc" },
    immortality = { label = "不灭成就", aliases = { "immortality" }, guard = "tocachievement" },
    immortal = { label = "不朽者成就", aliases = { "immortal", "undying" }, guard = "naxxachievement" },
    boosts = { label = "代刷服务", aliases = { "boost services", "boosting", "boost" }, guard = "raidtrade" },
    cheapboost = { label = "低价代刷", aliases = { "cheap boost" }, guard = "raidtrade" },
    goldonly = { label = "仅收金币", aliases = { "for gold only" }, guard = "raidtrade" },
    forgold = { label = "以金币结算", aliases = { "for gold" }, guard = "raidtrade" },
    allloot = { label = "全部掉落", aliases = { "all loot" }, guard = "raidtrade" },
    mount = { label = "坐骑", aliases = { "mounts", "mount" }, guard = "advert" },
    moreraidinfo = { label = "更多信息", aliases = { "for more info", "for more information" }, guard = "advert" },
    joindiscord = { label = "加入Discord", aliases = { "join our discord" }, guard = "advert" },
    solace = { label = "慰藉饰品", aliases = { "solace" }, guard = "solaceloot" },
    dbw = { label = "死神的意志", aliases = { "deathbringer's will", "dbw" }, guard = "advert" },
    umbrage = { label = "荫影臂甲", aliases = { "umbrage armbands", "umbrage" }, guard = "trade" },
    trinketfarm = { label = "刷饰品", aliases = { "trinket farm" }, guard = "recruit" },
    arenaask = { label = "寻找竞技场队友", aliases = { "lf arena partner", "looking for arena partner", "looking for a 2v2 partner", "looking for 2v2 partner", "lf 2 v2 partner", "lf 2 vs2 partner", "lf 3 v3 partner", "lf 2 v2", "lf 2 vs2", "lf 3 v3", "lf 5 v5", "lf 2 s", "lf 3 s", "lf 5 s", "2 vs 2", "3 vs 3", "5 vs 5", "lf partner", "lf arena parner", "lf arena" }, guard = "arena" },
    bis = { label = "毕业装", aliases = { "best in slot", "bis", "biss" }, guard = "advert" },
    arenagames = { label = "场", aliases = { "games", "arenas", "arena" }, guard = "arena" },
    arenamore = { label = "或更多", aliases = { "or more" }, guard = "arena" },
    sunwell = { label = "太阳之井高地", aliases = { "sunwell plateau", "sunwell" }, guard = "recruit", category = "副本" },
    valfragment = { label = "瓦兰奈尔的碎片", aliases = { "fragment of val'anyr", "frags", "frag" }, guard = "ulduarloot" },
    fullhc = { label = "全英雄团", aliases = { "full hc runs", "full hc run", "full hc" }, guard = "recruit" },
    lastdps = { label = "最后一个输出位置", aliases = { "last dps" }, guard = "shortrecruit" },
    lasthealer = { label = "最后一个治疗位置", aliases = { "last healer", "last heal" }, guard = "shortrecruit" },
    lasttank = { label = "最后一个坦克位置", aliases = { "last tank" }, guard = "shortrecruit" },
    whisperinfo = { label = "私聊获取更多信息", aliases = { "wisp for more info", "whisp for more info" }, guard = "advert" },
    whisperaninvite = { label = "私聊申请进组", aliases = { "whisp me for an invite", "whisper me for an invite" }, guard = "guild" },
    gems = { label = "宝石", aliases = { "gems", "gem", "sockets", "socket" }, guard = "recruit" },
    guildroster = { label = "招募玩家补齐团队阵容", aliases = { "looking for players to fill our raid roster", "looking for players to fill raid roster" }, guard = "guild" },
    allclasses = { label = "各职业都招", aliases = { "need all classes" }, guard = "recruit" },
    whispermore = { label = "私聊我了解详情", aliases = { "/w me for more info", "whisper me for more info" }, guard = "advert" },
    casterback = { label = "法系披风", aliases = { "back spell", "spell back" }, guard = "rubybackloot" },
    memorial = { label = "达拉然纪念碑", aliases = { "memo" }, guard = "memorial" },
    paladin = { label = "圣骑士", aliases = { "paladin", "pally", "pala", "pal", "paladins" }, guard = "roster", role = true },
    druid = { label = "德鲁伊", aliases = { "druid", "dudu", "druids" }, guard = "roster", role = true },
    priest = { label = "牧师", aliases = { "priest", "prist", "pirest", "priests" }, guard = "roster", role = true },
    combatrogue = { label = "战斗贼", aliases = { "combat rogue", "combatrogue", "crogue", "crog", "combat rogues" }, guard = "roster", role = true },
    feralcat = { label = "猫德", aliases = { "feral cat", "cat druid", "cat", "dcat", "cat druids" }, guard = "roster", role = true },
    feral = { label = "野德", aliases = { "feral druid", "feral", "feral druids" }, guard = "roster", role = true },
    fmagerole = { label = "法师（Fmage）", aliases = { "fmage" }, guard = "roster", role = true },
    dlockrole = { label = "术士（Dlock）", aliases = { "dlock" }, guard = "roster", role = true },
    lookingrole = { label = "寻找", aliases = { "looking for" }, guard = "lookrole" },
    lookingall = { label = "各位置都缺", aliases = { "looking for all" }, guard = "lookrole" },
    seekguild = { label = "寻找公会", aliases = { "looking for a guild", "looking for guild", "lf raiding guild", "lf raid guild", "lf leveling guild", "lf guild" }, guard = "guildseek" },
    enchantgear = { label = "附魔", aliases = { "enchant", "enchants", "ench", "enchat", "encant", "enchats" }, guard = "raidrequirement" },
    fullgem = { label = "宝石齐全", aliases = { "full gem", "full gems" }, guard = "raidrequirement" },
    fullgemsenchant = { label = "宝石和附魔齐全", aliases = { "full gem and enchant", "full gem and ench", "gem enchat full" }, guard = "raidrequirement" },
    semiguild = { label = "半公会团", aliases = { "half guild run", "semi guild run", "semi-grun", "semi grun", "semigrun" }, guard = "raidrequirement" },
    classrequest = { label = "职业", aliases = { "classes", "class" }, guard = "roster" },
    rolerequest = { label = "职责", aliases = { "role" }, guard = "roster" },
    randomhealer = { label = "任意治疗职业", aliases = { "random heal" }, guard = "roster" },
    fewdps = { label = "少量输出", aliases = { "few dps" }, guard = "roster" },
    grouploot = { label = "队伍分配", aliases = { "group loot", "grp loot", "grouploot" }, guard = "raidrequirement" },
    maxboss = { label = "多打Boss", aliases = { "going max boss", "max boss" }, guard = "raidrequirement" },
    havetime = { label = "需预留时间", aliases = { "must have time", "have time" }, guard = "raidrequirement" },
    replaceafk = { label = "替换AFK", aliases = { "replace afk", "replase afk ppl", "replace afk ppl" }, guard = "raidrequirement" },
    replaceoffline = { label = "替换离线成员", aliases = { "repalce offline", "replace offline" }, guard = "raidrequirement" },
    readygo = { label = "准备出发", aliases = { "rdy to go", "ready to go" }, guard = "raidrequirement" },
    invitation = { label = "邀请入组", aliases = { "for invite", "for inv", "inv" }, guard = "invite" },
    achievementrequired = { label = "无成就不组", aliases = { "no achiv = no inv", "no achi = no inv", "no achievement no inv", "no achiev no inv", "no achiv no inv", "no achi no inv" }, guard = "raidrequirement" },
    shamanhands = { label = "萨满手套", aliases = { "shaman hands" }, guard = "roleloot" },
    guildmaingroup = { label = "主力团", aliases = { "main runs" }, guard = "guild" },
    guildhosts = { label = "组织", aliases = { "we host" }, guard = "guild" },
    guildadditional = { label = "组建额外团队", aliases = { "is forming additional raid groupsh", "ish forming additional raid groupsh", "is forming additional raid groups" }, guard = "guild" },
    guildenglish = { label = "使用英语沟通", aliases = { "english-speaking" }, guard = "guild" },
    guildlootsystem = { label = "分配方式", aliases = { "loot system", "loot" }, guard = "guildlootsystem" },
    guilddkpsystem = { label = "DKP分配", aliases = { "we use dkp system" }, guard = "guild" },
    guildcommunity = { label = "加入我们的公会", aliases = { "to be part of our community" }, guard = "guild" },
    guildis = { label = "是", aliases = { "is a" }, guard = "guild" },
    arena_rating = { label = "竞技场等级", aliases = { "rating", "reiting" }, guard = "arena" },
    arenaexperienced = { label = "有经验的", aliases = { "experienced" }, guard = "advert" },
    needhelp = { label = "需要帮忙", aliases = { "need help" } },
    pleasehelp = { label = "请帮我", aliases = { "please help me" } },
    tradecod = { label = "货到付款", aliases = { "cash on delivery", "cod" }, guard = "trade" },
    tradecodsend = { label = "货到付款邮寄给我", aliases = { "cod to me", "send them by post(cod) to me" }, guard = "trade" },
    tradegreenblue = { label = "绿装／蓝装", aliases = { "green/blue items" }, guard = "trade" },
    tradeperstack = { label = "每组", aliases = { "per stack" }, guard = "trade" },
    tradeperitem = { label = "每件", aliases = { "per item" }, guard = "trade" },
    tradecobalt = { label = "钴锭", aliases = { "kobaltbars", "cobalt bars" }, guard = "trade" },
    tradenethercloth = { label = "灵纹布", aliases = { "netherweave cloth" }, guard = "trade" },
    tradecheaper = { label = "比拍卖行便宜", aliases = { "cheaper than ah" }, guard = "trade" },
    tradelevel = { label = "等级", aliases = { "level", "lvl" }, guard = "level" },
    connectand = { label = "和", aliases = { "and" }, guard = "roster" },
    connectfor = { label = "打", aliases = { "for" }, guard = "forraid" },
    connector = { label = "或", aliases = { "or" }, guard = "roster" },
    whisperforinfo = { label = "私聊了解详情", aliases = { "dm for info" }, guard = "guild" },
    gunshipgs = { label = "炮艇战", aliases = { "gunshiphc", "gs" }, guard = "gunshipgs", category = "首领/icc" },
    seekenchant = { label = "寻找附魔师", aliases = { "lf enchant", "lf enchanter" } },
    eot = { label = "凯旋牌子", aliases = { "emblem of triumph", "eots", "eot" }, guard = "advert" },
    gold = { label = "金币", aliases = { "gold", "g" }, guard = "advert" },
    goldore = { label = "金矿石", aliases = { "gold ore", "gold ores" } },
    goldbar = { label = "金锭", aliases = { "gold bar", "gold bars" } },
    coins = { label = "商城币", aliases = { "coins", "coin", "conis" }, guard = "advert" },
    flyriding = { label = "飞行骑术", aliases = { "fly" }, guard = "advert" },
    maxed = { label = "满级", aliases = { "maxed", "max" }, guard = "advert" },
    professions = { label = "专业技能", aliases = { "professions", "profession", "proffs", "profs", "proff", "prof" }, guard = "advert" },
    dualspec = { label = "双专精", aliases = { "dual spec", "dualspec", "2 specs", "2 spec", "2specs" }, guard = "advert" },
    jc = { label = "珠宝加工", aliases = { "jewelcrafting", "jewelcraft", "jc" }, guard = "advert" },
    mining = { label = "采矿", aliases = { "mining" }, guard = "advert" },
    tailoring = { label = "裁缝", aliases = { "tailoring", "tailor" }, guard = "advert" },
    cooking = { label = "烹饪", aliases = { "cooking", "cook" }, guard = "advert" },
    fishing = { label = "钓鱼", aliases = { "fishing", "fish" }, guard = "advert" },
    firstaid = { label = "急救", aliases = { "first aid", "faid" }, guard = "advert" },
    enchantprof = { label = "附魔", aliases = { "enchanting" }, guard = "advert" },
    inscription = { label = "铭文", aliases = { "inscription" }, guard = "advert" },
    alchemy = { label = "炼金", aliases = { "alchemy", "alch" }, guard = "advert" },
    skinning = { label = "剥皮", aliases = { "skinning" }, guard = "advert" },
    blacksmithing = { label = "锻造", aliases = { "blacksmithing", "blacksmith", "blacksmhithing" }, guard = "advert" },
    engineering = { label = "工程", aliases = { "engineering", "engi", "eng" }, guard = "advert" },
    herbalism = { label = "草药", aliases = { "herbalism" }, guard = "advert" },
    ele = { label = "元素萨", aliases = { "elemental shaman", "ele shaman", "ele shamy", "ele", "ele shamans", "elemental shamans" }, role = true, guard = "ele" },
    protwarrior = { label = "防战", aliases = { "protection warrior", "prot warrior", "protection war", "prot war", "pwar", "prot warriors", "protection warriors" }, role = true, guard = "roster" },
    dongon = { label = "地下城", aliases = { "dungeon", "dungeons", "dongon" }, guard = "recruit" },
    doing = { label = "开", aliases = { "doing" }, guard = "recruit" },
    run = { label = "团", aliases = { "runs", "run", "runn" }, guard = "recruit" },
    man = { label = "人", aliases = { "man", "men", "m" }, guard = "raidsize" },
    moreplayers = { label = "人（还缺）", aliases = { "more" }, guard = "moreneeded" },
    fulltrail = { label = "全程", aliases = { "full" }, guard = "fulltrail" },
    daily = { label = "日常", aliases = { "dailies", "daily" }, guard = "recruit" },
    join = { label = "加入", aliases = { "join" }, guard = "recruit" },
    pref = { label = "优先", aliases = { "preferred", "prefe", "prefer", "pref" }, guard = "recruit" },
    andgo = { label = "人齐就走", aliases = { "and goooo", "and gooo", "and go" }, guard = "recruit" },
    dc = { label = "掉线", aliases = { "dc", "disconnect", "disconnected" }, guard = "recruit" },
    farm = { label = "刷取", aliases = { "farming", "farm" }, guard = "advert" },
    mountrun = { label = "坐骑团", aliases = { "mount run", "mount runs", "mount runn" }, guard = "recruit" },
    bosses = { label = "首领", aliases = { "bosses", "boss" }, guard = "recruit" },
    lastboss = { label = "尾王", aliases = { "last bosses", "last boss" }, guard = "recruit" },
    repfarm = { label = "声望团", aliases = { "farm rep", "rep farm", "rep farms", "rep run", "rep runs", "repfram" }, guard = "recruit" },
    rep = { label = "声望", aliases = { "reputation", "rep" }, guard = "advert" },
    invincible = { label = "无敌（坐骑）", aliases = { "invincible" }, guard = "advert" },
    bestoffer = { label = "最优价", aliases = { "best offer" }, guard = "advert" },
    giveaway = { label = "抽奖", aliases = { "giveaway", "give away" } },
    insanetitle = { label = "疯狂称号", aliases = { "insane title" }, guard = "advert" },
    rare = { label = "稀有", aliases = { "rare" }, guard = "advert" },
    pet = { label = "宠物", aliases = { "pets", "pet" }, guard = "advert" },
    farmed = { label = "已刷好", aliases = { "farmed" }, guard = "advert" },
    inclusions = { label = "附带物品", aliases = { "inclusions", "inclusion" }, guard = "advert" },
    smweapon = { label = "影之哀伤", aliases = { "shm", "sm" }, guard = "smweapon" },
    realmfirst = { label = "全服第一", aliases = { "realm first", "realmfirst", "server first" } },
    thunderfury = { label = "雷霆之怒", aliases = { "thunderfury" } },
    eternalfire = { label = "永恒之火", aliases = { "eternal fire" } },
    eternalearth = { label = "永恒大地", aliases = { "eternal earth" } },
    eternalwater = { label = "永恒之水", aliases = { "eternal water" } },
    eternalair = { label = "永恒空气", aliases = { "eternal air" } },
    eternallife = { label = "永恒生命", aliases = { "eternal life" } },
    eternalshadow = { label = "永恒暗影", aliases = { "eternal shadow" } },
    pitfarm = { label = "萨隆矿坑刷取", aliases = { "pit farm", "pit farms" }, guard = "recruit" },
    serpentshrine = { label = "毒蛇神殿", aliases = { "serpentshrine cavern", "serpentshrine", "ssc" }, guard = "recruit", category = "副本" },
    halionid = { label = "海里昂进度", aliases = { "halion id" }, guard = "recruit", category = "首领/rs" },
    cloak = { label = "披风", aliases = { "cloack", "cloak", "cape" }, guard = "cloakloot" },
    randomdps = { label = "任意输出", aliases = { "random dps" }, guard = "roster" },
    belf = { label = "血精灵", aliases = { "blood elf", "belf" }, guard = "advert" },
    dwarf = { label = "矮人", aliases = { "dwarf" }, guard = "advert" },
    humanrace = { label = "人类", aliases = { "human" }, guard = "advert" },
    nightelf = { label = "暗夜精灵", aliases = { "night elf", "nelf" }, guard = "advert" },
    draenei = { label = "德莱尼", aliases = { "draenei" }, guard = "advert" },
    gnome = { label = "侏儒", aliases = { "gnome" }, guard = "advert" },
    orc = { label = "兽人", aliases = { "orc" }, guard = "advert" },
    trollrace = { label = "巨魔", aliases = { "troll" }, guard = "advert" },
    tauren = { label = "牛头人", aliases = { "tauren" }, guard = "advert" },
    undeadrace = { label = "亡灵", aliases = { "undead" }, guard = "advert" },
    agility = { label = "敏捷", aliases = { "agility", "agi" }, guard = "advert" },
    intellectstat = { label = "智力", aliases = { "intellect", "intel", "int" }, guard = "advert" },
    stamina = { label = "耐力", aliases = { "stamina", "stam", "sta" }, guard = "advert" },
    strength = { label = "力量", aliases = { "strength", "str" }, guard = "advert" },
    spiritstat = { label = "精神", aliases = { "spirit" }, guard = "advert" },
    haste = { label = "急速", aliases = { "haste" }, guard = "advert" },
    crit = { label = "暴击", aliases = { "critical", "crit" }, guard = "advert" },
    hit = { label = "命中", aliases = { "hit" }, guard = "advert" },
    arp = { label = "护甲穿透", aliases = { "armor penetration", "armor pen", "arp" }, guard = "advert" },
    ty = { label = "谢谢", aliases = { "tysm", "thx", "tyty", "tks", "ty", "thank you", "thanks" } },
    disenchant = { label = "分解", aliases = { "disenchants", "disenchant" } },
    portal = { label = "开门", aliases = { "portals", "portal" } },
    stonard = { label = "斯通纳德", aliases = { "stonard" } },
    platearmor = { label = "板甲", aliases = { "plate" } },
    leatherarmor = { label = "皮甲", aliases = { "leather" } },
    clotharmor = { label = "布甲", aliases = { "cloth" } },
    chainarmor = { label = "锁甲", aliases = { "chain" } },
    frostboss = { label = "冰王", aliases = { "frost" }, guard = "voafrost", category = "首领/otherraid" },
    princes = { label = "血王子议会", aliases = { "princes", "prince" }, guard = "iccboss", category = "首领/icc" },
    valitria = { label = "绿龙", aliases = { "valitria", "vali" }, guard = "iccboss", category = "首领/icc" },
    iccbp = { label = "装绑+萨钢", aliases = { "b+primos", "b+primo", "b+p" }, guard = "iccboss" },
    onixya = { label = "黑龙妹", aliases = { "onixya", "onyxya" }, guard = "recruit", category = "首领/otherraid" },
    stormingcitadel = { label = "攻城拔寨", aliases = { "storming the citadel" }, category = "成就/icc" },
    valanyr = { label = "瓦兰奈尔", aliases = { "valynar", "val'anyr", "valanyr", "valnyr" } },
    req = { label = "要求", aliases = { "reqs", "req" }, guard = "recruit" },
    summon = { label = "召唤", aliases = { "summ", "summon", "sumon" }, guard = "recruit" },
    ready = { label = "就绪", aliases = { "rdy", "ready" }, guard = "recruit" },
    queue = { label = "排队", aliases = { "que", "queue" }, guard = "recruit" },
    classrun = { label = "职业团", aliases = { "class runs", "class run" }, guard = "recruit" },
    trinket = { label = "饰品", aliases = { "trinkets", "trinket", "trincks" }, guard = "advert" },
    weapon = { label = "武器", aliases = { "weapons", "weapon", "wepon" }, guard = "advert" },
    titles = { label = "头衔", aliases = { "titles", "title" }, guard = "advert" },
    brain = { label = "带脑子", aliases = { "brain" }, guard = "recruit" },
    hellfire = { label = "地狱火半岛", aliases = { "hellfire" } },
    atm = { label = "现在", aliases = { "atm" }, guard = "recruit" },
    warglaive = { label = "蛋刀", aliases = { "warglaives", "warglaive", "azzinot" }, guard = "recruit" },
    offhand = { label = "副手", aliases = { "offhand", "off-hand", "off hand" }, guard = "recruit" },
    must = { label = "必须", aliases = { "must have", "must wis", "must be", "must" }, guard = "raidrequirement" },
    free = { label = "免费", aliases = { "free" }, guard = "recruit" },
    customized = { label = "定制团", aliases = { "customized runs", "customized run", "custom runs", "custom run" }, guard = "recruit" },
    freeroll = { label = "免费掷点", aliases = { "free roll", "free rolls" }, guard = "recruit" },
    holypriest = { label = "神牧", aliases = { "holy priest", "holypriest", "hpriest", "holy priests" }, role = true, guard = "roster" },
    feralbear = { label = "熊T", aliases = { "bear druid", "feral tank", "bear", "bear druids", "feral tanks" }, role = true, guard = "bearrole" },
    protection = { label = "防护专精", aliases = { "prot" }, role = true, guard = "roster" },
    cts = { label = "焦黑暮光龙鳞", aliases = { "charred twilight scale", "cts" }, guard = "advert" },
    muradinspyglass = { label = "穆拉丁的望远镜", aliases = { "muradin's spyglass", "muradins spyglass", "spyglass" }, guard = "iccboss" },
    tocboepatterns = { label = "装绑物品和专业图纸不分", aliases = { "boe p ress", "boe p res", "boe+p ress", "boe+p res" }, guard = "tocloot" },
    whisperscore = { label = "私聊发装备评分", aliases = { "/w me with gs" }, guard = "recruit" },
    tradeoffer = { label = "私聊报价", aliases = { "/w me offer", "/w offer" }, guard = "trade" },
    tradeall = { label = "有多少收多少", aliases = { "all you have" }, guard = "trade" },
    unlimited = { label = "不限量", aliases = { "unlimited" }, guard = "trade" },
    tradeanytime = { label = "随时交易", aliases = { "trade anytime" }, guard = "trade" },
    goldperstack = { label = "金币/组", aliases = { "g/stack" }, guard = "trade" },
    legslot = { label = "护腿", aliases = { "pants", "leg", "legs" }, guard = "advert" },
    ourbase = { label = "我方基地", aliases = { "our base" }, guard = "groupflow" },
    insideourbase = { label = "我方基地内部", aliases = { "inside our base" }, guard = "groupflow" },
    carrybombs = { label = "把炸弹送到对方城门", aliases = { "carry bombs to their gate" }, guard = "groupflow" },
    killasap = { label = "尽快击杀", aliases = { "kill asap" }, guard = "groupflow" },
    blackwing = { label = "黑翼之巢", aliases = { "blackwing lair", "black wing lair", "bwl" }, guard = "recruit", category = "副本" },
    pts = { label = "石化暮光龙鳞", aliases = { "petrified twilight scale", "pts" }, guard = "advert" },
    wfs = { label = "密语尖牙颅骨", aliases = { "whispering fanged skull", "wfs" }, guard = "advert" },
    stackquantity = { label = "组", aliases = { "stacks", "stack" }, guard = "trade" },
    freefaction = { label = "免费转阵营", aliases = { "free faction change" }, guard = "trade" },
    renamecharacter = { label = "角色改名", aliases = { "character rename" }, guard = "trade" },
    helprequest = { label = "请帮忙", aliases = { "please help", "plz help" } },
    raidreset = { label = "重置前", aliases = { "before reset" }, guard = "raidrequirement" },
    nextday = { label = "明天重置", aliases = { "reset tomorrow" }, guard = "arena" },
}

-- BEGIN GENERATED WLK LEXICON
-- Source: src/translations/chat_wlk_lexicon.json; regenerate with tools/build_wlk_chat_lexicon.py.
P.concepts["wlk_anti_magic_shell"] = { label = "反魔法护罩", aliases = { "anti-magic shell", "ams" }, wlk = true, rules = { ["anti-magic shell"] = "name", ["ams"] = "skill" }, owner = "dk", category = "职业技能/dk" }
P.concepts["wlk_anti_magic_zone"] = { label = "反魔法领域", aliases = { "anti-magic zone", "amz" }, wlk = true, rules = { ["anti-magic zone"] = "name", ["amz"] = "skill" }, owner = "dk", category = "职业技能/dk" }
P.concepts["wlk_icebound_fortitude"] = { label = "冰封之韧", aliases = { "icebound fortitude", "ibf" }, wlk = true, rules = { ["icebound fortitude"] = "name", ["ibf"] = "skill" }, owner = "dk", category = "职业技能/dk" }
P.concepts["wlk_death_grip"] = { label = "死亡之握", aliases = { "death grip", "grip" }, wlk = true, rules = { ["death grip"] = "name", ["grip"] = "skill" }, owner = "dk", category = "职业技能/dk" }
P.concepts["wlk_mind_freeze"] = { label = "心灵冰冻", aliases = { "mind freeze", "mf" }, wlk = true, rules = { ["mind freeze"] = "name", ["mf"] = "owner" }, owner = "dk", category = "职业技能/dk" }
P.concepts["wlk_strangulate"] = { label = "绞袭", aliases = { "strangulate", "strang" }, wlk = true, rules = { ["strangulate"] = "game", ["strang"] = "skill" }, owner = "dk", category = "职业技能/dk" }
P.concepts["wlk_death_and_decay"] = { label = "枯萎凋零", aliases = { "death and decay", "dnd", "d&d" }, wlk = true, rules = { ["death and decay"] = "name", ["dnd"] = "owner", ["d&d"] = "owner" }, owner = "dk", category = "职业技能/dk" }
P.concepts["wlk_rune_strike"] = { label = "符文打击", aliases = { "rune strike", "rs" }, wlk = true, rules = { ["rune strike"] = "name", ["rs"] = "owner" }, owner = "dk", category = "职业技能/dk" }
P.concepts["wlk_death_strike"] = { label = "灵界打击", aliases = { "death strike", "ds" }, wlk = true, rules = { ["death strike"] = "name", ["ds"] = "owner" }, owner = "dk", category = "职业技能/dk" }
P.concepts["wlk_plague_strike"] = { label = "暗影打击", aliases = { "plague strike", "ps" }, wlk = true, rules = { ["plague strike"] = "name", ["ps"] = "owner" }, owner = "dk", category = "职业技能/dk" }
P.concepts["wlk_heart_strike"] = { label = "心脏打击", aliases = { "heart strike", "hs" }, wlk = true, rules = { ["heart strike"] = "name", ["hs"] = "owner" }, owner = "dk", category = "职业技能/dk" }
P.concepts["wlk_icy_touch"] = { label = "冰冷触摸", aliases = { "icy touch", "it" }, wlk = true, rules = { ["icy touch"] = "name", ["it"] = "ownerupper" }, owner = "dk", category = "职业技能/dk" }
P.concepts["wlk_vampiric_blood"] = { label = "吸血鬼之血", aliases = { "vampiric blood", "vb" }, wlk = true, rules = { ["vampiric blood"] = "name", ["vb"] = "owner" }, owner = "dk", category = "职业技能/dk" }
P.concepts["wlk_rune_tap"] = { label = "符文分流", aliases = { "rune tap", "rt" }, wlk = true, rules = { ["rune tap"] = "name", ["rt"] = "owner" }, owner = "dk", category = "职业技能/dk" }
P.concepts["wlk_raise_ally"] = { label = "复活盟友", aliases = { "raise ally" }, wlk = true, rules = { ["raise ally"] = "name" }, owner = "dk", category = "职业技能/dk" }
P.concepts["wlk_army_of_the_dead"] = { label = "亡者大军", aliases = { "army of the dead", "aotd" }, wlk = true, rules = { ["army of the dead"] = "name", ["aotd"] = "skill" }, owner = "dk", category = "职业技能/dk" }
P.concepts["wlk_empower_rune_weapon"] = { label = "符文武器增效", aliases = { "empower rune weapon", "erw" }, wlk = true, rules = { ["empower rune weapon"] = "name", ["erw"] = "skill" }, owner = "dk", category = "职业技能/dk" }
P.concepts["wlk_bone_shield"] = { label = "白骨之盾", aliases = { "bone shield" }, wlk = true, rules = { ["bone shield"] = "name" }, owner = "dk", category = "职业技能/dk" }
P.concepts["wlk_hysteria"] = { label = "狂乱", aliases = { "hysteria" }, wlk = true, rules = { ["hysteria"] = "game" }, owner = "dk", category = "职业技能/dk" }
P.concepts["wlk_scourge_strike"] = { label = "天灾打击", aliases = { "scourge strike", "ss" }, wlk = true, rules = { ["scourge strike"] = "name", ["ss"] = "owner" }, owner = "dk", category = "职业技能/dk" }
P.concepts["wlk_death_coil_dk"] = { label = "凋零缠绕", aliases = { "death coil", "dc" }, wlk = true, rules = { ["death coil"] = "owner", ["dc"] = "owner" }, owner = "dk", category = "职业技能/dk" }
P.concepts["wlk_chains_of_ice"] = { label = "寒冰锁链", aliases = { "chains of ice", "coi" }, wlk = true, rules = { ["chains of ice"] = "name", ["coi"] = "skill" }, owner = "dk", category = "职业技能/dk" }
P.concepts["wlk_innervate"] = { label = "激活", aliases = { "innervate", "innerv" }, wlk = true, rules = { ["innervate"] = "game", ["innerv"] = "skill" }, owner = "druid", category = "职业技能/druid" }
P.concepts["wlk_rebirth"] = { label = "战复", aliases = { "rebirth", "bress", "cress" }, wlk = true, rules = { ["rebirth"] = "game", ["bress"] = "skill", ["cress"] = "skill" }, owner = "druid", category = "职业技能/druid" }
P.concepts["wlk_barkskin"] = { label = "树皮术", aliases = { "barkskin" }, wlk = true, rules = { ["barkskin"] = "game" }, owner = "druid", category = "职业技能/druid" }
P.concepts["wlk_survival_instincts"] = { label = "生存本能", aliases = { "survival instincts", "si" }, wlk = true, rules = { ["survival instincts"] = "name", ["si"] = "owner" }, owner = "druid", category = "职业技能/druid" }
P.concepts["wlk_frenzied_regeneration"] = { label = "狂暴回复", aliases = { "frenzied regeneration" }, wlk = true, rules = { ["frenzied regeneration"] = "name" }, owner = "druid", category = "职业技能/druid" }
P.concepts["wlk_nature_s_swiftness"] = { label = "自然迅捷", aliases = { "nature's swiftness", "ns" }, wlk = true, rules = { ["nature's swiftness"] = "name", ["ns"] = "owner" }, owner = "druid/shaman", category = "职业技能/druid" }
P.concepts["wlk_tranquility"] = { label = "宁静", aliases = { "tranquility", "tranq" }, wlk = true, rules = { ["tranquility"] = "game", ["tranq"] = "skill" }, owner = "druid", category = "职业技能/druid" }
P.concepts["wlk_cyclone"] = { label = "旋风", aliases = { "cyclone", "clone" }, wlk = true, rules = { ["cyclone"] = "game", ["clone"] = "skill" }, owner = "druid", category = "职业技能/druid" }
P.concepts["wlk_entangling_roots"] = { label = "纠缠根须", aliases = { "entangling roots" }, wlk = true, rules = { ["entangling roots"] = "name" }, owner = "druid", category = "职业技能/druid" }
P.concepts["wlk_hibernate"] = { label = "休眠", aliases = { "hibernate" }, wlk = true, rules = { ["hibernate"] = "game" }, owner = "druid", category = "职业技能/druid" }
P.concepts["wlk_faerie_fire"] = { label = "精灵之火", aliases = { "faerie fire", "ff" }, wlk = true, rules = { ["faerie fire"] = "name", ["ff"] = "owner" }, owner = "druid", category = "职业技能/druid" }
P.concepts["wlk_typhoon"] = { label = "台风", aliases = { "typhoon" }, wlk = true, rules = { ["typhoon"] = "game" }, owner = "druid", category = "职业技能/druid" }
P.concepts["wlk_wild_growth"] = { label = "野性成长", aliases = { "wild growth", "wg" }, wlk = true, rules = { ["wild growth"] = "name", ["wg"] = "owner" }, owner = "druid", category = "职业技能/druid" }
P.concepts["wlk_rejuvenation"] = { label = "回春术", aliases = { "rejuvenation", "rejuv" }, wlk = true, rules = { ["rejuvenation"] = "game", ["rejuv"] = "skill" }, owner = "druid", category = "职业技能/druid" }
P.concepts["wlk_regrowth"] = { label = "愈合", aliases = { "regrowth" }, wlk = true, rules = { ["regrowth"] = "game" }, owner = "druid", category = "职业技能/druid" }
P.concepts["wlk_lifebloom"] = { label = "生命绽放", aliases = { "lifebloom" }, wlk = true, rules = { ["lifebloom"] = "game" }, owner = "druid", category = "职业技能/druid" }
P.concepts["wlk_swiftmend"] = { label = "迅捷治愈", aliases = { "swiftmend" }, wlk = true, rules = { ["swiftmend"] = "game" }, owner = "druid", category = "职业技能/druid" }
P.concepts["wlk_starfall"] = { label = "星辰坠落", aliases = { "starfall" }, wlk = true, rules = { ["starfall"] = "game" }, owner = "druid", category = "职业技能/druid" }
P.concepts["wlk_berserk"] = { label = "狂暴", aliases = { "berserk" }, wlk = true, rules = { ["berserk"] = "game" }, owner = "druid", category = "职业技能/druid" }
P.concepts["wlk_savage_roar"] = { label = "野蛮咆哮", aliases = { "savage roar", "sr" }, wlk = true, rules = { ["savage roar"] = "name", ["sr"] = "owner" }, owner = "druid", category = "职业技能/druid" }
P.concepts["wlk_tiger_s_fury"] = { label = "猛虎之怒", aliases = { "tiger's fury", "tf" }, wlk = true, rules = { ["tiger's fury"] = "name", ["tf"] = "owner" }, owner = "druid", category = "职业技能/druid" }
P.concepts["wlk_predator_s_swiftness"] = { label = "掠食者的迅捷", aliases = { "predator's swiftness", "predatory swiftness", "ps" }, wlk = true, rules = { ["predator's swiftness"] = "name", ["predatory swiftness"] = "skill", ["ps"] = "owner" }, owner = "druid", category = "职业技能/druid" }
P.concepts["wlk_misdirection"] = { label = "误导", aliases = { "misdirection", "md" }, wlk = true, rules = { ["misdirection"] = "game", ["md"] = "owner" }, owner = "hunter", category = "职业技能/hunter" }
P.concepts["wlk_feign_death"] = { label = "假死", aliases = { "feign death", "fd" }, wlk = true, rules = { ["feign death"] = "name", ["fd"] = "owner" }, owner = "hunter", category = "职业技能/hunter" }
P.concepts["wlk_deterrence"] = { label = "威慑", aliases = { "deterrence", "dt" }, wlk = true, rules = { ["deterrence"] = "game", ["dt"] = "owner" }, owner = "hunter", category = "职业技能/hunter" }
P.concepts["wlk_disengage"] = { label = "逃脱", aliases = { "disengage", "de" }, wlk = true, rules = { ["disengage"] = "game", ["de"] = "owner" }, owner = "hunter", category = "职业技能/hunter" }
P.concepts["wlk_tranquilizing_shot"] = { label = "宁神射击", aliases = { "tranquilizing shot", "ts" }, wlk = true, rules = { ["tranquilizing shot"] = "name", ["ts"] = "owner" }, owner = "hunter", category = "职业技能/hunter" }
P.concepts["wlk_silencing_shot"] = { label = "沉默射击", aliases = { "silencing shot", "ss" }, wlk = true, rules = { ["silencing shot"] = "name", ["ss"] = "owner" }, owner = "hunter", category = "职业技能/hunter" }
P.concepts["wlk_distracting_shot"] = { label = "扰乱射击", aliases = { "distracting shot", "ds" }, wlk = true, rules = { ["distracting shot"] = "name", ["ds"] = "owner" }, owner = "hunter", category = "职业技能/hunter" }
P.concepts["wlk_scatter_shot"] = { label = "驱散射击", aliases = { "scatter shot", "sc" }, wlk = true, rules = { ["scatter shot"] = "name", ["sc"] = "owner" }, owner = "hunter", category = "职业技能/hunter" }
P.concepts["wlk_master_s_call"] = { label = "主人的召唤", aliases = { "master's call", "mc" }, wlk = true, rules = { ["master's call"] = "name", ["mc"] = "owner" }, owner = "hunter", category = "职业技能/hunter" }
P.concepts["wlk_freezing_trap"] = { label = "冰冻陷阱", aliases = { "freezing trap" }, wlk = true, rules = { ["freezing trap"] = "name" }, owner = "hunter", category = "职业技能/hunter" }
P.concepts["wlk_freezing_arrow"] = { label = "冰冻之箭", aliases = { "freezing arrow", "fa" }, wlk = true, rules = { ["freezing arrow"] = "name", ["fa"] = "owner" }, owner = "hunter", category = "职业技能/hunter" }
P.concepts["wlk_frost_trap"] = { label = "冰霜陷阱", aliases = { "frost trap" }, wlk = true, rules = { ["frost trap"] = "name" }, owner = "hunter", category = "职业技能/hunter" }
P.concepts["wlk_explosive_trap"] = { label = "爆炸陷阱", aliases = { "explosive trap", "et" }, wlk = true, rules = { ["explosive trap"] = "name", ["et"] = "owner" }, owner = "hunter", category = "职业技能/hunter" }
P.concepts["wlk_rapid_fire"] = { label = "快速射击", aliases = { "rapid fire", "rf" }, wlk = true, rules = { ["rapid fire"] = "name", ["rf"] = "owner" }, owner = "hunter", category = "职业技能/hunter" }
P.concepts["wlk_aimed_shot"] = { label = "瞄准射击", aliases = { "aimed shot", "as" }, wlk = true, rules = { ["aimed shot"] = "name", ["as"] = "ownerupper" }, owner = "hunter", category = "职业技能/hunter" }
P.concepts["wlk_steady_shot"] = { label = "稳固射击", aliases = { "steady shot", "ss" }, wlk = true, rules = { ["steady shot"] = "name", ["ss"] = "owner" }, owner = "hunter", category = "职业技能/hunter" }
P.concepts["wlk_wyvern_sting"] = { label = "翼龙钉刺", aliases = { "wyvern sting", "ws" }, wlk = true, rules = { ["wyvern sting"] = "name", ["ws"] = "owner" }, owner = "hunter", category = "职业技能/hunter" }
P.concepts["wlk_counterspell"] = { label = "法术反制", aliases = { "counterspell", "cs" }, wlk = true, rules = { ["counterspell"] = "game", ["cs"] = "owner" }, owner = "mage", category = "职业技能/mage" }
P.concepts["wlk_spellsteal"] = { label = "法术吸取", aliases = { "spellsteal" }, wlk = true, rules = { ["spellsteal"] = "game" }, owner = "mage", category = "职业技能/mage" }
P.concepts["wlk_polymorph"] = { label = "变形术", aliases = { "polymorph", "sheep" }, wlk = true, rules = { ["polymorph"] = "game", ["sheep"] = "skill" }, owner = "mage", category = "职业技能/mage" }
P.concepts["wlk_ice_block"] = { label = "寒冰屏障", aliases = { "ice block", "iceblock" }, wlk = true, rules = { ["ice block"] = "name", ["iceblock"] = "skill" }, owner = "mage", category = "职业技能/mage" }
P.concepts["wlk_blink"] = { label = "闪现术", aliases = { "blink" }, wlk = true, rules = { ["blink"] = "game" }, owner = "mage", category = "职业技能/mage" }
P.concepts["wlk_evocation"] = { label = "唤醒", aliases = { "evocation", "evo" }, wlk = true, rules = { ["evocation"] = "game", ["evo"] = "skill" }, owner = "mage", category = "职业技能/mage" }
P.concepts["wlk_invisibility"] = { label = "隐形术", aliases = { "invisibility", "invis" }, wlk = true, rules = { ["invisibility"] = "game", ["invis"] = "skill" }, owner = "mage", category = "职业技能/mage" }
P.concepts["wlk_presence_of_mind"] = { label = "气定神闲", aliases = { "presence of mind", "pom" }, wlk = true, rules = { ["presence of mind"] = "name", ["pom"] = "owner" }, owner = "mage", category = "职业技能/mage" }
P.concepts["wlk_icy_veins"] = { label = "冰冷血脉", aliases = { "icy veins", "iv" }, wlk = true, rules = { ["icy veins"] = "name", ["iv"] = "owner" }, owner = "mage", category = "职业技能/mage" }
P.concepts["wlk_arcane_power"] = { label = "奥术能量", aliases = { "arcane power" }, wlk = true, rules = { ["arcane power"] = "name" }, owner = "mage", category = "职业技能/mage" }
P.concepts["wlk_cold_snap"] = { label = "急速冷却", aliases = { "cold snap", "cs" }, wlk = true, rules = { ["cold snap"] = "name", ["cs"] = "owner" }, owner = "mage", category = "职业技能/mage" }
P.concepts["wlk_remove_curse"] = { label = "解除诅咒", aliases = { "remove curse" }, wlk = true, rules = { ["remove curse"] = "name" }, owner = "mage", category = "职业技能/mage" }
P.concepts["wlk_focus_magic"] = { label = "专注魔法", aliases = { "focus magic", "fm" }, wlk = true, rules = { ["focus magic"] = "name", ["fm"] = "owner" }, owner = "mage", category = "职业技能/mage" }
P.concepts["wlk_hand_of_protection"] = { label = "保护之手", aliases = { "hand of protection", "hop", "bop" }, wlk = true, rules = { ["hand of protection"] = "name", ["hop"] = "skill", ["bop"] = "owner" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_hand_of_sacrifice"] = { label = "牺牲之手", aliases = { "hand of sacrifice", "hosac" }, wlk = true, rules = { ["hand of sacrifice"] = "name", ["hosac"] = "skill" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_hand_of_salvation"] = { label = "拯救之手", aliases = { "hand of salvation", "hosalv" }, wlk = true, rules = { ["hand of salvation"] = "name", ["hosalv"] = "skill" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_hand_of_freedom"] = { label = "自由之手", aliases = { "hand of freedom", "hof" }, wlk = true, rules = { ["hand of freedom"] = "name", ["hof"] = "skill" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_aura_mastery"] = { label = "光环掌握", aliases = { "aura mastery", "am" }, wlk = true, rules = { ["aura mastery"] = "name", ["am"] = "ownerupper" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_divine_sacrifice"] = { label = "神圣牺牲", aliases = { "divine sacrifice", "disac" }, wlk = true, rules = { ["divine sacrifice"] = "name", ["disac"] = "skill" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_divine_guardian"] = { label = "神圣守护者", aliases = { "divine guardian", "dg" }, wlk = true, rules = { ["divine guardian"] = "name", ["dg"] = "owner" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_divine_shield"] = { label = "圣盾术", aliases = { "divine shield", "bubble", "ds" }, wlk = true, rules = { ["divine shield"] = "name", ["bubble"] = "skill", ["ds"] = "owner" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_divine_protection"] = { label = "圣佑术", aliases = { "divine protection", "dp" }, wlk = true, rules = { ["divine protection"] = "name", ["dp"] = "owner" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_divine_plea"] = { label = "神圣恳求", aliases = { "divine plea", "dp" }, wlk = true, rules = { ["divine plea"] = "name", ["dp"] = "owner" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_divine_intervention"] = { label = "神圣干涉", aliases = { "divine intervention", "di" }, wlk = true, rules = { ["divine intervention"] = "name", ["di"] = "owner" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_divine_illumination"] = { label = "神启", aliases = { "divine illumination", "di" }, wlk = true, rules = { ["divine illumination"] = "name", ["di"] = "owner" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_avenging_wrath"] = { label = "复仇之怒", aliases = { "avenging wrath", "aw", "wings" }, wlk = true, rules = { ["avenging wrath"] = "name", ["aw"] = "owner", ["wings"] = "skill" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_beacon_of_light"] = { label = "圣光道标", aliases = { "beacon of light", "bol" }, wlk = true, rules = { ["beacon of light"] = "name", ["bol"] = "skill" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_sacred_shield"] = { label = "圣洁护盾", aliases = { "sacred shield", "ss" }, wlk = true, rules = { ["sacred shield"] = "name", ["ss"] = "owner" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_holy_shock"] = { label = "神圣震击", aliases = { "holy shock", "hs" }, wlk = true, rules = { ["holy shock"] = "name", ["hs"] = "owner" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_holy_shield"] = { label = "神圣之盾", aliases = { "holy shield", "hs" }, wlk = true, rules = { ["holy shield"] = "name", ["hs"] = "owner" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_holy_light"] = { label = "圣光术", aliases = { "holy light", "hl" }, wlk = true, rules = { ["holy light"] = "name", ["hl"] = "owner" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_flash_of_light"] = { label = "圣光闪现", aliases = { "flash of light", "fol" }, wlk = true, rules = { ["flash of light"] = "name", ["fol"] = "skill" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_lay_on_hands"] = { label = "圣疗术", aliases = { "lay on hands", "loh" }, wlk = true, rules = { ["lay on hands"] = "name", ["loh"] = "skill" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_cleanse"] = { label = "清洁术", aliases = { "cleanse" }, wlk = true, rules = { ["cleanse"] = "game" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_righteous_defense"] = { label = "正义防御", aliases = { "righteous defense" }, wlk = true, rules = { ["righteous defense"] = "name" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_hammer_of_justice"] = { label = "制裁之锤", aliases = { "hammer of justice", "hoj" }, wlk = true, rules = { ["hammer of justice"] = "name", ["hoj"] = "skill" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_righteous_fury"] = { label = "正义之怒", aliases = { "righteous fury" }, wlk = true, rules = { ["righteous fury"] = "name" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_divine_storm"] = { label = "神圣风暴", aliases = { "divine storm", "ds" }, wlk = true, rules = { ["divine storm"] = "name", ["ds"] = "owner" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_crusader_strike"] = { label = "十字军打击", aliases = { "crusader strike", "cs" }, wlk = true, rules = { ["crusader strike"] = "name", ["cs"] = "owner" }, owner = "paladin", category = "职业技能/paladin" }
P.concepts["wlk_pain_suppression"] = { label = "痛苦压制", aliases = { "pain suppression", "ps" }, wlk = true, rules = { ["pain suppression"] = "name", ["ps"] = "owner" }, owner = "priest", category = "职业技能/priest" }
P.concepts["wlk_guardian_spirit"] = { label = "守护之魂", aliases = { "guardian spirit", "gs" }, wlk = true, rules = { ["guardian spirit"] = "name", ["gs"] = "owner" }, owner = "priest", category = "职业技能/priest" }
P.concepts["wlk_power_infusion"] = { label = "能量灌注", aliases = { "power infusion", "pi" }, wlk = true, rules = { ["power infusion"] = "name", ["pi"] = "owner" }, owner = "priest", category = "职业技能/priest" }
P.concepts["wlk_power_word_shield"] = { label = "真言术：盾", aliases = { "power word: shield", "pws", "pw:s" }, wlk = true, rules = { ["power word: shield"] = "name", ["pws"] = "skill", ["pw:s"] = "skill" }, owner = "priest", category = "职业技能/priest" }
P.concepts["wlk_prayer_of_mending"] = { label = "愈合祷言", aliases = { "prayer of mending", "pom" }, wlk = true, rules = { ["prayer of mending"] = "name", ["pom"] = "owner" }, owner = "priest", category = "职业技能/priest" }
P.concepts["wlk_prayer_of_healing"] = { label = "治疗祷言", aliases = { "prayer of healing", "poh" }, wlk = true, rules = { ["prayer of healing"] = "name", ["poh"] = "skill" }, owner = "priest", category = "职业技能/priest" }
P.concepts["wlk_circle_of_healing"] = { label = "治疗之环", aliases = { "circle of healing", "coh" }, wlk = true, rules = { ["circle of healing"] = "name", ["coh"] = "skill" }, owner = "priest", category = "职业技能/priest" }
P.concepts["wlk_penance"] = { label = "苦修", aliases = { "penance" }, wlk = true, rules = { ["penance"] = "game" }, owner = "priest", category = "职业技能/priest" }
P.concepts["wlk_dispersion"] = { label = "消散", aliases = { "dispersion" }, wlk = true, rules = { ["dispersion"] = "game" }, owner = "priest", category = "职业技能/priest" }
P.concepts["wlk_divine_hymn"] = { label = "神圣赞美诗", aliases = { "divine hymn", "dh" }, wlk = true, rules = { ["divine hymn"] = "name", ["dh"] = "owner" }, owner = "priest", category = "职业技能/priest" }
P.concepts["wlk_hymn_of_hope"] = { label = "希望圣歌", aliases = { "hymn of hope", "hoh" }, wlk = true, rules = { ["hymn of hope"] = "name", ["hoh"] = "skill" }, owner = "priest", category = "职业技能/priest" }
P.concepts["wlk_mass_dispel"] = { label = "群体驱散", aliases = { "mass dispel", "md" }, wlk = true, rules = { ["mass dispel"] = "name", ["md"] = "owner" }, owner = "priest", category = "职业技能/priest" }
P.concepts["wlk_dispel_magic"] = { label = "驱散魔法", aliases = { "dispel magic" }, wlk = true, rules = { ["dispel magic"] = "name" }, owner = "priest", category = "职业技能/priest" }
P.concepts["wlk_shackle_undead"] = { label = "束缚亡灵", aliases = { "shackle undead" }, wlk = true, rules = { ["shackle undead"] = "name" }, owner = "priest", category = "职业技能/priest" }
P.concepts["wlk_mind_control"] = { label = "精神控制", aliases = { "mind control", "mc" }, wlk = true, rules = { ["mind control"] = "name", ["mc"] = "owner" }, owner = "priest", category = "职业技能/priest" }
P.concepts["wlk_psychic_scream"] = { label = "心灵尖啸", aliases = { "psychic scream" }, wlk = true, rules = { ["psychic scream"] = "name" }, owner = "priest", category = "职业技能/priest" }
P.concepts["wlk_fear_ward"] = { label = "防护恐惧结界", aliases = { "fear ward" }, wlk = true, rules = { ["fear ward"] = "name" }, owner = "priest", category = "职业技能/priest" }
P.concepts["wlk_devouring_plague"] = { label = "噬灵疫病", aliases = { "devouring plague" }, wlk = true, rules = { ["devouring plague"] = "name" }, owner = "priest", category = "职业技能/priest" }
P.concepts["wlk_borrowed_time"] = { label = "争分夺秒", aliases = { "borrowed time", "bt" }, wlk = true, rules = { ["borrowed time"] = "name", ["bt"] = "owner" }, owner = "priest", category = "职业技能/priest" }
P.concepts["wlk_shadow_word_pain"] = { label = "暗言术：痛", aliases = { "shadow word: pain", "swp", "sw:p" }, wlk = true, rules = { ["shadow word: pain"] = "name", ["swp"] = "skill", ["sw:p"] = "skill" }, owner = "priest", category = "职业技能/priest" }
P.concepts["wlk_shadow_word_death"] = { label = "暗言术：灭", aliases = { "shadow word: death", "swd", "sw:d" }, wlk = true, rules = { ["shadow word: death"] = "name", ["swd"] = "skill", ["sw:d"] = "skill" }, owner = "priest", category = "职业技能/priest" }
P.concepts["wlk_tricks_of_the_trade"] = { label = "嫁祸诀窍", aliases = { "tricks of the trade", "tott", "tot" }, wlk = true, rules = { ["tricks of the trade"] = "name", ["tott"] = "skill", ["tot"] = "skill" }, owner = "rogue", category = "职业技能/rogue" }
P.concepts["wlk_kick"] = { label = "脚踢", aliases = { "kick" }, wlk = true, rules = { ["kick"] = "game" }, owner = "rogue", category = "职业技能/rogue" }
P.concepts["wlk_cheap_shot"] = { label = "偷袭", aliases = { "cheap shot", "cs" }, wlk = true, rules = { ["cheap shot"] = "name", ["cs"] = "owner" }, owner = "rogue", category = "职业技能/rogue" }
P.concepts["wlk_sap"] = { label = "闷棍", aliases = { "sap" }, wlk = true, rules = { ["sap"] = "game" }, owner = "rogue", category = "职业技能/rogue" }
P.concepts["wlk_blind"] = { label = "致盲", aliases = { "blind" }, wlk = true, rules = { ["blind"] = "game" }, owner = "rogue", category = "职业技能/rogue" }
P.concepts["wlk_cloak_of_shadows"] = { label = "暗影斗篷", aliases = { "cloak of shadows", "clos" }, wlk = true, rules = { ["cloak of shadows"] = "name", ["clos"] = "skill" }, owner = "rogue", category = "职业技能/rogue" }
P.concepts["wlk_evasion"] = { label = "闪避", aliases = { "evasion" }, wlk = true, rules = { ["evasion"] = "game" }, owner = "rogue", category = "职业技能/rogue" }
P.concepts["wlk_vanish"] = { label = "消失", aliases = { "vanish" }, wlk = true, rules = { ["vanish"] = "game" }, owner = "rogue", category = "职业技能/rogue" }
P.concepts["wlk_feint"] = { label = "佯攻", aliases = { "feint" }, wlk = true, rules = { ["feint"] = "game" }, owner = "rogue", category = "职业技能/rogue" }
P.concepts["wlk_fan_of_knives"] = { label = "刀扇", aliases = { "fan of knives", "fok" }, wlk = true, rules = { ["fan of knives"] = "name", ["fok"] = "skill" }, owner = "rogue", category = "职业技能/rogue" }
P.concepts["wlk_slice_and_dice"] = { label = "切割", aliases = { "slice and dice", "snd", "s&d" }, wlk = true, rules = { ["slice and dice"] = "name", ["snd"] = "skill", ["s&d"] = "skill" }, owner = "rogue", category = "职业技能/rogue" }
P.concepts["wlk_sinister_strike"] = { label = "影袭", aliases = { "sinister strike", "ss" }, wlk = true, rules = { ["sinister strike"] = "name", ["ss"] = "owner" }, owner = "rogue", category = "职业技能/rogue" }
P.concepts["wlk_adrenaline_rush"] = { label = "激素刺激", aliases = { "adrenaline rush", "ar" }, wlk = true, rules = { ["adrenaline rush"] = "name", ["ar"] = "owner" }, owner = "rogue", category = "职业技能/rogue" }
P.concepts["wlk_blade_flurry"] = { label = "剑刃乱舞", aliases = { "blade flurry", "bf" }, wlk = true, rules = { ["blade flurry"] = "name", ["bf"] = "owner" }, owner = "rogue", category = "职业技能/rogue" }
P.concepts["wlk_killing_spree"] = { label = "杀戮盛筵", aliases = { "killing spree", "ks" }, wlk = true, rules = { ["killing spree"] = "name", ["ks"] = "owner" }, owner = "rogue", category = "职业技能/rogue" }
P.concepts["wlk_deadly_poison"] = { label = "致命药膏", aliases = { "deadly poison", "dp" }, wlk = true, rules = { ["deadly poison"] = "name", ["dp"] = "owner" }, owner = "rogue", category = "职业技能/rogue" }
P.concepts["wlk_expose_armor"] = { label = "破甲", aliases = { "expose armor", "ea" }, wlk = true, rules = { ["expose armor"] = "name", ["ea"] = "owner" }, owner = "rogue", category = "职业技能/rogue" }
P.concepts["wlk_dismantle"] = { label = "拆卸", aliases = { "dismantle" }, wlk = true, rules = { ["dismantle"] = "game" }, owner = "rogue", category = "职业技能/rogue" }
P.concepts["wlk_bloodlust"] = { label = "嗜血", aliases = { "bloodlust", "bl" }, wlk = true, rules = { ["bloodlust"] = "game", ["bl"] = "skill" }, owner = "shaman", category = "职业技能/shaman" }
P.concepts["wlk_heroism"] = { label = "英勇", aliases = { "heroism", "hero" }, wlk = true, rules = { ["heroism"] = "game", ["hero"] = "skill" }, owner = "shaman", category = "职业技能/shaman" }
P.concepts["wlk_wind_shear"] = { label = "风剪", aliases = { "wind shear" }, wlk = true, rules = { ["wind shear"] = "name" }, owner = "shaman", category = "职业技能/shaman" }
P.concepts["wlk_tremor_totem"] = { label = "战栗图腾", aliases = { "tremor totem" }, wlk = true, rules = { ["tremor totem"] = "name" }, owner = "shaman", category = "职业技能/shaman" }
P.concepts["wlk_mana_tide_totem"] = { label = "法力之潮图腾", aliases = { "mana tide totem", "mtt" }, wlk = true, rules = { ["mana tide totem"] = "name", ["mtt"] = "skill" }, owner = "shaman", category = "职业技能/shaman" }
P.concepts["wlk_chain_heal"] = { label = "治疗链", aliases = { "chain heal", "ch" }, wlk = true, rules = { ["chain heal"] = "name", ["ch"] = "owner" }, owner = "shaman", category = "职业技能/shaman" }
P.concepts["wlk_healing_wave"] = { label = "治疗波", aliases = { "healing wave", "hw" }, wlk = true, rules = { ["healing wave"] = "name", ["hw"] = "owner" }, owner = "shaman", category = "职业技能/shaman" }
P.concepts["wlk_lesser_healing_wave"] = { label = "次级治疗波", aliases = { "lesser healing wave", "lhw" }, wlk = true, rules = { ["lesser healing wave"] = "name", ["lhw"] = "skill" }, owner = "shaman", category = "职业技能/shaman" }
P.concepts["wlk_riptide"] = { label = "激流", aliases = { "riptide" }, wlk = true, rules = { ["riptide"] = "game" }, owner = "shaman", category = "职业技能/shaman" }
P.concepts["wlk_earth_shield"] = { label = "大地之盾", aliases = { "earth shield", "es" }, wlk = true, rules = { ["earth shield"] = "name", ["es"] = "owner" }, owner = "shaman", category = "职业技能/shaman" }
P.concepts["wlk_water_shield"] = { label = "水之护盾", aliases = { "water shield" }, wlk = true, rules = { ["water shield"] = "name" }, owner = "shaman", category = "职业技能/shaman" }
P.concepts["wlk_purge"] = { label = "净化术", aliases = { "purge" }, wlk = true, rules = { ["purge"] = "game" }, owner = "shaman", category = "职业技能/shaman" }
P.concepts["wlk_hex"] = { label = "妖术", aliases = { "hex" }, wlk = true, rules = { ["hex"] = "game" }, owner = "shaman", category = "职业技能/shaman" }
P.concepts["wlk_reincarnation"] = { label = "复生", aliases = { "reincarnation", "ankh" }, wlk = true, rules = { ["reincarnation"] = "game", ["ankh"] = "skill" }, owner = "shaman", category = "职业技能/shaman" }
P.concepts["wlk_thunderstorm"] = { label = "雷霆风暴", aliases = { "thunderstorm" }, wlk = true, rules = { ["thunderstorm"] = "game" }, owner = "shaman", category = "职业技能/shaman" }
P.concepts["wlk_soulstone_resurrection"] = { label = "灵魂石复活", aliases = { "soulstone resurrection", "soulstone", "ss" }, wlk = true, rules = { ["soulstone resurrection"] = "name", ["soulstone"] = "skill", ["ss"] = "owner" }, owner = "warlock", category = "职业技能/warlock" }
P.concepts["wlk_create_healthstone"] = { label = "制造治疗石", aliases = { "create healthstone" }, wlk = true, rules = { ["create healthstone"] = "name" }, owner = "warlock", category = "职业技能/warlock" }
P.concepts["wlk_healthstone"] = { label = "治疗石", aliases = { "healthstone", "hs" }, wlk = true, rules = { ["healthstone"] = "game", ["hs"] = "owner" }, owner = "warlock", category = "职业技能/warlock" }
P.concepts["wlk_ritual_of_summoning"] = { label = "召唤仪式", aliases = { "ritual of summoning", "summoning portal" }, wlk = true, rules = { ["ritual of summoning"] = "name", ["summoning portal"] = "skill" }, owner = "warlock", category = "职业技能/warlock" }
P.concepts["wlk_ritual_of_souls"] = { label = "灵魂仪式", aliases = { "ritual of souls", "soulwell" }, wlk = true, rules = { ["ritual of souls"] = "name", ["soulwell"] = "skill" }, owner = "warlock", category = "职业技能/warlock" }
P.concepts["wlk_banish"] = { label = "放逐术", aliases = { "banish" }, wlk = true, rules = { ["banish"] = "game" }, owner = "warlock", category = "职业技能/warlock" }
P.concepts["wlk_fear"] = { label = "恐惧", aliases = { "fear" }, wlk = true, rules = { ["fear"] = "game" }, owner = "warlock", category = "职业技能/warlock" }
P.concepts["wlk_shadowfury"] = { label = "暗影之怒", aliases = { "shadowfury" }, wlk = true, rules = { ["shadowfury"] = "game" }, owner = "warlock", category = "职业技能/warlock" }
P.concepts["wlk_death_coil_warlock"] = { label = "死亡缠绕", aliases = { "death coil", "dc" }, wlk = true, rules = { ["death coil"] = "owner", ["dc"] = "owner" }, owner = "warlock", category = "职业技能/warlock" }
P.concepts["wlk_curse_of_the_elements"] = { label = "元素诅咒", aliases = { "curse of the elements", "coe" }, wlk = true, rules = { ["curse of the elements"] = "name", ["coe"] = "skill" }, owner = "warlock", category = "职业技能/warlock" }
P.concepts["wlk_curse_of_tongues"] = { label = "语言诅咒", aliases = { "curse of tongues", "cot" }, wlk = true, rules = { ["curse of tongues"] = "name", ["cot"] = "skill" }, owner = "warlock", category = "职业技能/warlock" }
P.concepts["wlk_curse_of_weakness"] = { label = "虚弱诅咒", aliases = { "curse of weakness", "cow" }, wlk = true, rules = { ["curse of weakness"] = "name", ["cow"] = "skill" }, owner = "warlock", category = "职业技能/warlock" }
P.concepts["wlk_curse_of_agony"] = { label = "痛苦诅咒", aliases = { "curse of agony", "coa" }, wlk = true, rules = { ["curse of agony"] = "name", ["coa"] = "skill" }, owner = "warlock", category = "职业技能/warlock" }
P.concepts["wlk_soulshatter"] = { label = "灵魂碎裂", aliases = { "soulshatter" }, wlk = true, rules = { ["soulshatter"] = "game" }, owner = "warlock", category = "职业技能/warlock" }
P.concepts["wlk_demonic_circle_teleport"] = { label = "恶魔法阵：传送", aliases = { "demonic circle: teleport" }, wlk = true, rules = { ["demonic circle: teleport"] = "name" }, owner = "warlock", category = "职业技能/warlock" }
P.concepts["wlk_life_tap"] = { label = "生命分流", aliases = { "life tap" }, wlk = true, rules = { ["life tap"] = "name" }, owner = "warlock", category = "职业技能/warlock" }
P.concepts["wlk_drain_soul"] = { label = "吸取灵魂", aliases = { "drain soul" }, wlk = true, rules = { ["drain soul"] = "name" }, owner = "warlock", category = "职业技能/warlock" }
P.concepts["wlk_unstable_affliction"] = { label = "痛苦无常", aliases = { "unstable affliction", "ua" }, wlk = true, rules = { ["unstable affliction"] = "name", ["ua"] = "owner" }, owner = "warlock", category = "职业技能/warlock" }
P.concepts["wlk_seed_of_corruption"] = { label = "腐蚀之种", aliases = { "seed of corruption", "soc" }, wlk = true, rules = { ["seed of corruption"] = "name", ["soc"] = "skill" }, owner = "warlock", category = "职业技能/warlock" }
P.concepts["wlk_shield_wall"] = { label = "盾墙", aliases = { "shield wall", "sw" }, wlk = true, rules = { ["shield wall"] = "name", ["sw"] = "owner" }, owner = "warrior", category = "职业技能/warrior" }
P.concepts["wlk_last_stand"] = { label = "破釜沉舟", aliases = { "last stand" }, wlk = true, rules = { ["last stand"] = "name" }, owner = "warrior", category = "职业技能/warrior" }
P.concepts["wlk_shield_block"] = { label = "盾牌格挡", aliases = { "shield block" }, wlk = true, rules = { ["shield block"] = "name" }, owner = "warrior", category = "职业技能/warrior" }
P.concepts["wlk_spell_reflection"] = { label = "法术反射", aliases = { "spell reflection" }, wlk = true, rules = { ["spell reflection"] = "name" }, owner = "warrior", category = "职业技能/warrior" }
P.concepts["wlk_intervene"] = { label = "援护", aliases = { "intervene" }, wlk = true, rules = { ["intervene"] = "game" }, owner = "warrior", category = "职业技能/warrior" }
P.concepts["wlk_pummel"] = { label = "拳击", aliases = { "pummel" }, wlk = true, rules = { ["pummel"] = "game" }, owner = "warrior", category = "职业技能/warrior" }
P.concepts["wlk_sunder_armor"] = { label = "破甲攻击", aliases = { "sunder armor" }, wlk = true, rules = { ["sunder armor"] = "name" }, owner = "warrior", category = "职业技能/warrior" }
P.concepts["wlk_shattering_throw"] = { label = "碎裂投掷", aliases = { "shattering throw" }, wlk = true, rules = { ["shattering throw"] = "name" }, owner = "warrior", category = "职业技能/warrior" }
P.concepts["wlk_demoralizing_shout"] = { label = "挫志怒吼", aliases = { "demoralizing shout", "demo shout" }, wlk = true, rules = { ["demoralizing shout"] = "name", ["demo shout"] = "skill" }, owner = "warrior", category = "职业技能/warrior" }
P.concepts["wlk_thunder_clap"] = { label = "雷霆一击", aliases = { "thunder clap" }, wlk = true, rules = { ["thunder clap"] = "name" }, owner = "warrior", category = "职业技能/warrior" }
P.concepts["wlk_commanding_shout"] = { label = "命令怒吼", aliases = { "commanding shout", "cs" }, wlk = true, rules = { ["commanding shout"] = "name", ["cs"] = "owner" }, owner = "warrior", category = "职业技能/warrior" }
P.concepts["wlk_battle_shout"] = { label = "战斗怒吼", aliases = { "battle shout", "bs" }, wlk = true, rules = { ["battle shout"] = "name", ["bs"] = "ownerbuff" }, owner = "warrior", category = "职业技能/warrior" }
P.concepts["wlk_bladestorm"] = { label = "剑刃风暴", aliases = { "bladestorm", "bs" }, wlk = true, rules = { ["bladestorm"] = "game", ["bs"] = "owner" }, owner = "warrior", category = "职业技能/warrior" }
P.concepts["wlk_sweeping_strikes"] = { label = "横扫攻击", aliases = { "sweeping strikes", "ss" }, wlk = true, rules = { ["sweeping strikes"] = "name", ["ss"] = "owner" }, owner = "warrior", category = "职业技能/warrior" }
P.concepts["wlk_mortal_strike"] = { label = "致死打击", aliases = { "mortal strike", "ms" }, wlk = true, rules = { ["mortal strike"] = "name", ["ms"] = "owner" }, owner = "warrior", category = "职业技能/warrior" }
P.concepts["wlk_bloodthirst"] = { label = "嗜血", aliases = { "bloodthirst", "bt" }, wlk = true, rules = { ["bloodthirst"] = "game", ["bt"] = "owner" }, owner = "warrior", category = "职业技能/warrior" }
P.concepts["wlk_whirlwind"] = { label = "旋风斩", aliases = { "whirlwind", "ww" }, wlk = true, rules = { ["whirlwind"] = "game", ["ww"] = "owner" }, owner = "warrior", category = "职业技能/warrior" }
P.concepts["wlk_heroic_strike"] = { label = "英勇打击", aliases = { "heroic strike", "hs" }, wlk = true, rules = { ["heroic strike"] = "name", ["hs"] = "owner" }, owner = "warrior", category = "职业技能/warrior" }
P.concepts["wlk_taunt"] = { label = "嘲讽", aliases = { "taunt" }, wlk = true, rules = { ["taunt"] = "game" }, owner = "warrior", category = "职业技能/warrior" }
P.concepts["wlk_mocking_blow"] = { label = "惩戒痛击", aliases = { "mocking blow" }, wlk = true, rules = { ["mocking blow"] = "name" }, owner = "warrior", category = "职业技能/warrior" }
P.concepts["wlk_challenging_shout"] = { label = "挑战怒吼", aliases = { "challenging shout" }, wlk = true, rules = { ["challenging shout"] = "name" }, owner = "warrior", category = "职业技能/warrior" }
P.concepts["wlk_blessing_of_kings"] = { label = "王者祝福", aliases = { "blessing of kings", "bok" }, wlk = true, rules = { ["blessing of kings"] = "name", ["bok"] = "game" }, category = "团队Buff" }
P.concepts["wlk_greater_blessing_of_kings"] = { label = "强效王者祝福", aliases = { "greater blessing of kings", "gbok" }, wlk = true, rules = { ["greater blessing of kings"] = "name", ["gbok"] = "game" }, category = "团队Buff" }
P.concepts["wlk_blessing_of_might"] = { label = "力量祝福", aliases = { "blessing of might", "bom" }, wlk = true, rules = { ["blessing of might"] = "name", ["bom"] = "game" }, category = "团队Buff" }
P.concepts["wlk_greater_blessing_of_might"] = { label = "强效力量祝福", aliases = { "greater blessing of might", "gbom" }, wlk = true, rules = { ["greater blessing of might"] = "name", ["gbom"] = "game" }, category = "团队Buff" }
P.concepts["wlk_blessing_of_wisdom"] = { label = "智慧祝福", aliases = { "blessing of wisdom", "bow" }, wlk = true, rules = { ["blessing of wisdom"] = "name", ["bow"] = "upper" }, category = "团队Buff" }
P.concepts["wlk_greater_blessing_of_wisdom"] = { label = "强效智慧祝福", aliases = { "greater blessing of wisdom", "gbow" }, wlk = true, rules = { ["greater blessing of wisdom"] = "name", ["gbow"] = "game" }, category = "团队Buff" }
P.concepts["wlk_blessing_of_sanctuary"] = { label = "庇护祝福", aliases = { "blessing of sanctuary" }, wlk = true, rules = { ["blessing of sanctuary"] = "name" }, category = "团队Buff" }
P.concepts["wlk_greater_blessing_of_sanctuary"] = { label = "强效庇护祝福", aliases = { "greater blessing of sanctuary", "gbos" }, wlk = true, rules = { ["greater blessing of sanctuary"] = "name", ["gbos"] = "game" }, category = "团队Buff" }
P.concepts["wlk_mark_of_the_wild"] = { label = "野性印记", aliases = { "mark of the wild", "motw" }, wlk = true, rules = { ["mark of the wild"] = "name", ["motw"] = "game" }, category = "团队Buff" }
P.concepts["wlk_gift_of_the_wild"] = { label = "野性赐福", aliases = { "gift of the wild", "gotw" }, wlk = true, rules = { ["gift of the wild"] = "name", ["gotw"] = "game" }, category = "团队Buff" }
P.concepts["wlk_thorns"] = { label = "荆棘术", aliases = { "thorns" }, wlk = true, rules = { ["thorns"] = "name" }, category = "团队Buff" }
P.concepts["wlk_arcane_intellect"] = { label = "奥术智慧", aliases = { "arcane intellect", "ai" }, wlk = true, rules = { ["arcane intellect"] = "name", ["ai"] = "buff" }, category = "团队Buff" }
P.concepts["wlk_arcane_brilliance"] = { label = "奥术光辉", aliases = { "arcane brilliance", "ab" }, wlk = true, rules = { ["arcane brilliance"] = "name", ["ab"] = "buff" }, category = "团队Buff" }
P.concepts["wlk_power_word_fortitude"] = { label = "真言术：韧", aliases = { "power word: fortitude", "fort", "fortitude" }, wlk = true, rules = { ["power word: fortitude"] = "name", ["fort"] = "game", ["fortitude"] = "game" }, category = "团队Buff" }
P.concepts["wlk_prayer_of_fortitude"] = { label = "坚韧祷言", aliases = { "prayer of fortitude" }, wlk = true, rules = { ["prayer of fortitude"] = "name" }, category = "团队Buff" }
P.concepts["wlk_divine_spirit"] = { label = "神圣之灵", aliases = { "divine spirit", "ds" }, wlk = true, rules = { ["divine spirit"] = "name", ["ds"] = "owner" }, owner = "priest", category = "团队Buff" }
P.concepts["wlk_prayer_of_spirit"] = { label = "精神祷言", aliases = { "prayer of spirit" }, wlk = true, rules = { ["prayer of spirit"] = "name" }, category = "团队Buff" }
P.concepts["wlk_shadow_protection"] = { label = "防护暗影", aliases = { "shadow protection", "shadow prot" }, wlk = true, rules = { ["shadow protection"] = "name", ["shadow prot"] = "game" }, category = "团队Buff" }
P.concepts["wlk_prayer_of_shadow_protection"] = { label = "暗影防护祷言", aliases = { "prayer of shadow protection" }, wlk = true, rules = { ["prayer of shadow protection"] = "name" }, category = "团队Buff" }
P.concepts["wlk_horn_of_winter"] = { label = "寒冬号角", aliases = { "horn of winter", "how" }, wlk = true, rules = { ["horn of winter"] = "name", ["how"] = "upper" }, category = "团队Buff" }
P.concepts["wlk_trueshot_aura"] = { label = "强击光环", aliases = { "trueshot aura" }, wlk = true, rules = { ["trueshot aura"] = "name" }, category = "团队Buff" }
P.concepts["wlk_aspect_of_the_pack"] = { label = "豹群守护", aliases = { "aspect of the pack" }, wlk = true, rules = { ["aspect of the pack"] = "name" }, category = "团队Buff" }
P.concepts["wlk_aspect_of_the_cheetah"] = { label = "猎豹守护", aliases = { "aspect of the cheetah" }, wlk = true, rules = { ["aspect of the cheetah"] = "name" }, category = "团队Buff" }
P.concepts["wlk_demonic_pact"] = { label = "恶魔契约", aliases = { "demonic pact" }, wlk = true, rules = { ["demonic pact"] = "name" }, category = "团队Buff" }
P.concepts["wlk_fel_intelligence"] = { label = "邪能智力", aliases = { "fel intelligence" }, wlk = true, rules = { ["fel intelligence"] = "name" }, category = "团队Buff" }
P.concepts["wlk_blood_pact"] = { label = "血之契印", aliases = { "blood pact" }, wlk = true, rules = { ["blood pact"] = "name" }, category = "团队Buff" }
P.concepts["wlk_windfury_totem"] = { label = "风怒图腾", aliases = { "windfury totem" }, wlk = true, rules = { ["windfury totem"] = "name" }, category = "团队Buff" }
P.concepts["wlk_wrath_of_air_totem"] = { label = "空气之怒图腾", aliases = { "wrath of air totem", "woa" }, wlk = true, rules = { ["wrath of air totem"] = "name", ["woa"] = "game" }, category = "团队Buff" }
P.concepts["wlk_strength_of_earth_totem"] = { label = "大地之力图腾", aliases = { "strength of earth totem" }, wlk = true, rules = { ["strength of earth totem"] = "name" }, category = "团队Buff" }
P.concepts["wlk_totem_of_wrath"] = { label = "天怒图腾", aliases = { "totem of wrath", "tow" }, wlk = true, rules = { ["totem of wrath"] = "name", ["tow"] = "game" }, category = "团队Buff" }
P.concepts["wlk_flametongue_totem"] = { label = "火舌图腾", aliases = { "flametongue totem" }, wlk = true, rules = { ["flametongue totem"] = "name" }, category = "团队Buff" }
P.concepts["wlk_mana_spring_totem"] = { label = "法力之泉图腾", aliases = { "mana spring totem" }, wlk = true, rules = { ["mana spring totem"] = "name" }, category = "团队Buff" }
P.concepts["wlk_devotion_aura"] = { label = "虔诚光环", aliases = { "devotion aura" }, wlk = true, rules = { ["devotion aura"] = "name" }, category = "团队Buff" }
P.concepts["wlk_retribution_aura"] = { label = "惩戒光环", aliases = { "retribution aura" }, wlk = true, rules = { ["retribution aura"] = "name" }, category = "团队Buff" }
P.concepts["wlk_concentration_aura"] = { label = "专注光环", aliases = { "concentration aura" }, wlk = true, rules = { ["concentration aura"] = "name" }, category = "团队Buff" }
P.concepts["wlk_frost_resistance_aura"] = { label = "冰霜抗性光环", aliases = { "frost resistance aura" }, wlk = true, rules = { ["frost resistance aura"] = "name" }, category = "团队Buff" }
P.concepts["wlk_fire_resistance_aura"] = { label = "火焰抗性光环", aliases = { "fire resistance aura" }, wlk = true, rules = { ["fire resistance aura"] = "name" }, category = "团队Buff" }
P.concepts["wlk_shadow_resistance_aura"] = { label = "暗影抗性光环", aliases = { "shadow resistance aura" }, wlk = true, rules = { ["shadow resistance aura"] = "name" }, category = "团队Buff" }
P.concepts["wlk_bone_spike_graveyard"] = { label = "天灾领主之刺", aliases = { "bone spike graveyard", "bone spikes" }, wlk = true, rules = { ["bone spike graveyard"] = "name", ["bone spikes"] = "zone" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_bone_storm"] = { label = "白骨风暴", aliases = { "bone storm" }, wlk = true, rules = { ["bone storm"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_coldflame"] = { label = "冷焰", aliases = { "coldflame" }, wlk = true, rules = { ["coldflame"] = "zone" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_mana_barrier"] = { label = "法力壁垒", aliases = { "mana barrier" }, wlk = true, rules = { ["mana barrier"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_frostbolt_volley"] = { label = "寒冰箭雨", aliases = { "frostbolt volley" }, wlk = true, rules = { ["frostbolt volley"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_rune_of_blood"] = { label = "符文之血", aliases = { "rune of blood" }, wlk = true, rules = { ["rune of blood"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_mark_of_the_fallen_champion"] = { label = "阵亡勇士的印记", aliases = { "mark of the fallen champion" }, wlk = true, rules = { ["mark of the fallen champion"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_blood_nova"] = { label = "鲜血新星", aliases = { "blood nova" }, wlk = true, rules = { ["blood nova"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_boiling_blood"] = { label = "沸腾之血", aliases = { "boiling blood" }, wlk = true, rules = { ["boiling blood"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_gas_spore"] = { label = "毒气孢子", aliases = { "gas spore", "spores" }, wlk = true, rules = { ["gas spore"] = "name", ["spores"] = "zone" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_pungent_blight"] = { label = "刺鼻毒气", aliases = { "pungent blight" }, wlk = true, rules = { ["pungent blight"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_vile_gas"] = { label = "邪恶毒气", aliases = { "vile gas" }, wlk = true, rules = { ["vile gas"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_gastric_bloat"] = { label = "毒肿", aliases = { "gastric bloat" }, wlk = true, rules = { ["gastric bloat"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_mutated_infection"] = { label = "畸变感染", aliases = { "mutated infection" }, wlk = true, rules = { ["mutated infection"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_slime_spray"] = { label = "软泥喷射", aliases = { "slime spray" }, wlk = true, rules = { ["slime spray"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_unstable_ooze_explosion"] = { label = "不稳定的软泥爆炸", aliases = { "unstable ooze explosion" }, wlk = true, rules = { ["unstable ooze explosion"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_malleable_goo"] = { label = "可延展黏液", aliases = { "malleable goo", "goo" }, wlk = true, rules = { ["malleable goo"] = "name", ["goo"] = "zone" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_unbound_plague"] = { label = "肆虐毒疫", aliases = { "unbound plague" }, wlk = true, rules = { ["unbound plague"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_mutated_plague"] = { label = "畸变瘟疫", aliases = { "mutated plague" }, wlk = true, rules = { ["mutated plague"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_choking_gas_bomb"] = { label = "窒息毒气弹", aliases = { "choking gas bomb" }, wlk = true, rules = { ["choking gas bomb"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_volatile_ooze_adhesive"] = { label = "不稳定的软泥怪黏合剂", aliases = { "volatile ooze adhesive", "ooze adhesive" }, wlk = true, rules = { ["volatile ooze adhesive"] = "name", ["ooze adhesive"] = "zone" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_gaseous_bloat"] = { label = "毒肿", aliases = { "gaseous bloat" }, wlk = true, rules = { ["gaseous bloat"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_kinetic_bomb"] = { label = "动力炸弹", aliases = { "kinetic bomb", "kinetics" }, wlk = true, rules = { ["kinetic bomb"] = "name", ["kinetics"] = "zone" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_empowered_shock_vortex"] = { label = "强能震荡涡流", aliases = { "empowered shock vortex" }, wlk = true, rules = { ["empowered shock vortex"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_shadow_prison"] = { label = "暗影牢笼", aliases = { "shadow prison" }, wlk = true, rules = { ["shadow prison"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_glittering_sparks"] = { label = "闪耀火花", aliases = { "glittering sparks" }, wlk = true, rules = { ["glittering sparks"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_swarming_shadows"] = { label = "蜂拥之影", aliases = { "swarming shadows" }, wlk = true, rules = { ["swarming shadows"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_pact_of_the_darkfallen"] = { label = "黑暗堕落者的契约", aliases = { "pact of the darkfallen", "pact" }, wlk = true, rules = { ["pact of the darkfallen"] = "name", ["pact"] = "zone" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_frenzied_bloodthirst"] = { label = "疯狂嗜血", aliases = { "frenzied bloodthirst" }, wlk = true, rules = { ["frenzied bloodthirst"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_vampiric_bite"] = { label = "吸血撕咬", aliases = { "vampiric bite", "bite" }, wlk = true, rules = { ["vampiric bite"] = "name", ["bite"] = "zone" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_incite_terror"] = { label = "煽动惊恐", aliases = { "incite terror" }, wlk = true, rules = { ["incite terror"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_emerald_vigor"] = { label = "翡翠精髓", aliases = { "emerald vigor" }, wlk = true, rules = { ["emerald vigor"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_gut_spray"] = { label = "胆汁喷溅", aliases = { "gut spray" }, wlk = true, rules = { ["gut spray"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_frost_beacon"] = { label = "冰霜道标", aliases = { "frost beacon", "beacon" }, wlk = true, rules = { ["frost beacon"] = "name", ["beacon"] = "zone" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_ice_tomb"] = { label = "寒冰坟墓", aliases = { "ice tomb", "tombs" }, wlk = true, rules = { ["ice tomb"] = "name", ["tombs"] = "zone" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_unchained_magic"] = { label = "狂咒", aliases = { "unchained magic" }, wlk = true, rules = { ["unchained magic"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_instability"] = { label = "易变", aliases = { "instability" }, wlk = true, rules = { ["instability"] = "zone" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_blistering_cold"] = { label = "严寒", aliases = { "blistering cold" }, wlk = true, rules = { ["blistering cold"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_mystic_buffet"] = { label = "秘法打击", aliases = { "mystic buffet" }, wlk = true, rules = { ["mystic buffet"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_frost_bomb"] = { label = "冰霜炸弹", aliases = { "frost bomb" }, wlk = true, rules = { ["frost bomb"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_defile"] = { label = "污染", aliases = { "defile" }, wlk = true, rules = { ["defile"] = "zone" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_necrotic_plague"] = { label = "死疽", aliases = { "necrotic plague", "np" }, wlk = true, rules = { ["necrotic plague"] = "name", ["np"] = "zone" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_infest"] = { label = "寄生", aliases = { "infest" }, wlk = true, rules = { ["infest"] = "zone" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_soul_reaper"] = { label = "灵魂收割", aliases = { "soul reaper" }, wlk = true, rules = { ["soul reaper"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_harvest_soul"] = { label = "收割灵魂", aliases = { "harvest soul" }, wlk = true, rules = { ["harvest soul"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_harvest_souls"] = { label = "收割灵魂", aliases = { "harvest souls" }, wlk = true, rules = { ["harvest souls"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_remorseless_winter"] = { label = "冷酷严冬", aliases = { "remorseless winter" }, wlk = true, rules = { ["remorseless winter"] = "name" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_raging_spirit"] = { label = "狂怒之魂", aliases = { "raging spirit", "raging spirits" }, wlk = true, rules = { ["raging spirit"] = "name", ["raging spirits"] = "zone" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_fiery_combustion"] = { label = "炽焰燃烧", aliases = { "fiery combustion" }, wlk = true, rules = { ["fiery combustion"] = "name" }, zone = "rs", category = "副本机制/rs" }
P.concepts["wlk_soul_consumption"] = { label = "灵魂吞噬", aliases = { "soul consumption" }, wlk = true, rules = { ["soul consumption"] = "name" }, zone = "rs", category = "副本机制/rs" }
P.concepts["wlk_twilight_cutter"] = { label = "暮光撕裂射线", aliases = { "twilight cutter", "cutter" }, wlk = true, rules = { ["twilight cutter"] = "name", ["cutter"] = "zone" }, zone = "rs", category = "副本机制/rs" }
P.concepts["wlk_meteor_strike"] = { label = "流星打击", aliases = { "meteor strike" }, wlk = true, rules = { ["meteor strike"] = "name" }, zone = "rs", category = "副本机制/rs" }
P.concepts["wlk_corporeality"] = { label = "实体", aliases = { "corporeality" }, wlk = true, rules = { ["corporeality"] = "zone" }, zone = "rs", category = "副本机制/rs" }
P.concepts["wlk_impale"] = { label = "穿刺", aliases = { "impale" }, wlk = true, rules = { ["impale"] = "zone" }, zone = "toc", category = "副本机制/toc" }
P.concepts["wlk_paralytic_toxin"] = { label = "麻痹毒素", aliases = { "paralytic toxin" }, wlk = true, rules = { ["paralytic toxin"] = "name" }, zone = "toc", category = "副本机制/toc" }
P.concepts["wlk_burning_bile"] = { label = "灼热胆汁", aliases = { "burning bile" }, wlk = true, rules = { ["burning bile"] = "name" }, zone = "toc", category = "副本机制/toc" }
P.concepts["wlk_arctic_breath"] = { label = "极寒吐息", aliases = { "arctic breath" }, wlk = true, rules = { ["arctic breath"] = "name" }, zone = "toc", category = "副本机制/toc" }
P.concepts["wlk_massive_crash"] = { label = "重型撞击", aliases = { "massive crash" }, wlk = true, rules = { ["massive crash"] = "name" }, zone = "toc", category = "副本机制/toc" }
P.concepts["wlk_legion_flame"] = { label = "军团烈焰", aliases = { "legion flame" }, wlk = true, rules = { ["legion flame"] = "name" }, zone = "toc", category = "副本机制/toc" }
P.concepts["wlk_incinerate_flesh"] = { label = "血肉成灰", aliases = { "incinerate flesh" }, wlk = true, rules = { ["incinerate flesh"] = "name" }, zone = "toc", category = "副本机制/toc" }
P.concepts["wlk_nether_power"] = { label = "虚空之能", aliases = { "nether power" }, wlk = true, rules = { ["nether power"] = "name" }, zone = "toc", category = "副本机制/toc" }
P.concepts["wlk_fel_lightning"] = { label = "魔能闪电", aliases = { "fel lightning" }, wlk = true, rules = { ["fel lightning"] = "name" }, zone = "toc", category = "副本机制/toc" }
P.concepts["wlk_light_essence"] = { label = "光明精粹", aliases = { "light essence" }, wlk = true, rules = { ["light essence"] = "name" }, zone = "toc", category = "副本机制/toc" }
P.concepts["wlk_dark_essence"] = { label = "黑暗精粹", aliases = { "dark essence" }, wlk = true, rules = { ["dark essence"] = "name" }, zone = "toc", category = "副本机制/toc" }
P.concepts["wlk_light_vortex"] = { label = "光明漩涡", aliases = { "light vortex" }, wlk = true, rules = { ["light vortex"] = "name" }, zone = "toc", category = "副本机制/toc" }
P.concepts["wlk_dark_vortex"] = { label = "黑暗漩涡", aliases = { "dark vortex" }, wlk = true, rules = { ["dark vortex"] = "name" }, zone = "toc", category = "副本机制/toc" }
P.concepts["wlk_twin_s_pact"] = { label = "双生相协", aliases = { "twin's pact" }, wlk = true, rules = { ["twin's pact"] = "name" }, zone = "toc", category = "副本机制/toc" }
P.concepts["wlk_penetrating_cold"] = { label = "刺骨之寒", aliases = { "penetrating cold" }, wlk = true, rules = { ["penetrating cold"] = "name" }, zone = "toc", category = "副本机制/toc" }
P.concepts["wlk_leeching_swarm"] = { label = "吸血虫群", aliases = { "leeching swarm" }, wlk = true, rules = { ["leeching swarm"] = "name" }, zone = "toc", category = "副本机制/toc" }
P.concepts["wlk_shadow_strike"] = { label = "暗影突击", aliases = { "shadow strike" }, wlk = true, rules = { ["shadow strike"] = "name" }, zone = "toc", category = "副本机制/toc" }
P.concepts["wlk_permafrost"] = { label = "永冻", aliases = { "permafrost" }, wlk = true, rules = { ["permafrost"] = "zone" }, zone = "toc", category = "副本机制/toc" }
P.concepts["wlk_pursuing_spikes"] = { label = "追击穿刺", aliases = { "pursuing spikes" }, wlk = true, rules = { ["pursuing spikes"] = "name" }, zone = "toc", category = "副本机制/toc" }
P.concepts["wlk_locust_swarm"] = { label = "虫群风暴", aliases = { "locust swarm" }, wlk = true, rules = { ["locust swarm"] = "name" }, zone = "naxx", category = "副本机制/naxx" }
P.concepts["wlk_web_wrap"] = { label = "蛛网裹体", aliases = { "web wrap" }, wlk = true, rules = { ["web wrap"] = "name" }, zone = "naxx", category = "副本机制/naxx" }
P.concepts["wlk_web_spray"] = { label = "蛛网喷射", aliases = { "web spray" }, wlk = true, rules = { ["web spray"] = "name" }, zone = "naxx", category = "副本机制/naxx" }
P.concepts["wlk_hateful_strike"] = { label = "仇恨打击", aliases = { "hateful strike" }, wlk = true, rules = { ["hateful strike"] = "name" }, zone = "naxx", category = "副本机制/naxx" }
P.concepts["wlk_mutating_injection"] = { label = "变异注射", aliases = { "mutating injection" }, wlk = true, rules = { ["mutating injection"] = "name" }, zone = "naxx", category = "副本机制/naxx" }
P.concepts["wlk_decimate"] = { label = "屠杀", aliases = { "decimate" }, wlk = true, rules = { ["decimate"] = "zone" }, zone = "naxx", category = "副本机制/naxx" }
P.concepts["wlk_polarity_shift"] = { label = "极性转化", aliases = { "polarity shift", "polarity" }, wlk = true, rules = { ["polarity shift"] = "name", ["polarity"] = "zone" }, zone = "naxx", category = "副本机制/naxx" }
P.concepts["wlk_positive_charge"] = { label = "正能量电荷", aliases = { "positive charge" }, wlk = true, rules = { ["positive charge"] = "name" }, zone = "naxx", category = "副本机制/naxx" }
P.concepts["wlk_negative_charge"] = { label = "负能量电荷", aliases = { "negative charge" }, wlk = true, rules = { ["negative charge"] = "name" }, zone = "naxx", category = "副本机制/naxx" }
P.concepts["wlk_necrotic_aura"] = { label = "死灵光环", aliases = { "necrotic aura" }, wlk = true, rules = { ["necrotic aura"] = "name" }, zone = "naxx", category = "副本机制/naxx" }
P.concepts["wlk_unbalancing_strike"] = { label = "重压打击", aliases = { "unbalancing strike" }, wlk = true, rules = { ["unbalancing strike"] = "name" }, zone = "naxx", category = "副本机制/naxx" }
P.concepts["wlk_frost_blast"] = { label = "冰霜冲击", aliases = { "frost blast" }, wlk = true, rules = { ["frost blast"] = "name" }, zone = "naxx", category = "副本机制/naxx" }
P.concepts["wlk_shadow_fissure"] = { label = "暗影裂隙", aliases = { "shadow fissure" }, wlk = true, rules = { ["shadow fissure"] = "name" }, zone = "naxx", category = "副本机制/naxx" }
P.concepts["wlk_detonate_mana"] = { label = "自爆法力", aliases = { "detonate mana" }, wlk = true, rules = { ["detonate mana"] = "name" }, zone = "naxx", category = "副本机制/naxx" }
P.concepts["wlk_chains_of_kel_thuzad"] = { label = "克尔苏加德锁链", aliases = { "chains of kel'thuzad" }, wlk = true, rules = { ["chains of kel'thuzad"] = "name" }, zone = "naxx", category = "副本机制/naxx" }
P.concepts["wlk_flame_jets"] = { label = "烈焰喷射", aliases = { "flame jets" }, wlk = true, rules = { ["flame jets"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_scorch"] = { label = "灼烧", aliases = { "scorch" }, wlk = true, rules = { ["scorch"] = "zone" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_searing_light"] = { label = "灼热之光", aliases = { "searing light" }, wlk = true, rules = { ["searing light"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_gravity_bomb"] = { label = "重力炸弹", aliases = { "gravity bomb" }, wlk = true, rules = { ["gravity bomb"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_overload"] = { label = "过载", aliases = { "overload" }, wlk = true, rules = { ["overload"] = "zone" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_rune_of_power"] = { label = "能量符文", aliases = { "rune of power" }, wlk = true, rules = { ["rune of power"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_rune_of_death"] = { label = "死亡符文", aliases = { "rune of death" }, wlk = true, rules = { ["rune of death"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_fusion_punch"] = { label = "熔化冲压", aliases = { "fusion punch" }, wlk = true, rules = { ["fusion punch"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_stone_grip"] = { label = "岩石之握", aliases = { "stone grip" }, wlk = true, rules = { ["stone grip"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_focused_eyebeam"] = { label = "聚焦视线", aliases = { "focused eyebeam" }, wlk = true, rules = { ["focused eyebeam"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_flash_freeze"] = { label = "快速冻结", aliases = { "flash freeze" }, wlk = true, rules = { ["flash freeze"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_biting_cold"] = { label = "刺骨之寒", aliases = { "biting cold" }, wlk = true, rules = { ["biting cold"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_starlight"] = { label = "星光", aliases = { "starlight" }, wlk = true, rules = { ["starlight"] = "zone" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_lightning_charge"] = { label = "闪电充能", aliases = { "lightning charge" }, wlk = true, rules = { ["lightning charge"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_nature_s_fury"] = { label = "自然之怒", aliases = { "nature's fury" }, wlk = true, rules = { ["nature's fury"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_plasma_blast"] = { label = "等离子冲击", aliases = { "plasma blast" }, wlk = true, rules = { ["plasma blast"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_shock_blast"] = { label = "震爆", aliases = { "shock blast" }, wlk = true, rules = { ["shock blast"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_heat_wave"] = { label = "热浪", aliases = { "heat wave" }, wlk = true, rules = { ["heat wave"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_proximity_mines"] = { label = "地雷", aliases = { "proximity mines" }, wlk = true, rules = { ["proximity mines"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_rocket_strike"] = { label = "火箭打击", aliases = { "rocket strike" }, wlk = true, rules = { ["rocket strike"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_spinning_up"] = { label = "旋转", aliases = { "spinning up" }, wlk = true, rules = { ["spinning up"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_shadow_crash"] = { label = "暗影撞击", aliases = { "shadow crash" }, wlk = true, rules = { ["shadow crash"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_mark_of_the_faceless"] = { label = "无面者的印记", aliases = { "mark of the faceless" }, wlk = true, rules = { ["mark of the faceless"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_surge_of_darkness"] = { label = "黑暗翻腾", aliases = { "surge of darkness" }, wlk = true, rules = { ["surge of darkness"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_sanity"] = { label = "理智", aliases = { "sanity" }, wlk = true, rules = { ["sanity"] = "zone" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_lunatic_gaze"] = { label = "疯乱凝视", aliases = { "lunatic gaze" }, wlk = true, rules = { ["lunatic gaze"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_brain_link"] = { label = "心智链接", aliases = { "brain link" }, wlk = true, rules = { ["brain link"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_cosmic_smash"] = { label = "宇宙重击", aliases = { "cosmic smash" }, wlk = true, rules = { ["cosmic smash"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_big_bang"] = { label = "大爆炸", aliases = { "big bang" }, wlk = true, rules = { ["big bang"] = "name" }, zone = "ulduar", category = "副本机制/ulduar" }
P.concepts["wlk_power_spark"] = { label = "能量火花", aliases = { "power spark" }, wlk = true, rules = { ["power spark"] = "name" }, zone = "otherraid", category = "副本机制/otherraid" }
P.concepts["wlk_static_field"] = { label = "静止力场", aliases = { "static field" }, wlk = true, rules = { ["static field"] = "name" }, zone = "otherraid", category = "副本机制/otherraid" }
P.concepts["wlk_flame_tsunami"] = { label = "烈焰之啸", aliases = { "flame tsunami" }, wlk = true, rules = { ["flame tsunami"] = "name" }, zone = "otherraid", category = "副本机制/otherraid" }
P.concepts["wlk_twilight_torment"] = { label = "暮光折磨", aliases = { "twilight torment" }, wlk = true, rules = { ["twilight torment"] = "name" }, zone = "otherraid", category = "副本机制/otherraid" }
P.concepts["wlk_overcharge"] = { label = "能量超载", aliases = { "overcharge" }, wlk = true, rules = { ["overcharge"] = "zone" }, zone = "otherraid", category = "副本机制/otherraid" }
P.concepts["wlk_frozen_orb"] = { label = "冰冻之球", aliases = { "frozen orb" }, wlk = true, rules = { ["frozen orb"] = "name" }, zone = "otherraid", category = "副本机制/otherraid" }
P.concepts["wlk_whiteout"] = { label = "霜至", aliases = { "whiteout" }, wlk = true, rules = { ["whiteout"] = "zone" }, zone = "otherraid", category = "副本机制/otherraid" }
P.concepts["wlk_mirrored_soul"] = { label = "灵魂倒映", aliases = { "mirrored soul" }, wlk = true, rules = { ["mirrored soul"] = "name" }, zone = "dungeon", category = "副本机制/dungeon" }
P.concepts["wlk_wailing_souls"] = { label = "哀嚎之魂", aliases = { "wailing souls" }, wlk = true, rules = { ["wailing souls"] = "name" }, zone = "dungeon", category = "副本机制/dungeon" }
P.concepts["wlk_magic_s_bane"] = { label = "魔法的灾难", aliases = { "magic's bane" }, wlk = true, rules = { ["magic's bane"] = "name" }, zone = "dungeon", category = "副本机制/dungeon" }
P.concepts["wlk_overlord_s_brand"] = { label = "天灾领主的烙印", aliases = { "overlord's brand" }, wlk = true, rules = { ["overlord's brand"] = "name" }, zone = "dungeon", category = "副本机制/dungeon" }
P.concepts["wlk_unholy_power"] = { label = "邪恶强化", aliases = { "unholy power" }, wlk = true, rules = { ["unholy power"] = "name" }, zone = "dungeon", category = "副本机制/dungeon" }
P.concepts["wlk_bane"] = { label = "灾祸", aliases = { "bane" }, wlk = true, rules = { ["bane"] = "zone" }, zone = "dungeon", category = "副本机制/dungeon" }
P.concepts["wlk_pursued_by_anub_arak"] = { label = "被阿努巴拉克追逐", aliases = { "pursued by anub'arak" }, wlk = true, rules = { ["pursued by anub'arak"] = "name" }, zone = "dungeon", category = "副本机制/dungeon" }
P.concepts["wlk_poison_nova"] = { label = "毒性新星", aliases = { "poison nova" }, wlk = true, rules = { ["poison nova"] = "name" }, zone = "dungeon", category = "副本机制/dungeon" }
P.concepts["wlk_lightning_nova"] = { label = "闪电新星", aliases = { "lightning nova", "loken's lightning nova" }, wlk = true, rules = { ["lightning nova"] = "name", ["loken's lightning nova"] = "zone" }, zone = "dungeon", category = "副本机制/dungeon" }
P.concepts["wlk_intense_cold"] = { label = "极度冰寒", aliases = { "intense cold" }, wlk = true, rules = { ["intense cold"] = "name" }, zone = "dungeon", category = "副本机制/dungeon" }
P.concepts["wlk_pound"] = { label = "重击", aliases = { "pound" }, wlk = true, rules = { ["pound"] = "zone" }, zone = "dungeon", category = "副本机制/dungeon" }
P.concepts["wlk_web_grab"] = { label = "蛛网抓捕", aliases = { "web grab" }, wlk = true, rules = { ["web grab"] = "name" }, zone = "dungeon", category = "副本机制/dungeon" }
P.concepts["wlk_toxic_waste"] = { label = "剧毒废渣", aliases = { "toxic waste" }, wlk = true, rules = { ["toxic waste"] = "name" }, zone = "dungeon", category = "副本机制/dungeon" }
P.concepts["wlk_dark_slash"] = { label = "黑暗鞭笞", aliases = { "dark slash" }, wlk = true, rules = { ["dark slash"] = "name" }, zone = "dungeon", category = "副本机制/dungeon" }
P.concepts["wlk_lord_marrowgar"] = { label = "骨王", aliases = { "lord marrowgar", "marrowgar" }, wlk = true, rules = { ["lord marrowgar"] = "name", ["marrowgar"] = "zone" }, zone = "icc", category = "首领/icc" }
P.concepts["wlk_lady_deathwhisper"] = { label = "亡语者女士", aliases = { "lady deathwhisper", "ldw" }, wlk = true, rules = { ["lady deathwhisper"] = "name", ["ldw"] = "zone" }, zone = "icc", category = "首领/icc" }
P.concepts["wlk_gunship_battle"] = { label = "炮舰战", aliases = { "gunship battle", "gunship" }, wlk = true, rules = { ["gunship battle"] = "name", ["gunship"] = "zone" }, zone = "icc", category = "首领/icc" }
P.concepts["wlk_deathbringer_saurfang"] = { label = "死亡使者萨鲁法尔", aliases = { "deathbringer saurfang", "dbs" }, wlk = true, rules = { ["deathbringer saurfang"] = "name", ["dbs"] = "zone" }, zone = "icc", category = "首领/icc" }
P.concepts["wlk_festergut"] = { label = "烂肠", aliases = { "festergut", "fester" }, wlk = true, rules = { ["festergut"] = "name", ["fester"] = "zone" }, zone = "icc", category = "首领/icc" }
P.concepts["wlk_rotface"] = { label = "腐面", aliases = { "rotface", "rf" }, wlk = true, rules = { ["rotface"] = "name", ["rf"] = "zone" }, zone = "icc", category = "首领/icc" }
P.concepts["wlk_professor_putricide"] = { label = "教授", aliases = { "professor putricide", "pp", "proffosor" }, wlk = true, rules = { ["professor putricide"] = "name", ["pp"] = "zone", ["proffosor"] = "zone" }, zone = "icc", category = "首领/icc" }
P.concepts["wlk_blood_prince_council"] = { label = "血王子议会", aliases = { "blood prince council", "bpc" }, wlk = true, rules = { ["blood prince council"] = "name", ["bpc"] = "zone" }, zone = "icc", category = "首领/icc" }
P.concepts["wlk_blood_queen_lana_thel"] = { label = "血女王", aliases = { "blood-queen lana'thel", "bql", "blood queen" }, wlk = true, rules = { ["blood-queen lana'thel"] = "name", ["bql"] = "zone", ["blood queen"] = "zone" }, zone = "icc", category = "首领/icc" }
P.concepts["wlk_valithria_dreamwalker"] = { label = "绿龙", aliases = { "valithria dreamwalker", "vdw" }, wlk = true, rules = { ["valithria dreamwalker"] = "name", ["vdw"] = "zone" }, zone = "icc", category = "首领/icc" }
P.concepts["wlk_halion"] = { label = "海里昂", aliases = { "halion" }, wlk = true, rules = { ["halion"] = "name" }, zone = "rs", category = "首领/rs" }
P.concepts["wlk_baltharus_the_warborn"] = { label = "战争之子巴尔萨鲁斯", aliases = { "baltharus the warborn" }, wlk = true, rules = { ["baltharus the warborn"] = "name" }, zone = "rs", category = "首领/rs" }
P.concepts["wlk_saviana_ragefire"] = { label = "萨维安娜·怒火", aliases = { "saviana ragefire" }, wlk = true, rules = { ["saviana ragefire"] = "name" }, zone = "rs", category = "首领/rs" }
P.concepts["wlk_general_zarithrian"] = { label = "扎里斯利安将军", aliases = { "general zarithrian" }, wlk = true, rules = { ["general zarithrian"] = "name" }, zone = "rs", category = "首领/rs" }
P.concepts["wlk_northrend_beasts"] = { label = "诺森德猛兽", aliases = { "northrend beasts", "beasts" }, wlk = true, rules = { ["northrend beasts"] = "name", ["beasts"] = "zone" }, zone = "toc", category = "首领/toc" }
P.concepts["wlk_gormok_the_impaler"] = { label = "穿刺者戈莫克", aliases = { "gormok the impaler", "gormok" }, wlk = true, rules = { ["gormok the impaler"] = "name", ["gormok"] = "zone" }, zone = "toc", category = "首领/toc" }
P.concepts["wlk_acidmaw"] = { label = "酸喉", aliases = { "acidmaw" }, wlk = true, rules = { ["acidmaw"] = "name" }, zone = "toc", category = "首领/toc" }
P.concepts["wlk_dreadscale"] = { label = "恐鳞", aliases = { "dreadscale" }, wlk = true, rules = { ["dreadscale"] = "name" }, zone = "toc", category = "首领/toc" }
P.concepts["wlk_icehowl"] = { label = "冰吼", aliases = { "icehowl" }, wlk = true, rules = { ["icehowl"] = "name" }, zone = "toc", category = "首领/toc" }
P.concepts["wlk_lord_jaraxxus"] = { label = "加拉克苏斯大王", aliases = { "lord jaraxxus", "jaraxxus" }, wlk = true, rules = { ["lord jaraxxus"] = "name", ["jaraxxus"] = "zone" }, zone = "toc", category = "首领/toc" }
P.concepts["wlk_faction_champions"] = { label = "阵营冠军", aliases = { "faction champions", "champions" }, wlk = true, rules = { ["faction champions"] = "name", ["champions"] = "zone" }, zone = "toc", category = "首领/toc" }
P.concepts["wlk_twin_val_kyr"] = { label = "双子", aliases = { "twin val'kyr", "twins" }, wlk = true, rules = { ["twin val'kyr"] = "name", ["twins"] = "zone" }, zone = "toc", category = "首领/toc" }
P.concepts["wlk_anub_arak"] = { label = "小强", aliases = { "anub'arak", "anub" }, wlk = true, rules = { ["anub'arak"] = "name", ["anub"] = "zone" }, zone = "toc", category = "首领/toc" }
P.concepts["wlk_anub_rekhan"] = { label = "阿努布雷坎", aliases = { "anub'rekhan" }, wlk = true, rules = { ["anub'rekhan"] = "name" }, zone = "naxx", category = "首领/naxx" }
P.concepts["wlk_grand_widow_faerlina"] = { label = "黑女巫法琳娜", aliases = { "grand widow faerlina", "faerlina" }, wlk = true, rules = { ["grand widow faerlina"] = "name", ["faerlina"] = "zone" }, zone = "naxx", category = "首领/naxx" }
P.concepts["wlk_maexxna"] = { label = "迈克斯纳", aliases = { "maexxna" }, wlk = true, rules = { ["maexxna"] = "name" }, zone = "naxx", category = "首领/naxx" }
P.concepts["wlk_patchwerk"] = { label = "帕奇维克", aliases = { "patchwerk", "patch" }, wlk = true, rules = { ["patchwerk"] = "name", ["patch"] = "zone" }, zone = "naxx", category = "首领/naxx" }
P.concepts["wlk_grobbulus"] = { label = "格罗布鲁斯", aliases = { "grobbulus" }, wlk = true, rules = { ["grobbulus"] = "name" }, zone = "naxx", category = "首领/naxx" }
P.concepts["wlk_gluth"] = { label = "格拉斯", aliases = { "gluth" }, wlk = true, rules = { ["gluth"] = "name" }, zone = "naxx", category = "首领/naxx" }
P.concepts["wlk_thaddius"] = { label = "塔迪乌斯", aliases = { "thaddius" }, wlk = true, rules = { ["thaddius"] = "name" }, zone = "naxx", category = "首领/naxx" }
P.concepts["wlk_noth_the_plaguebringer"] = { label = "瘟疫使者诺斯", aliases = { "noth the plaguebringer", "noth" }, wlk = true, rules = { ["noth the plaguebringer"] = "name", ["noth"] = "zone" }, zone = "naxx", category = "首领/naxx" }
P.concepts["wlk_heigan_the_unclean"] = { label = "肮脏的希尔盖", aliases = { "heigan the unclean", "heigan" }, wlk = true, rules = { ["heigan the unclean"] = "name", ["heigan"] = "zone" }, zone = "naxx", category = "首领/naxx" }
P.concepts["wlk_loatheb"] = { label = "洛欧塞布", aliases = { "loatheb" }, wlk = true, rules = { ["loatheb"] = "name" }, zone = "naxx", category = "首领/naxx" }
P.concepts["wlk_instructor_razuvious"] = { label = "教官拉苏维奥斯", aliases = { "instructor razuvious", "razuvious" }, wlk = true, rules = { ["instructor razuvious"] = "name", ["razuvious"] = "zone" }, zone = "naxx", category = "首领/naxx" }
P.concepts["wlk_gothik_the_harvester"] = { label = "收割者戈提克", aliases = { "gothik the harvester", "gothik" }, wlk = true, rules = { ["gothik the harvester"] = "name", ["gothik"] = "zone" }, zone = "naxx", category = "首领/naxx" }
P.concepts["wlk_four_horsemen"] = { label = "天启四骑士", aliases = { "four horsemen", "4 horsemen" }, wlk = true, rules = { ["four horsemen"] = "name", ["4 horsemen"] = "zone" }, zone = "naxx", category = "首领/naxx" }
P.concepts["wlk_sapphiron"] = { label = "萨菲隆", aliases = { "sapphiron", "sapph" }, wlk = true, rules = { ["sapphiron"] = "name", ["sapph"] = "zone" }, zone = "naxx", category = "首领/naxx" }
P.concepts["wlk_kel_thuzad"] = { label = "克尔苏加德", aliases = { "kel'thuzad", "kt" }, wlk = true, rules = { ["kel'thuzad"] = "name", ["kt"] = "zone" }, zone = "naxx", category = "首领/naxx" }
P.concepts["wlk_flame_leviathan"] = { label = "烈焰巨兽", aliases = { "flame leviathan", "leviathan" }, wlk = true, rules = { ["flame leviathan"] = "name", ["leviathan"] = "zone" }, zone = "ulduar", category = "首领/ulduar" }
P.concepts["wlk_ignis_the_furnace_master"] = { label = "掌炉者伊格尼斯", aliases = { "ignis the furnace master", "ignis" }, wlk = true, rules = { ["ignis the furnace master"] = "name", ["ignis"] = "zone" }, zone = "ulduar", category = "首领/ulduar" }
P.concepts["wlk_razorscale"] = { label = "锋鳞", aliases = { "razorscale" }, wlk = true, rules = { ["razorscale"] = "name" }, zone = "ulduar", category = "首领/ulduar" }
P.concepts["wlk_xt_002_deconstructor"] = { label = "XT-002拆解者", aliases = { "xt-002 deconstructor", "xt", "xt002" }, wlk = true, rules = { ["xt-002 deconstructor"] = "name", ["xt"] = "zone", ["xt002"] = "zone" }, zone = "ulduar", category = "首领/ulduar" }
P.concepts["wlk_assembly_of_iron"] = { label = "钢铁议会", aliases = { "assembly of iron", "iron council" }, wlk = true, rules = { ["assembly of iron"] = "name", ["iron council"] = "zone" }, zone = "ulduar", category = "首领/ulduar" }
P.concepts["wlk_kologarn"] = { label = "科隆加恩", aliases = { "kologarn" }, wlk = true, rules = { ["kologarn"] = "name" }, zone = "ulduar", category = "首领/ulduar" }
P.concepts["wlk_auriaya"] = { label = "欧尔莉亚", aliases = { "auriaya" }, wlk = true, rules = { ["auriaya"] = "name" }, zone = "ulduar", category = "首领/ulduar" }
P.concepts["wlk_hodir"] = { label = "霍迪尔", aliases = { "hodir" }, wlk = true, rules = { ["hodir"] = "name" }, zone = "ulduar", category = "首领/ulduar" }
P.concepts["wlk_thorim"] = { label = "托里姆", aliases = { "thorim" }, wlk = true, rules = { ["thorim"] = "name" }, zone = "ulduar", category = "首领/ulduar" }
P.concepts["wlk_freya"] = { label = "芙蕾雅", aliases = { "freya" }, wlk = true, rules = { ["freya"] = "name" }, zone = "ulduar", category = "首领/ulduar" }
P.concepts["wlk_mimiron"] = { label = "米米尔隆", aliases = { "mimiron", "mimi" }, wlk = true, rules = { ["mimiron"] = "name", ["mimi"] = "zone" }, zone = "ulduar", category = "首领/ulduar" }
P.concepts["wlk_general_vezax"] = { label = "维扎克斯将军", aliases = { "general vezax", "vezax" }, wlk = true, rules = { ["general vezax"] = "name", ["vezax"] = "zone" }, zone = "ulduar", category = "首领/ulduar" }
P.concepts["wlk_yogg_saron"] = { label = "尤格萨隆", aliases = { "yogg-saron", "yogg" }, wlk = true, rules = { ["yogg-saron"] = "name", ["yogg"] = "zone" }, zone = "ulduar", category = "首领/ulduar" }
P.concepts["wlk_algalon_the_observer"] = { label = "观察者奥尔加隆", aliases = { "algalon the observer", "algalon" }, wlk = true, rules = { ["algalon the observer"] = "name", ["algalon"] = "zone" }, zone = "ulduar", category = "首领/ulduar" }
P.concepts["wlk_malygos"] = { label = "玛里苟斯", aliases = { "malygos" }, wlk = true, rules = { ["malygos"] = "name" }, zone = "otherraid", category = "首领/otherraid" }
P.concepts["wlk_sartharion"] = { label = "萨塔里奥", aliases = { "sartharion", "sarth" }, wlk = true, rules = { ["sartharion"] = "name", ["sarth"] = "zone" }, zone = "otherraid", category = "首领/otherraid" }
P.concepts["wlk_onyxia"] = { label = "黑龙妹", aliases = { "onyxia", "ony" }, wlk = true, rules = { ["onyxia"] = "name", ["ony"] = "zone" }, zone = "otherraid", category = "首领/otherraid" }
P.concepts["wlk_archavon_the_stone_watcher"] = { label = "岩王", aliases = { "archavon the stone watcher", "archavon" }, wlk = true, rules = { ["archavon the stone watcher"] = "name", ["archavon"] = "zone" }, zone = "otherraid", category = "首领/otherraid" }
P.concepts["wlk_emalon_the_storm_watcher"] = { label = "电王", aliases = { "emalon the storm watcher", "emalon" }, wlk = true, rules = { ["emalon the storm watcher"] = "name", ["emalon"] = "zone" }, zone = "otherraid", category = "首领/otherraid" }
P.concepts["wlk_koralon_the_flame_watcher"] = { label = "火王", aliases = { "koralon the flame watcher", "koralon" }, wlk = true, rules = { ["koralon the flame watcher"] = "name", ["koralon"] = "zone" }, zone = "otherraid", category = "首领/otherraid" }
P.concepts["wlk_toravon_the_ice_watcher"] = { label = "冰王", aliases = { "toravon the ice watcher", "toravon" }, wlk = true, rules = { ["toravon the ice watcher"] = "name", ["toravon"] = "zone" }, zone = "otherraid", category = "首领/otherraid" }
P.concepts["wlk_bronjahm"] = { label = "布隆亚姆", aliases = { "bronjahm" }, wlk = true, rules = { ["bronjahm"] = "name" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_devourer_of_souls"] = { label = "噬魂者", aliases = { "devourer of souls" }, wlk = true, rules = { ["devourer of souls"] = "name" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_forgemaster_garfrost"] = { label = "熔炉之主加弗斯特", aliases = { "forgemaster garfrost", "garfrost" }, wlk = true, rules = { ["forgemaster garfrost"] = "name", ["garfrost"] = "zone" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_krick_and_ick"] = { label = "克瑞克与伊克", aliases = { "krick and ick" }, wlk = true, rules = { ["krick and ick"] = "name" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_scourgelord_tyrannus"] = { label = "天灾领主泰兰努斯", aliases = { "scourgelord tyrannus", "tyrannus" }, wlk = true, rules = { ["scourgelord tyrannus"] = "name", ["tyrannus"] = "zone" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_falric"] = { label = "法瑞克", aliases = { "falric" }, wlk = true, rules = { ["falric"] = "name" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_marwyn"] = { label = "玛维恩", aliases = { "marwyn" }, wlk = true, rules = { ["marwyn"] = "name" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_keristrasza"] = { label = "克莉斯塔萨", aliases = { "keristrasza" }, wlk = true, rules = { ["keristrasza"] = "name" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_anomalus"] = { label = "阿诺玛鲁斯", aliases = { "anomalus" }, wlk = true, rules = { ["anomalus"] = "name" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_cyanigosa"] = { label = "塞安妮苟萨", aliases = { "cyanigosa" }, wlk = true, rules = { ["cyanigosa"] = "name" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_loken"] = { label = "洛肯", aliases = { "loken" }, wlk = true, rules = { ["loken"] = "name" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_ionar"] = { label = "艾欧纳尔", aliases = { "ionar" }, wlk = true, rules = { ["ionar"] = "name" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_king_ymiron"] = { label = "伊米隆国王", aliases = { "king ymiron" }, wlk = true, rules = { ["king ymiron"] = "name" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_skadi_the_ruthless"] = { label = "残忍的斯卡迪", aliases = { "skadi the ruthless", "skadi" }, wlk = true, rules = { ["skadi the ruthless"] = "name", ["skadi"] = "zone" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_sjonnir_the_ironshaper"] = { label = "塑铁者斯约尼尔", aliases = { "sjonnir the ironshaper", "sjonnir" }, wlk = true, rules = { ["sjonnir the ironshaper"] = "name", ["sjonnir"] = "zone" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_tribunal_of_ages"] = { label = "远古法庭", aliases = { "tribunal of ages" }, wlk = true, rules = { ["tribunal of ages"] = "name" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_mal_ganis"] = { label = "玛尔加尼斯", aliases = { "mal'ganis" }, wlk = true, rules = { ["mal'ganis"] = "name" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_salramm_the_fleshcrafter"] = { label = "塑血者沙尔拉姆", aliases = { "salramm the fleshcrafter" }, wlk = true, rules = { ["salramm the fleshcrafter"] = "name" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_herald_volazj"] = { label = "传令官沃拉兹", aliases = { "herald volazj", "volazj" }, wlk = true, rules = { ["herald volazj"] = "name", ["volazj"] = "zone" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_jedoga_shadowseeker"] = { label = "耶戈达·觅影者", aliases = { "jedoga shadowseeker" }, wlk = true, rules = { ["jedoga shadowseeker"] = "name" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_eck_the_ferocious"] = { label = "凶残的伊克", aliases = { "eck the ferocious", "eck" }, wlk = true, rules = { ["eck the ferocious"] = "name", ["eck"] = "zone" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_gal_darah"] = { label = "迦尔达拉", aliases = { "gal'darah" }, wlk = true, rules = { ["gal'darah"] = "name" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_drakos_the_interrogator"] = { label = "审讯者达库斯", aliases = { "drakos the interrogator", "drakos" }, wlk = true, rules = { ["drakos the interrogator"] = "name", ["drakos"] = "zone" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_ley_guardian_eregos"] = { label = "魔网守护者埃雷苟斯", aliases = { "ley-guardian eregos", "eregos" }, wlk = true, rules = { ["ley-guardian eregos"] = "name", ["eregos"] = "zone" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_the_black_knight"] = { label = "黑骑士", aliases = { "the black knight", "black knight" }, wlk = true, rules = { ["the black knight"] = "name", ["black knight"] = "zone" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_eadric_the_pure"] = { label = "纯洁者耶德瑞克", aliases = { "eadric the pure", "eadric" }, wlk = true, rules = { ["eadric the pure"] = "name", ["eadric"] = "zone" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_argent_confessor_paletress"] = { label = "银色神官帕尔崔丝", aliases = { "argent confessor paletress", "paletress" }, wlk = true, rules = { ["argent confessor paletress"] = "name", ["paletress"] = "zone" }, zone = "dungeon", category = "首领/dungeon" }
P.concepts["wlk_dark_nucleus"] = { label = "黑暗之核", aliases = { "dark nucleus", "dark nuclei" }, wlk = true, rules = { ["dark nucleus"] = "name", ["dark nuclei"] = "zone" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_suppressor"] = { label = "镇压者", aliases = { "suppressor", "suppressors", "suppresser", "suppressers" }, wlk = true, rules = { ["suppressor"] = "name", ["suppressors"] = "zone", ["suppresser"] = "zone", ["suppressers"] = "zone" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_blistering_zombie"] = { label = "腐疱僵尸", aliases = { "blistering zombie", "blistering zombies" }, wlk = true, rules = { ["blistering zombie"] = "name", ["blistering zombies"] = "zone" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_blazing_skeleton"] = { label = "炽热骷髅", aliases = { "blazing skeleton", "blazing skeletons" }, wlk = true, rules = { ["blazing skeleton"] = "name", ["blazing skeletons"] = "zone" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_vile_spirit"] = { label = "邪恶灵魂", aliases = { "vile spirit", "vile spirits" }, wlk = true, rules = { ["vile spirit"] = "name", ["vile spirits"] = "zone" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_shambling_horror"] = { label = "蹒跚恐魔", aliases = { "shambling horror", "shambling horrors" }, wlk = true, rules = { ["shambling horror"] = "name", ["shambling horrors"] = "zone" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_val_kyr_shadowguard"] = { label = "瓦格里暗影卫士", aliases = { "val'kyr shadowguard", "valkyrs", "valks" }, wlk = true, rules = { ["val'kyr shadowguard"] = "name", ["valkyrs"] = "zone", ["valks"] = "zone" }, zone = "icc", category = "副本机制/icc" }
P.concepts["wlk_living_inferno"] = { label = "活体烈焰", aliases = { "living inferno", "living infernos" }, wlk = true, rules = { ["living inferno"] = "name", ["living infernos"] = "zone" }, zone = "rs", category = "副本机制/rs" }
P.concepts["wlk_living_ember"] = { label = "活体余烬", aliases = { "living ember", "living embers" }, wlk = true, rules = { ["living ember"] = "name", ["living embers"] = "zone" }, zone = "rs", category = "副本机制/rs" }
P.concepts["wlk_snobold_vassal"] = { label = "狗头人奴仆", aliases = { "snobold vassal", "snobolds" }, wlk = true, rules = { ["snobold vassal"] = "name", ["snobolds"] = "zone" }, zone = "toc", category = "副本机制/toc" }
P.concepts["wlk_naxxramas"] = { label = "纳克萨玛斯", aliases = { "naxxramas", "naxx" }, wlk = true, rules = { ["naxxramas"] = "name", ["naxx"] = "game" }, category = "副本" }
P.concepts["wlk_ulduar"] = { label = "奥杜尔", aliases = { "ulduar", "uldu" }, wlk = true, rules = { ["ulduar"] = "name", ["uldu"] = "game" }, category = "副本" }
P.concepts["wlk_vault_of_archavon"] = { label = "宝库", aliases = { "vault of archavon", "voa" }, wlk = true, rules = { ["vault of archavon"] = "name", ["voa"] = "game" }, category = "副本" }
P.concepts["wlk_the_obsidian_sanctum"] = { label = "黑曜石圣殿", aliases = { "the obsidian sanctum", "obsidian sanctum", "os" }, wlk = true, rules = { ["the obsidian sanctum"] = "name", ["obsidian sanctum"] = "game", ["os"] = "dungeon" }, category = "副本" }
P.concepts["wlk_the_eye_of_eternity"] = { label = "永恒之眼", aliases = { "the eye of eternity", "eye of eternity", "eoe" }, wlk = true, rules = { ["the eye of eternity"] = "name", ["eye of eternity"] = "game", ["eoe"] = "game" }, category = "副本" }
P.concepts["wlk_onyxia_s_lair"] = { label = "黑龙妹的巢穴", aliases = { "onyxia's lair", "onyxia lair" }, wlk = true, rules = { ["onyxia's lair"] = "name", ["onyxia lair"] = "game" }, category = "副本" }
P.concepts["wlk_the_forge_of_souls"] = { label = "灵魂洪炉", aliases = { "the forge of souls", "forge of souls", "fos", "foss" }, wlk = true, rules = { ["the forge of souls"] = "name", ["forge of souls"] = "game", ["fos"] = "game", ["foss"] = "dungeon" }, category = "副本" }
P.concepts["wlk_pit_of_saron"] = { label = "萨隆矿坑", aliases = { "pit of saron", "pos", "poss" }, wlk = true, rules = { ["pit of saron"] = "name", ["pos"] = "game", ["poss"] = "dungeon" }, category = "副本" }
P.concepts["wlk_the_nexus"] = { label = "魔枢", aliases = { "the nexus", "nexus" }, wlk = true, rules = { ["the nexus"] = "name", ["nexus"] = "game" }, category = "副本" }
P.concepts["wlk_the_oculus"] = { label = "魔环", aliases = { "the oculus", "oculus" }, wlk = true, rules = { ["the oculus"] = "name", ["oculus"] = "game" }, category = "副本" }
P.concepts["wlk_utgarde_keep"] = { label = "乌特加德城堡", aliases = { "utgarde keep", "uk" }, wlk = true, rules = { ["utgarde keep"] = "name", ["uk"] = "game" }, category = "副本" }
P.concepts["wlk_utgarde_pinnacle"] = { label = "乌特加德之巅", aliases = { "utgarde pinnacle", "up" }, wlk = true, rules = { ["utgarde pinnacle"] = "name", ["up"] = "dungeon" }, category = "副本" }
P.concepts["wlk_azjol_nerub"] = { label = "艾卓-尼鲁布", aliases = { "azjol-nerub", "an" }, wlk = true, rules = { ["azjol-nerub"] = "name", ["an"] = "dungeon" }, category = "副本" }
P.concepts["wlk_ahn_kahet_the_old_kingdom"] = { label = "安卡赫特：古代王国", aliases = { "ahn'kahet: the old kingdom", "old kingdom", "ak" }, wlk = true, rules = { ["ahn'kahet: the old kingdom"] = "name", ["old kingdom"] = "game", ["ak"] = "dungeon" }, category = "副本" }
P.concepts["wlk_drak_tharon_keep"] = { label = "达克萨隆要塞", aliases = { "drak'tharon keep", "dtk" }, wlk = true, rules = { ["drak'tharon keep"] = "name", ["dtk"] = "game" }, category = "副本" }
P.concepts["wlk_the_violet_hold"] = { label = "紫罗兰监狱", aliases = { "the violet hold", "violet hold", "vh" }, wlk = true, rules = { ["the violet hold"] = "name", ["violet hold"] = "game", ["vh"] = "game" }, category = "副本" }
P.concepts["wlk_gundrak"] = { label = "古达克", aliases = { "gundrak", "gd" }, wlk = true, rules = { ["gundrak"] = "name", ["gd"] = "game" }, category = "副本" }
P.concepts["wlk_halls_of_stone"] = { label = "岩石大厅", aliases = { "halls of stone", "hos" }, wlk = true, rules = { ["halls of stone"] = "name", ["hos"] = "game" }, category = "副本" }
P.concepts["wlk_halls_of_lightning"] = { label = "闪电大厅", aliases = { "halls of lightning", "hol" }, wlk = true, rules = { ["halls of lightning"] = "name", ["hol"] = "game" }, category = "副本" }
P.concepts["wlk_the_culling_of_stratholme"] = { label = "净化斯坦索姆", aliases = { "the culling of stratholme", "culling of stratholme", "cos" }, wlk = true, rules = { ["the culling of stratholme"] = "name", ["culling of stratholme"] = "game", ["cos"] = "game" }, category = "副本" }
P.concepts["wlk_trial_of_the_champion"] = { label = "冠军的试炼", aliases = { "trial of the champion", "toc5", "toc" }, wlk = true, rules = { ["trial of the champion"] = "name", ["toc5"] = "game", ["toc"] = "dungeon" }, category = "副本" }
P.concepts["wlk_random_dungeon_finder"] = { label = "随机地下城", aliases = { "random dungeon finder", "rdf" }, wlk = true, rules = { ["random dungeon finder"] = "name", ["rdf"] = "game" }, category = "副本" }
P.concepts["wlk_random_heroic"] = { label = "随机英雄地下城", aliases = { "random heroic", "rdf hc", "rdhc", "rhc", "rdf h", "df hc" }, wlk = true, rules = { ["random heroic"] = "name", ["rdf hc"] = "game", ["rdhc"] = "game", ["rhc"] = "game", ["rdf h"] = "game", ["df hc"] = "game" }, category = "副本" }
P.concepts["wlk_stop_dps"] = { label = "停止输出", aliases = { "stop dps" }, wlk = true, rules = { ["stop dps"] = "flow" }, category = "副本流程" }
P.concepts["wlk_switch_target"] = { label = "切换目标", aliases = { "switch target", "swap target" }, wlk = true, rules = { ["switch target"] = "flow", ["swap target"] = "game" }, category = "副本流程" }
P.concepts["wlk_switch_to_adds"] = { label = "转火小怪", aliases = { "switch to adds" }, wlk = true, rules = { ["switch to adds"] = "flow" }, category = "副本流程" }
P.concepts["wlk_kill_adds"] = { label = "击杀小怪", aliases = { "kill adds" }, wlk = true, rules = { ["kill adds"] = "flow" }, category = "副本流程" }
P.concepts["wlk_stack_up"] = { label = "集合", aliases = { "stack up" }, wlk = true, rules = { ["stack up"] = "flow" }, category = "副本流程" }
P.concepts["wlk_spread_out"] = { label = "分散", aliases = { "spread out" }, wlk = true, rules = { ["spread out"] = "flow" }, category = "副本流程" }
P.concepts["wlk_move_out"] = { label = "移开", aliases = { "move out" }, wlk = true, rules = { ["move out"] = "flow" }, category = "副本流程" }
P.concepts["wlk_stay_behind"] = { label = "待在后方", aliases = { "stay behind" }, wlk = true, rules = { ["stay behind"] = "flow" }, category = "副本流程" }
P.concepts["wlk_face_away"] = { label = "背向团队", aliases = { "face away" }, wlk = true, rules = { ["face away"] = "flow" }, category = "副本流程" }
P.concepts["wlk_taunt_swap"] = { label = "换坦嘲讽", aliases = { "taunt swap" }, wlk = true, rules = { ["taunt swap"] = "flow" }, category = "副本流程" }
P.concepts["wlk_ready_check"] = { label = "就绪确认", aliases = { "ready check", "rc" }, wlk = true, rules = { ["ready check"] = "flow", ["rc"] = "game" }, category = "副本流程" }
P.concepts["wlk_pull_timer"] = { label = "开怪倒计时", aliases = { "pull timer" }, wlk = true, rules = { ["pull timer"] = "flow" }, category = "副本流程" }
P.concepts["wlk_pull_in"] = { label = "开怪倒计时", aliases = { "pull in" }, wlk = true, rules = { ["pull in"] = "flow" }, category = "副本流程" }
P.concepts["wlk_tank_swap"] = { label = "换坦", aliases = { "tank swap" }, wlk = true, rules = { ["tank swap"] = "flow" }, category = "副本流程" }
P.concepts["wlk_interrupt"] = { label = "打断", aliases = { "interrupt", "kick rotation" }, wlk = true, rules = { ["interrupt"] = "flow", ["kick rotation"] = "game" }, category = "副本流程" }
P.concepts["wlk_dispel"] = { label = "驱散", aliases = { "dispel" }, wlk = true, rules = { ["dispel"] = "flow" }, category = "副本流程" }
P.concepts["wlk_decurse"] = { label = "解除诅咒", aliases = { "decurse" }, wlk = true, rules = { ["decurse"] = "flow" }, category = "副本流程" }
P.concepts["wlk_crowd_control"] = { label = "控制", aliases = { "crowd control", "cc" }, wlk = true, rules = { ["crowd control"] = "flow", ["cc"] = "game" }, category = "副本流程" }
P.concepts["wlk_line_of_sight"] = { label = "视线", aliases = { "line of sight", "los" }, wlk = true, rules = { ["line of sight"] = "flow", ["los"] = "game" }, category = "副本流程" }
P.concepts["wlk_out_of_mana"] = { label = "没蓝了", aliases = { "out of mana", "oom" }, wlk = true, rules = { ["out of mana"] = "flow", ["oom"] = "game" }, category = "副本流程" }
P.concepts["wlk_battle_resurrection"] = { label = "战复", aliases = { "battle resurrection", "combat res", "combat ress", "battle res", "battle ress" }, wlk = true, rules = { ["battle resurrection"] = "flow", ["combat res"] = "game", ["combat ress"] = "game", ["battle res"] = "game", ["battle ress"] = "game" }, category = "副本流程" }
P.concepts["wlk_release_spirit"] = { label = "释放灵魂", aliases = { "release spirit" }, wlk = true, rules = { ["release spirit"] = "flow" }, category = "副本流程" }
P.concepts["wlk_do_not_release"] = { label = "不要释放灵魂", aliases = { "do not release", "don't release" }, wlk = true, rules = { ["do not release"] = "flow", ["don't release"] = "game" }, category = "副本流程" }
P.concepts["wlk_do_not_dispel"] = { label = "不要驱散", aliases = { "do not dispel", "don't dispel" }, wlk = true, rules = { ["do not dispel"] = "flow", ["don't dispel"] = "game" }, category = "副本流程" }
P.concepts["wlk_do_not_pull"] = { label = "不要开怪", aliases = { "do not pull", "don't pull" }, wlk = true, rules = { ["do not pull"] = "flow", ["don't pull"] = "game" }, category = "副本流程" }
P.concepts["wlk_need_summon"] = { label = "需要召唤", aliases = { "need summon" }, wlk = true, rules = { ["need summon"] = "flow" }, category = "副本流程" }
P.concepts["wlk_summon_me"] = { label = "召唤我", aliases = { "summon me" }, wlk = true, rules = { ["summon me"] = "flow" }, category = "副本流程" }
P.concepts["wlk_wipe_it"] = { label = "放弃本次战斗", aliases = { "wipe it" }, wlk = true, rules = { ["wipe it"] = "flow" }, category = "副本流程" }
P.concepts["wlk_wipe_recovery"] = { label = "灭团后恢复", aliases = { "wipe recovery" }, wlk = true, rules = { ["wipe recovery"] = "flow" }, category = "副本流程" }
P.concepts["wlk_food_buff"] = { label = "食物增益", aliases = { "food buff" }, wlk = true, rules = { ["food buff"] = "flow" }, category = "副本流程" }
P.concepts["wlk_flask_check"] = { label = "合剂检查", aliases = { "flask check" }, wlk = true, rules = { ["flask check"] = "flow" }, category = "副本流程" }
P.concepts["wlk_potions"] = { label = "药水", aliases = { "potions" }, wlk = true, rules = { ["potions"] = "flow" }, category = "副本流程" }
P.concepts["wlk_off_tank"] = { label = "副坦克", aliases = { "off tank", "ot" }, wlk = true, rules = { ["off tank"] = "flow", ["ot"] = "game" }, category = "副本流程" }
P.concepts["wlk_main_spec"] = { label = "主天赋", aliases = { "main spec", "ms" }, wlk = true, rules = { ["main spec"] = "flow", ["ms"] = "loot" }, category = "副本流程" }
P.concepts["wlk_off_spec"] = { label = "副天赋", aliases = { "off spec" }, wlk = true, rules = { ["off spec"] = "flow" }, category = "副本流程" }
P.concepts["wlk_hard_mode"] = { label = "困难模式", aliases = { "hard mode", "hm" }, wlk = true, rules = { ["hard mode"] = "flow", ["hm"] = "game" }, category = "副本流程" }
P.concepts["wlk_enrage_timer"] = { label = "狂暴计时", aliases = { "enrage timer" }, wlk = true, rules = { ["enrage timer"] = "flow" }, category = "副本流程" }
P.concepts["wlk_raid_leader"] = { label = "团长", aliases = { "raid leader", "rl" }, wlk = true, rules = { ["raid leader"] = "flow", ["rl"] = "game" }, category = "副本流程" }
P.concepts["wlk_trash_mobs"] = { label = "小怪", aliases = { "trash mobs" }, wlk = true, rules = { ["trash mobs"] = "flow" }, category = "副本流程" }
P.concepts["wlk_resurrection"] = { label = "复活", aliases = { "resurrection" }, wlk = true, rules = { ["resurrection"] = "flow" }, category = "副本流程" }
P.concepts["wlk_afk"] = { label = "暂离", aliases = { "afk" }, wlk = true, rules = { ["afk"] = "flow" }, category = "副本流程" }
P.concepts["wlk_brb"] = { label = "马上回来", aliases = { "brb" }, wlk = true, rules = { ["brb"] = "flow" }, category = "副本流程" }
P.concepts["wlk_buff_check"] = { label = "增益检查", aliases = { "buff check" }, wlk = true, rules = { ["buff check"] = "flow" }, category = "副本流程" }
P.concepts["wlk_raid_buffs"] = { label = "团队增益", aliases = { "raid buffs" }, wlk = true, rules = { ["raid buffs"] = "flow" }, category = "副本流程" }
P.concepts["wlk_adds"] = { label = "小怪", aliases = { "adds" }, wlk = true, rules = { ["adds"] = "flow" }, category = "副本流程" }
P.concepts["wlk_cooldown"] = { label = "冷却时间", aliases = { "cooldown", "cd" }, wlk = true, rules = { ["cooldown"] = "flow", ["cd"] = "game" }, category = "副本流程" }
P.concepts["wlk_kite"] = { label = "风筝", aliases = { "kite" }, wlk = true, rules = { ["kite"] = "flow" }, category = "副本流程" }
P.concepts["wlk_aggro"] = { label = "仇恨", aliases = { "aggro" }, wlk = true, rules = { ["aggro"] = "flow" }, category = "副本流程" }
P.concepts["wlk_wipe"] = { label = "灭团", aliases = { "wipe", "wipes" }, wlk = true, rules = { ["wipe"] = "flow", ["wipes"] = "flow" }, category = "副本流程" }
P.concepts["wlk_ms_os"] = { label = "主天赋优先于副天赋", aliases = { "ms>os", "ms > os" }, wlk = true, rules = { ["ms>os"] = "flow", ["ms > os"] = "game" }, category = "副本流程" }
P.concepts["wlk_rebuff"] = { label = "补增益", aliases = { "rebuff" }, wlk = true, rules = { ["rebuff"] = "flow" }, category = "副本流程" }
P.sharedAliases = {
    ["bane"] = { "iccbane", "wlk_bane" },
    ["bs"] = { "wlk_battle_shout", "wlk_bladestorm" },
    ["bt"] = { "wlk_bloodthirst", "wlk_borrowed_time" },
    ["cs"] = { "wlk_cheap_shot", "wlk_cold_snap", "wlk_commanding_shout", "wlk_counterspell", "wlk_crusader_strike" },
    ["dc"] = { "dc", "wlk_death_coil_dk", "wlk_death_coil_warlock" },
    ["death coil"] = { "wlk_death_coil_dk", "wlk_death_coil_warlock" },
    ["di"] = { "wlk_divine_illumination", "wlk_divine_intervention" },
    ["dp"] = { "wlk_deadly_poison", "wlk_divine_plea", "wlk_divine_protection" },
    ["ds"] = { "wlk_death_strike", "wlk_distracting_shot", "wlk_divine_shield", "wlk_divine_spirit", "wlk_divine_storm" },
    ["gs"] = { "gs", "gunshipgs", "wlk_guardian_spirit" },
    ["hs"] = { "wlk_healthstone", "wlk_heart_strike", "wlk_heroic_strike", "wlk_holy_shield", "wlk_holy_shock" },
    ["lf"] = { "lfg", "lfm" },
    ["mc"] = { "wlk_master_s_call", "wlk_mind_control" },
    ["md"] = { "wlk_mass_dispel", "wlk_misdirection" },
    ["ms"] = { "wlk_main_spec", "wlk_mortal_strike" },
    ["pom"] = { "wlk_prayer_of_mending", "wlk_presence_of_mind" },
    ["ps"] = { "wlk_pain_suppression", "wlk_plague_strike", "wlk_predator_s_swiftness" },
    ["rf"] = { "wlk_rapid_fire", "wlk_rotface" },
    ["rs"] = { "rs", "wlk_rune_strike" },
    ["ss"] = { "wlk_sacred_shield", "wlk_scourge_strike", "wlk_silencing_shot", "wlk_sinister_strike", "wlk_soulstone_resurrection", "wlk_steady_shot", "wlk_sweeping_strikes" },
    ["toc"] = { "toc", "wlk_trial_of_the_champion" },
    ["weekly"] = { "guildweekly", "weekly" },
}
P.zoneHints = {
    ["dungeon"] = { "ahn'kahet: the old kingdom", "ak", "anomalus", "argent confessor paletress", "azjol-nerub", "bronjahm", "cos", "culling of stratholme", "cyanigosa", "devourer of souls", "drak'tharon keep", "drakos the interrogator", "dtk", "eadric the pure", "eck the ferocious", "falric", "forge of souls", "forgemaster garfrost", "fos", "foss", "gal'darah", "gd", "gundrak", "halls of lightning", "halls of reflection", "halls of stone", "herald volazj", "hol", "hor", "hos", "ionar", "jedoga shadowseeker", "keristrasza", "king ymiron", "krick and ick", "ley-guardian eregos", "loken", "mal'ganis", "marwyn", "nexus", "oculus", "old kingdom", "pit of saron", "pos", "poss", "salramm the fleshcrafter", "scourgelord tyrannus", "sjonnir the ironshaper", "skadi the ruthless", "the black knight", "the culling of stratholme", "the forge of souls", "the nexus", "the oculus", "the violet hold", "toc", "toc5", "trial of the champion", "tribunal of ages", "uk", "utgarde keep", "utgarde pinnacle", "vh", "violet hold" },
    ["icc"] = { "blood prince council", "blood-queen lana'thel", "deathbringer saurfang", "festergut", "gunship battle", "icc", "icecrown citadel", "lady deathwhisper", "lich king", "lk", "lord marrowgar", "professor putricide", "rotface", "sindragosa", "sindy", "valithria dreamwalker" },
    ["naxx"] = { "anub'rekhan", "four horsemen", "gluth", "gothik the harvester", "grand widow faerlina", "grobbulus", "heigan the unclean", "instructor razuvious", "kel'thuzad", "loatheb", "maexxna", "naxx", "naxxramas", "noth the plaguebringer", "patchwerk", "sapphiron", "thaddius" },
    ["otherraid"] = { "archavon the stone watcher", "emalon the storm watcher", "eoe", "koralon the flame watcher", "malygos", "onyxia", "onyxia's lair", "sartharion", "the eye of eternity", "the obsidian sanctum", "toravon the ice watcher", "vault of archavon", "voa" },
    ["rs"] = { "baltharus the warborn", "general zarithrian", "halion", "ruby sanctum", "saviana ragefire" },
    ["toc"] = { "acidmaw", "anub'arak", "dreadscale", "faction champions", "gormok the impaler", "icehowl", "lord jaraxxus", "northrend beasts", "togc", "trial of the crusader", "trial of the grand crusader", "twin val'kyr" },
    ["ulduar"] = { "algalon the observer", "assembly of iron", "auriaya", "flame leviathan", "freya", "general vezax", "hodir", "ignis the furnace master", "kologarn", "mimiron", "razorscale", "thorim", "uldu", "ulduar", "xt-002 deconstructor", "yogg-saron" },
}
P.instanceZones = {
    ["ahn'kahet: the old kingdom"] = "dungeon",
    ["azjol-nerub"] = "dungeon",
    ["drak'tharon keep"] = "dungeon",
    ["gundrak"] = "dungeon",
    ["halls of lightning"] = "dungeon",
    ["halls of reflection"] = "dungeon",
    ["halls of stone"] = "dungeon",
    ["icecrown citadel"] = "icc",
    ["naxxramas"] = "naxx",
    ["onyxia's lair"] = "otherraid",
    ["pit of saron"] = "dungeon",
    ["ruby sanctum"] = "rs",
    ["the culling of stratholme"] = "dungeon",
    ["the eye of eternity"] = "otherraid",
    ["the forge of souls"] = "dungeon",
    ["the nexus"] = "dungeon",
    ["the obsidian sanctum"] = "otherraid",
    ["the oculus"] = "dungeon",
    ["the violet hold"] = "dungeon",
    ["trial of the champion"] = "dungeon",
    ["trial of the crusader"] = "toc",
    ["trial of the grand crusader"] = "toc",
    ["ulduar"] = "ulduar",
    ["utgarde keep"] = "dungeon",
    ["utgarde pinnacle"] = "dungeon",
    ["vault of archavon"] = "otherraid",
    ["乌特加德之巅"] = "dungeon",
    ["乌特加德城堡"] = "dungeon",
    ["冠军的试炼"] = "dungeon",
    ["冰冠堡垒"] = "icc",
    ["净化斯坦索姆"] = "dungeon",
    ["十字军的试炼"] = "toc",
    ["古达克"] = "dungeon",
    ["大十字军的试炼"] = "toc",
    ["奥妮克希亚的巢穴"] = "otherraid",
    ["奥杜尔"] = "ulduar",
    ["安卡赫特：古代王国"] = "dungeon",
    ["岩石大厅"] = "dungeon",
    ["映像大厅"] = "dungeon",
    ["永恒之眼"] = "otherraid",
    ["灵魂洪炉"] = "dungeon",
    ["紫罗兰监狱"] = "dungeon",
    ["红玉圣殿"] = "rs",
    ["纳克萨玛斯"] = "naxx",
    ["艾卓-尼鲁布"] = "dungeon",
    ["萨隆矿坑"] = "dungeon",
    ["达克萨隆要塞"] = "dungeon",
    ["闪电大厅"] = "dungeon",
    ["阿尔卡冯的宝库"] = "otherraid",
    ["魔枢"] = "dungeon",
    ["魔环"] = "dungeon",
    ["黑曜石圣殿"] = "otherraid",
}
-- END GENERATED WLK LEXICON

-- Compile once and prefer the longest literal alias at overlapping positions.
local aliases, aliasGroups, byAlias = {}, {}, {}
for id, concept in pairs(P.concepts) do
    for _, alias in ipairs(concept.aliases) do
        local entry = { id = id, alias = alias }
        aliases[#aliases + 1] = entry
        if not byAlias[alias] then
            byAlias[alias] = { alias = alias, entries = {} }
            aliasGroups[#aliasGroups + 1] = byAlias[alias]
        end
        local entries = byAlias[alias].entries
        entries[#entries + 1] = entry
    end
end
table.sort(aliases, function(a, b)
    if #a.alias ~= #b.alias then return #a.alias > #b.alias end
    if a.alias ~= b.alias then return a.alias < b.alias end
    return a.id < b.id
end)
table.sort(aliasGroups, function(a, b)
    if #a.alias ~= #b.alias then return #a.alias > #b.alias end
    return a.alias < b.alias
end)

-- Every raid shortcut recognized in recruitment gating. One list feeds the
-- anywhere check, the anchored opening check and the "for <raid>" connector.
local RAID_WORDS = { "icc", "lcc", "rs", "toc", "togc", "ruby", "ulduar", "naxx", "nax",
    "naxxramas", "sunwell", "voa", "onyxia", "onixya", "os", "bwl", "blackwing lair", "black wing lair" }

local abstractRoles = {tank=true,healer=true,dps=true,ranged=true,melee=true,mt=true}

local classNames = {
    dk = { "dk", "bdk", "udk", "death knight" }, druid = { "druid", "feral", "resto druid" },
    hunter = { "hunter", "hunt" }, mage = { "mage" }, paladin = { "paladin", "pala", "pally", "hpala", "ppala", "ret" },
    priest = { "priest", "disc", "disco", "shadow priest", "shadowpriest", "spriest" }, rogue = { "rogue", "rouge", "rog" },
    shaman = { "shaman", "sham", "rsham" }, warlock = { "warlock", "wlock", "lock" }, warrior = { "warrior", "warr" },
}

-- Precomputed at load so per-message work never rebuilds them. roleAliases
-- keeps the longest-first order of `aliases`; the sentence tables keep the
-- first entry for each "lfm <alias>" / "lfg <alias>" whole-message key, which
-- is exactly the entry the previous linear scan returned first.
local roleAliases, lfmSentences, lfgSentences = {}, {}, {}
for _, entry in ipairs(aliases) do
    if P.concepts[entry.id].role and entry.alias ~= "rdude" and entry.alias ~= "retry"
        and entry.id ~= "dlockrole" and entry.id ~= "fmagerole" then
        roleAliases[#roleAliases + 1] = entry
        local lfmKey = "lfm " .. entry.alias
        if not lfmSentences[lfmKey] then lfmSentences[lfmKey] = entry end
        local lfgKey = "lfg " .. entry.alias
        if not lfgSentences[lfgKey] then lfgSentences[lfgKey] = entry end
    end
end

-- Word tokens of a literal ([%w_]+ runs). A literal with edge word-boundary
-- checks can only match a text whose word set contains every token, so token
-- membership is an exact skip test for the alias scan, word() and zone hints.
local function literalTokens(value)
    local tokens, from = {}, 1
    while from <= #value do
        local a, b = value:find("[%w_]+", from)
        if not a then break end
        tokens[#tokens + 1] = value:sub(a, b)
        from = b + 1
    end
    return tokens
end

-- Word-boundary find patterns with their word tokens, keyed by literal text.
local wordInfos = {}
local function wordInfo(alias)
    local info = wordInfos[alias]
    if not info then
        info = { pattern = "%f[%w_]" .. alias .. "%f[^%w_]", tokens = literalTokens(alias) }
        wordInfos[alias] = info
    end
    return info
end
-- Bytes matching the [%w_] pattern class (letters, digits, underscore).
local ISWORD = {}
for i = 48, 57 do ISWORD[i] = true end
for i = 65, 90 do ISWORD[i] = true end
for i = 97, 122 do ISWORD[i] = true end
ISWORD[95] = true
local raidOpenPatterns, countedRolePatterns = {}, {
    "%f[%d][1-9]%d*%s*x?%s*healer%f[^%w_]", "%f[%d][1-9]%d*%s*x?%s*heal%f[^%w_]",
    "%f[%d][1-9]%d*%s*x?%s*tank%f[^%w_]", "%f[%d][1-9]%d*%s*x?%s*dps%f[^%w_]",
}
for _, name in ipairs(RAID_WORDS) do
    raidOpenPatterns[name] = "^" .. name .. "%f[^%w_]"
end

for _, group in ipairs(aliasGroups) do
    group.rank = _
    group.tokens = literalTokens(group.alias)
end
-- Groups indexed by their first token: the message's own words pull the
-- candidate list, which is then restored to global longest-first rank order.
local groupsByFirstToken = {}
for _, group in ipairs(aliasGroups) do
    local first = group.tokens[1]
    local bucket = groupsByFirstToken[first]
    if not bucket then bucket = {}; groupsByFirstToken[first] = bucket end
    bucket[#bucket + 1] = group
end
local zoneHintsByToken = {}
for zone, hints in pairs(P.zoneHints) do
    for _, hint in ipairs(hints) do
        local entry = { hint = hint, zone = zone, tokens = literalTokens(hint) }
        local first = entry.tokens[1]
        local bucket = zoneHintsByToken[first]
        if not bucket then bucket = {}; zoneHintsByToken[first] = bucket end
        bucket[#bucket + 1] = entry
    end
end

-- Role aliases bucketed by first byte; roleAliases stays longest-first, so
-- each bucket keeps that order and the first hit is the longest prefix.
local roleByFirstByte = {}
for _, entry in ipairs(roleAliases) do
    local first = entry.alias:byte()
    local bucket = roleByFirstByte[first]
    if not bucket then bucket = {}; roleByFirstByte[first] = bucket end
    bucket[#bucket + 1] = entry
end

local function roleEntryAt(s)
    local bucket = s ~= "" and roleByFirstByte[s:byte()] or nil
    if not bucket then return nil end
    for _, entry in ipairs(bucket) do
        local alias = entry.alias
        if #alias <= #s and s:sub(1, #alias) == alias
            and not s:sub(#alias + 1, #alias + 1):match("[%w_]") then return entry end
    end
end

-- Only group messages inherit the current instance. History must not inherit
-- today's location, and a public advertisement concerns its own named raid.
function P.ChatContext(category, history)
    local group = category == "PARTY" or category == "RAID" or category == "RAID_WARNING" or category == "BATTLEGROUND"
    local context = { group = group }
    if group and not history and type(GetInstanceInfo) == "function" then
        local ok, name, kind = pcall(GetInstanceInfo)
        if ok and type(name) == "string" and (kind == "party" or kind == "raid") then
            context.zone = P.instanceZones[name:lower()]
        end
    end
    return context
end

-- Links and textures are opaque: neither their metadata nor display names are terms.
-- Byte dispatch keeps the common path free of per-character substring calls:
-- only "|" (124) and "{" (123) need the marker logic.
local CHAR_OF_BYTE = {}
for i = 0, 255 do CHAR_OF_BYTE[i] = string.char(i) end
local ICON_TAGS = { star=true, circle=true, diamond=true, triangle=true,
    moon=true, square=true, cross=true, skull=true }

local function scanVisible(text)
    local out, protected, i = {}, false, 1
    local starts, stops, controls = {}, {}, {}
    local n = 0
    local function emit(char, first, last)
        n = n + 1
        out[n], starts[n], stops[n] = char, first, last
    end
    local function control(first, last)
        controls[#controls + 1] = { start = first, stop = last }
    end
    local len = #text
    while i <= len do
        local b = text:byte(i)
        if b == 124 then -- "|"
            local marker = text:sub(i, i + 1)
            if marker == "|H" then
                local first = text:find("|h", i + 2, true)
                local last = first and text:find("|h", first + 2, true)
                if not last then return nil end
                emit("\001", 0, 0); control(i, last + 1)
                protected, i = true, last + 2
            elseif marker == "|T" then
                local last = text:find("|t", i + 2, true)
                if not last then return nil end
                emit("\001", 0, 0); control(i, last + 1)
                protected, i = true, last + 2
            elseif marker == "|c" then
                if not text:sub(i + 2, i + 9):match("^%x%x%x%x%x%x%x%x$") then return nil end
                control(i, i + 9); i = i + 10
            elseif marker == "|r" then
                control(i, i + 1); i = i + 2
            elseif marker == "||" then
                emit("|", i, i + 1); control(i, i + 1); i = i + 2
            else
                return nil -- Unknown or malformed control text: preserve it without analysis.
            end
        elseif b == 123 then -- "{"
            local last = text:find("}", i + 1, true)
            -- A missing brace is ordinary text; only complete known tags are icons.
            local tag = last and text:sub(i + 1, last - 1):lower() or ""
            if tag:match("^rt[1-8]$") or ICON_TAGS[tag] then
                emit("\001", 0, 0); control(i, last)
                protected, i = true, last + 1
            else
                emit("{", i, i); i = i + 1
            end
        else
            n = n + 1
            out[n], starts[n], stops[n] = CHAR_OF_BYTE[b], i, i
            i = i + 1
        end
    end
    return table.concat(out), protected, starts, stops, controls
end

-- One message flows through BlockReason, Translate and RecordMessage within a
-- single event, so the same raw text is scanned several times. A one-slot memo
-- collapses those to one scan; the returned tables are read-only downstream.
local memoText, memoVisible, memoProtected, memoStarts, memoStops, memoControls
function P.VisibleText(text)
    if text ~= memoText then
        memoVisible, memoProtected, memoStarts, memoStops, memoControls = scanVisible(text)
        memoText = text
    end
    return memoVisible, memoProtected, memoStarts, memoStops, memoControls
end

-- Analysis positions point back to raw bytes. Spaces inserted to recognize
-- compounds have no raw bytes; normalization never edits the displayed message.
-- Byte tables mirror Lua 5.1 semantics exactly: %s and string.lower touch only
-- ASCII bytes, so higher bytes pass through unchanged.
local LOWER_BYTES, SPACE_BYTES = {}, {}
for i = 0, 255 do LOWER_BYTES[i] = string.char(i) end
for i = 65, 90 do LOWER_BYTES[i] = string.char(i + 32) end
for b = 9, 13 do SPACE_BYTES[b] = true end
SPACE_BYTES[32] = true

local function mappedNormalize(visible, starts, stops)
    local out, first, last = {}, {}, {}
    local n, i, len = 0, 1, #visible
    while i <= len do
        local b = visible:byte(i)
        if SPACE_BYTES[b] then
            local nextByte = i + 1
            while nextByte <= len and SPACE_BYTES[visible:byte(nextByte)] do
                nextByte = nextByte + 1
            end
            if n > 0 and nextByte <= len then
                n = n + 1
                out[n] = " "
                first[n], last[n] = starts[i], stops[nextByte - 1]
            end
            i = nextByte
        else
            n = n + 1
            out[n] = LOWER_BYTES[b]
            first[n], last[n] = starts[i], stops[i]
            i = i + 1
        end
    end
    return table.concat(out), first, last
end

local function splitMapped(text, starts, stops, pattern, keepX)
    local cuts, from = {}, 1
    while from <= #text do
        local first, last, cut = text:find(pattern, from)
        if not first then break end
        if not keepX or text:sub(cut, last) ~= "x" then cuts[cut] = true end
        from = last + 1
    end
    if not next(cuts) then return text, starts, stops end
    local out, rawStarts, rawStops = {}, {}, {}
    for i = 1, #text do
        if cuts[i] then out[#out + 1] = " "; rawStarts[#out], rawStops[#out] = 0, 0 end
        out[#out + 1] = text:sub(i, i)
        rawStarts[#out], rawStops[#out] = starts[i], stops[i]
    end
    return table.concat(out), rawStarts, rawStops
end

P.defaultColors = { dungeon = "C77DFF", role = "66E870", other = "6FD6FF" }
function P.ColorHex(db, category)
    local value = db and type(db.colors)=="table" and db.colors[category]
    if type(value)=="string" and value:match("^%x%x%x%x%x%x$") then return value:upper() end
    return P.defaultColors[category] or P.defaultColors.other
end
function P.ColorRGB(db, category)
    local hex=P.ColorHex(db,category)
    return tonumber(hex:sub(1,2),16)/255,tonumber(hex:sub(3,4),16)/255,tonumber(hex:sub(5,6),16)/255
end
function P.ConceptColorCategory(id)
    local concept=P.concepts[id]
    if not concept then return "other" end
    if concept.role then return "role" end
    local category=concept.category or ""
    if category=="副本" or category:match("^首领/") or category:match("^副本机制/") then return "dungeon" end
    if ({icc=true,rs=true,bt=true,togc=true,toc=true,hor=true,lk=true,sindy=true})[id] then return "dungeon" end
    return "other"
end
local function label(id, db)
    local custom = db and db.labels and db.labels[id]
    local value = type(custom)=="string" and custom~="" and custom or P.concepts[id].label
    if db and db.colorByCategory then
        local category = P.ConceptColorCategory(id)
        -- "Other" text follows the channel/base color; only dungeon and
        -- class/role terms carry their own accent.
        if category == "other" then return value end
        return "|cff"..P.ColorHex(db,category)..value.."|r"
    end
    return value
end

local function mixedText(raw, matches, starts, stops, controls, db)
    local out, cursor, controlIndex = {}, 1, 1
    for _, match in ipairs(matches) do
        local first, last = starts[match.start], stops[match.stop]
        out[#out + 1] = raw:sub(cursor, first - 1)
        out[#out + 1] = label(match.id, db)
        -- Retain color/escape controls that occurred inside a replaced expression.
        -- Opaque links/icons are barriers and cannot be part of such a match.
        while controls[controlIndex] and controls[controlIndex].start <= last do
            local span = controls[controlIndex]
            if span.start >= first then out[#out + 1] = raw:sub(span.start, span.stop) end
            controlIndex = controlIndex + 1
        end
        cursor = last + 1
    end
    out[#out + 1] = raw:sub(cursor)
    return "→ 翻译：" .. table.concat(out)
end

-- Annotate mode: keep the original wording untouched and append each
-- recognized term's translation in parentheses after it -- nothing is
-- replaced and nothing is hidden, so no [orig] link is needed.
local function annotateText(raw, matches, starts, stops, db)
    local out, cursor = {}, 1
    for _, match in ipairs(matches) do
        local first, last = starts[match.start], stops[match.stop]
        out[#out + 1] = raw:sub(cursor, last)
        out[#out + 1] = "(" .. label(match.id, db) .. ")"
        cursor = last + 1
    end
    out[#out + 1] = raw:sub(cursor)
    return "→ 翻译：" .. table.concat(out)
end

function P.Translate(raw, db, context)
    -- Localized DKP-addon bookkeeping is already readable; do not expand its
    -- DKP labels into a second chat line or change player names in those notices.
    if type(raw) == "string" and raw:match("^QDKP2?>") and
        (raw:find("获得",1,true) or raw:find("消费",1,true) or raw:find("购买",1,true)) then return nil end
    local visible, protected, starts, stops, controls = P.VisibleText(raw)
    if not visible then return nil end
    local text
    text, starts, stops = mappedNormalize(visible, starts, stops)
    -- Plain web addresses are not WoW hyperlinks. Mask their analysis bytes
    -- without moving the raw offsets or feeding URL words into context checks.
    if text:find("://",1,true) or text:find("www.",1,true) or text:find("discord.gg/",1,true) then
        for _, pattern in ipairs({"https?://%S+", "www%.%S+", "discord%.gg/%S+"}) do
            text = text:gsub(pattern, function(url)
                protected = true
                return string.rep(" ", #url)
            end)
        end
    end
    -- Preserve a leading guild tag even when it contains dungeon or class aliases.
    -- Spaces keep the normalized-to-raw offsets intact; matching resumes after it.
    local guildTagStart, guildTagStop = text:find("^%s*<[^<>]+>")
    if not guildTagStart then
        -- Some guild tags use doubled angle brackets <<Name>>.
        guildTagStart, guildTagStop = text:find("^%s*<<[^<>]+>>")
    end
    if guildTagStart then
        text = string.rep(" ", guildTagStop) .. text:sub(guildTagStop + 1)
        protected = true
    end
    -- A full translation must match an entire whitelisted sentence, not a prefix.
    if not protected and not text:find("[\128-\255]") and (not db or db.display ~= "annotate") then
        local sentence = lfmSentences[text]
        if sentence then return "→ 译文：队伍招募" .. label(sentence.id, db) end
        sentence = lfgSentences[text]
        if sentence then return "→ 译文：" .. label(sentence.id, db) .. "求组" end
        if text == "don't pull yet" or text == "do not pull yet" then return "→ 译文：先别开怪" end
    end

    -- Underscores are separators only in an anchored recruitment advertisement.
    -- Their mapped raw bytes remain intact outside a replaced known phrase.
    local opening = text:gsub("^[%s:;!%-\001]+", ""):gsub("^lmf%f[^%w_]", "lfm"):gsub("^llfm%f[^%w_]", "lfm"):gsub("^neeed%f[^%w_]", "need")
    if opening:match("^lf[mg]_") then text = text:gsub("_", " ") end
    -- Split only supported dungeon compounds and numeric role prefixes. Raw text
    -- is untouched; the expanded text is used solely for boundary matching.
    for _, dungeon in ipairs({ "icc", "rs", "ruby", "togc" }) do
        text, starts, stops = splitMapped(text, starts, stops, "%f[%w_]" .. dungeon .. "()%d+")
    end
    for _, size in ipairs({ "10", "25" }) do
        text, starts, stops = splitMapped(text, starts, stops, "%f[%w_]toc()" .. size)
        text, starts, stops = splitMapped(text, starts, stops, "%f[%w_]voa()" .. size)
    end
    text, starts, stops = splitMapped(text, starts, stops, "%f[%d]%d+[.,]?%d*%s*k()gs%f[^%w_]")
    text, starts, stops = splitMapped(text, starts, stops, "%f[%w_]%d+x()[%a]")
    text, starts, stops = splitMapped(text, starts, stops, "%f[%w_]%d+()[%a]+", true)
    text, starts, stops = splitMapped(text, starts, stops, "%f[%w_]rs()hc%f[^%w_]")
    text, starts, stops = splitMapped(text, starts, stops, "%f[%w_]rs()nm%f[^%w_]")
    text, starts, stops = splitMapped(text, starts, stops, "%f[%w_]rdf()hc%f[^%w_]")
    text, starts, stops = splitMapped(text, starts, stops, "%f[%w_]rdf()nm%f[^%w_]")
    text, starts, stops = splitMapped(text, starts, stops, "%f[%w_]%d+()more%f[^%w_]")
    text, starts, stops = splitMapped(text, starts, stops, "%f[%w_]gs()%d+")
    -- Words of the finished text. Literal scans with edge word-boundary checks
    -- can only match when every token of the literal is one of these words.
    local wordSet = {}
    do
        local from = 1
        while from <= #text do
            local a, b = text:find("[%w_]+", from)
            if not a then break end
            wordSet[text:sub(a, b)] = true
            from = b + 1
        end
    end
    -- Collect boundary-valid alias occurrences before any context-flag work:
    -- a message that names no known term anywhere returns immediately, which
    -- is what ordinary social chat resolves to after a full run anyway.
    -- Candidates come from the message's own words, then restore the global
    -- longest-first order that the overlap rules depend on.
    local occurrences, candidates = {}, {}
    for word in pairs(wordSet) do
        local bucket = groupsByFirstToken[word]
        if bucket then
            for _, group in ipairs(bucket) do candidates[#candidates + 1] = group end
        end
    end
    table.sort(candidates, function(a, b) return a.rank < b.rank end)
    for _, group in ipairs(candidates) do
        local tokens = group.tokens
        local present = true
        for i = 2, #tokens do
            if not wordSet[tokens[i]] then present = false; break end
        end
        if present then
            local from = 1
            while from <= #text do
                local start, stop = text:find(group.alias, from, true)
                if not start then break end
                if not ISWORD[text:byte(start - 1)] and not ISWORD[text:byte(stop + 1)] then
                    occurrences[#occurrences + 1] = { group = group, start = start, stop = stop }
                end
                from = stop + 1
            end
        end
    end
    if #occurrences == 0 then return nil end
    local function word(alias)
        local info = wordInfo(alias)
        local tokens = info.tokens
        for i = 1, #tokens do
            if not wordSet[tokens[i]] then return nil end
        end
        return text:find(info.pattern)
    end
    opening = text:gsub("^[%s:;!%-\001]+", ""):gsub("^lmf%f[^%w_]", "lfm"):gsub("^llfm%f[^%w_]", "lfm"):gsub("^neeed%f[^%w_]", "need")
    -- Bracketed intent prefixes ([WTB], [LFG], ...) anchor like the bare word.
    opening = opening:gsub("^%[%s*wt([bs])%s*%]", "wt%1")
    opening = opening:gsub("^%[%s*lf([mg])%s*%]", "lf%1")
    -- Numbered raid advertisements retain their number in displayed text.
    local numbered = opening:match("^#%d+[%s>%-:]+(.+)")
    if numbered then numbered=numbered:gsub("^[%s>%-:]+", "") end
    if numbered and (numbered:match("^lf[mg]%f[^%w_]") or numbered:match("^icc%s+%d")
        or numbered:match("^rs%s+%d") or numbered:match("^toc%s+%d")) then opening = numbered end
    local function anyRaidWord(s)
        for _, name in ipairs(RAID_WORDS) do
            if s:find(wordInfo(name).pattern) then return true end
        end
        return false
    end
    -- A role alias (with optional leading count) at the string start; returns
    -- the matched entry so callers can inspect the remainder.
    -- A nonzero "N heal/tank/dps" later in the string ("0 heal" is not recruitment).
    local function hasCountedRole(s)
        for i = 1, #countedRolePatterns do
            if s:find(countedRolePatterns[i]) then return true end
        end
        return false
    end
    local raid = anyRaidWord(text)
    -- Fresh ToC/RS use the same raid-prefix rules as fresh ICC. Only the
    -- context view changes; mapped display text keeps the original prefix.
    local raidPrefix=opening:gsub("^fresh%s+", "")
    local bracketedRaid=raidPrefix:match("^%[%s*([^%]]+)%]")
    if bracketedRaid and (bracketedRaid:find("%f[%d]10%f[^%d]") or bracketedRaid:find("%f[%d]25%f[^%d]")) then
        raidPrefix=bracketedRaid
    end
    local raidOpening = false
    for _, name in ipairs(RAID_WORDS) do
        if raidPrefix:match(raidOpenPatterns[name]) then raidOpening = true break end
    end
    -- LF alone is ambiguous. An explicit positive count followed by a known
    -- role identifies a recruitment request without guessing from its tail.
    local dungeon = word("fos") or word("pos") or word("foss") or word("poss")
        or word("trial of the champion") or word("rdf") or word("rdhc") or word("rhc") or word("df hc") or word("hor") or word("dongon")
    local lfCount, lfRoleStart = opening:match("^lf%s+(%d+)x?%s+()")
    local countedRecruit = false
    if lfCount and tonumber(lfCount) > 0 then
        local tail = opening:sub(lfRoleStart):gsub("^x%s+", "")
        if roleEntryAt(tail) then countedRecruit = true end
    end
    -- "LF DPS 1 HEAL ..." names a role first and a counted role later; a bare
    -- "LF tank" still stays unrecognized.
    if not countedRecruit then
        local lfMore = opening:match("^lf(%d+)m%f[^%w_]")
        if lfMore and tonumber(lfMore) > 0 then countedRecruit = true end
    end
    if not countedRecruit then
        local lfPos = opening:match("^lf%s+()")
        if lfPos then
            local entry = roleEntryAt(opening:sub(lfPos))
            if entry then
                local rest = opening:sub(lfPos + #entry.alias)
                -- "LF healer fos/pos ..." names the dungeon it recruits for.
                if hasCountedRole(rest) or raid or dungeon then countedRecruit = true end
            end
        end
    end
    local needRoleRaid = false
    local needTail = opening:match("^need%s+(.+)")
    if needTail and raid then
        needTail = needTail:gsub("^%d+x?%s*", "")
        local entry = roleEntryAt(needTail)
        if entry and not (entry.id == "shadow"
            and needTail:sub(#entry.alias + 1):match("^%s*[%+%-=]?%s*%d")) then
            needRoleRaid = true
        end
    end
    local guildRecruit = (word("guild") and (word("recruiting") or word("seeking")))
        or (guildTagStart and opening:match("^is recruiting%f[^%w_]"))
        or ((guildTagStart or word("guild")) and word("looking for players") and word("raid roster"))
        or (guildTagStart and text:find("forming additional raid groups", 1, true) and word("progression"))
        or (guildTagStart and word("recruiting"))
        or (word("recruiting") and (word("melee") or word("dps") or word("heal") or word("tank")
            or word("spec") or word("class")))
        or (guildTagStart and (word("looking for raiders") or word("filling")))
    local arenaRecruit = word("lf arena") or word("lf arena parner") or word("lf arena partner") or word("looking for arena partner")
        or word("looking for a 2v2 partner") or word("looking for 2v2 partner")
        or word("lf partner") or word("lf 2 v2") or word("lf 2 vs2") or word("lf 3 v3") or word("lf 5 v5")
        or word("lf 2 s") or word("lf 3 s") or word("lf 5 s") or word("arena games")
        or word("2 vs 2") or word("3 vs 3") or word("5 vs 5")
        or (word("arena") and (word("2 v2") or word("2 vs2") or word("3 v3") or word("5 v5")
            or word("2 vs 2") or word("3 vs 3") or word("5 vs 5")))
    local lastRole = opening:match("^last dps%f[^%w_]") or opening:match("^last healer%f[^%w_]")
        or opening:match("^last tank%f[^%w_]") or opening:match("^last heal%f[^%w_]")
    local shortRecruit = lastRole and (raid or dungeon or protected or (word("spec") and word("gs")))
        or (opening:match("^heal for%f[^%w_]") and raw:find("|Hquest:",1,true))
    local eofRoster = raidOpening and word("eof run") and
        (text:find("%f[%d][1-9]%d*%s+heal%f[^%w_]") or text:find("%f[%d][1-9]%d*%s+off tank%f[^%w_]")
        or text:find("%f[%d][1-9]%d*%s+tank%f[^%w_]"))
    local function startsRole(tail)
        return roleEntryAt(tail) ~= nil
    end
    local lookingTail = opening:match("^looking for%s+(.+)")
    local lookingRoster = lookingTail and raid and
        (lookingTail:match("^all%f[^%w_]") or lookingTail:match("^any%f[^%w_]")
        or startsRole(lookingTail:gsub("^%d+x?%s+", "")))
    local roleRoster = startsRole(opening) and (raid or dungeon)
        and (word("for") or word("and") or word("join"))
    local weeklyQuest = raw:find("|Hquest:24589:",1,true) or raw:find("|Hquest:24586:",1,true) or raw:find("|Hquest:24588:",1,true)
    local questRoster = weeklyQuest
        and (startsRole(opening) or (opening:match("^need%s+") and
            startsRole(opening:gsub("^need%s+", ""):gsub("^%d+x?%s+", ""))))
    local queueRoster = (word("que") or word("queue")) and startsRole(opening)
        and (opening:find("%f[%d]%d+%s*%-%s*%d+%f[^%d]") or word("normal") or word("hc"))
    -- A weekly raid or Black Temple achievement link supplies the activity
    -- when its body starts with a role request. Never scan link labels as prose.
    local linkedRaidRoster = (weeklyQuest or raw:find("|Hachievement:697:",1,true))
        and (opening:match("^need%s+all%f[^%w_]") or
            (opening:match("^need%s+") and startsRole(opening:gsub("^need%s+", ""):gsub("^only%s+", ""):gsub("^%d+x?%s*", ""))))
    local dmgCount=tonumber(opening:match("^(%d+)%s+dmg%f[^%w_]"))
    linkedRaidRoster = linkedRaidRoster or (weeklyQuest and
        (hasCountedRole(text) or (dmgCount and dmgCount>0 and dmgCount<=40) or opening:match("^lf%s+all%f[^%w_]")) )
    linkedRaidRoster = linkedRaidRoster or (weeklyQuest and hasCountedRole(text)
        and (opening:match("^lf%f[^%w_]") or opening:match("^need%f[^%w_]")))
    -- "rogue 5.5 lf icc 25", "1 dps HOR nm", "UH DK ... LF partner": a role
    -- opens the message and a context word follows; bare "war is hell" stays out.
    local roleOpening = false
    do
        local function roleGateAt(tail)
            local entry = roleEntryAt(tail)
            if not entry then return false end
            local rest = tail:sub(#entry.alias + 1)
            if not rest:match("^%s*%S") then return false end
            return word("lf") or word("lfm") or word("lfg") or word("lf1m") or raid or dungeon
                or word("last spot") or word("lasts spots") or word("last slots") or word("last stop")
                or word("2 v2") or word("2 vs2") or word("3 v3") or word("5 v5")
                or word("wtb") or word("wts") or word("looking for")
        end
        local pos = opening:match("^%d*%s*x?%s*()")
        local tail = opening:sub(pos)
        roleOpening = roleGateAt(tail)
        if not roleOpening then
            local anyPos = tail:match("^any%s+()")
            if anyPos then roleOpening = roleGateAt(tail:sub(anyPos)) end
        end
    end
    local parenRole = false
    if raidOpening then
        for capture in opening:gmatch("%(([^()]+)%)") do
            if roleEntryAt(capture:match("^%s*(.-)%s*$")) then parenRole = true; break end
        end
    end
    local needAllRaid = opening:match("^need%s+all%f[^%w_]") ~= nil and (raid or dungeon) or false
    -- Zero ("ICC 10 eof run 0 heal") is not a recruitment count.
    local countedRoles = raid and hasCountedRole(text)
    local guildSeeker = word("looking for a guild") or word("looking for guild")
        or word("lf raiding guild") or word("lf raid guild") or word("lf leveling guild") or word("lf guild")
    -- LF is resolved by the stated intent: a NEED/ALL request recruits;
    -- a role-led self-description or scored role following LF <raid> seeks.
    -- Do not infer seeking from a bare LF tank or unknown trailing text.
    local dungeonLastRole = dungeon and word("last spot") and (word("tank") or word("heal") or word("dps"))
    local lfRecruitRequest = opening:match("^lf%s+") and (raid or weeklyQuest or dungeon)
        and (word("need") or word("all") or dungeonLastRole)
        and not (word("do not need") or word("don't need") or word("no need"))
    local selfHead=opening:gsub("^%d+[.,]%d+%s*k?%s+", "")
    local selfRole=startsRole(selfHead)
    local namedRole=false
    if opening:match("^lf%s+") and raid and (word("gs") or text:find("%d+[.,]%d+")) then
        for _,occurrence in ipairs(occurrences) do
            for _,entry in ipairs(occurrence.group.entries) do
                if P.concepts[entry.id].role and not abstractRoles[entry.id] then namedRole=true; break end
            end
            if namedRole then break end
        end
    end
    local lfSeeking = word("lf") and raid and not word("guild") and not word("need") and not word("all")
        and not countedRecruit and not hasCountedRole(text)
        and (selfRole or (opening:match("^lf%s+") and (namedRole or word("rep farm") or word("repfram"))))
    local weeklyTail = opening:match("^weekly%s+need%s+(.+)") or opening:match("^weekley%s+need%s+(.+)")
    local weeklyRequest = false
    if weeklyTail then
        local count = tonumber(weeklyTail:match("^(%d+)%s+"))
        if not count or (count > 0 and count <= 40) then
            weeklyRequest = weeklyTail:match("^all%f[^%w_]") or startsRole(weeklyTail:gsub("^%d+%s+", ""))
        end
    end
    local taggedCount, taggedTail = opening:match("^@[%a]+%s+@(%d+)%s+random%s+(.+)")
    local taggedRoster = raid and taggedCount and tonumber(taggedCount)>0 and tonumber(taggedCount)<=40
        and startsRole(taggedTail) and not (word("do not need") or word("don't need") or word("no need"))
    local bossCount, bossTail = opening:match("^(%d+)%s+(.+)")
    local bossRoster = bossCount and tonumber(bossCount)>0 and tonumber(bossCount)<=40
        and startsRole(bossTail) and word("need") and word("lk")
        and (text:find("%f[%d]10%f[^%d]") or text:find("%f[%d]25%f[^%d]"))
        and not (word("do not need") or word("don't need") or word("no need"))
    local recruit = opening:match("^lf[mg]%f[^%w_]") or opening:match("^looking for more%f[^%w_]")
        or opening:match("^looking for group%f[^%w_]")
        or countedRecruit or needRoleRaid or guildRecruit or arenaRecruit or shortRecruit or eofRoster
        or lookingRoster or roleRoster or questRoster or linkedRaidRoster or queueRoster or guildSeeker or roleOpening
        or needAllRaid or countedRoles or lfRecruitRequest or lfSeeking
        or weeklyRequest or taggedRoster or bossRoster
        or (dungeon and (opening:match("^fos") or opening:match("^pos") or opening:match("^hor")
            or opening:match("^rdf") or opening:match("^rhc%f[^%w_]") or word("need")))
        or (raidOpening and (word("need") or word("lf all") or word("lfm")))
        or (word("warglaive") and word("offhand"))
        or (raidOpening and (word("frost") or word("nothing ress") or word("nothing res") or word("free roll") or word("class run") or word("class runs")))
        or (raw:find("|Hachievement:2136:", 1, true) and (word("heal") or word("dps") or word("tank")))
        or parenRole
    local trade = opening:match("^wt[bst]h?%f[^%w_]") or opening:match("^want to sell%f[^%w_]")
        or opening:match("^selling%f[^%w_]")
        or opening:match("^want to buy%f[^%w_]") or opening:match("^buy all%f[^%w_]")
        or opening:match("^buying%f[^%w_]")
        or (raw:find("|Hitem:",1,true) and (opening:match("^buy%f[^%w_]")
            or (opening:match("^%d+%s*gold%f[^%w_]") and word("wts"))))
    local toc25 = text:find("%f[%w_]toc%s+25%f[^%w_]")
    local tocRaid = toc25 or text:find("%f[%w_]toc%s+10%f[^%w_]") ~= nil
    local tocFive = text:find("%f[%w_]toc%s+5%f[^%d]")
    local raidTrade = trade and (word("icc") or tocRaid or word("togc") or word("ulduar")
        or word("naxx") or word("naxxramas") or text:find("%f[%w_]rs%s+25%f[^%d]")
        or text:find("%f[%w_]rs%s+10%f[^%d]"))
    recruit = recruit or raidTrade
    local zones = {}
    local zoneHintSeen = {}
    for word in pairs(wordSet) do
        local bucket = zoneHintsByToken[word]
        if bucket then
            for _, entry in ipairs(bucket) do
                if not zoneHintSeen[entry] and not zones[entry.zone] then
                    zoneHintSeen[entry] = true
                    local tokens = entry.tokens
                    local present = true
                    for i = 2, #tokens do
                        if not wordSet[tokens[i]] then present = false; break end
                    end
                    if present then
                        -- Literal matching is essential for apostrophes and punctuation.
                        local hint = entry.hint
                        local from = 1
                        while from <= #text do
                            local a, b = text:find(hint, from, true)
                            if not a then break end
                            if not text:sub(a - 1, a - 1):match("[%w_]") and not text:sub(b + 1, b + 1):match("[%w_]") then
                                zones[entry.zone] = true; break
                            end
                            from = b + 1
                        end
                    end
                end
            end
        end
    end
    if tocRaid then zones.toc = true end
    if recruit and (word("rs") or text:find("%f[%w_]ruby%s+10%f[^%d]")
        or text:find("%f[%w_]ruby%s+25%f[^%d]")) then zones.rs = true end
    -- A named destination in a message takes precedence over the live location.
    if not next(zones) and context and context.zone then zones[context.zone] = true end
    local game = recruit or next(zones) ~= nil or (context and context.group) or word("buff") or word("buffs") or word("rebuff")
    local ownerCache = {}
    local function actor(owner, start)
        local key = owner .. ":" .. start
        if ownerCache[key] ~= nil then return ownerCache[key] end
        local before = text:sub(1, start - 1)
        for class in owner:gmatch("[^/]+") do
            for _, name in ipairs(classNames[class] or {}) do
                local from = 1
                while from <= #before do
                    local a, b = before:find(name, from, true)
                    if not a then break end
                    if not before:sub(a - 1, a - 1):match("[%w_]") and not before:sub(b + 1, b + 1):match("[%w_]") then
                        local tail = before:sub(b + 1):gsub("[%s,:%-]", " ")
                        local valid = true
                        for token in tail:gmatch("%S+") do
                            if token ~= "please" and token ~= "pls" and token ~= "use" and token ~= "cast" and token ~= "pop"
                                and token ~= "give" and token ~= "buff" and token ~= "proc" and token ~= "uses" then valid = false; break end
                        end
                        if valid then ownerCache[key] = true; return true end
                    end
                    from = b + 1
                end
            end
        end
        ownerCache[key] = false; return false
    end
    local function uppercase(start, stop)
        return raw:sub(starts[start], stops[stop]):match("%u") ~= nil
    end
    local ordinarySkills = { blind=true, fear=true, kick=true, blink=true, purge=true, hex=true,
        hibernate=true, clone=true, rebirth=true, regrowth=true, evasion=true, feint=true,
        dismantle=true, berserk=true, typhoon=true, starfall=true, hysteria=true, taunt=true,
        dispel=true, interrupt=true }
    local function command(start, stop)
        local before, after = text:sub(1, start - 1), text:sub(stop + 1)
        if after:match("^%s+is%f[^%w_]") or after:match("^%s+my%f[^%w_]") then return false end
        return before:match("^[%s\001]*$") or before:match("please%s*$") or before:match("pls%s*$")
            or before:match("use%s*$") or before:match("cast%s*$")
            or before:match("don't%s*$") or before:match("do not%s*$")
    end
    local function allowed(entry, start, stop)
        local concept, alias = P.concepts[entry.id], entry.alias
        local guard = concept.guard
        if entry.id == "lfm" and alias == "lf" then
            return (countedRecruit or lfRecruitRequest) and not lfSeeking and start == text:find("lf", 1, true)
        end
        if entry.id=="lfg" and alias=="lf" then return lfSeeking,2 end
        if entry.id == "gold" and alias == "g" then
            return trade and text:sub(1,start-1):match("%d+%s*$")
        end
        if concept.wlk then
            local rule = concept.rules[alias]
            if entry.id=="wlk_trial_of_the_champion" and alias=="toc" then return recruit and tocFive, 2 end
            if alias == "gs" and text:sub(stop + 1):match("^%s*[%+]?%d") then return false end
            if alias == "rs" and recruit and text:sub(stop + 1):match("^%s*%d") then return false end
            if alias == "dnd" and text:sub(start - 1, start - 1) == "/" then return false end
            if alias == "bl" and (text:sub(1, start - 1):match("to%s*$") or word("blacklist")) then return false end
            if alias == "how" and text:sub(stop + 1):match("^%s+[a-z]+") then
                local first = text:sub(stop + 1):match("^%s+([a-z]+)")
                if first == "many" or first == "much" or first == "to" or first == "are" or first == "is" then return false end
            end
            if alias == "ot" and not (text:sub(1, start - 1):match("%f[%d]%d+%s*x?%s*$")
                or text:sub(1, start - 1):match("mt[%+/]+$")
                or text:sub(stop + 1):match("^%s*tank%f[^%w_]")) then return false end
            if ordinarySkills[alias] and not (concept.owner and actor(concept.owner, start)) then
                if not game or not command(start, stop) then return false end
                if alias == "kick" and (word("from group") or word("from raid") or word("offline")) then return false end
            end
            if rule == "name" then return true end
            if rule == "owner" or rule == "ownerupper" then
                return actor(concept.owner, start) and (rule ~= "ownerupper" or uppercase(start, stop)), 3
            elseif rule == "ownerbuff" then
                if word("buff") or word("buffs") or word("rebuff") then return true, 4 end
                return actor(concept.owner, start), 3
            elseif rule == "skill" then
                return game or actor(concept.owner, start), 1
            elseif rule == "zone" then
                return zones[concept.zone], 2
            elseif rule == "upper" then
                return game and uppercase(start, stop), 1
            elseif rule == "dungeon" then
                if alias == "up" and text:sub(1,start-1):match("gs%s*$") then return false end
                if ({an=true,ak=true,up=true,os=true})[alias] then
                    local head=text:sub(1,start-1)
                    if not uppercase(start,stop) and not head:match("^[%s\001]*lf[gm]%s*$")
                        and not head:match("dungeon%s*$") then return false end
                end
                return recruit or word("dungeon") or word("dungeons"), 1
            elseif rule == "buff" then
                return word("buff") or word("buffs") or word("rebuff"), 4
            elseif rule == "loot" then
                return game and (word("loot") or word("roll") or word("spec")), 1
            elseif rule == "flow" or rule == "game" then
                if alias == "cc" and (word("proc") or word("procs") or word("clearcasting")) then return false end
                return game or (concept.owner and actor(concept.owner, start)), 1
            end
            return false
        end
        if guard == "disc" then
            return (alias ~= "disc" and alias ~= "disco") or text == alias or recruit or word("priest")
        elseif guard == "shadow" and alias == "sp" then
            if not recruit or word("spell power") or word("spellpower") then return false end
            -- A stat such as SP 3000 or +SP is not a role request.
            local tail = text:sub(stop + 1)
            local head = text:sub(1, start - 1)
            local numberedRole = head:match("%f[%w_]%d+x%s+$")
            local plusTail = tail:match("^%s*[,/]%s*%+?%s*(.+)")
            local rosterPlus = text:sub(start - 1, start - 1) == "+" and plusTail and startsRole(plusTail)
            return (text:sub(start - 1, start - 1) ~= "+" or rosterPlus)
                and not head:match("%f[%w_]%d+%s+$")
                and (numberedRole or not tail:match("^%s*[%+%-=]?%s*%d")
                    or tail:match("^%s*%d+%s*/%s*%d+"))
        elseif guard == "bearrole" then
            if alias == "bear" and text:sub(stop+1):match("^%s+mount%f[^%w_]") then return false end
            return recruit or (trade and (word("druid") or word("feral")))
        elseif guard == "restodruid" then
            if alias == "tree" then return recruit and not trade end
            if alias == "rdude" then return recruit and (word("heal") or word("healer") or word("healers") or word("heals")) end
            return recruit or trade
        elseif guard == "sindy" then return alias ~= "sindi" or zones.icc
        elseif guard == "balance" then
            if ({balance=true,boom=true,bomie=true,bmmie=true,bommier=true,boomky=true,boomi=true,bala=true,bommy=true})[alias] then return recruit or trade end
            return true
        elseif guard == "demo" then
            return (alias ~= "demo" and alias ~= "demon") or recruit or trade
        elseif guard == "rubyraid" then
            if alias == "ruby" then
                local tail=text:sub(stop+1)
                return recruit and (tail:match("^%s+10%f[^%d]") or tail:match("^%s+25%f[^%d]"))
            end
            if alias == "rs" and actor("dk",start) and not text:sub(stop+1):match("^%s*%d") then return false end
            return recruit or text==alias or #alias>8
        elseif guard == "servertime" then
            local before=text:sub(1,start-1)
            return (alias ~= "st" and alias ~= "svt") or (recruit and (before:match("%d%d?:%d%d%s*$")
                or (word("raid time") and (before:match("%d%d?%s*[ap]m%s*$") or before:match("%d%d?%s*$")))))
        elseif guard == "recruit" then
            if entry.id=="ret" and trade and alias~="retry" then return true end
            if alias == "retry" then
                return recruit and raid and text:sub(1,start-1):match("/%s*$")
                    and text:sub(stop+1):match("^%s*/")
            end
            if alias == "mini" then return recruit and text:sub(stop+1):match("^%s+gs%f[^%w_]") end
            if entry.id=="hc" and alias=="h" then
                return recruit and ((raid and (text:sub(1,start-1):match("%f[%d]25%s*$")
                    or text:sub(1,start-1):match("%f[%d]10%s*$")))
                    or (dungeon and text:sub(1,start-1):match("[a-z]+%s*$"))
                    or (word("icc") and text:sub(1,start-1):match("%(%s*gs%s*$")))
            end
            if alias == "gs" and game and text:sub(stop + 1):match("^%s*[%+]?%d") then return true end
            if alias == "gs" and actor("priest", start) and not text:sub(stop + 1):match("^%s*[%+]?%d") then return false end
            if alias == "rs" and actor("dk", start) and not text:sub(stop + 1):match("^%s*%d") then return false end
            if context and context.group and (entry.id == "icc" or entry.id == "lk" or entry.id == "tank" or entry.id == "healer" or entry.id == "dps") then return true end
            return recruit or text == alias or #alias > 8
        elseif guard == "vocabulary" then
            return game or trade
        elseif guard == "advert" then
            return recruit or trade or text == alias
        elseif guard == "gunshipgs" then
            if alias == "gunshiphc" then return recruit and word("icc") end
            -- In ICC recruitment, (GS HC) describes the Gunship difficulty.
            -- A score requires a number; neither scores nor priest spell GS match this form.
            return recruit and word("icc") and text:sub(1,start-1):match("%(%s*$")
                and (text:sub(stop+1):match("^%s+hc%s*%)") or text:sub(stop+1):match("^%s+h%s*%)")
                    or text:sub(stop+1):match("^%s+heroic%s*%)")), 2
        elseif guard == "invite" then return recruit and not trade
        elseif guard == "lookrole" then return lookingRoster
        elseif guard == "guildseek" then return guildSeeker
        elseif guard == "raidrequirement" then return recruit and raid
        elseif guard == "level" then return trade or roleRoster
        elseif guard == "guildlootsystem" then return guildRecruit and (alias ~= "loot" or text:sub(stop+1):match("^%s*:"))
        elseif guard == "guild" then return guildRecruit
        elseif guard == "weekly" then return recruit and (raid or weeklyQuest or weeklyRequest or word("weekly") or word("weekley")) and not guildRecruit
        elseif guard == "guildweekly" then return guildRecruit
        elseif guard == "raidtrade" then return raidTrade
        elseif guard == "groupflow" then return context and context.group
        elseif guard == "arena" then return arenaRecruit
        elseif guard == "shortrecruit" then return shortRecruit
        elseif guard == "raidachievement" then return recruit and (raid or guildRecruit)
        elseif guard == "bane" or guard == "iccbane" then return recruit and word("icc") and text:find("%f[%d]10%f[^%d]")
        elseif guard == "tocachievement" then return recruit and (toc25 or word("togc"))
        elseif guard == "naxxachievement" then return recruit and (word("naxx") or word("nax") or word("naxxramas"))
        elseif guard == "solaceloot" then
            return recruit and tocRaid and text:sub(stop+1):match("^[%s+%-]*b%s*%+")
        elseif guard == "ulduarloot" then
            return recruit and word("ulduar") and (word("boe") or word("res") or word("ress") or word("reserved"))
        elseif guard == "trade" then
            return trade
        elseif guard == "roster" then
            if not recruit and not trade then return false end
            -- These English words also have ordinary meanings in conversation.
            local tail = text:sub(stop + 1)
            if alias == "lock" and tail:match("^%s+the%s") then return false end
            return true
        elseif guard == "enh" then
            return alias ~= "enh" or (recruit and (word("melee") or word("mdps") or word("shaman")))
        elseif guard == "tocraid" then
            -- ToC alone can also mean Trial of the Champion, a five-player dungeon.
            return alias ~= "toc" or (recruit and tocRaid)
        elseif guard == "difficulty" then
            return recruit and raid and (text:sub(1, start - 1):match("%f[%d]25%s*%(%s*$")
                or text:sub(1, start - 1):match("%f[%d]10%s*%(%s*$")
                or text:sub(1, start - 1):match("%f[%d]25%s*$")
                or text:sub(1, start - 1):match("%f[%d]10%s*$"))
        elseif guard == "lootnegative" then
            if alias:match("^noth%s") and (word("naxx") or word("nax") or word("naxxramas")) then return false end
            return recruit and raid
        elseif guard == "bossloot" then
            return recruit and raid and word("boe") and (word("res") or word("ress") or word("reserved"))
        elseif guard == "lastneed" then
            return recruit and raid and text:sub(stop + 1):match("^%s+%d+")
        elseif guard == "whisperrequest" then
            local tail = text:sub(stop + 1)
            return recruit and (tail:match("^%s+gs%f[^%w_]") or tail:match("^%s+spec%f[^%w_]")
                or tail:match("^%s+ach[%a]*%f[^%w_]") or tail:match("^%s+class%f[^%w_]")
                or tail:match("^%s+role%f[^%w_]"))
        elseif guard == "pull" then
            if game and command(start, stop) and not word("pull request") then return true end
            return text == "pull" or text:match("^don't pull until%s") or text:match("^do not pull until%s")
        elseif guard == "tocloot" then
            -- ToC25 loot shorthand: BOE + Crusader Orbs + Patterns. This is
            -- not the generic BOP binding abbreviation or ICC's Primo/SFS list.
            return recruit and toc25 and not ((alias:match("^bop%s") or alias:match("^b%.o%.p%s")) and actor("paladin",start))
        elseif guard == "rubybackloot" then
            local tail = text:sub(stop + 1)
            return recruit and word("rs") and text:find("%f[%d]25%f[^%d]")
                and (tail:match("^%s+ress%f[^%w_]") or tail:match("^%s+res%f[^%w_]")
                    or tail:match("^%s+reserved%f[^%w_]"))
        elseif guard == "memorial" then
            -- memo is the Dalaran monument where the raid leader inspects gear;
            -- it appears in ICC and ToC recruitment alike, e.g. "inspect@memo".
            return recruit and (word("inspect") or ((word("gs") or word("come memo"))
                and (word("achiv") or word("achive") or word("achiev") or word("achieve")
                    or word("achievement") or word("come memo"))))
        elseif guard == "roleloot" then
            return recruit and word("rs") and text:sub(stop+1):match("^%s+ress%f[^%w_]")
        elseif guard == "reserve" then
            if not recruit then return false end
            if alias == "reserved" then return true end
            if word("rs") and text:sub(1,start-1):match("%f[%w_]cts%s*=%s*$")
                and text:sub(stop+1):match("^%s*[%)%]]") then return true end
            -- RES can also mean resurrection. Recognize it only in a loot list
            -- adjoining BOE/SFS/STS, including RESS(BOE+SFS) and (STS RESS).
            local before, after = text:sub(1, start - 1), text:sub(stop + 1)
            if before:match("%f[%w_]please%s*$") or before:match("%f[%w_]pls%s*$") then return false end
            if startsRole(after:gsub("^%s+", "")) and
                (after:find("%f[%w_]please%f[^%w_]") or after:find("%f[%w_]pls%f[^%w_]")) then return false end
            if before:match("%f[%w_]nothing%s*$") then return false end
            local listBefore = before:match("([%a%s+%-]+)%s*%)?%s*$") or ""
            local listAfter = after:match("^%s*%(?%s*([%a%s+%-]+)") or ""
            local list = " " .. listBefore .. " " .. listAfter .. " "
            return list:find("%f[%w_]boe%f[^%w_]") or list:find("%f[%w_]sfs%f[^%w_]")
                or list:find("%f[%w_]sts%f[^%w_]") or list:find("%f[%w_]cts%f[^%w_]")
                or (word("icc") and (before:match("%f[%w_]dbw%W*$") or before:match("%f[%w_]wfs%W*$")
                    or after:match("^%s*%(?%s*dbw%f[^%w_]") or after:match("^%s*%(?%s*wfs%f[^%w_]")))
                or (word("rs") and (before:match("%f[%w_]pts%W*$") or after:match("^%s*%(?%s*pts%f[^%w_]")))
                or (word("rs") and list:find("%f[%w_]shaman hands%f[^%w_]"))
                or list:find("%f[%w_]primos?%f[^%w_]")
                or (word("rs") and text:find("%f[%d]25%f[^%d]")
                    and (list:find("%f[%w_]back spell%f[^%w_]") or list:find("%f[%w_]spell back%f[^%w_]")))
                or (word("icc") and (list:find("b%+p%f[^%w_]") or list:find("%f[%w_]bp%f[^%w_]")
                    or list:find("%f[%w_]muradin%f[^%w_]")))
                or list:find("%f[%w_]boes%f[^%w_]")
                or list:find("%f[%w_]warglaives?%f[^%w_]") or list:find("%f[%w_]azzinot%f[^%w_]")
                or (word("voa") and (list:find("%f[%w_]mount%f[^%w_]")
                    or ((list:find("%f[%w_]pve%f[^%w_]") or list:find("%f[%w_]pvp%f[^%w_]")
                        or list:find("%f[%w_]pants%f[^%w_]") or list:find("%f[%w_]leg%f[^%w_]"))
                        and (list:find("%f[%w_]mage%f[^%w_]") or list:find("%f[%w_]feral%f[^%w_]")
                            or list:find("%f[%w_]warr%f[^%w_]") or list:find("%f[%w_]dk%f[^%w_]")
                            or list:find("%f[%w_]pally%f[^%w_]") or list:find("%f[%w_]rsham%f[^%w_]")))))
        elseif guard == "raidsize" or guard == "moreneeded" then
            return recruit and text:sub(1, start - 1):match("%f[%d]%d+%s*$") ~= nil
        elseif guard == "fulltrail" then
            local before = text:sub(1, start - 1)
            return recruit and (before:match("[%d]%s*x?%s*$") or before:match("hc%s*$")
                or before:match("nm%s*$")) ~= nil
        elseif guard == "forraid" then
            local after = text:sub(stop + 1)
            return recruit and (after:match("^%s*icc%f[^%w_]") or after:match("^%s*rs%f[^%w_]")
                or after:match("^%s*toc%f[^%w_]") or after:match("^%s*togc%f[^%w_]")
                or after:match("^%s*voa%f[^%w_]") or after:match("^%s*hor%f[^%w_]")
                or after:match("^%s*ulduar%f[^%w_]") or after:match("^%s*naxx%f[^%w_]")
                or after:match("^%s*naxxramas%f[^%w_]") or after:match("^%s*sunwell%f[^%w_]")
                or after:match("^%s*onyxia%f[^%w_]") or after:match("^%s*onixya%f[^%w_]")
                or after:match("^%s*os%f[^%w_]") or after:match("^%s*%[?%s*serpentshrine")) ~= nil
        elseif guard == "ele" then
            return (recruit or trade) and (word("shaman") or word("shammy") or word("shamy") or word("sham")
                or word("rdps") or word("ranged") or word("range") or word("mdps") or word("melee"))
        elseif guard == "smweapon" then
            return trade
        elseif guard == "voafrost" then
            return recruit and word("voa")
        elseif guard == "iccboss" then
            return recruit and word("icc")
        elseif guard == "cloakloot" then
            if not recruit then return false end
            local before, after = text:sub(1, start - 1), text:sub(stop + 1)
            local list = " " .. (before:match("([%a%s+%-]+)%s*%)?%s*$") or "")
                .. " " .. (after:match("^%s*%(?%s*([%a%s+%-]+)") or "") .. " "
            return after:match("^%s*res") ~= nil or list:find("%f[%w_]res%f[^%w_]") ~= nil
                or list:find("%f[%w_]ress%f[^%w_]") ~= nil or list:find("%f[%w_]resv%f[^%w_]") ~= nil
                or list:find("%f[%w_]reserved%f[^%w_]") ~= nil
        end
        return true
    end
    -- Select entries per occurrence in the collected order (groups longest
    -- first, occurrences left to right), marking occupied bytes so an accepted
    -- longer alias blocks overlapping shorter ones.
    local occupied, matches = {}, {}
    for _, occurrence in ipairs(occurrences) do
        local group, start, stop = occurrence.group, occurrence.start, occurrence.stop
        local selected, priority, ambiguous = nil, -1, false
        for _, entry in ipairs(group.entries) do
            local yes, rank = allowed(entry, start, stop)
            rank = rank or 0
            if yes and rank > priority then selected, priority, ambiguous = entry, rank, false
            elseif yes and rank == priority then ambiguous = true end
        end
        local overlap = false
        for i = start, stop do if occupied[i] then overlap = true; break end end
        if selected and not ambiguous and not overlap then
            for i = start, stop do occupied[i] = true end
            matches[#matches + 1] = { start = start, stop = stop, id = selected.id, alias = group.alias }
        end
    end
    table.sort(matches, function(a, b) return a.start < b.start end)
    if #matches > 0 and (not db or db.display ~= "terms") then
        if db and db.display == "annotate" then
            return annotateText(raw, matches, starts, stops, db)
        end
        return mixedText(raw, matches, starts, stops, controls, db)
    end
    local terms, used = {}, {}
    for _, match in ipairs(matches) do
        if not used[match.id] then
            used[match.id] = true
            terms[#terms + 1] = match.alias .. "＝" .. label(match.id, db)
        end
    end
    if #terms > 0 then return "→ 术语：" .. table.concat(terms, "；") end
    return nil
end

P.categories = {
    CHAT_MSG_CHANNEL = "CHANNEL", CHAT_MSG_PARTY = "PARTY", CHAT_MSG_PARTY_LEADER = "PARTY",
    CHAT_MSG_RAID = "RAID", CHAT_MSG_RAID_LEADER = "RAID", CHAT_MSG_RAID_WARNING = "RAID_WARNING",
    CHAT_MSG_BATTLEGROUND = "BATTLEGROUND", CHAT_MSG_BATTLEGROUND_LEADER = "BATTLEGROUND",
    CHAT_MSG_WHISPER = "WHISPER", CHAT_MSG_WHISPER_INFORM = "WHISPER",
    CHAT_MSG_GUILD = "GUILD", CHAT_MSG_OFFICER = "OFFICER",
    CHAT_MSG_SAY = "SAY", CHAT_MSG_YELL = "YELL",
}

local function field(value)
    value = tostring(value or "")
    return #value .. ":" .. value
end

function P.MessageKey(event, args)
    local category = P.categories[event]
    if not category or type(args[1]) ~= "string" or type(args[2]) ~= "string" then return nil end
    local channel = category
    if category == "CHANNEL" then
        -- Visible channel numbers can change. Prefer the unnumbered channel name.
        local name = args[9]
        if type(name) ~= "string" or name == "" then return nil end
        channel = category .. ":" .. name:lower()
    elseif event == "CHAT_MSG_WHISPER_INFORM" then
        channel = "WHISPER_OUT" -- Incoming and outgoing conversations are distinct.
    end
    return field(args[2]) .. field(channel) .. field(args[1]), category
end

function P.ShouldDedup(db, category, args)
    if db.filterEnabled == false then return false end
    if db.dedupEnabled==false then return false end
    if not db.dedup or db.dedup[category] ~= true then return false end
    if category ~= "CHANNEL" then return true end
    local name = type(args[9]) == "string" and args[9]:lower() or ""
    local override = db.channelDedup and db.channelDedup[name]
    if override ~= nil then return override == true end
    -- Standard public channels plus Warmane's commonly named public channels.
    -- Other player-created channels are not automatically considered public.
    return (tonumber(args[7]) or 0) > 0 or name == "global" or name == "world"
end

function P.IsPublicSource(category, args)
    if category == "YELL" then return true end
    if category ~= "CHANNEL" then return false end
    local name = type(args[9]) == "string" and args[9]:lower() or ""
    return (tonumber(args[7]) or 0) > 0 or name == "global" or name == "world"
end

function P.DedupKey(db, category, args, key)
    -- Display dedup may share a public source group; event identity and sample
    -- records still retain the original channel and event.
    if db.crossPublicDedup == true and P.IsPublicSource(category, args)
        and P.ShouldDedup(db, category, args) then
        return field(args[2]) .. field("PUBLIC") .. field(args[1])
    end
    return key
end

function P.DedupSeconds(db)
    local seconds=tonumber(db.dedupSeconds) or 30
    if seconds~=seconds then seconds=30 end
    return math.max(10,math.min(300,math.floor(seconds)))
end

-- Literal matching: English edges are word boundaries; Chinese is a substring.
-- matchPrepared expects text already lowercased with squashed spaces; the
-- exported MatchRule keeps preparing both sides for outside callers.
local function matchPrepared(text, rule, preparedRule)
    if type(rule)~="string" then return false end
    if not preparedRule then
        rule=rule:match("^%s*(.-)%s*$"):lower()
        rule=rule:gsub("%s+"," ")
    end
    if rule=="" then return false end
    local from=1
    while from<=#text do
        local first,last=text:find(rule,from,true)
        if not first then return false end
        local leftOK=not rule:sub(1,1):match("[%w_]") or not text:sub(first-1,first-1):match("[%w_]")
        local rightOK=not rule:sub(-1):match("[%w_]") or not text:sub(last+1,last+1):match("[%w_]")
        if leftOK and rightOK then return true end
        from=last+1
    end
    return false
end

function P.MatchRule(text, rule)
    if type(text)~="string" or type(rule)~="string" then return false end
    return matchPrepared(text:lower():gsub("%s+"," "), rule)
end

P.adLabels={gold="出售金币",account="出售账号",leveling="代练",boost="付费代刷"}
P.guildRecruitmentLabel="公会招募"
local function guildCandidate(raw)
    if type(raw)~="string" then return false end
    if raw:find("<",1,true) then return true end
    local lower,from=raw:lower(),1
    while true do
        local first,last=lower:find("guild",from,true)
        if not first then return false end
        if not lower:sub(first-1,first-1):match("%a") and not lower:sub(last+1,last+1):match("%a") then return true end
        from=last+1
    end
end

-- Prepared visible text only. A guild subject plus an explicit recruitment
-- action is required; tags, raid invitations and guild-seeking are insufficient.
function P.IsGuildRecruitment(text)
    text=text:gsub("^[%s\001]+","")
    local tagged = text:match("^<[^<>]+>")
    local body = tagged and text:sub(#tagged+1):match("^%s*(.-)%s*$") or text:match("^%s*(.-)%s*$")
    local guild = matchPrepared(body,"guild")
    if not tagged and not guild then return false end
    if body:find("?",1,true) or body:match('^["\']') then return false end
    for _,phrase in ipairs({"not recruiting","not currently recruiting","no longer recruiting",
        "never recruiting","isn't recruiting","isnt recruiting","aren't recruiting","arent recruiting",
        "not seeking","don't recruit","do not recruit","looking for a guild","looking for guild",
        "lf guild","lf raiding guild","lf raid guild","guild run","guild raid"}) do
        if matchPrepared(body,phrase) then return false end
    end
    if body:match("^lf[mg]%f[^%a]") then
        return guild and (matchPrepared(body,"guild members") or matchPrepared(body,"guild recruits"))
    end
    if not tagged and not (body:match("^guild%f[^%a]") or body:match("^our guild%f[^%a]")
        or body:match("^my guild%f[^%a]") or body:match("^new guild%f[^%a]")
        or body:match("^pve guild%f[^%a]") or body:match("^pvp guild%f[^%a]")
        or matchPrepared(body,"we are recruiting") or matchPrepared(body,"apply")
        or matchPrepared(body,"/w") or matchPrepared(body,"whisper me")
        or matchPrepared(body,"discord")) then return false end
    if body:match("^recruiting%s+%d") then return false end
    if not tagged and (body:match("^i heard%f[^%a]") or body:match("^someone%f[^%a]")
        or body:match("^is your%f[^%a]") or body:match("^any guild%f[^%a]")
        or body:match("^stop%f[^%a]") or body:match("^please%f[^%a]")
        or body:match("^why%f[^%a]") or body:match("^no guild%f[^%a]")) then return false end
    if matchPrepared(body,"recruiting") or matchPrepared(body,"recruits") then return true end
    local seeking = matchPrepared(body,"seeking") or matchPrepared(body,"looking for players")
        or matchPrepared(body,"looking for active players") or matchPrepared(body,"looking for members")
    if seeking and (guild or matchPrepared(body,"raid roster") or matchPrepared(body,"guild members")) then return true end
    return tagged and matchPrepared(body,"forming additional raid groups") and matchPrepared(body,"progression") or false
end

function P.BlockReason(db,event,args)
    if db.filterEnabled == false then return nil end
    local category=P.categories[event]
    -- Channel scope mirrors P.ShouldDedup against filterChannels/channelFilter
    -- (without the dedup switches) but avoids a per-message table allocation.
    if not category or not db.filterChannels or db.filterChannels[category] ~= true then return nil end
    if category == "CHANNEL" then
        local name = type(args[9]) == "string" and args[9]:lower() or ""
        local override = db.channelFilter and db.channelFilter[name]
        local isPublic
        if override ~= nil then isPublic = override == true
        else isPublic = (tonumber(args[7]) or 0) > 0 or name == "global" or name == "world" end
        if not isPublic then return nil end
    end
    -- With no blocking rule enabled, whitelist checks cannot change the result.
    local activeAds = db.ads or {}
    local guild = db.hideGuildRecruitment == true and P.IsPublicSource(category,args) and guildCandidate(args[1])
    if not (activeAds.gold or activeAds.account or activeAds.leveling or activeAds.boost)
        and #(db.blockWords or {}) == 0 and not guild then return nil end
    for _,name in ipairs(db.whitelistPlayers or {}) do
        if type(name)=="string" and type(args[2])=="string" and name:lower()==args[2]:lower() then return nil end
    end
    local raw=P.VisibleText(args[1]); if not raw then return nil end
    -- One prepared copy of the visible text serves every rule match below.
    local normalized=raw:lower():gsub("%s+"," ")
    for _,rule in ipairs(db.whitelistText or {}) do if matchPrepared(normalized,rule) then return nil end end
    for _,rule in ipairs(db.blockWords or {}) do
        if matchPrepared(normalized,rule) then return "屏蔽词："..rule end
    end
    if guild and P.IsGuildRecruitment(normalized) then return P.guildRecruitmentLabel end
    if not (activeAds.gold or activeAds.account or activeAds.leveling or activeAds.boost) then return nil end
    local ads=db.ads or {}
    -- Precision takes priority: an explicit offer must start the message. Mere
    -- mentions, questions, quoted offers and uncertain wording remain visible.
    local text=normalized:match("^[%s\001]*(.-)%s*$")
    text=text:gsub("^%[wts%]%s*","wts ")
    local certainty=text:gsub("%f[%a]not%s+free%f[^%a]","paid")
        :gsub("%f[%a]no%s+payment%s+until%f[^%a]","payment deferred until")
        :gsub("%f[%a]no%s+fee%s+until%f[^%a]","fee deferred until")
    if text:find("?",1,true) then return nil end
    for _,word in ipairs({"free","not","don't","dont","no","never","forbidden","avoid","warning"}) do
        if matchPrepared(certainty,word) then return nil end
    end
    local offer=text:match("^wts[%s:%-]+(.+)$") or text:match("^selling[%s:%-]+(.+)$")
        or text:match("^i am selling%s+(.+)$") or text:match("^i'm selling%s+(.+)$")
    if not offer then return nil end
    -- Do not combine an item sale with an account or carry mentioned later.
    local head=offer:match("^[^,;!?]+") or offer
    local function has(...)
        for i=1,select("#",...) do if matchPrepared(head,select(i,...)) then return true end end
        return false
    end
    local goldTail=head:match("^gold%f[^%w_](.*)$")
        or head:match("^%d[%d.,]*%s*[km]?%s*gold%f[^%w_](.*)$")
    if ads.gold and goldTail and not head:find("\001",1,true)
        and not has("ore","ores","bar","bars","rod","rods","ring","rings","guide","farming","farm") then
        return P.adLabels.gold
    end
    if ads.account and not has("account bound","account-bound","transfer","recovery","guide","guides","help","items") and
        (head:match("^accounts?%f[^%w_]") or head:match("^lvl%s*%d+%s+accounts?%f[^%w_]")
        or head:match("^level%s*%d+%s+accounts?%f[^%w_]") or head:match("^%d+%s+accounts?%f[^%w_]")
        or head:match("^full%s+bis%s+accounts?%f[^%w_]")) then return P.adLabels.account end
    if ads.leveling and not has("guide","guides","tips","book","books") and
        (head:match("^powerleveling%f[^%w_]") or head:match("^power%s+leveling%f[^%w_]")
        or head:match("^leveling%s+service%f[^%w_]") or head:match("^levelling%s+service%f[^%w_]")) then
        return P.adLabels.leveling
    end
    local service=has("boost","boosts","boosting","carry","carries","carrying")
    local activity=has("icc","rs","toc","togc","naxx","ulduar","raid","dungeon","arena","leveling","service","services")
    for _,raid in ipairs({"icc","rs","toc","togc"}) do
        if head:find("%f[%w_]"..raid.."%d") then activity=true end
    end
    local money=head:match("%d[%d.,]*%s*[km]?%s*gold%f[^%w_]") or head:match("%d[%d.,]*%s*[km]?%s*g%f[^%w_]")
    if ads.boost and service and (activity or money)
        and not has("boe","boes","item","items","potion","potions","enchant","enchants","gem","gems") then
        return P.adLabels.boost
    end
    return nil
end




function P.NeedsCapture(raw,hint)
    if type(raw)~="string" or raw:find("[\208-\209][\128-\191]") then return false end
    if raw:match("^%s*QDKP2?>") then return false end
    local visible=P.VisibleText(raw) or ""
    if #visible-#visible:gsub("[\228-\233][\128-\191][\128-\191]","")>24 then return false end
    if not hint then return visible:find("%a%a")~=nil end
    if hint:find("→ 译文：",1,true)==1 then return false end
    if hint:find("→ 术语：",1,true)==1 then return true end
    local visible=P.VisibleText(hint) or ""
    return visible:find("%a%a")~=nil
end

function P.RecordMessage(state,db,kind,event,args,hint,reason,history,now,captureEligible)
    if history or db.captureEnabled~=true or not P.ShouldRecordLanguage(args[3]) then return end
    local key,category=P.MessageKey(event,args); if not key then return end
    local id=tonumber(args[11])
    local observed=field(event)..field(id and id>0 and id<math.huge and id or math.floor(now))..key
    if state.observed[observed] then return end
    if state.observedCount>=1024 then return end
    -- A subscribed window may have already recorded this event. Only accepted
    -- samples enter observed, so another kind can still record a rejected one.
    if kind=="missed" then
        if captureEligible==nil then captureEligible=P.NeedsCapture(args[1],hint) end
        if not captureEligible then return false end
    end
    state.observed[observed]=now; state.observedCount=state.observedCount+1
    if type(db.records)~="table" then db.records={} end
    local records=db.records[kind]
    if type(records)~="table" then records={}; db.records[kind]=records end
    -- SavedVariables keeps plain entries; queue links exist only in runtime.
    -- Detect list replacement as well as external length changes (clear/load).
    local index = state.recordIndex[kind]
    if not index or index.list ~= records or index.count ~= #records then
        index = {list=records, count=#records, nodes={}}
        for position,entry in ipairs(records) do
            local node={item=entry,slot=position,previous=index.tail}
            if index.tail then index.tail.next=node else index.head=node end
            index.tail=node; index.nodes[entry]=node
            if not index[entry.key] then index[entry.key]=entry end
        end
        state.recordIndex[kind]=index
    end
    local stamp=type(time)=="function" and time() or now
    local item = index[key]
    local node=item and index.nodes[item]
    if node and node~=index.tail then
        if node.previous then node.previous.next=node.next else index.head=node.next end
        node.next.previous=node.previous
        node.previous=index.tail; node.next=nil
        index.tail.next=node; index.tail=node; index.dirty=true
    elseif not item then
        item={key=key,raw=args[1],author=args[2],category=category,channel=args[9],first=stamp,count=0}
        node={item=item,slot=#records+1,previous=index.tail}
        if index.tail then index.tail.next=node else index.head=node end
        index.tail=node; index.nodes[item]=node; records[node.slot]=item
    end
    item.last=stamp; item.count=item.count+1; item.hint=hint
    item.reason=reason or (hint and "部分翻译" or "未识别"); item.version=P.version
    item.language=args[3]
    if item.visible==nil then item.visible=P.VisibleText(args[1]) end
    index[key] = item
    local limit=kind=="blocked" and 100 or 1000
    while #records>limit do
        local evicted=index.head
        index.head=evicted.next
        if index.head then index.head.previous=nil else index.tail=nil end
        -- Fill the removed storage slot instead of shifting every array entry.
        local newest=records[#records]
        records[evicted.slot]=newest; index.nodes[newest].slot=evicted.slot
        records[#records]=nil
        index.nodes[evicted.item]=nil
        if index[evicted.item.key]==evicted.item then index[evicted.item.key]=nil end
        index.dirty=true
    end
    index.count = #records
    return true
end

-- Materialize chronological order only for readers and SavedVariables saving.
function P.FlushRecords(state,db)
    if not state or not db or type(db.records)~="table" then return end
    for kind,index in pairs(state.recordIndex) do
        local records=db.records[kind]
        if records~=index.list or #records~=index.count then
            state.recordIndex[kind]=nil
        elseif index.dirty then
            local node,position=index.head,1
            while node do
                records[position]=node.item; node.slot=position
                node=node.next; position=position+1
            end
            index.dirty=false
        end
    end
end

function P.NewState()
    return {
        events = {}, filters = {}, filterCount=0, lastShown = {}, lastShownCount=0, lastAnalysis = {}, analysisCount=0, observed = {}, observedCount=0, active = {}, cleaned = -1, eventCount = 0,
        origins = {}, originKeys = {}, originSeq = 0, recordIndex = {},
        publicTranslations = {entries={},count=0,bytes=0},
        expiryHeap={}, expiryByKey={}, latestExpiry=nil,
        lineTranslated = {}, lineOriginal = {}, lineFrame = {},
        lineRegion = {}, lineIsOriginal = {},
        stats = { shown = 0, hints = 0, hidden = 0, noID = 0, errors = 0, unmatched = 0,
            calls = 0, withoutHint = 0, foreignLanguage = 0, blockedCommon = 0, blockedAds=0, blockedGuild=0, reusedAnalysis=0, reusedTranslation=0, replaced = 0 },
    }
end

P.publicTranslationLimits = {count=256,bytes=524288,entryBytes=8192,seconds=600}

local function removePublicTranslation(cache,entry)
    if entry.previous then entry.previous.next=entry.next else cache.first=entry.next end
    if entry.next then entry.next.previous=entry.previous else cache.last=entry.previous end
    cache.entries[entry.raw]=nil
    cache.count=cache.count-1; cache.bytes=cache.bytes-entry.bytes
end

-- The caller has already checked language, live identity and public source.
-- Public translation has no author/channel/instance context. Nil hints are
-- successful negative results; display and capture decisions remain separate.
function P.PublicTranslation(state,db,raw,now)
    local cache=state.publicTranslations
    if cache.db~=db or cache.display~=db.display or cache.colored~=db.colorByCategory
        or cache.colors~=db.colors or cache.labels~=db.labels then
        cache={entries={},count=0,bytes=0,db=db,display=db.display,colored=db.colorByCategory,
            colors=db.colors,labels=db.labels}
        state.publicTranslations=cache
    end
    local limits=P.publicTranslationLimits
    local entry=cache.entries[raw]
    if entry and now-entry.created<limits.seconds then
        state.stats.reusedTranslation=state.stats.reusedTranslation+1
        return entry.hint
    end
    if entry then removePublicTranslation(cache,entry) end
    -- FIFO creation order makes expiry cleanup independent of the full map.
    while cache.first and now-cache.first.created>=limits.seconds do removePublicTranslation(cache,cache.first) end
    local hint=P.Translate(raw,db,{group=false})
    local bytes=#raw+(hint and #hint or 0)
    if bytes>limits.entryBytes then return hint end
    while cache.first and (cache.count>=limits.count or cache.bytes+bytes>limits.bytes) do
        removePublicTranslation(cache,cache.first)
    end
    entry={raw=raw,hint=hint,created=now,bytes=bytes,previous=cache.last}
    if cache.last then cache.last.next=entry else cache.first=entry end
    cache.last=entry; cache.entries[raw]=entry
    cache.count=cache.count+1; cache.bytes=cache.bytes+bytes
    return hint
end

local function expiryUp(heap,position)
    local node=heap[position]
    while position>1 do
        local parent=math.floor(position/2)
        if heap[parent].at<=node.at then break end
        heap[position]=heap[parent]; heap[position].position=position
        position=parent
    end
    heap[position]=node; node.position=position
end

local function expiryDown(heap,position)
    local node=heap[position]; local count=#heap
    while position*2<=count do
        local child=position*2
        if child<count and heap[child+1].at<heap[child].at then child=child+1 end
        if node.at<=heap[child].at then break end
        heap[position]=heap[child]; heap[position].position=position
        position=child
    end
    heap[position]=node; node.position=position
end

local function scheduleExpiry(state,key,at)
    local heap=state.expiryHeap
    local node=state.expiryByKey[key]
    if node then
        local previous=node.at; node.at=at
        if at<previous then expiryUp(heap,node.position) else expiryDown(heap,node.position) end
    else
        node={key=key,at=at,position=#heap+1}
        heap[node.position]=node; state.expiryByKey[key]=node
        expiryUp(heap,node.position)
    end
    -- A conservative upper bound remains valid when an existing node moves
    -- earlier. It only delays the whole-cache shortcut, never expiry itself.
    state.latestExpiry=math.max(state.latestExpiry or at,at)
end

local function pruneDedup(state,now)
    local heap=state.expiryHeap
    if not heap[1] or heap[1].at>now then return end
    if state.latestExpiry and now>=state.latestExpiry then
        state.lastShown={}; state.lastAnalysis={}
        state.lastShownCount=0; state.analysisCount=0
        state.expiryHeap={}; state.expiryByKey={}; state.latestExpiry=nil
        return
    end
    while heap[1] and heap[1].at<=now do
        local expired=heap[1]; local last=heap[#heap]; heap[#heap]=nil
        if #heap>0 then heap[1]=last; expiryDown(heap,1) end
        state.expiryByKey[expired.key]=nil
        state.lastShown[expired.key]=nil
        state.lastShownCount=state.lastShownCount-1
        if state.lastAnalysis[expired.key] then
            state.lastAnalysis[expired.key]=nil; state.analysisCount=state.analysisCount-1
        end
    end
    if not heap[1] then state.latestExpiry=nil end
end

local function pruneWork(state, now)
    -- Dedup expiry runs at the exact message time, even if the small event and
    -- capture caches were cleaned less than a second ago.
    pruneDedup(state,now)
    if now - state.cleaned < 1 then return end
    state.cleaned = now
    for key, record in pairs(state.events) do
        if now - record.created >= 2 then state.events[key] = nil; state.eventCount = state.eventCount - 1 end
    end
    for key, record in pairs(state.filters) do
        if now-record.created>=2 then state.filters[key]=nil; state.filterCount=state.filterCount-1 end
    end
    for key,observed in pairs(state.observed) do
        if now-observed>=2 then state.observed[key]=nil; state.observedCount=state.observedCount-1 end
    end
end

local prune = pruneWork

-- Reuse both allowed and blocked decisions across windows and history storage.
-- A live ID never shares decisions with replay, another source or another body.
function P.EventBlockReason(state,db,event,args,history,now)
    local ads=db.ads or {}
    if db.filterEnabled==false or (not db.hideGuildRecruitment and # (db.blockWords or {})==0
        and not (ads.gold or ads.account or ads.leveling or ads.boost)) then return nil end
    if history then return P.BlockReason(db,event,args) end
    prune(state,now)
    local id=tonumber(args[11])
    local validID=id and id>0 and id==id and id<math.huge
    local key=validID and P.MessageKey(event,args)
    -- Builtin channel IDs influence public-source filtering independently of name.
    key=key and (field(event)..field(id)..key..field(args[7]))
    local cached=key and state.filters[key]
    if cached and now-cached.created<2 then return cached.reason or nil end
    if cached then state.filters[key]=nil; state.filterCount=state.filterCount-1 end
    local reason=P.BlockReason(db,event,args)
    if key and state.filterCount<1024 then
        state.filters[key]={reason=reason or false,created=now}; state.filterCount=state.filterCount+1
    end
    return reason
end

function P.Begin(state, db, event, args, history, now, defaultLanguage, seconds)
    local key, category = P.MessageKey(event, args)
    if not key then return nil end
    seconds = seconds or P.DedupSeconds(db)
    prune(state, now)
    -- Subscribed windows share this event's first translation and decision.
    -- History and events without a valid ID still follow the uncached path.
    local id = not history and tonumber(args[11])
    local validID = id and id > 0 and id == id and id < math.huge
    local eventKey = validID and (field(event) .. field(id) .. key)
    local cached = eventKey and state.events[eventKey]
    if cached then return cached end
    local dedupKey = P.DedupKey(db,category,args,key)
    local last = state.lastShown[dedupKey]
    local eligible=validID and state.eventCount<1024 and not history and P.ShouldDedup(db,category,args)
    local hide = eligible and last ~= nil and now-last<seconds
    local language = args[3]
    local foreignLanguage = type(language) == "string" and language ~= "" and language ~= "Universal"
        and defaultLanguage ~= nil and language ~= defaultLanguage
    local analysisAllowed = not foreignLanguage and (db.enabled~=false or (not history and db.captureEnabled==true))
        and (not db.translate or db.translate[category] ~= false)
    local public = P.IsPublicSource(category,args)
    local previous = hide and public and state.lastAnalysis[dedupKey]
    local reused = previous and previous.analysisAllowed==analysisAllowed and previous.display==db.display
        and previous.foreignLanguage==foreignLanguage
    local hint, captureEligible
    if reused then
        -- Only a hidden exact public duplicate can reuse the committed first
        -- analysis. Group context, settings resets and expiry use a fresh run.
        hint, captureEligible = previous.hint, previous.captureEligible
        state.stats.reusedAnalysis = state.stats.reusedAnalysis + 1
    elseif (not hide or db.captureEnabled==true) and analysisAllowed then
        if public and validID and state.eventCount<1024 and not history then
            hint=P.PublicTranslation(state,db,args[1],now)
        else
            hint = P.Translate(args[1], db, P.ChatContext(category, history))
        end
    end
    if history then return { history = true, hint = hint, key = key, foreignLanguage = foreignLanguage } end
    if not validID then
        state.stats.noID = state.stats.noID + 1
        return { anonymous = true, hint = hint, key = key, foreignLanguage = foreignLanguage } -- Fail open.
    end
    if state.eventCount >= 1024 then
        state.stats.noID = state.stats.noID + 1
        return { anonymous = true, hint = hint, key = key, foreignLanguage = foreignLanguage }
    end
    local record = { key = key, dedupKey = dedupKey, hint = hint, created = now, foreignLanguage = foreignLanguage, hide = hide,
        publicAnalysis = public, analysisAllowed = analysisAllowed, display = db.display, captureEligible = captureEligible,
        expireSeconds=seconds }
    state.events[eventKey], state.eventCount = record, state.eventCount + 1
    return record
end

function P.Commit(state, record, now)
    if not record or record.history or record.anonymous or record.committed then return end
    record.committed=true
    local key = record.dedupKey or record.key
    if not state.lastShown[key] then
        if state.lastShownCount>=4096 then return end -- Capacity exhaustion keeps new messages visible.
        state.lastShownCount=state.lastShownCount+1
    end
    state.lastShown[key]=now
    scheduleExpiry(state,key,now+(record.expireSeconds or 30))
    if record.publicAnalysis and (state.lastAnalysis[key] or state.analysisCount < 1024) then
        if not state.lastAnalysis[key] then state.analysisCount = state.analysisCount + 1 end
        state.lastAnalysis[key] = record
    end
end

-- Inline mode: swap the raw message inside the final display line for its
-- translation and append an [原文] link carrying the original.
-- Raid-icon tags get re-rendered for display ({rt1} shown as {星形} by the
-- localized tag list, {star} as a texture). Canonicalize every spelling back
-- to {rtN} so inline splicing can still locate the server's original text.
local ICON_TAG_CANON = {
    star=1, circle=2, coin=2, diamond=3, triangle=4, moon=5, square=6, cross=7,
    ["x"]=7, skull=8,
    ["星形"]=1, ["圆圈"]=2, ["硬币"]=2, ["菱形"]=3, ["三角"]=4, ["月亮"]=5,
    ["方块"]=6, ["十字"]=7, ["骷髅"]=8,
}
local function canonicalIconTags(s)
    s = s:gsub("|T[^|]-UI%-RaidTargetingIcon_(%d)[^|]-|t", "{rt%1}")
    s = s:gsub("{([%w_]+)}", function(tag)
        local index = ICON_TAG_CANON[tag]
        return index and "{rt" .. index .. "}" or nil
    end)
    for name, index in pairs(ICON_TAG_CANON) do
        local byte = name:byte()
        if byte >= 128 then s = s:gsub("{" .. name .. "}", "{rt" .. index .. "}") end
    end
    return s
end

local function spliceLine(text, raw, replacement, candidate)
    -- Both supported handlers append the raw body after the sender link. Match
    -- that suffix, never a same-named player or channel in the header. Changed
    -- bodies or unfamiliar layouts fall back to the two-line display.
    if raw == "" then return nil end
    local first = #text - #raw + 1
    if first < 1 or text:sub(first) ~= raw then
        -- Icon-tag re-rendering changed the wording; canonicalize both sides
        -- and retry before giving up.
        text = canonicalIconTags(text)
        raw = canonicalIconTags(raw)
        first = #text - #raw + 1
        if first < 1 or text:sub(first) ~= raw then return nil end
    end
    local sender = text:find(candidate, 1, true)
    local linkText = sender and text:find("|h", sender + #candidate, true)
    local linkEnd = linkText and text:find("|h", linkText + 2, true)
    if not linkEnd or linkEnd + 1 >= first then return nil end
    return text:sub(1, first - 1) .. replacement
end

-- Intercept only this event's final player-chat output. Unrelated filter output passes through.
-- The previous writer is restored even when the original handler raises an error.
function P.Run(state, db, frame, event, args, history, invoke, clock)
    -- Display filtering is independent of translation and requires no event ID.
    -- Apply before building text caches, including ElvUI history replay.
    if db.hideCommon and P.categories[event] and P.IsCommonLanguage(args[3]) then
        state.stats.blockedCommon = state.stats.blockedCommon + 1
        return
    end
    if state.active[frame] or not frame or type(frame.AddMessage) ~= "function" then
        return invoke()
    end
    local now=clock()
    local seconds=P.DedupSeconds(db)
    prune(state,now)
    local reason=P.EventBlockReason(state,db,event,args,history,now)
    if reason then
        if reason==P.guildRecruitmentLabel then state.stats.blockedGuild=state.stats.blockedGuild+1
        else state.stats.blockedAds=state.stats.blockedAds+1 end
        P.RecordMessage(state,db,"blocked",event,args,nil,reason,history,now)
        return
    end
    local record = P.Begin(state, db, event, args, history, now, frame.defaultLanguage, seconds)
    if not record then return invoke() end
    if not record.foreignLanguage then
        local eligible=P.RecordMessage(state,db,"missed",event,args,record.hint,nil,history,now,record.captureEligible)
        if eligible~=nil then record.captureEligible=eligible end
    end
    local hint=db.enabled and record.hint or nil
    state.stats.calls = state.stats.calls + 1
    local writer = frame.AddMessage
    local candidate, seen = "|Hplayer:" .. args[2] .. ":", false
    state.active[frame] = true
    frame.AddMessage = function(self, text, ...)
        if self ~= frame or seen or type(text) ~= "string" or not text:find(candidate, 1, true) then
            return writer(self, text, ...)
        end
        seen = true
        if record.hide then state.stats.hidden = state.stats.hidden + 1; return end
        local extras = pack(...)
        local linked = nil
        if hint and db.inlineReplace ~= false then
            local body = hint:gsub("^→ [^：]+：", "")
            local newLine = body and body ~= "" and spliceLine(text, args[1], body, candidate) or nil
            if newLine then
                state.originSeq = state.originSeq + 1
                local id = tostring(state.originSeq)
                state.origins[id] = args[1]
                state.originKeys[#state.originKeys + 1] = id
                if #state.originKeys > 256 then
                    local evicted = table.remove(state.originKeys, 1)
                    state.origins[evicted] = nil
                    state.lineTranslated[evicted] = nil
                    state.lineOriginal[evicted] = nil
                    state.lineFrame[evicted] = nil
                    state.lineRegion[evicted] = nil
                    state.lineIsOriginal[evicted] = nil
                end
                state.lineTranslated[id] = newLine
                state.lineOriginal[id] = text
                state.lineFrame[id] = frame
                if db.display == "annotate" then
                    linked = newLine
                else
                    linked = newLine .. " |Hmcodeorig:" .. id .. "|h|cff777777[原文]|r|h"
                end
            end
        end
        local result
        if linked then
            -- The replaced line keeps the channel's own base color (yell red,
            -- say white, channel default); category accents stay colored.
            result = pack(writer(self, linked, unpack(extras, 1, extras.n)))
            state.stats.shown = state.stats.shown + 1
            state.stats.hints = state.stats.hints + 1
            state.stats.replaced = state.stats.replaced + 1
        else
            result = pack(writer(self, text, unpack(extras, 1, extras.n)))
            state.stats.shown = state.stats.shown + 1
            if not hint then state.stats.withoutHint = state.stats.withoutHint + 1 end
            if record.foreignLanguage then state.stats.foreignLanguage = state.stats.foreignLanguage + 1 end
        end
        P.Commit(state, record, clock())
        if hint and not linked then
            -- Link |r markers reset to AddMessage's RGB. Use the hint color as
            -- that base instead of the original channel color; retain metadata.
            local r,g,b=P.ColorRGB(db,"other")
            local ok = pcall(writer, self, "|cff"..P.ColorHex(db,"other") .. hint .. "|r",
                r,g,b, unpack(extras, 4, extras.n))
            if ok then state.stats.hints = state.stats.hints + 1 else state.stats.errors = state.stats.errors + 1 end
        end
        return unpack(result, 1, result.n)
    end
    local result = pack(pcall(invoke))
    frame.AddMessage, state.active[frame] = writer, nil
    if not seen then state.stats.unmatched = state.stats.unmatched + 1 end
    if not result[1] then state.stats.errors = state.stats.errors + 1; error(result[2], 0) end
    return unpack(result, 2, result.n)
end

-- Diagnostics are temporary wrappers. The disabled path keeps the original
-- functions and cleanup callback, with no timer reads or per-message samples.
P.perfStages = {"entry", "filter", "translate", "record", "flush", "cleanup", "publicCache"}

local function perfRead(perf)
    if not perf.timer then return nil end
    local ok,value=pcall(perf.timer)
    if ok and type(value)=="number" and value==value and value>=0 and value<math.huge then return value end
end

local function perfOpen(perf,stage)
    local row=perf.stages[stage]
    row.calls=row.calls+1
    return perfRead(perf)
end

local function perfClose(perf,stage,start)
    local row=perf.stages[stage]
    local finish=perfRead(perf)
    if start and finish and finish>=start then
        local elapsed=finish-start
        row.timed=row.timed+1; row.ms=row.ms+elapsed; row.max=math.max(row.max,elapsed)
    else row.invalid=row.invalid+1 end
end

function P.PerfStop()
    local perf=P.perf
    if not perf or not perf.enabled then return end
    perf.enabled=false; perf.stopped=type(GetTime)=="function" and GetTime() or perf.started
    for name,hook in pairs(perf.hooks) do
        -- Do not remove a later wrapper installed by another caller.
        if P[name]==hook.wrapper then P[name]=hook.original end
    end
    prune=pruneWork
    perf.hooks={}
end

function P.PerfStart()
    P.PerfStop()
    local perf={enabled=true,stages={},hooks={},depth=0,live=0,history=0,nested=0,
        hidden=0,common=0,guild=0,ads=0,errors=0,analysisHits=0,cacheHits=0,cacheMisses=0,
        started=type(GetTime)=="function" and GetTime() or 0}
    if type(debugprofilestop)=="function" then
        perf.timer=debugprofilestop; perf.timerLabel="debugprofilestop（毫秒）"
    elseif type(GetTime)=="function" then
        local timer=GetTime
        perf.timer=function() return timer()*1000 end
        perf.timerLabel="GetTime（低精度毫秒，短调用可能为0）"
    else perf.timerLabel="无计时API，仅计数" end
    for _,stage in ipairs(P.perfStages) do perf.stages[stage]={calls=0,timed=0,invalid=0,ms=0,max=0} end
    P.perf=perf

    local function ownState(state) return state==P.state end
    local function inChat() return perf.depth>0 end
    local function wrap(name,stage,applies,after)
        local original=P[name]
        local wrapper=function(...)
            if not perf.enabled or not applies(...) then return original(...) end
            local before=after and P.state.stats.reusedTranslation
            local start=perfOpen(perf,stage)
            local result=pack(pcall(original,...))
            perfClose(perf,stage,start)
            if not result[1] then error(result[2],0) end
            if after then after(before) end
            return unpack(result,2,result.n)
        end
        perf.hooks[name]={original=original,wrapper=wrapper}; P[name]=wrapper
    end
    wrap("EventBlockReason","filter",ownState)
    wrap("Translate","translate",inChat)
    wrap("RecordMessage","record",ownState)
    wrap("FlushRecords","flush",ownState)
    wrap("PublicTranslation","publicCache",ownState,function(before)
        if P.state.stats.reusedTranslation>before then perf.cacheHits=perf.cacheHits+1
        else perf.cacheMisses=perf.cacheMisses+1 end
    end)
    prune=function(state,now)
        if not perf.enabled or state~=P.state then return pruneWork(state,now) end
        local start=perfOpen(perf,"cleanup")
        local ok,err=pcall(pruneWork,state,now)
        perfClose(perf,"cleanup",start)
        if not ok then error(err,0) end
    end

    local original=P.Run
    local wrapper=function(state,db,frame,event,args,history,invoke,clock)
        if not perf.enabled or state~=P.state then return original(state,db,frame,event,args,history,invoke,clock) end
        if history then perf.history=perf.history+1 else perf.live=perf.live+1 end
        -- Nested native callbacks are included in the outer entry, rather than
        -- counting their elapsed time twice in the entry average.
        if perf.depth>0 then
            perf.nested=perf.nested+1
            return original(state,db,frame,event,args,history,invoke,clock)
        end
        local stats=state.stats
        local hidden,common,guild,ads,analysis=stats.hidden,stats.blockedCommon,stats.blockedGuild,stats.blockedAds,stats.reusedAnalysis
        local start=perfOpen(perf,"entry"); perf.depth=1
        local result=pack(pcall(original,state,db,frame,event,args,history,invoke,clock))
        perf.depth=0; perfClose(perf,"entry",start)
        perf.hidden=perf.hidden+stats.hidden-hidden; perf.common=perf.common+stats.blockedCommon-common
        perf.guild=perf.guild+stats.blockedGuild-guild; perf.ads=perf.ads+stats.blockedAds-ads
        perf.analysisHits=perf.analysisHits+stats.reusedAnalysis-analysis
        if not result[1] then perf.errors=perf.errors+1; error(result[2],0) end
        return unpack(result,2,result.n)
    end
    perf.hooks.Run={original=original,wrapper=wrapper}; P.Run=wrapper
end

function P.PerfSnapshot()
    local perf=P.perf
    if not perf then return nil end
    local snapshot={enabled=perf.enabled,timerLabel=perf.timerLabel,stages={}}
    for _,key in ipairs({"live","history","nested","hidden","common","guild","ads","errors","analysisHits","cacheHits","cacheMisses"}) do
        snapshot[key]=perf[key]
    end
    for _,stage in ipairs(P.perfStages) do
        local row=perf.stages[stage]
        snapshot.stages[stage]={calls=row.calls,timed=row.timed,invalid=row.invalid,ms=row.ms,max=row.max}
    end
    local finish=perf.stopped or (type(GetTime)=="function" and GetTime() or perf.started)
    snapshot.seconds=math.max(0,finish-perf.started)
    local state=P.state; local cache=state.publicTranslations
    snapshot.cache={translations=cache.count,textBytes=cache.bytes,events=state.eventCount,
        filters=state.filterCount,dedup=state.lastShownCount,expiry=#state.expiryHeap,
        analysis=state.analysisCount,observed=state.observedCount}
    return snapshot
end
