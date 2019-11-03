player_data = {}

AddEvent("OnPlayerJoin", function(player)
    SetPlayerSpawnLocation(player, 125773.000000, 80246.000000, 1645.000000, 90.0)
end)

AddEvent("OnPlayerSteamAuth", function(player)
    local steamId = tostring(GetPlayerSteamId(player))
    mariadb_query(db, "SELECT * FROM players WHERE steam_id='"..steamId.."';", function()
        if mariadb_get_row_count() > 0 then
            player_data[player] = {
                db = mariadb_get_value_name_int(1, "id"),
                steam = steamId,
                name = mariadb_get_value_name(1, "name"),
                cash = mariadb_get_value_name_int(1, "cash"),
                balance = mariadb_get_value_name_int(1, "balance"),
                xp = mariadb_get_value_name_int(1, "xp"),
                payday = mariadb_get_value_name_int(1, "payday"),
                salary = mariadb_get_value_name_int(1, "salary"),
                first_join = false
            }
            SetPlayerPropertyValue(player, "cash", player_data[player].cash, true)
            SetPlayerPropertyValue(player, "balance", player_data[player].balance, true)
            CallEvent("OnPlayerDataReady", player, player_data[player])
        else
            mariadb_query(db, "INSERT INTO players (steam_id,name) VALUES ('"..steamId.."','"..GetPlayerName(player).."');", function()
                player_data[player] = {
                    db = mariadb_get_insert_id(),
                    steam = steamId,
                    name = GetPlayerName(player),
                    cash = 500,
                    balance = 4500,
                    xp = 0,
                    payday = 0,
                    salary = 0,
                    first_join = true
                }
                SetPlayerPropertyValue(player, "cash", player_data[player].cash, true)
                SetPlayerPropertyValue(player, "balance", player_data[player].balance, true)
                CallEvent("OnPlayerDataReady", player, player_data[player])
            end)
        end
    end)
end)

local function updatePlayerList()
    local playerList = {}
    for k,v in pairs(player_data) do
        playerList[k] = {
            name = v.name
        }
    end
    local ids = GetAllPlayers()
    for i=1,#ids do
        SetPlayerPropertyValue(ids[i], "player_list", playerList, true)
    end
end

AddEvent("OnPlayerDataReady", function(player, data)
    updatePlayerList()
end)

AddEvent("OnPlayerQuit", function(player)
    if player_data[player] == nil then
        return
    end
    CallEvent("OnPlayerDataFinish", player)
    mariadb_query(db, "UPDATE players SET cash='"..player_data[player].cash.."',balance='"..player_data[player].balance.."',xp='"..player_data[player].xp.."',payday='"..player_data[player].payday.."',salary='"..player_data[player].salary.."' WHERE id='"..player_data[player].db.."';")
    player_data[player] = nil
    updatePlayerList()
end)

CreateTimer(function()
    for i,v in pairs(player_data) do
        player_data[i].payday = player_data[i].payday + 1
        if player_data[i].payday == 60 then
            player_data[i].payday = 0
            player_data[i].xp = player_data[i].xp + 1
            AddPlayerChat(i, "-----------------------------------------------------------------------------")
            AddPlayerChat(i, "                                  ".._("payday"))
            AddPlayerChat(i, "-----------------------------------------------------------------------------")
            AddPlayerChat(i, "  ".._("payday_old_balance")..": "..player_data[i].balance.." ".._("currency_symbol"))
            player_data[i].balance = player_data[i].balance + player_data[i].salary
            SetPlayerPropertyValue(i, "balance", player_data[i].balance, true)
            AddPlayerChat(i, "  ".._("payday_salary")..": +"..player_data[i].salary.." ".._("currency_symbol"))
            AddPlayerChat(i, "  ".._("payday_new_balance")..": "..player_data[i].balance.." ".._("currency_symbol"))
            AddPlayerChat(i, "-----------------------------------------------------------------------------")
            player_data[i].salary = 0
        end
    end
end, 60000)