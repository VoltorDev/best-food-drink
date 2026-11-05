-- Lógica de elección (Modules/Picker.lua): números del tooltip, clasificación comida/bebida y
-- orden de preferencia. Se carga solo Picker.lua: no toca API de WoW.
local WowEnv = require("wow_env")

local function loadPicker()
    local env = WowEnv.new()
    local ns = {}
    env:LoadFile("Modules/Picker.lua", "BestFoodDrink", ns)
    assert.are.same({}, env:Missing())
    return ns.Picker
end

local Picker = loadPicker()

local function food(id, restore, minLevel, total, extra)
    local c = { itemID = id, kind = "food", restore = restore, minLevel = minLevel, total = total, slots = {} }
    for k, v in pairs(extra or {}) do
        c[k] = v
    end
    if #c.slots == 0 then
        c.slots = { { bag = 0, slot = id % 16 + 1, count = total } }
    end
    return c
end

describe("ParseNumber", function()
    it("lee enteros, miles con punto o coma y decimales", function()
        assert.are.equal(61, Picker.ParseNumber("restores 61 health"))
        assert.are.equal(1344, Picker.ParseNumber("restaura 1.344 p. de salud"))
        assert.are.equal(2148, Picker.ParseNumber("restores 2,148 mana"))
        assert.are.equal(243.6, Picker.ParseNumber("restores 243.6 health"))
        assert.are.equal(18, Picker.ParseNumber("18 s."))
        assert.is_nil(Picker.ParseNumber("sin números"))
        assert.is_nil(Picker.ParseNumber(nil))
    end)
end)

describe("ParseTooltip", function()
    it("comida en inglés: salud y cantidad", function()
        local t = Picker.ParseTooltip({ "Tough Jerky", "Use: Restores 61 health over 18 sec." })
        assert.is_true(t.health)
        assert.is_false(t.mana)
        assert.are.equal(61, t.restore)
        assert.is_false(t.buff)
    end)

    it("bebida en español del cliente esES", function()
        local t = Picker.ParseTooltip({ "Agua de manantial", "Uso: Restaura 151 p. de maná durante 18 s." })
        assert.is_true(t.mana)
        assert.is_false(t.health)
        assert.are.equal(151, t.restore)
    end)

    it("la línea de nivel requerido no cuenta como restauración", function()
        local t = Picker.ParseTooltip({ "Requires Level 15", "Use: Restores 552 health over 24 sec." })
        assert.are.equal(552, t.restore)
    end)

    it("detecta el bonus Bien alimentado en inglés y en español", function()
        assert.is_true(Picker.ParseTooltip({ "Use: Restores 243 health. ... you will become well fed ..." }).buff)
        assert.is_true(Picker.ParseTooltip({ "Uso: Restaura 243 p. de salud. ... estarás bien alimentado ..." }).buff)
    end)

    it("ignora líneas que no son texto (p. ej. un valor que no sea string)", function()
        local t = Picker.ParseTooltip({ 42, false, "Use: Restores 61 health" })
        assert.are.equal(61, t.restore)
    end)
end)

describe("Classify", function()
    it("por el nombre del hechizo de uso, en inglés y en español", function()
        assert.are.equal("food", Picker.Classify("Food"))
        assert.are.equal("food", Picker.Classify("Comida"))
        assert.are.equal("drink", Picker.Classify("Drink"))
        assert.are.equal("drink", Picker.Classify("Bebida"))
        assert.are.equal("both", Picker.Classify("Refreshment"))
    end)

    it("acepta los nombres traducidos que da el cliente", function()
        assert.are.equal("food", Picker.Classify("Essen", nil, "Essen", "Trinken"))
        assert.are.equal("drink", Picker.Classify("Trinken", nil, "Essen", "Trinken"))
    end)

    it("si el hechizo no lo dice, decide el tooltip", function()
        assert.are.equal("food", Picker.Classify("Algo raro", { health = true, mana = false }))
        assert.are.equal("drink", Picker.Classify(nil, { health = false, mana = true }))
        assert.are.equal("both", Picker.Classify(nil, { health = true, mana = true }))
        assert.is_nil(Picker.Classify("Rumsey Rum", { health = false, mana = false }))
    end)
end)

