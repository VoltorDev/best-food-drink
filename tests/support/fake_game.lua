-- Bolsas, objetos, hechizos de uso, tooltips y macros simulados para BestFoodDrink. Se inyectan
-- como globales en el cliente simulado de wow_env (opts.globals). Los objetos imitan los de
-- Vanilla; los valores de restauración son ilustrativos, no copiados de ninguna base de datos.
local WowEnv = require("wow_env")

local M = {}

local TOC = "BestFoodDrink.toc"
local CONSUMABLE, FOODDRINK, POTION, BANDAGE = 0, 5, 1, 7
local MAX_ACCOUNT = 120

-- itemID -> datos. lines = texto del tooltip (inglés por defecto).
M.ITEMS = {
    [117] = {
        name = "Tough Jerky",
        minLevel = 1,
        subclass = FOODDRINK,
        spell = "Food",
        icon = 1001,
        lines = { "Tough Jerky", "Use: Restores 61 health over 18 sec. Must remain seated while eating." },
    },
    [2287] = {
        name = "Haunch of Meat",
        minLevel = 5,
        subclass = FOODDRINK,
        spell = "Food",
        icon = 1002,
        lines = { "Haunch of Meat", "Requires Level 5", "Use: Restores 243 health over 21 sec." },
    },
    [3770] = {
        name = "Mutton Chop",
        minLevel = 15,
        subclass = FOODDRINK,
        spell = "Food",
        icon = 1003,
        lines = { "Mutton Chop", "Requires Level 15", "Use: Restores 552 health over 24 sec." },
    },
    [724] = {
        name = "Goretusk Liver Pie",
        minLevel = 5,
        subclass = FOODDRINK,
        spell = "Food",
        icon = 1004,
        lines = {
            "Goretusk Liver Pie",
            "Use: Restores 243 health over 21 sec. If you spend at least 10 seconds eating you will become "
                .. "well fed and gain 4 Stamina and Spirit for 15 min.",
        },
    },
    [159] = {
        name = "Refreshing Spring Water",
        minLevel = 1,
        subclass = FOODDRINK,
        spell = "Drink",
        icon = 2001,
        lines = { "Refreshing Spring Water", "Use: Restores 151 mana over 18 sec." },
    },
    [1179] = {
        name = "Ice Cold Milk",
        minLevel = 5,
        subclass = FOODDRINK,
        spell = "Drink",
        icon = 2002,
        lines = { "Ice Cold Milk", "Requires Level 5", "Use: Restores 436 mana over 21 sec." },
    },
    [1205] = {
        name = "Melon Juice",
        minLevel = 15,
        subclass = FOODDRINK,
        spell = "Drink",
        icon = 2003,
        lines = { "Melon Juice", "Requires Level 15", "Use: Restores 835 mana over 24 sec." },
    },
    [118] = {
        name = "Minor Healing Potion",
        minLevel = 1,
        subclass = POTION,
        spell = "Healing Potion",
        icon = 3001,
        lines = { "Minor Healing Potion", "Use: Restores 70 to 90 health." },
    },
    [1251] = {
        name = "Linen Bandage",
        minLevel = 1,
        subclass = BANDAGE,
        spell = "First Aid",
        icon = 3002,
        lines = { "Linen Bandage", "Use: Heals 66 damage over 6 sec." },
    },
    [6948] = {
        name = "Hearthstone",
        minLevel = 1,
        class = 15,
        subclass = 0,
        spell = "Hearthstone",
        icon = 3003,
        lines = { "Hearthstone", "Use: Returns you to your home." },
    },
}

