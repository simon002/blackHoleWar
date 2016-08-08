----------------------------------------
-- light框架的商城模块
-- 作者：klli
-- 创建日期：2016-01-12
----------------------------------------

local Shop = {}

Shop._infoTable = nil
Shop._propertyTable = nil
Shop._providerTable = nil
Shop._goodsItemTable = nil
Shop._goodsByProviderTable = nil
Shop._goodsByProviderAndPropertyIdTable = nil

Shop._externalShopInfoHandler = nil
Shop._externalBuyProductHandler = nil


-- todo 后续与孙豹、姚龙商讨并补充完整
Shop.PROPERTY_INVALID = 0
Shop.PROPERTY_GOLD_COINS = 1
Shop.PROPERTY_DIAMONDS = 3

Shop.CurrencyCNY = 'CNY'
Shop.CurrencyUSD = 'USD'

Shop.PropertyIdMap = {
    mmbilling = 6,
    ctestore = 7,
    unipay = 16,
    alipay = 100,
    upmp = 24,
    wechatpay = 107,
    alipayweb = 108,
}

function Shop.setShopUrl( url )
    local shopModel = ShopModel:getInstance()
    ShopModel:setShopConfigCenterUrl(url)
end

function Shop.requestShopInfo(packageId, externalHandler)
    local shopModel = ShopModel:getInstance()
    Shop._externalShopInfoHandler = externalHandler
    shopModel:requestShopInfo(packageId, Shop._handleShopInfo)
end

function Shop._handleShopInfo(strJson)
    Shop._resetShopInfo()

    -- 解析json
    local t = json.decode(strJson)
    if t then
        Shop._infoTable = t.data
        Shop._initPropertyTable()
        Shop._initProviderTable()
        Shop._initGoodsItemTable()
        Shop._initGoodsByProviderTable()
    end

    -- 检查数据完整性
    local isValidData = Shop._checkDataIntegrity()
    if isValidIdData then
        Shop._initGoodsByProviderAndPropertyTable()
    end
    -- 回调外部handler
    if Shop._externalShopInfoHandler then
        Shop._externalShopInfoHandler(isValidData)
        Shop._externalShopInfoHandler = nil
    end
end

function Shop.buyProduct(userId, provider, goodsItem, externalHandler)
    Shop._externalBuyProductHandler = externalHandler

    local info = BuyRequestInfo:new()
    info.provider = "" .. Shop.getNumericalProviderId(provider.providerId) 
    info.goodsId = goodsItem.goodsId
    if goodsItem.itemId then
        info.itemId = goodsItem.itemId
    end
    info.goodsName = goodsItem.goodsName
    info.price = "" .. goodsItem.price
    --info.currencyType = "CNY"
    info.productCount = "1"
    info.userId = userId
    --info.extendInfo = "nothing"

    local shop = ShopModel:getInstance()
    shop:buyProduct(info, Shop._handleBuyProduct)

    info:delete()
end

function Shop._handleBuyProduct(errCode, errMsg)
    -- 回调外部handler
    -- 某些sdk没有回调，或者在某些情况下无回调
    -- sdk回调显示成功，只代表sdk这一层是成功了，真正到账与否要根据后续服务端的通知
    -- sdk回调显示取消或者失败，说明支付确实是取消或者失败了
    if Shop._externalBuyProductHandler then
        Shop._externalBuyProductHandler(errCode, errMsg)
        Shop._externalBuyProductHandler = nil
    end
end

function Shop.getSortedProviders()
    local vecProviders = {}
    for k in pairs(Shop._goodsByProviderTable) do
        table.insert(vecProviders, Shop._providerTable[k])
    end
    table.sort(vecProviders, Shop._compare)

    return vecProviders
end

function Shop.getSortedGoodsListByProvider(providerId)
    local goodsIdList = Shop._goodsByProviderTable[providerId]
    local goodsList = {}
    for k, v in pairs(goodsIdList) do
        table.insert(goodsList, Shop._goodsItemTable[v])
    end

    table.sort(goodsList, Shop._compare)

    return goodsList 
end

function Shop.getPropertyById(propertyId)
    return Shop._propertyTable[propertyId]
end

function Shop._compare(a, b)
    return a.sort < b.sort
end

function Shop._resetShopInfo()
    Shop._infoTable = nil
    Shop._propertyTable = nil
    Shop._providerTable = nil
    Shop._goodsItemTable = nil
    Shop._goodsByProviderTable = nil
    Shop._goodsByProviderAndPropertyIdTable = nil
end

function Shop._initPropertyTable()
    Shop._propertyTable = nil
    if (not Shop._infoTable) or (not Shop._infoTable.propertyList) then return end

    -- 遍历Shop._infoTable.propertyList数组,构造方便查询的table
    Shop._propertyTable = {}
    local list = Shop._infoTable.propertyList
    for i = 1, #list do
        local item = list[i]
        if item.propertyId and item.propertyName and item.propertyType and item.sort then -- 滤掉信息不全的item
            Shop._propertyTable[item.propertyId] = item
        end
    end
end

function Shop._initProviderTable()
    Shop._providerTable = nil
    if (not Shop._infoTable) or (not Shop._infoTable.providerList) then return end

    -- 遍历Shop._infoTable.providerList数组,构造方便查询的table
    Shop._providerTable = {}
    local list = Shop._infoTable.providerList
    for i = 1, #list do
        local item = list[i]
        --if item.currencyType and item.providerIcon and item.providerId and
        if item.currencyType and item.providerId and
           item.providerName and item.sort then -- 滤掉信息不全的item
            Shop._providerTable[item.providerId] = item
        end
    end
