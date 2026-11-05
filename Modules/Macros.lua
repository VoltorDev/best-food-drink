local _, ns = ...
local L = ns.L
local Picker = ns.Picker
local module = ns:NewModule("Macros")
ns.Macros = module

-- Dos macros de PERSONAJE (cada personaje tiene su nivel y sus bolsas) que el addon reescribe
-- fuera de combate cada vez que cambian las bolsas o el nivel. Se eligió esto frente a botones
-- seguros propios porque una macro se arrastra a cualquier barra (la de Blizzard o la de otro
-- addon), muestra icono, número y reutilización sin código extra, y comer o beber no es posible
-- en combate, así que no importa que no se pueda editar durante él: se pone al día al salir.

local KINDS = { "food", "drink" }
local QUESTION_MARK_ICON = 134400 -- INV_Misc_QuestionMark
local FOOD_SPELL_ID, DRINK_SPELL_ID = 433, 430 -- "Comida"/"Bebida" (Tough Jerky, Refreshing Spring Water)
local CONSUMABLE_CLASS = Enum.ItemClass and Enum.ItemClass.Consumable or 0
local FOOD_SUBCLASS = Enum.ItemConsumableSubclass and Enum.ItemConsumableSubclass.Fooddrink or 5
local GENERIC_SUBCLASS = Enum.ItemConsumableSubclass and Enum.ItemConsumableSubclass.Generic or 0
local REFRESH_DELAY = 0.3

local itemCache = {} -- itemID -> { kind, restore, buff, minLevel } (solo si el tooltip tenía texto)
module.itemCache = itemCache

function module:MacroName(kind)
    return kind == "food" and L.MACRO_FOOD or L.MACRO_DRINK
end

local function TooltipLines(bag, slot)
    local data = C_TooltipInfo and C_TooltipInfo.GetBagItem(bag, slot)
    local lines = {}
    if data and data.lines then
        for _, line in ipairs(data.lines) do
            local text = line.leftText
            if type(text) == "string" and not issecretvalue(text) then
                lines[#lines + 1] = text
            end
        end
    end
    return lines
end

-- Datos de un objeto: si aún no está en la caché del cliente, devuelve nil y se reintenta con
-- GET_ITEM_INFO_RECEIVED.
function module:Describe(itemID, bag, slot)
    local cached = itemCache[itemID]
    if cached then
        return cached
    end
    local _, _, _, _, minLevel, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemID)
    if not classID then
        self.waitingItems = true
        return nil
    end
    local info = { minLevel = minLevel or 0, icon = C_Item.GetItemIconByID(itemID) }
    if classID ~= CONSUMABLE_CLASS or (subclassID ~= FOOD_SUBCLASS and subclassID ~= GENERIC_SUBCLASS) then
        itemCache[itemID] = info -- no es comida ni bebida (info.kind = nil)
        return info
    end
    local spellName = C_Item.GetItemSpell(itemID)
    if not spellName then
        return info -- sin hechizo de uso conocido todavía: no se cachea
    end
    local lines = TooltipLines(bag, slot)
    local tip = Picker.ParseTooltip(lines)
    if subclassID == FOOD_SUBCLASS then
        info.kind = Picker.Classify(spellName, tip, self.foodSpellName, self.drinkSpellName)
    else
        -- Consumible genérico: solo si el hechizo se llama Comida/Bebida (no por el tooltip, que
        -- confundiría pociones o vendas).
        info.kind = Picker.Classify(spellName, nil, self.foodSpellName, self.drinkSpellName)
    end
    info.restore, info.buff = tip.restore, tip.buff
    if #lines > 0 then
        itemCache[itemID] = info
    end
    return info
end

