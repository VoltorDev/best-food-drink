local _, ns = ...

-- Lógica pura de elección (sin API de WoW): se prueba entera fuera del juego.
-- Un candidato es { itemID, kind = "food"|"drink"|"both", restore, minLevel, buff, total,
-- slots = { { bag, slot, count }, ... } }.
local Picker = {}
ns.Picker = Picker

-- Palabras clave en inglés y español (esES/esMX), en minúsculas. No dependen del idioma del
-- cliente: un cliente en inglés con objetos en inglés y uno en español usan la misma lista.
Picker.SPELL_FOOD = { "food", "comida" }
Picker.SPELL_DRINK = { "drink", "bebida" }
Picker.SPELL_BOTH = { "refreshment", "refrigerio" }
Picker.WORDS_HEALTH = { "health", "salud", "vida" }
Picker.WORDS_MANA = { "mana", "maná" }
Picker.WORDS_BUFF = { "well fed", "bien alimentad" }

-- Minúsculas solo en ASCII: string.lower depende del locale de C y puede romper los bytes UTF-8
-- de "á" (pasó en los tests con el locale de Windows).
local function asciiLower(text)
    return (text:gsub("[A-Z]", function(c)
        return string.char(c:byte() + 32)
    end))
end
Picker.Lower = asciiLower

local function containsAny(text, words)
    for _, word in ipairs(words) do
        if text:find(word, 1, true) then
            return true
        end
    end
    return false
end

local function equalsAny(text, words)
    for _, word in ipairs(words) do
        if text == word then
            return true
        end
    end
    return false
end

-- Primer número de un texto. "1.344" y "1,344" (grupo de 3 cifras) son miles; "243.6" es decimal.
function Picker.ParseNumber(text)
    local raw = text and text:match("%d[%d%.,]*")
    if not raw then
        return nil
    end
    raw = raw:gsub("[%.,]$", "")
    local digits = raw:gsub("[%.,](%d%d%d)", "%1")
    digits = digits:gsub(",", ".")
    return tonumber(digits)
end

-- Lee las líneas de texto de un tooltip (cadenas). Devuelve { health, mana, restore, buff }.
-- restore = el número de la primera línea que habla de salud o maná ("Restaura 61 p. de salud").
function Picker.ParseTooltip(lines)
    local info = { health = false, mana = false, buff = false }
    for _, line in ipairs(lines or {}) do
        if type(line) == "string" then
            local text = asciiLower(line)
            local health, mana = containsAny(text, Picker.WORDS_HEALTH), containsAny(text, Picker.WORDS_MANA)
            local number = Picker.ParseNumber(text)
            if (health or mana) and number then
                info.health = info.health or health
                info.mana = info.mana or mana
                info.restore = info.restore or number
            end
            if containsAny(text, Picker.WORDS_BUFF) then
                info.buff = true
            end
        end
    end
    return info
end

-- Clasifica un objeto por el nombre del hechizo de uso ("Comida", "Bebida", "Refrigerio") y, si
-- no basta, por lo que restaura su tooltip. extraFood/extraDrink: nombres traducidos que da el
-- cliente. Devuelve "food", "drink", "both" o nil.
function Picker.Classify(spellName, tooltipInfo, extraFood, extraDrink)
    local name = type(spellName) == "string" and asciiLower(spellName) or nil
    if name then
        if equalsAny(name, Picker.SPELL_BOTH) then
            return "both"
        elseif equalsAny(name, Picker.SPELL_FOOD) or (extraFood and name == asciiLower(extraFood)) then
            return "food"
        elseif equalsAny(name, Picker.SPELL_DRINK) or (extraDrink and name == asciiLower(extraDrink)) then
            return "drink"
        end
    end
    if tooltipInfo then
        if tooltipInfo.health and tooltipInfo.mana then
            return "both"
        elseif tooltipInfo.health then
            return "food"
        elseif tooltipInfo.mana then
            return "drink"
        end
    end
    return nil
end

local function Better(a, b, preferBuff)
    if a.buff ~= b.buff then
        if preferBuff then
            return a.buff
        end
        return b.buff
    end
    local ra, rb = a.restore or 0, b.restore or 0
    if ra ~= rb then
        return ra > rb
    end
    local la, lb = a.minLevel or 0, b.minLevel or 0
    if la ~= lb then
        return la > lb
    end
    local ta, tb = a.total or 0, b.total or 0
    if ta ~= tb then
        return ta < tb -- con todo igual, antes lo que menos tienes: libera huecos
    end
    return a.itemID < b.itemID
end
Picker.Better = Better

-- El hueco con la pila más pequeña (en empate, el primero en orden de bolsa y hueco).
function Picker.SmallestSlot(candidate)
    local best
    for _, s in ipairs(candidate.slots or {}) do
        if
            not best
            or s.count < best.count
            or (s.count == best.count and (s.bag < best.bag or (s.bag == best.bag and s.slot < best.slot)))
        then
            best = s
        end
    end
    return best
end

-- Mejor candidato de un tipo ("food" o "drink") que el personaje puede usar a su nivel.
-- opts = { level = número, preferBuff = bool }. Devuelve el candidato y su hueco, o nil.
function Picker.Choose(candidates, kind, opts)
    local level = opts and opts.level or 1
    local preferBuff = opts and opts.preferBuff or false
    local best
    for _, c in ipairs(candidates or {}) do
        local fits = c.kind == kind or c.kind == "both"
        if fits and (c.minLevel or 0) <= level and c.total and c.total > 0 then
            if not best or Better(c, best, preferBuff) then
                best = c
            end
        end
    end
    if not best then
        return nil
    end
    return best, Picker.SmallestSlot(best)
end

-- Cuerpo de la macro. Con objeto: tooltip e icono del objeto y /use de bolsa y hueco concretos
-- (así se gasta la pila más pequeña). Sin objeto: llama al addon para avisar en el chat.
function Picker.MacroBody(kind, candidate, slot)
    if candidate and slot then
        return ("#showtooltip item:%d\n/use %d %d"):format(candidate.itemID, slot.bag, slot.slot)
    end
    return "/bfd none " .. kind
end