-- Crea el estado del juego. opts: level, bags = { [bag] = { [slot] = { itemID, count } } },
-- numSlots (por bolsa, 16), uncached = { [itemID] = true }, charMacros (número ya ocupados).
function M.new(opts)
    opts = opts or {}
    local game = {
        level = opts.level or 7,
        bags = opts.bags or { [0] = {} },
        numSlots = opts.numSlots or 16,
        uncached = opts.uncached or {},
        macros = {}, -- [índice] = { name, icon, body }
        created = 0,
        edits = 0,
        env = nil,
    }
    for i = 1, opts.charMacros or 0 do
        game.macros[MAX_ACCOUNT + i] = { name = "Otra" .. i, icon = 1, body = "/sit" }
    end

    local function inCombat()
        ---@diagnostic disable-next-line: undefined-field
        return game.env and game.env.InCombatLockdown() or false
    end
    local function assertNoCombat(api)
        if inCombat() then
            error(api .. ": acción protegida en combate (simulado)", 3)
        end
    end
    local function item(id)
        if game.uncached[id] then
            return nil
        end
        return M.ITEMS[id]
    end

    function game:Put(bag, slot, itemID, count)
        self.bags[bag] = self.bags[bag] or {}
        self.bags[bag][slot] = { itemID = itemID, count = count or 1 }
    end
    function game:Clear(bag, slot)
        if self.bags[bag] then
            self.bags[bag][slot] = nil
        end
    end
    function game:Macro(name)
        for index, m in pairs(self.macros) do
            if m.name == name then
                return m, index
            end
        end
    end
    function game:DeleteMacro(name)
        local _, index = self:Macro(name)
        if index then
            self.macros[index] = nil
        end
    end

    local G = {}
    G.UnitLevel = function(unit)
        assert(unit == "player")
        return game.level
    end
    G.C_Container = {
        GetContainerNumSlots = function(bag)
            return game.bags[bag] and game.numSlots or 0
        end,
        GetContainerItemInfo = function(bag, slot)
            local s = game.bags[bag] and game.bags[bag][slot]
            if not s then
                return nil
            end
            return { itemID = s.itemID, stackCount = s.count, iconFileID = M.ITEMS[s.itemID].icon }
        end,
    }
    G.C_Item = {
        GetItemInfo = function(id)
            local it = item(id)
            if not it then
                return nil
            end
            local class = it.class or CONSUMABLE
            -- name, link, quality, ilvl, minLevel, type, subType, stack, equipLoc, texture,
            -- sellPrice, classID, subclassID
            return it.name, "|Hitem:" .. id .. "|h", 1, 1, it.minLevel, "", "", 20, "", it.icon, 1, class, it.subclass
        end,
        GetItemSpell = function(id)
            local it = item(id)
            if it then
                return it.spell, 1000 + id
            end
        end,
        GetItemIconByID = function(id)
            return M.ITEMS[id] and M.ITEMS[id].icon
        end,
        GetItemNameByID = function(id)
            local it = item(id)
            return it and it.name
        end,
    }
    G.C_Spell = {
        GetSpellName = function(id)
            return ({ [433] = "Food", [430] = "Drink" })[id]
        end,
    }
    G.C_TooltipInfo = {
        GetBagItem = function(bag, slot)
            local s = game.bags[bag] and game.bags[bag][slot]
            local it = s and item(s.itemID)
            if not it then
                return nil
            end
            local lines = {}
            for i, text in ipairs(it.lines) do
                lines[i] = { leftText = text }
            end
            return { lines = lines }
        end,
    }
    G.GetNumMacros = function()
        local account, character = 0, 0
        for index in pairs(game.macros) do
            if index > MAX_ACCOUNT then
                character = character + 1
            else
                account = account + 1
            end
        end
        return account, character
    end
    G.GetMacroIndexByName = function(name)
        local _, index = game:Macro(name)
        return index or 0
    end
    G.GetMacroInfo = function(index)
        local m = game.macros[index]
        if m then
            return m.name, m.icon, m.body
        end
    end
    G.CreateMacro = function(name, icon, body, perCharacter)
        assertNoCombat("CreateMacro")
        assert(#name <= 16, "nombre de macro de más de 16 caracteres: " .. name)
        assert(#body <= 255, "cuerpo de macro de más de 255 caracteres")
        assert(perCharacter == true, "se esperaba una macro de personaje")
        local index = MAX_ACCOUNT + 1
        while game.macros[index] do
            index = index + 1
        end
        game.macros[index] = { name = name, icon = icon, body = body }
        game.created = game.created + 1
        return index
    end
    G.EditMacro = function(index, name, icon, body)
        assertNoCombat("EditMacro")
        assert(game.macros[index], "EditMacro sobre una macro que no existe")
        assert(#body <= 255, "cuerpo de macro de más de 255 caracteres")
        game.macros[index] = { name = name, icon = icon, body = body }
        game.edits = game.edits + 1
        return index
    end
    game.globals = G
    return game
end

-- Opciones de WowEnv con el juego simulado; extra se mezcla encima (locale, etc.).
function M.opts(game, extra)
    local opts = {}
    for k, v in pairs(extra or {}) do
        opts[k] = v
    end
    opts.globals = opts.globals or {}
    for k, v in pairs(game.globals) do
        opts.globals[k] = v
    end
    return opts
end

-- Arranca el addon con el juego simulado y deja correr el refresco diferido de la entrada.
-- Devuelve env, ns, game.
function M.boot(gameOpts, envOpts, saved)
    local game = M.new(gameOpts)
    local env = WowEnv.new(M.opts(game, envOpts))
    game.env = env
    if saved then
        env.BestFoodDrinkDB = saved.db
        env.BestFoodDrinkCharDB = saved.charDB
    end
    local ns = env:LoadToc(TOC) or error("el addon no cargó")
    env:Login()
    env:Advance(1)
    return env, ns, game
end

-- Sustitutos de WowEnv.new/WowEnv.boot con un juego vacío (para los tests de la plantilla).
function M.envNew(envOpts)
    local game = M.new()
    local env = WowEnv.new(M.opts(game, envOpts))
    game.env = env
    return env, game
end

function M.envBoot(tocPath, envOpts)
    local game = M.new()
    local env, ns = WowEnv.boot(tocPath, M.opts(game, envOpts))
    game.env = env
    return env, ns, game
end

M.TOC = TOC
return M
