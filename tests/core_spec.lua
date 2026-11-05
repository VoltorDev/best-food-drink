-- Ciclo de vida (ADDON_LOADED -> PLAYER_LOGIN) y SavedVariables de Core.lua: valores por
-- defecto en el primer inicio, datos existentes en el segundo y migraciones de esquema.
local FakeGame = require("fake_game")

local TOC = "BestFoodDrink.toc"

-- Arranca el addon con unas SavedVariables dadas (nil = primer inicio) y opciones del cliente.
local function bootWith(saved, charSaved, opts)
    local env = FakeGame.envNew(opts)
    env.BestFoodDrinkDB = saved
    env.BestFoodDrinkCharDB = charSaved
    local ns = env:LoadToc(TOC) or error("el addon no cargó")
    env:Login()
    return env, ns
end

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for k, v in pairs(value) do
        copy[k] = deepCopy(v)
    end
    return copy
end

describe("ciclo ADDON_LOADED -> PLAYER_LOGIN", function()
    it("las SavedVariables se preparan en el ADDON_LOADED propio, no antes ni con el de otro addon", function()
        local env = FakeGame.envNew()
        local ns = env:LoadToc(TOC) or error("el addon no cargó")
        assert.is_nil(ns.db)
        env:Fire("ADDON_LOADED", "OtroAddon", false)
        assert.is_nil(ns.db)
        env:Fire("ADDON_LOADED", env:AddonName(), false)
        assert.are.equal(env.BestFoodDrinkDB, ns.db)
        assert.are.equal(env.BestFoodDrinkCharDB, ns.charDB)
    end)

    it("los módulos se activan en PLAYER_LOGIN, con las SavedVariables ya cargadas", function()
        local env = FakeGame.envNew()
        local ns = env:LoadToc(TOC) or error("el addon no cargó")
        env:Fire("ADDON_LOADED", env:AddonName(), false)
        assert.is_nil(ns.Macros.foodSpellName)
        env:Fire("PLAYER_LOGIN")
        assert.are.equal("Food", ns.Macros.foodSpellName)
        assert.are.equal("Drink", ns.Macros.drinkSpellName)
    end)

    it("PLAYER_LOGIN se atiende una sola vez (el manejador se desregistra)", function()
        local env, ns = FakeGame.envBoot(TOC)
        env:ClearPrinted()
        env:Fire("PLAYER_LOGIN")
        assert.is_nil(env:Printed():find(ns.L.LOADED, 1, true))
    end)
end)

describe("SavedVariables", function()
    it("primer inicio: crea las tablas con los valores por defecto (copias, no referencias)", function()
        local env, ns = FakeGame.envBoot(TOC)
        assert.are.same(ns.DEFAULTS, env.BestFoodDrinkDB)
        assert.are.equal(1, env.BestFoodDrinkCharDB.schema)
        assert.are_not.equal(ns.CHAR_DEFAULTS.created, env.BestFoodDrinkCharDB.created)
    end)

    it("segundo inicio: conserva lo guardado y rellena lo que falta", function()
        local env = bootWith({ schema = 1, preferBuffFood = true }, { schema = 1, created = { food = true } })
        local db = env.BestFoodDrinkDB
        assert.is_true(db.preferBuffFood)
        assert.is_true(db.enabled)
        assert.is_true(db.createMacros)
        assert.are.equal(1, db.schema)
        assert.is_true(env.BestFoodDrinkCharDB.created.food)
    end)

    it("una tabla sin schema (anterior a ese campo) se trata como esquema 1", function()
        local env = bootWith({ preferBuffFood = true }, nil)
        assert.are.equal(1, env.BestFoodDrinkDB.schema)
        assert.is_true(env.BestFoodDrinkDB.preferBuffFood)
    end)

    it("unas SavedVariables corruptas (no son tabla) se sustituyen por los valores por defecto", function()
        local env, ns = bootWith("basura", 42)
        assert.are.same(ns.DEFAULTS, env.BestFoodDrinkDB)
        assert.are.equal(1, env.BestFoodDrinkCharDB.schema)
    end)
end)

-- Simula que el desarrollador sube el esquema a 2 y añade MIGRATIONS[2] (renombra un campo).
-- El código se añade al FINAL de Core.lua solo en memoria: el fichero real no cambia.
local MIGRATION_2 = [[

ns.DEFAULTS.schema = 2
MIGRATIONS[2] = function(db)
    if db.buff ~= nil then
        db.preferBuffFood = db.buff
        db.buff = nil
    end
end
]]

describe("migraciones de SavedVariables (Core.lua con un esquema 2 de ejemplo)", function()
    local opts = {
        patch = {
            ["Core.lua"] = function(source)
                return source .. MIGRATION_2
            end,
        },
    }

    it("migra una tabla del esquema 1 al 2 y conserva el resto", function()
        local env = bootWith({ schema = 1, buff = true, enabled = false }, nil, opts)
        assert.are.equal(2, env.BestFoodDrinkDB.schema)
        assert.is_true(env.BestFoodDrinkDB.preferBuffFood)
        assert.is_nil(env.BestFoodDrinkDB.buff)
        assert.is_false(env.BestFoodDrinkDB.enabled)
    end)

    it("una instalación nueva nace en el esquema actual sin pasar por la migración", function()
        local env = bootWith(nil, nil, opts)
        assert.are.equal(2, env.BestFoodDrinkDB.schema)
        assert.is_false(env.BestFoodDrinkDB.preferBuffFood)
    end)

    it("es idempotente: un segundo inicio con la tabla migrada no cambia nada", function()
        local first = bootWith({ schema = 1, buff = true }, nil, opts).BestFoodDrinkDB
        local copy = deepCopy(first)
        local second = bootWith(first, nil, opts).BestFoodDrinkDB
        assert.are.same(copy, second)
    end)

    it("la tabla por personaje sigue en su propio esquema", function()
        local env = bootWith({ schema = 1, buff = true }, { schema = 1 }, opts)
        assert.are.equal(1, env.BestFoodDrinkCharDB.schema)
    end)

    it("una tabla guardada por una versión más nueva del addon no se toca", function()
        local env = bootWith({ schema = 5, buff = true }, nil, opts)
        assert.are.equal(5, env.BestFoodDrinkDB.schema)
        assert.is_true(env.BestFoodDrinkDB.buff)
    end)
end)
