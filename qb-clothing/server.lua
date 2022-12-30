local QBCore = exports['qb-core']:GetCoreObject()

local function checkExistenceClothes(citizenid, cb)
    exports.oxmysql:execute("SELECT citizenid FROM character_current WHERE citizenid = '" .. citizenid .. "'", function(result)
        local exists = result and result[1] and true or false
        cb(exists)
    end)
end

local function checkExistenceFace(citizenid, cb)
    exports.oxmysql:execute("SELECT citizenid FROM character_face WHERE citizenid = '" .. citizenid .. "' LIMIT 1;", {["citizenid"] = citizenid}, function(result)
        local exists = result and result[1] and true or false
        cb(exists)
    end)
end


RegisterServerEvent("raid_clothes:insert_character_current")
AddEventHandler("raid_clothes:insert_character_current",function(data)
    if not data then return end
    local src = source
    local user = QBCore.Functions.GetPlayer(src)
    local characterId = user.PlayerData.citizenid
    if not characterId then return end
    checkExistenceClothes(characterId, function(exists)

        local values = {
            ["citizenid"] = characterId,
            ["model"] = json.encode(data.model),
            ["drawables"] = json.encode(data.drawables),
            ["props"] = json.encode(data.props),
            ["drawtextures"] = json.encode(data.drawtextures),
            ["proptextures"] = json.encode(data.proptextures),
        }

        if not exists then
            local cols = "citizenid, model, drawables, props, drawtextures, proptextures"
            local vals = "'" .. characterId .. "', '" .. values["model"] ..  "', '" .. values["drawables"] ..  "', '" .. values["props"] ..  "', '" .. values["drawtextures"] ..  "', '" .. values["proptextures"] ..  "'"

            exports.oxmysql:execute("INSERT INTO character_current ("..cols..") VALUES ("..vals..")", values, function()
            end)
            return
        end

        local set = "model = '" .. json.encode(data.model) .. "',drawables = '" .. json.encode(data.drawables) .. "',props = '" .. json.encode(data.props) .. "',drawtextures = '" .. json.encode(data.drawtextures) .. "',proptextures = '" .. json.encode(data.proptextures) .. "'"
        exports.oxmysql:execute("UPDATE character_current SET "..set.." WHERE citizenid = '" .. characterId .. "'", values)
    end)
end)

RegisterServerEvent("raid_clothes:insert_character_face")
AddEventHandler("raid_clothes:insert_character_face",function(data)
    if not data then return end
    local src = source

    local user = QBCore.Functions.GetPlayer(src)
    local characterId = user.PlayerData.citizenid

    if not characterId then return end

    checkExistenceFace(characterId, function(exists)
        if data.headBlend == "null" or data.headBlend == nil then
            data.headBlend = '[]'
        else
            data.headBlend = json.encode(data.headBlend)
        end
        local values = {
            ["citizenid"] = characterId,
            ["hairColor"] = json.encode(data.hairColor),
            ["headBlend"] = data.headBlend,
            ["headOverlay"] = json.encode(data.headOverlay),
            ["headStructure"] = json.encode(data.headStructure),
        }

        if not exists then
            local cols = "citizenid, hairColor, headBlend, headOverlay, headStructure"
            local vals = "'" .. characterId .. "', '" .. json.encode(data.hairColor) .. "', '" .. data.headBlend .. "', '" .. json.encode(data.headOverlay) .. "', '" .. json.encode(data.headStructure) .. "'"

            exports.oxmysql:execute("INSERT INTO character_face ("..cols..") VALUES ("..vals..")", values, function()
            end)
            return
        end

        local set = "hairColor = '" .. json.encode(data.hairColor) .. "',headBlend = '" .. data.headBlend .. "', headOverlay = '" .. json.encode(data.headOverlay) .. "',headStructure = '" .. json.encode(data.headStructure) .. "'"
        exports.oxmysql:execute("UPDATE character_face SET "..set.." WHERE citizenid = '" .. characterId .. "'", values )
    end)
end)

RegisterServerEvent("raid_clothes:get_character_face")
AddEventHandler("raid_clothes:get_character_face",function(pSrc)
    local src = (not pSrc and source or pSrc)
    local user = QBCore.Functions.GetPlayer(src)
    local characterId = user.PlayerData.citizenid

    if not characterId then return end

    exports.oxmysql:execute("SELECT cc.model, cf.hairColor, cf.headBlend, cf.headOverlay, cf.headStructure FROM character_face cf INNER JOIN character_current cc on cc.citizenid = cf.citizenid WHERE cf.citizenid = '" .. characterId .. "'", {}, function(result)
        if (result ~= nil and result[1] ~= nil) then
            local temp_data = {
                hairColor = json.decode(result[1].hairColor),
                headBlend = json.decode(result[1].headBlend),
                headOverlay = json.decode(result[1].headOverlay),
                headStructure = json.decode(result[1].headStructure),
            }
            local model = tonumber(result[1].model)
            if model == 1885233650 or model == -1667301416 then
                TriggerClientEvent("raid_clothes:setpedfeatures", src, temp_data)
            end
        else
            TriggerClientEvent("raid_clothes:setpedfeatures", src, false)
        end
	end)
end)

