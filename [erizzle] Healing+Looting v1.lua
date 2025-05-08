ThreadSpeed = 50 -- How long the thread will sleep after every tick
Owner = "MrFade + SpeedySaky + erizzle" -- Declaring the owner of this plugin
Name = "Healing BOT" -- Plugin Name

Player = GetPlayer() -- Returns the current Player wUnit
Units = GetUnitsList() -- Returns a list of all current wUnits (includes players)
Players = GetPlayersList() -- Returns a list of all current players

MasterName = "Thorgal" -- You would change this to the name of your master char!
YardsBehindMaster = 15 -- This is how many yards behind the master the slave must stay!
YardsToHealUnits = 40 -- This is how many yards away from the player the BOT will target other players to heal

function FindMaster()
    FoundMaster = FindPlayerByName(MasterName)
end

function DistanceOfMeshToMaster()
    if FoundMaster.IsFalling() then
        Log("Master is falling!")
        return 0
    end

    CurrentPath = GetCurrentPath()
    CurrentPathSize = GetCurrentPathSize()
    if CurrentPath.Length < CurrentPathSize then
        FindMeshPathToUnit(FoundMaster)
        Log("No path yet...")
        return 100
    end

    MyVecFloatArray = VecToFloatArray(CurrentPath[CurrentPathSize-1])
    FoundMasterFloatArray = UnitPosToFloatArray(FoundMaster)
    Distance = DistanceBetweenPoints(FoundMasterFloatArray, MyVecFloatArray)
    return Distance
end

function LootNearbyMobs()
    Units = GetUnitsList()
    foreach Unit in Units do
        if (Unit.Health == 0) and (IsUnitValid(Unit) == true) and (IsUnitLootable(Unit) == true) then
            if DistanceToUnit(Player, Unit) <= 100 then
                Log("Lootable " .. Unit.Name .. " found at position " .. Unit.Position)
                StopMoving()
                FindMeshPathToUnit(Unit)
                SetBOTState("PathingToLoot")

                -- Wait until we reach the unit
                while GetBOTState() == "PathingToLoot" and DistanceToUnit(Player, Unit) > 1 do
                    Path()
                    Sleep(25) -- Reduced delay for smoother pathing
                end

                if DistanceToUnit(Player, Unit) <= 5 then -- Verify we reached the lootable unit
                    TargetUnit(Unit) -- Target the lootable unit
                    Log("Targeted lootable unit: " .. Unit.Name)
                    InteractWithUnit(Unit) -- Loot the unit
                    Log("Looted unit: " .. Unit.Name)
                    Sleep(3000) -- Wait for loot to complete
                else
                    Log("Failed to reach lootable unit.")
                end
            end
        end
    end
end

Max = 100
-- Check player's health and include it in the healing logic
if GetUnitReaction(Player, Player) == 4 and DistanceToUnit(Player, Player) < YardsToHealUnits and Player.HealthPercent < Max and Player.IsDead() ~= true then
    Max = Player.HealthPercent
    HealTarget = Player -- Storing the player's health
end

foreach Unit in Players do -- Loop through every object near the player
    if GetUnitReaction(Unit, Player) == 4 and DistanceToUnit(Player, Unit) < YardsToHealUnits then -- We are checking to see that each unit is friendly to the player
        if Unit.HealthPercent < Max and Unit.IsDead() ~= true then -- Checking to see the current unit's health is less than our last
            Max = Unit.HealthPercent
            HealTarget = Unit -- Storing the lowest unit health
        end
    end
end

if IsUnitValid(HealTarget) then -- Checking to see if our Unit is valid before anything else
    TargetUnit(HealTarget) -- Targeting the unit
    -- More Healing Logic would go here
end

if IsUnitValid(FoundMaster) then -- Checking to see if our Unit is valid before anything else
    if (GetBOTState() == "Pathing" or GetBOTState() == "Idle" or GetBOTState() == "UpdateQuestState") and DistanceToUnit(Player, FoundMaster) > YardsBehindMaster then -- Checking our bot state then checking if we are more than YardsBehindMaster yards from our master; if we are, we generate a path to him
        FindMeshPathToUnit(FoundMaster) -- Generating a path to our master
        SetBOTState("PathingToMaster") -- Setting our state so we don't spam
    end

    if GetBOTState() == "PathingToMaster" and DistanceOfMeshToMaster() < YardsBehindMaster and DistanceToUnit(Player, FoundMaster) < YardsBehindMaster then
        SetBOTState("TooCloseToMaster")
        StopMoving()
    else
        if GetBOTState() == "TooCloseToMaster" and DistanceOfMeshToMaster() > YardsBehindMaster then
            FindMeshPathToUnit(FoundMaster) -- Generating a path to our master
            SetBOTState("PathingToMaster") -- Setting our state so we don't spam
        end
    end

    if GetBOTState() == "PathingToMaster" then -- Calling our path tick
        Path()
    end

    if GetBOTState() == "Done" then -- We have reached the end of our path
        SetBOTState("Pathing")
    end

    if FoundMaster.CastID == 8690 and Player.IsCasting == false then -- Check if our master is casting Hearthstone; if he is, use the item as well
        Log("Our master is using its hearthstone; following!!!")
        UseItem("Hearthstone")
    end
else
    Log("Looking for master")
    FindMaster() -- Call FindMaster to rescan for our master
end

-- Perform looting if not in combat
if Player.IsInCombat ~= true then
    LootNearbyMobs()
end


-- Basic example of a healing BOT written entirely in our API