describe("Choose", function()
    it("elige la que más restaura", function()
        local best = Picker.Choose({ food(117, 61, 1, 5), food(2287, 243, 5, 5) }, "food", { level = 7 })
        assert.are.equal(2287, best.itemID)
    end)

    it("descarta la que pide más nivel del que tienes", function()
        local best = Picker.Choose({ food(2287, 243, 5, 5), food(3770, 552, 15, 5) }, "food", { level = 7 })
        assert.are.equal(2287, best.itemID)
        best = Picker.Choose({ food(2287, 243, 5, 5), food(3770, 552, 15, 5) }, "food", { level = 15 })
        assert.are.equal(3770, best.itemID)
    end)

    it("sin datos de restauración, decide el nivel requerido", function()
        local best = Picker.Choose({ food(1, nil, 1, 5), food(2, nil, 5, 5) }, "food", { level = 7 })
        assert.are.equal(2, best.itemID)
    end)

    it("con todo igual, gasta antes lo que menos tienes", function()
        local best = Picker.Choose({ food(10, 243, 5, 20), food(11, 243, 5, 3) }, "food", { level = 7 })
        assert.are.equal(11, best.itemID)
    end)

    it("la comida con bonus va al final salvo que se prefiera", function()
        local plain, buffed = food(2287, 243, 5, 5), food(724, 300, 5, 5, { buff = true })
        assert.are.equal(2287, Picker.Choose({ plain, buffed }, "food", { level = 7 }).itemID)
        assert.are.equal(724, Picker.Choose({ plain, buffed }, "food", { level = 7, preferBuff = true }).itemID)
        -- Sin otra opción, se usa aunque no se prefiera.
        assert.are.equal(724, Picker.Choose({ buffed }, "food", { level = 7 }).itemID)
    end)

    it("no mezcla comida y bebida; 'both' sirve para las dos", function()
        local water = food(159, 151, 1, 5, { kind = "drink" })
        local both = food(500, 100, 1, 5, { kind = "both" })
        assert.are.equal(159, Picker.Choose({ water, both }, "drink", { level = 7 }).itemID)
        assert.are.equal(500, Picker.Choose({ water, both }, "food", { level = 7 }).itemID)
        assert.is_nil(Picker.Choose({ water }, "food", { level = 7 }))
        assert.is_nil(Picker.Choose({}, "food", { level = 7 }))
    end)

    it("devuelve el hueco con la pila más pequeña", function()
        local c = food(117, 61, 1, 25, {
            slots = {
                { bag = 0, slot = 1, count = 20 },
                { bag = 1, slot = 4, count = 2 },
                { bag = 0, slot = 9, count = 3 },
            },
        })
        local _, slot = Picker.Choose({ c }, "food", { level = 7 })
        assert.are.same({ bag = 1, slot = 4, count = 2 }, slot)
    end)

    it("con pilas iguales, el primer hueco en orden de bolsa", function()
        local c = food(117, 61, 1, 10, {
            slots = { { bag = 1, slot = 1, count = 5 }, { bag = 0, slot = 7, count = 5 } },
        })
        local _, slot = Picker.Choose({ c }, "food", { level = 7 })
        assert.are.equal(0, slot.bag)
        assert.are.equal(7, slot.slot)
    end)
end)

describe("MacroBody", function()
    it("con objeto: tooltip del objeto y /use de bolsa y hueco", function()
        local body = Picker.MacroBody("food", { itemID = 117 }, { bag = 1, slot = 4 })
        assert.are.equal("#showtooltip item:117\n/use 1 4", body)
    end)

    it("sin objeto: avisa por el comando del addon", function()
        assert.are.equal("/bfd none drink", Picker.MacroBody("drink"))
    end)
end)