RegisterServerEvent("raid_clothes:get_character_current")
AddEventHandler("raid_clothes:get_character_current",function(pSrc)
    local src = (not pSrc and source or pSrc)
    local user = QBCore.Functions.GetPlayer(src)
    local characterId = user.PlayerData.citizenid

    if not characterId then return end

    exports.oxmysql:execute("SELECT * FROM character_current WHERE citizenid = '" .. characterId .. "'", {}, function(result)
        local temp_data = {
            model = result[1].model,
            drawables = json.decode(result[1].drawables),
            props = json.decode(result[1].props),
            drawtextures = json.decode(result[1].drawtextures),
            proptextures = json.decode(result[1].proptextures),
        }
        TriggerClientEvent("raid_clothes:setclothes", src, temp_data,0)
	end)
end)

RegisterServerEvent("raid_clothes:retrieve_tats")
AddEventHandler("raid_clothes:retrieve_tats", function(pSrc)
    local src = (not pSrc and source or pSrc)
	local user = QBCore.Functions.GetPlayer(src)
    local char = user.PlayerData.citizenid
	exports.oxmysql:execute("SELECT * FROM playerstattoos WHERE citizenid = '" .. char .. "'", {}, function(result)
        if(#result == 1) then
			TriggerClientEvent("raid_clothes:settattoos", src, json.decode(result[1].tattoos))
		else
			local tattooValue = "{}"
			exports.oxmysql:execute("INSERT INTO playerstattoos (citizenid, tattoos) VALUES ('" .. char .. "', '" .. tattooValue .. "')", {})
			TriggerClientEvent("raid_clothes:settattoos", src, {})
		end
	end)
end)

RegisterServerEvent("raid_clothes:set_tats")
AddEventHandler("raid_clothes:set_tats", function(tattoosList)
	local src = source
	local user = QBCore.Functions.GetPlayer(src)
    local char = user.PlayerData.citizenid
	exports.oxmysql:execute("UPDATE playerstattoos SET tattoos = '" .. json.encode(tattoosList) .. "' WHERE citizenid = '" .. char .. "'", {})
end)


RegisterServerEvent("clothing:checkIfNew")
AddEventHandler("clothing:checkIfNew", function()
    local src = source
    local user = QBCore.Functions.GetPlayer(src)
    local citizenid = user.PlayerData.citizenid

    exports.oxmysql:execute("SELECT model FROM character_current WHERE citizenid = '" .. citizenid .. "'", {}, function(result)
        if not result[1] or not result[1].model then
            local temp_data = {
                model = '1885233650',
                drawables = json.decode('{"1":["masks",0],"2":["hair",0],"3":["torsos",0],"4":["legs",0],"5":["bags",0],"6":["shoes",1],"7":["neck",0],"8":["undershirts",0],"9":["vest",0],"10":["decals",0],"11":["jackets",0],"0":["face",0]}'),
                props = json.decode('{"1":["glasses",-1],"2":["earrings",-1],"3":["mouth",-1],"4":["lhand",-1],"5":["rhand",-1],"6":["watches",-1],"7":["braclets",-1],"0":["hats",-1]}'),
                drawtextures = json.decode('[["face",0],["masks",0],["hair",0],["torsos",0],["legs",0],["bags",0],["shoes",2],["neck",0],["undershirts",1],["vest",0],["decals",0],["jackets",11]]'),
                proptextures = json.decode('[["hats",-1],["glasses",-1],["earrings",-1],["mouth",-1],["lhand",-1],["rhand",-1],["watches",-1],["braclets",-1]]'),
            }

            TriggerClientEvent('raid_clothes:setclothes',src,{},temp_data)
            TriggerClientEvent("raid_clothes:hasEnough", src, 'clothesmenu')
        else
            TriggerEvent("raid_clothes:get_character_current", src)
        end
    end)
end)

RegisterServerEvent("clothing:checkMoney")
AddEventHandler("clothing:checkMoney", function(menu, askingPrice)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not askingPrice
    then
        askingPrice = 0
    end

    if (Player['PlayerData']['money']['cash'] >= askingPrice) then
        Player.Functions.RemoveMoney('cash', askingPrice)
        TriggerClientEvent('QBCore:Notify', src, "you pay $"..askingPrice.. " for clothing shop")
        TriggerClientEvent("raid_clothes:hasEnough", src, menu)
    else
        TriggerClientEvent('QBCore:Notify', src, "you need $"..askingPrice.. "", 'error')
    end
end)