end

function Shop._initGoodsItemTable()
    Shop._goodsItemTable = nil
    if (not Shop._infoTable) or (not Shop._infoTable.goodsItemList) then return end

    -- 遍历Shop._infoTable.providerList数组,构造方便查询的table
    Shop._goodsItemTable = {}
    local list = Shop._infoTable.goodsItemList
    for i = 1, #list do
        local item = list[i]
        --未判空item.activityId item.extend item.goodsBody item.goodsIcon item.itemId
        if item.giftQuantity and item.goodsId and item.goodsName and 
           item.price and item.propertyId and item.quantity and item.sort then
            -- item.extend为json字符串，需解析为table
            local json = require("framework.json")
            local extendTable = json.decode(item.extend)
            
            -- 将extendTable的字符key转为数字key，便于查询（其他table中的PropertyId都是数字）
            if extendTable then
                if extendTable["0"] then
                    extendTable["0"] = nil
                end

                local map = {}
                for k, v in pairs(extendTable) do
                    -- 转换字符串s为number时，可能抛出error，故用pcall保护
                    ret, val = pcall(function (s) return s + 0 end, k)
                    if ret then
                        map[val] = v
                    end
                end

                extendTable = map
            end
            
            if(extendTable and Shop.tableLength(extendTable) == 0) then
                extendTable = nil --滤掉内容为空的table
            end

            item.extend = extendTable
            Shop._goodsItemTable[item.goodsId] = item
        end
    end
end

function Shop._initGoodsByProviderTable()
    Shop._goodsByProviderTable = nil
    if (not Shop._infoTable) or (not Shop._infoTable.providerGoodsMapping) then return end

    -- Shop._infoTable.providerGoodsMapping是普通table（非数组），无需重新构造查询的table
    -- 但需要剔除value为空表的key
    local map = Shop._infoTable.providerGoodsMapping
    for k in pairs(map) do
        if Shop.tableLength(map[k]) == 0 then
            map[k] = nil
        end
    end

    -- 剔除某些key后，map可能为空表 后续的完整性检测会检出这样的数据错误
    Shop._goodsByProviderTable = map
end

function Shop._initGoodsByProviderAndPropertyTable()
    local map = Shop._goodsByProviderAndPropertyIdTable
    map = {}

    for k in pairs(Shop._goodsByProviderTable) do
        if map[k] == nil then
            map[k] = {}
        end

        local goodsList = Shop._goodsByProviderTable[k]
        for kk, vv in pairs(goodsList) do
            local goodsItem = Shop._goodsItemTable[vv]
            local propertyId = goodsItem.propertyId
            if map[k][propertyId] == nil then
                map[k][propertyId] = {}
            end

            table.insert(map[k][propertyId], goodsItem)
        end
    end

    -- 排序
    for k, v in pairs(map) do
        for kk, vv in pairs(v) do
            table.sort(vv, Shop._compare)
        end
    end
end

function Shop._checkDataIntegrity()
    if (not Shop._infoTable) or (Shop.tableLength(Shop._infoTable) == 0) then return false end
    if (not Shop._goodsByProviderTable) or (Shop.tableLength(Shop._goodsByProviderTable) == 0) then return false end
    if (not Shop._providerTable) or (Shop.tableLength(Shop._providerTable) == 0) then return false end
    if (not Shop._goodsItemTable) or (Shop.tableLength(Shop._goodsItemTable) == 0) then return false end
    if (not Shop._propertyTable) or (Shop.tableLength(Shop._propertyTable) == 0) then return false end

    local integrity = true

    for k in pairs(Shop._goodsByProviderTable) do
        if not Shop._providerTable[k] then -- 检测provider是否存在
            integrity = false
            break
        else --检查goodsList的每个goodsItem是否存在
            if not Shop._checkGoodsListInterity(Shop._goodsByProviderTable[k]) then
                integrity = false
                break
            end
        end
    end

    if integrity then
        integrity = Shop._checkGoodsPropertyIntegrity()
    end

    return integrity        
end

function Shop._checkGoodsListInterity(goodsList)
    if (not goodsList) or (Shop.tableLength(goodsList) == 0) then return false end

    local integrity = true
    for k in pairs(goodsList) do
        if not Shop._goodsItemTable[goodsList[k]] then
            integrity = false
            break
        end
    end

    return integrity
end

function Shop._checkGoodsPropertyIntegrity()
    local integrity = true
    local goods = Shop._goodsItemTable
    local props = Shop._propertyTable
    for k in pairs(goods) do
        local item = goods[k]
        -- 检查goodsItem的propertyId是否合法，是否在PropertyTable中存在
        if (item.propertyId == 0) or (props[item.propertyId] == nil) then
            print("bad id " .. item.propertyId)
            integrity = false
            break
        end

        local subIntegrity = true
        -- 检查goodsItem的extendTable的每个propertyId是否合法，是否在PropertyTable中存在
        if item.extend then
            for key in pairs(item.extend) do
                local v = item.extend[key]
                if (v.propertyId == 0) or (props[v.propertyId] == nil) then
                    print("bad extendTable id " .. v.propertyId)
                    subIntegrity = false
                    break
                end
            end 
        end

        if not subIntegrity then
            integrity = false
            break
        end
    end

    return integrity
end

function Shop.getNumericalProviderId(providerStrId)
    return Shop.PropertyIdMap[providerStrId]
end

function Shop.tableLength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

return Shop
