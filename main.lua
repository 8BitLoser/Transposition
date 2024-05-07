--=============================Config/Logging================================--
-- local config = require("BeefStranger.Magical Repairing.config")
local logger = require("logging.logger")
local log = logger.new { name = "Transpose", logLevel = "DEBUG", logToConsole = true, }
-- if config.debug then log:setLogLevel("DEBUG") end
--=============================Config/Logging================================--

local bs = require("BeefStranger.functions")
local spellMaker = require("BeefStranger.spellMaker")

require("BeefStranger.Transposition.transposeEffect")

local function initialized()
    print("[MWSE:Transposition Initialized]")
end
event.register(tes3.event.initialized, initialized)

local function registerSpells()
    spellMaker.create({
        id = "bsTranspose",
        name = "Transposistion",
        effect = tes3.effect.bsTranspose,
        alwaysSucceeds = true,
        min = 25,
        range = tes3.effectRange.target,
        radius = 10
    })

end
event.register("loaded", registerSpells, {priority = 1})

local function addSpells()
   tes3.addSpell({ reference = tes3.mobilePlayer, spell = "bsTranspose" })
   tes3.mobilePlayer:equipMagic { source = "bsTranspose" }
end
event.register(tes3.event.loaded, addSpells)

local objectTypeNames = {
    [1230259009] = "activator",
    [1212369985] = "alchemy",
    [1330466113] = "ammunition",
    [1095782465] = "apparatus",
    [1330467393] = "armor",
    [1313297218] = "birthsign",
    [1497648962] = "bodyPart",
    [1263488834] = "book",
    [1280066883] = "cell",
    [1396788291] = "class",
    [1414483011] = "clothing",
    [1414418243] = "container",
    [1095062083] = "creature",
    [1279347012] = "dialogue",
    [1330007625] = "dialogueInfo",
    [1380929348] = "door",
    [1212370501] = "enchantment",
    [1413693766] = "faction",
    [1414745415] = "gmst",
    [1380404809] = "ingredient",
    [1145979212] = "land",
    [1480938572] = "landTexture",
    [1129727308] = "leveledCreature",
    [1230390604] = "leveledItem",
    [1212631372] = "light",
    [1262702412] = "lockpick",
    [1178945357] = "magicEffect",
    [1129531725] = "miscItem",
    [1413693773] = "mobileActor",
    [1380139341] = "mobileCreature",
    [1212367181] = "mobileNPC",
    [1346584909] = "mobilePlayer",
    [1246908493] = "mobileProjectile",
    [1347637325] = "mobileSpellProjectile",
    [1598246990] = "npc",
    [1146242896] = "pathGrid",
    [1112494672] = "probe",
    [1397052753] = "quest",
    [1162035538] = "race",
    [1380336978] = "reference",
    [1313293650] = "region",
    [1095779666] = "repairItem",
    [1414546259] = "script",
    [1279871827] = "skill",
    [1314213715] = "sound",
    [1195658835] = "soundGenerator",
    [1279610963] = "spell",
    [1380143955] = "startScript",
    [1413567571] = "static",
    [1346454871] = "weapon"
}

local function onKeyDownI()
    if not tes3.menuMode()then
        -- log:debug("I Pressed")
        local target = tes3.getPlayerTarget()
        if not target then return end

        local typeName = objectTypeNames[target.object.objectType] or "Unknown Type"
        log:debug("%s, tes3.objectType.%s", target.object.id, typeName)
        -- log:debug("%s trap %s, locked %s, trapNode %s", target.object.name, target.lockNode.trap, target.lockNode.locked, target.lockNode)
        -- log:debug("objectFaction %s, playerFaction %s",target.object.faction[1].name, tes3.player.object.faction)

    end
end

event.register("keyUp", onKeyDownI, { filter = tes3.scanCode["i"] })

