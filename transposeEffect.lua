local effectMaker = require("BeefStranger.effectMaker")
local bs = require("BeefStranger.functions")
local logger = require("logging.logger")
local log = logger.getLogger("Transpose") or "Logger Not Found"


local looseItems = {
    [tes3.objectType.book] = true,
    [tes3.objectType.light] = true,
    [tes3.objectType.miscItem] = true,
}

local iterateRefs = {
    tes3.objectType.book,
    tes3.objectType.container,
    tes3.objectType.creature,
    tes3.objectType.ingredient,
    -- tes3.objectType.light,
    tes3.objectType.miscItem,
}

tes3.claimSpellEffectId("bsTranspose", 23336)
--Loot items from near collision
---@param e tes3magicEffectCollisionEventData
local function onTranspose(e)
    if e.collision then
        local effect = bs.getEffect(e, 23336)
        if effect == nil then return end
        log:debug("effect radius: %s", effect.max)

        log:debug("alwaysSucceeds = %s", e.sourceInstance.source.alwaysSucceeds)
        
        for container in e.collision.colliderRef.cell:iterateReferences(iterateRefs) do --Get every container in cell

            local distance = e.collision.point:distance(container.position) / 22.1
            local col = e.collision.point
            local objectType = container.object.objectType
            local typeContainer = tes3.objectType.container
            local inRange = distance <= effect.radius
            -- log:debug("container.object - %s, %s", container.object.name, distance)


-----------------------------------Just disabled for testing---------------------------------------------------------------
            if inRange and container.object.script == nil then --Only apply for containers within effects radius
                local owned = tes3.getOwner({reference = container}) --tes3.getOwner({ reference = container }) == nil

                log:debug("44: Container - %s, Owned = %s, distance - %s, radius - %s", container.object.name,owned, (distance), effect.radius)

                if not owned and (objectType == typeContainer and #container.object.inventory > 0) --[[ and container.lockNode.trap == nil and container.lockNode.locked == false ]] then
                    tes3.messageBox("49: %s not owned", container.object.name)
                    if container.lockNode then
                        if container.lockNode.trap or container.lockNode.locked then
                            log:debug("52: %s is locked/trapped", container.object.name)
                            return
                        end
                    else
                        log:debug("not locked/trapped proceeding")
                    end
                    tes3.transferInventory({ from = container, to = tes3.mobilePlayer})
                    log:debug("Looting - %s, distance - %s, spellRadius - %s", container.object.name, (distance), effect.radius)
                end

                if owned then
                    tes3.messageBox("%s IS owned by %s", container.object.name, tes3.getOwner({reference = container}))
                    tes3.createVisualEffect({ lifespan = 1, reference = container, magicEffectId = 23336, })
                end
            end
            --if 
            if inRange and container.object.script == nil and looseItems[container.object.objectType] and (container.deleted == false) then
                if container.object.name == "Gold" then --Gold piles dont work right, so i have to do this
                    tes3.addItem({reference = tes3.mobilePlayer, item = container.object, count = container.object.value})
                    log:debug("Looting %s - %s", container.object.id, container.object.value)
                    container:delete()
                else --Add the item to the player, then delete the item
                    tes3.addItem({reference = tes3.mobilePlayer, item = container.object, count = container.stackSize})
                    log:debug("Looting - %s, %s, distance - %s, spellRadius - %s", container.object.name, container.stackSize, (distance), effect.radius)
                    container:delete()
                end
            end
        end
    end
end


local function addEffects()
    local bsTranspose = effectMaker.create({
        id = tes3.effect.bsTranspose,
        name = "Transposistion",
        school = tes3.magicSchool["mysticism"],

        baseCost = 10,

        allowSpellmaking = true,
        canCastSelf = false,
        onCollision = onTranspose
    })
end
event.register("magicEffectsResolved", addEffects)