-- Recorre la mochila y las bolsas equipadas y agrupa por objeto.
function module:Scan()
    local byItem, list = {}, {}
    self.waitingItems = false
    local lastBag = Enum.BagIndex and Enum.BagIndex.ReagentBag or 5
    for bag = 0, lastBag do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local item = C_Container.GetContainerItemInfo(bag, slot)
            local itemID = item and item.itemID
            if itemID then
                local info = self:Describe(itemID, bag, slot)
                if info and info.kind then
                    local c = byItem[itemID]
                    if not c then
                        c = {
                            itemID = itemID,
                            kind = info.kind,
                            restore = info.restore,
                            buff = info.buff,
                            minLevel = info.minLevel,
                            icon = info.icon,
                            total = 0,
                            slots = {},
                        }
                        byItem[itemID] = c
                        list[#list + 1] = c
                    end
                    local count = item.stackCount or 1
                    c.total = c.total + count
                    c.slots[#c.slots + 1] = { bag = bag, slot = slot, count = count }
                end
            end
        end
    end
    return list
end

function module:Level()
    return self.level or UnitLevel("player") or 1
end

-- Crea la macro si falta y nunca se creó para este personaje (si Nico la borra, no vuelve
-- sola: /bfd crear). Devuelve su índice o 0.
function module:EnsureMacro(kind, force)
    local name = self:MacroName(kind)
    local index = GetMacroIndexByName(name)
    if index and index > 0 then
        return index
    end
    local created = ns.charDB.created
    if not force and (not ns.db.createMacros or created[kind]) then
        return 0
    end
    local _, numCharacter = GetNumMacros()
    local maxCharacter = Constants.MacroConsts and Constants.MacroConsts.MAX_CHARACTER_MACROS or 30
    if numCharacter >= maxCharacter then
        ns:Print(L.ERR_NO_MACRO_SLOTS)
        return 0
    end
    index = CreateMacro(name, QUESTION_MARK_ICON, Picker.MacroBody(kind), true)
    if index and index > 0 then
        created[kind] = true
        self.justCreated = true
        return index
    end
    return 0
end

function module:WriteMacro(kind, candidate, slot, force)
    local index = self:EnsureMacro(kind, force)
    if index == 0 then
        return
    end
    local name = self:MacroName(kind)
    local body = Picker.MacroBody(kind, candidate, slot)
    local icon = candidate and candidate.icon or QUESTION_MARK_ICON
    local _, currentIcon, currentBody = GetMacroInfo(index)
    if currentBody ~= body or currentIcon ~= icon then
        EditMacro(index, name, icon, body)
    end
end

-- Recalcula y reescribe las dos macros. En combate solo deja la tarea pendiente.
function module:Refresh(force)
    self.scheduled = false
    if not ns.db.enabled and not force then
        return
    end
    if InCombatLockdown() then
        self.pending = true
        return
    end
    self.pending = false
    local candidates = self:Scan()
    local opts = { level = self:Level(), preferBuff = ns.db.preferBuffFood }
    self.current = {}
    for _, kind in ipairs(KINDS) do
        local best, slot = Picker.Choose(candidates, kind, opts)
        self.current[kind] = best
        self:WriteMacro(kind, best, slot, force)
    end
    if self.justCreated then
        self.justCreated = false
        ns:Print(L.MACROS_CREATED:format(L.MACRO_FOOD, L.MACRO_DRINK))
    end
end

function module:ScheduleRefresh()
    if self.scheduled then
        return
    end
    self.scheduled = true
    C_Timer.After(REFRESH_DELAY, function()
        module:Refresh()
    end)
end

function module:OnEnable()
    self.foodSpellName = C_Spell.GetSpellName(FOOD_SPELL_ID)
    self.drinkSpellName = C_Spell.GetSpellName(DRINK_SPELL_ID)
    local function schedule()
        module:ScheduleRefresh()
    end
    ns:RegisterEvent("PLAYER_ENTERING_WORLD", schedule)
    ns:RegisterEvent("BAG_UPDATE_DELAYED", schedule)
    ns:RegisterEvent("PLAYER_LEVEL_UP", function(_, _, level)
        module.level = level
        schedule()
    end)
    ns:RegisterEvent("GET_ITEM_INFO_RECEIVED", function()
        if module.waitingItems then
            schedule()
        end
    end)
    ns:RegisterEvent("PLAYER_REGEN_ENABLED", function()
        if module.pending then
            schedule()
        end
    end)
end

function module:ApplySettings()
    if ns.db then
        self:ScheduleRefresh()
    end
end

-- Texto de estado para /bfd.
function module:StatusText(kind)
    local best = self.current and self.current[kind]
    if not best then
        return kind == "food" and L.NO_FOOD or L.NO_DRINK
    end
    local name = C_Item.GetItemNameByID(best.itemID) or ("item:" .. best.itemID)
    return L.STATUS_LINE:format(name, best.total, tostring(best.restore or "?"))
end
