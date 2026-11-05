-- Macros gestionadas (Modules/Macros.lua) contra bolsas, objetos y macros simulados.
local FakeGame = require("fake_game")

local function contains(text, fragment)
    assert(text:find(fragment, 1, true), "no aparece «" .. fragment .. "» en:\n" .. text)
end

local function bodies(game, ns)
    local f = game:Macro(ns.L.MACRO_FOOD)
    local d = game:Macro(ns.L.MACRO_DRINK)
    return f and f.body, d and d.body
end

describe("creación de las macros", function()
    it("al entrar crea las dos macros de personaje con la mejor comida y bebida", function()
        local env, ns, game = FakeGame.boot({
            level = 7,
            bags = { [0] = { [1] = { itemID = 117, count = 10 }, [2] = { itemID = 159, count = 5 } } },
        })
        local food, drink = bodies(game, ns)
        assert.are.equal("#showtooltip item:117\n/use 0 1", food)
        assert.are.equal("#showtooltip item:159\n/use 0 2", drink)
        assert.are.equal(1001, game:Macro(ns.L.MACRO_FOOD).icon)
        assert.are.equal(2, game.created)
        contains(env:Printed(), ns.L.MACROS_CREATED:format(ns.L.MACRO_FOOD, ns.L.MACRO_DRINK))
        assert.are.same({}, env:Missing())
    end)

    it("sin comida ni bebida la macro avisa por /bfd", function()
        local env, ns, game = FakeGame.boot({ bags = { [0] = {} } })
        local food, drink = bodies(game, ns)
        assert.are.equal("/bfd none food", food)
        assert.are.equal("/bfd none drink", drink)
        env:ClearPrinted()
        env:RunSlash(drink)
        contains(env:Printed(), ns.L.NO_DRINK)
    end)

    it("en español las macros se llaman MejorComida y MejorBebida", function()
        local _, ns, game = FakeGame.boot(
            { bags = { [0] = { [1] = { itemID = 117, count = 1 } } } },
            { locale = "esES" }
        )
        assert.are.equal("MejorComida", ns.L.MACRO_FOOD)
        assert.is_not_nil(game:Macro("MejorComida"))
        assert.is_not_nil(game:Macro("MejorBebida"))
    end)

    it("si Nico borra una macro, no vuelve sola; /bfd crear la recupera", function()
        local env, ns, game = FakeGame.boot({ bags = { [0] = { [1] = { itemID = 117, count = 1 } } } })
        game:DeleteMacro(ns.L.MACRO_FOOD)
        env:Fire("BAG_UPDATE_DELAYED")
        env:Advance(1)
        assert.is_nil(game:Macro(ns.L.MACRO_FOOD))
        assert.is_not_nil(game:Macro(ns.L.MACRO_DRINK))

        env:RunSlash("/bfd crear")
        assert.are.equal("#showtooltip item:117\n/use 0 1", game:Macro(ns.L.MACRO_FOOD).body)
    end)

    it("con la opción de crear desactivada no crea nada (pero /bfd crear sí)", function()
        local env, ns, game = FakeGame.boot({}, nil, { db = { schema = 1, createMacros = false } })
        assert.are.equal(0, game.created)
        env:RunSlash("/bfd create")
        assert.are.equal(2, game.created)
        assert.is_not_nil(game:Macro(ns.L.MACRO_FOOD))
    end)

    it("sin huecos de macro de personaje avisa y no falla", function()
        local env, ns, game = FakeGame.boot({ charMacros = 30 })
        assert.are.equal(0, game.created)
        contains(env:Printed(), ns.L.ERR_NO_MACRO_SLOTS)
    end)

    it("respeta una macro de Nico con otro nombre: solo edita las suyas", function()
        local _, _, game = FakeGame.boot({ charMacros = 2, bags = { [0] = { [1] = { itemID = 117, count = 1 } } } })
        assert.are.equal("/sit", game:Macro("Otra1").body)
        assert.are.equal("/sit", game:Macro("Otra2").body)
    end)
end)

