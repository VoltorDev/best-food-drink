local addonName, ns = ...
local L = ns.L
local module = ns:NewModule("Config")

-- Panel en Opciones > AddOns con la API nativa Settings (Blizzard_Settings_Shared).
-- Se registra en OnInitialize porque Settings.RegisterAddOnSetting escribe el valor por defecto
-- en la tabla si la clave es nil: hay que hacerlo DESPUÉS de cargar las SavedVariables.
function module:OnInitialize()
    local db = ns.db
    local category = Settings.RegisterVerticalLayoutCategory(L.ADDON_TITLE)

    local function OnSettingChanged()
        ns:ApplySettings()
    end

    local function AddCheckbox(suffix, key, label, tooltip)
        local setting = Settings.RegisterAddOnSetting(
            category,
            addonName .. "_" .. suffix,
            key,
            db,
            Settings.VarType.Boolean,
            label,
            ns.DEFAULTS[key]
        )
        setting:SetValueChangedCallback(OnSettingChanged)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    AddCheckbox("Enabled", "enabled", L.OPT_ENABLED, L.OPT_ENABLED_TT)
    AddCheckbox("CreateMacros", "createMacros", L.OPT_CREATE, L.OPT_CREATE_TT)
    AddCheckbox("PreferBuffFood", "preferBuffFood", L.OPT_BUFF, L.OPT_BUFF_TT)

    Settings.RegisterAddOnCategory(category)
    ns.settingsCategory = category
end

-- Abrir el panel está restringido en combate (C_SettingsUtil.OpenSettingsPanel lleva HasRestrictions).
function ns:OpenSettings()
    if InCombatLockdown() then
        self:Print(L.ERR_COMBAT)
        return
    end
    Settings.OpenToCategory(self.settingsCategory:GetID())
end

-- Compartimento de addons (botón del minimapa). Los nombres coinciden con el TOC.
-- El cliente llama a la función de clic con (addonName, buttonName) y a las de ratón
-- con (addonName, menuButtonFrame).
function BestFoodDrink_OnAddonCompartmentClick()
    ns:OpenSettings()
end

function BestFoodDrink_OnAddonCompartmentEnter(_, menuButtonFrame)
    GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_LEFT")
    GameTooltip:SetText(L.ADDON_TITLE)
    GameTooltip:AddLine(L.COMPARTMENT_TOOLTIP, 1, 1, 1)
    GameTooltip:Show()
end

function BestFoodDrink_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end
