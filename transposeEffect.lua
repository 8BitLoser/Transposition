local bs = require("BeefStranger.functions")
local effectMaker = require("BeefStranger.effectMaker")
local logger = require("logging.logger")
local log = logger.getLogger("Transpose") or "Logger Not Found"

--Boolean Table of loose item objectTypes
local itemTypes = {
    [tes3.objectType.armor] = true,
    [tes3.objectType.book] = true,
    [tes3.objectType.clothing] = true,
    [tes3.objectType.miscItem] = true,
    [tes3.objectType.weapon] = true,
}
--Boolean Table of objects with an inventory
local hasInventory = {
    [tes3.objectType.container] = true,
    [tes3.objectType.creature] = true,
    [tes3.objectType.npc] = true,
}
--Table of types to loop over in cell
local iterateRefs = {
    tes3.objectType.armor,
    tes3.objectType.book,
    tes3.objectType.container,
    tes3.objectType.clothing,
    tes3.objectType.creature,
    tes3.objectType.ingredient,
    tes3.objectType.miscItem,
    tes3.objectType.npc,
    tes3.objectType.weapon,
}
--Boolean Table of living beings
local being = {
    [tes3.objectType.creature] = true,
    [tes3.objectType.npc] = true,
}
----Need more experience with functions, so using a ton. Does make code look a bit nicer

local function addItem(ref) ---@param ref tes3reference Add item to player then delete it
    if itemTypes[ref.object.objectType] and (ref.deleted == false) then --If the item is in the list and not marked deleted
        if ref.object.name == "Gold" then                               --Gold piles dont work right, so i have to do this
            tes3.addItem({ reference = tes3.mobilePlayer, item = ref.object, count = ref.object.value })
            ----log:debug("Looting Gold - %s", ref.object.value)
            ref:delete()
        else --Add the item to the player, then delete the item
            tes3.addItem({ reference = tes3.mobilePlayer, item = ref.object, count = ref.stackSize })
            ----log:debug("Looting item - %s - %s", ref.object.name, ref.stackSize)
            ref:delete()
        end
    end
end

local function refCheck(ref) ---@param ref tes3reference --Function to test lockNode, Locked, Trapped, NPC, isDead, Owner, Inventory
    --lockNode Check
    if ref.lockNode then
        if ref.lockNode.trap then
            ----log:debug("%s is trapped : skipping", ref.object.name)
            return false
        elseif ref.lockNode.locked then
            ----log:debug("%s is locked : skipping", ref.object.name)
            return false
        end
        return true
    end

    --NPC and Creature living check
    if (ref.object.objectType == tes3.objectType.npc) or (ref.object.objectType == tes3.objectType.creature) then
        if ref.mobile.isDead then
            return true
        end
        --log:debug("%s is not dead : skipping", ref.object.name)
        return false
    end

    --Script Check
    if ref.object.script ~= nil then --false if object has script
        --log:debug("%s has script : skipping", ref.object.name)
        return false
    end

    --Owner Check
    if tes3.getOwner({ reference = ref }) ~= nil then
        --log:debug("%s owned : skipping", ref.object.name)
        return false
    end

    --Inventory check
    if hasInventory[ref.object.objectType] and #ref.object.inventory > 0 then
        --log:debug("%s has valid inventory", ref.object.name)
        return true
    end
end
local function transfer(ref) ---@param ref tes3reference Just a little function to transfer/play effect if refCheck true
    if refCheck(ref) then
        tes3.createVisualEffect({ lifespan = 1, reference = ref, magicEffectId = 23336, })
        --log:debug("playing effect on %s",ref.object.name)
        tes3.transferInventory({from = ref, to = tes3.mobilePlayer})
        --log:debug("transfering from %s",ref.object.name)
    end
end

local function teleport(ref)---@param ref tes3reference Function to handle random teleporting of living beings
    local pos, iter, rand, newPos = ref.position:copy(), 0, 1500, nil --setup pos as the current ref pos, and set iter to 0
    repeat --Repeat below until certain condition is met
        newPos = pos:copy()
        newPos.x = pos.x + math.random(-rand, rand) --Randomize xyz by +-rand
        newPos.y = pos.y + math.random(-rand, rand)
        newPos.z = pos.z + math.random(0, rand/1.5) --dont want them going downwards, causes lots of iterations and maxing out
        local collision = tes3.testLineOfSight({ position1 = pos, position2 = newPos}) --Gets los, using to get pos not in a wall
        iter = iter + 1 --Just a counter
        log:debug("iteration %s", iter)
    until collision == true or iter >= 150 --Repeat until a random point has been generated thats in los of ref, to stop them tp into walls

    ----log:debug("Ref pos %s, adjusted Pos %s", pos, newPos)

    if iter < 150 then --Only teleport if a valid collision pos was found within 175 tries
        tes3.positionCell({ reference = ref, position = newPos, cell = tes3.mobilePlayer.cell })
        -- tes3.positionCell({ reference = tes3.player, position = newPos, cell = tes3.mobilePlayer.cell })
    else
        log:debug("no safe pos found")
    end
end

tes3.claimSpellEffectId("bsTranspose", 23336)
--Transpose effect : Loot items from in radius of collision
---@param e tes3magicEffectCollisionEventData
local function onTranspose(e) 
    if e.collision then
        local closest = nil --Variable for storing the nearest item if nothing was in range

        for ref in e.collision.colliderRef.cell:iterateReferences(iterateRefs) do --Set ref to every object in cell, that matches a type in iterateRefs table
            local distance = (e.collision.point:distance(ref.position) / 22.1)    --The distance between the collision point and the position of the iterated ref
            local range = math.max((bs.getEffect(e, 23336).radius + 1.5), 1.5)    --Range is either the effect radius + 1.5 or 1.5, whatever is bigger
            local inRange = (distance <= range)                                   --Returns true if distance to ref is in range of the spell

            --Note about range/radius, things can be hit in the visual radius but outside of the actual radius,
            --not by much but it still happens. Most noticable at 0 radius, it will fail to impact items 
            --like 95% of the time. Setting a min value of 1.5 seems to help, and adding 1.5 makes it
            --about equal with the visual radius of the effect. Otherwise things in the circle might not
            --actually be hit even though visually it was.

            if inRange then
                tes3.messageBox("inRange")
                transfer(ref)
                addItem(ref)
                if being[ref.object.objectType] and ref.mobile.isDead == false then
                    teleport(ref)
                end
            end

            if not inRange then
                if distance <= 5 then
                    if closest == nil or distance < e.collision.point:distance(ref.position) / 22.1 then
                        closest = ref
                        transfer(closest)
                        addItem(closest)
                    end
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
        speed = 3,

        allowSpellmaking = true,
        hasNoMagnitude = true,
        hasNoDuration = true,
        canCastSelf = false,
        onCollision = onTranspose
    })
end
event.register("magicEffectsResolved", addEffects)