describe("actualización automática", function()
    it("al cambiar las bolsas pasa a la nueva mejor comida", function()
        local env, ns, game = FakeGame.boot({ level = 7, bags = { [0] = { [1] = { itemID = 117, count = 10 } } } })
        game:Put(0, 3, 2287, 4)
        env:Fire("BAG_UPDATE_DELAYED")
        env:Advance(1)
        assert.are.equal("#showtooltip item:2287\n/use 0 3", (bodies(game, ns)))
        game:Clear(0, 3)
        env:Fire("BAG_UPDATE_DELAYED")
        env:Advance(1)
        assert.are.equal("#showtooltip item:117\n/use 0 1", (bodies(game, ns)))
    end)

    it("varios BAG_UPDATE_DELAYED seguidos se agrupan en un solo refresco", function()
        local env, _, game = FakeGame.boot({ bags = { [0] = { [1] = { itemID = 117, count = 1 } } } })
        game:Put(0, 2, 2287, 1)
        local before = game.edits
        for _ = 1, 5 do
            env:Fire("BAG_UPDATE_DELAYED")
        end
        env:Advance(1)
        assert.are.equal(before + 1, game.edits)
    end)

    it("no reescribe la macro si no ha cambiado nada", function()
        local env, _, game = FakeGame.boot({ bags = { [0] = { [1] = { itemID = 117, count = 1 } } } })
        local before = game.edits
        env:Fire("BAG_UPDATE_DELAYED")
        env:Advance(1)
        assert.are.equal(before, game.edits)
    end)

    it("al subir de nivel desbloquea la comida de más nivel (usa el nivel del evento)", function()
        local env, ns, game = FakeGame.boot({
            level = 14,
            bags = { [0] = { [1] = { itemID = 2287, count = 5 }, [2] = { itemID = 3770, count = 5 } } },
        })
        assert.are.equal("#showtooltip item:2287\n/use 0 1", (bodies(game, ns)))
        env:Fire("PLAYER_LEVEL_UP", 15, 0, 0, 0, 0, 0, 0, 0, 0, 0) -- UnitLevel aún dice 14
        env:Advance(1)
        assert.are.equal("#showtooltip item:3770\n/use 0 2", (bodies(game, ns)))
    end)

    it("en combate no toca las macros; las pone al día al salir", function()
        local env, ns, game = FakeGame.boot({ bags = { [0] = { [1] = { itemID = 117, count = 1 } } } })
        env:SetCombat(true)
        game:Put(0, 2, 2287, 1)
        env:Fire("BAG_UPDATE_DELAYED")
        env:Advance(1) -- EditMacro en combate daría error en el juego simulado
        assert.are.equal("#showtooltip item:117\n/use 0 1", (bodies(game, ns)))
        assert.is_true(ns.Macros.pending)
        env:SetCombat(false)
        env:Advance(1)
        assert.are.equal("#showtooltip item:2287\n/use 0 2", (bodies(game, ns)))
        assert.is_false(ns.Macros.pending)
    end)

    it("un objeto aún sin datos se reintenta con GET_ITEM_INFO_RECEIVED", function()
        local env, ns, game = FakeGame.boot({
            bags = { [0] = { [1] = { itemID = 117, count = 1 }, [2] = { itemID = 2287, count = 1 } } },
            uncached = { [2287] = true },
        })
        assert.are.equal("#showtooltip item:117\n/use 0 1", (bodies(game, ns)))
        game.uncached[2287] = nil
        env:Fire("GET_ITEM_INFO_RECEIVED", 2287, true)
        env:Advance(1)
        assert.are.equal("#showtooltip item:2287\n/use 0 2", (bodies(game, ns)))
    end)

    it("con la opción 'mantener al día' desactivada no edita", function()
        local env, ns, game = FakeGame.boot({ bags = { [0] = { [1] = { itemID = 117, count = 1 } } } })
        env:SettingsRegistry().settings[env:AddonName() .. "_Enabled"]:SetValue(false)
        env:Advance(1)
        game:Put(0, 2, 2287, 1)
        env:Fire("BAG_UPDATE_DELAYED")
        env:Advance(1)
        assert.are.equal("#showtooltip item:117\n/use 0 1", (bodies(game, ns)))
    end)

    it("cambiar 'preferir comida con bonus' reescribe la macro", function()
        local env, ns, game = FakeGame.boot({
            bags = { [0] = { [1] = { itemID = 2287, count = 5 }, [2] = { itemID = 724, count = 5 } } },
        })
        assert.are.equal("#showtooltip item:2287\n/use 0 1", (bodies(game, ns)))
        env:SettingsRegistry().settings[env:AddonName() .. "_PreferBuffFood"]:SetValue(true)
        env:Advance(1)
        assert.are.equal("#showtooltip item:724\n/use 0 2", (bodies(game, ns)))
    end)
end)

describe("qué cuenta como comida o bebida", function()
    it("ignora pociones, vendas y otros objetos usables", function()
        local _, ns, game = FakeGame.boot({
            bags = {
                [0] = {
                    [1] = { itemID = 118, count = 5 },
                    [2] = { itemID = 1251, count = 5 },
                    [3] = { itemID = 6948, count = 1 },
                },
            },
        })
        local food, drink = bodies(game, ns)
        assert.are.equal("/bfd none food", food)
        assert.are.equal("/bfd none drink", drink)
    end)

    it("recorre todas las bolsas y usa la pila más pequeña", function()
        local _, ns, game = FakeGame.boot({
            bags = { [0] = { [5] = { itemID = 159, count = 20 } }, [2] = { [7] = { itemID = 159, count = 3 } } },
        })
        local _, drink = bodies(game, ns)
        assert.are.equal("#showtooltip item:159\n/use 2 7", drink)
    end)

    it("a nivel 7 elige la mejor bebida que puede usar", function()
        local _, ns, game = FakeGame.boot({
            level = 7,
            bags = {
                [0] = {
                    [1] = { itemID = 159, count = 5 },
                    [2] = { itemID = 1179, count = 5 },
                    [3] = { itemID = 1205, count = 5 },
                },
            },
        })
        local _, drink = bodies(game, ns)
        assert.are.equal("#showtooltip item:1179\n/use 0 2", drink)
    end)
end)

describe("/bfd", function()
    it("sin argumentos muestra qué usará cada macro", function()
        local env, ns = FakeGame.boot({ bags = { [0] = { [1] = { itemID = 117, count = 10 } } } })
        env:ClearPrinted()
        env:RunSlash("/bfd")
        local out = env:Printed()
        contains(out, ns.L.STATUS_HEADER)
        contains(out, ns.L.STATUS_LINE:format("Tough Jerky", 10, "61"))
        contains(out, ns.L.NO_DRINK)
    end)

    it("en combate no hace nada y lo explica", function()
        local env, ns = FakeGame.boot({})
        env:SetCombat(true)
        env:ClearPrinted()
        env:RunSlash("/bfd")
        env:RunSlash("/bfd crear")
        contains(env:Printed(), ns.L.ERR_COMBAT)
    end)

    it("'debug' lista los candidatos encontrados", function()
        local env = FakeGame.boot({ bags = { [0] = { [1] = { itemID = 117, count = 10 } } } })
        env:ClearPrinted()
        env:RunSlash("/bfd debug")
        contains(env:Printed(), "item:117 food restaura=61 nivel=1 buff=false total=10")
    end)
end)
