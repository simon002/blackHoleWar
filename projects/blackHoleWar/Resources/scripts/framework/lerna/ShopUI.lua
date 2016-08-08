----------------------------------------
-- light商城界面demo
--
-- 作者：klli
-- 创建日期：2016-01-13
----------------------------------------
local ShopUI = class("ShopUI", function() 
	local layer = display.newLayer()
	return layer
end)

local Shop = lerna.Shop

ShopUI.kTabDiamond = 1 
ShopUI.kTabCoin = 2
ShopUI.kTabOther = 3

function ShopUI:getTabFromPropertyId(propertyId)
	local tab = ShopUI.kTabOther
	if propertyId == Shop.PROPERTY_DIAMONDS then
		tab = ShopUI.kTabDiamond
	elseif propertyId == Shop.PROPERTY_GOLD_COINS then
		tab = ShopUI.kTabCoin
	end

	return tab
end

ShopUI.m_strPackageId = nil
ShopUI.m_pLabelNoData = nil
ShopUI.m_pQuitBtn = nil
ShopUI.m_vecTabBtn = nil
ShopUI.m_lvProviders = nil
ShopUI.m_lvGoods = nil
ShopUI.labelDebug_ = nil

ShopUI.m_vecProviders = nil
ShopUI.m_mapGoodsByTab = nil

ShopUI.m_nCurProvider = 1
ShopUI.m_nCurTab = 1

function ShopUI:ctor(packageId, ...)
	self.m_strPackageId = packageId
	--self.m_nCurProvider = 1
	--self.m_nCurTab = 1
	-- 商城标题
	ui.newTTFLabel({text = '商城', size = 36})
        :align(display.CENTER, display.cx, display.height - 50)
        :addTo(self)

    -- 数据拉取失败的提示    
    self.m_pLabelNoData = ui.newTTFLabel({text = '获取商城信息失败，请退出重试！', size = 26})
        :align(display.CENTER, display.cx, display.cy)
        :hide()
        :addTo(self)

    -- debug信息展示的label   
    self.labelDebug_ = ui.newTTFLabel({text = '', size = 24})
        :align(display.TOP_LEFT, 0, display.cy*2)
        :addTo(self)    

    -- 退出按钮
    self.m_pQuitBtn = ShopUI.newLabelButton("退出", {w = 80, h = 50}, 23)
    	:onButtonClicked(handler(self, self._onQuitBtnClicked))
        :align(display.CENTER, display.width - 100, display.height - 50)
        :addTo(self)
	
	-- 商品分页按钮
	local tab1 = ShopUI.newLabelButton("钻石", {w = 80, h = 50}, 23)
    	:onButtonClicked(handler(self, self._onTabBtn1Clicked))
        :align(display.CENTER, 395, 530)
        :addTo(self)
    tab1.m_tabIndex = ShopUI.kTabDiamond    

    local tab2 = ShopUI.newLabelButton("金币", {w = 80, h = 50}, 23)
    	:onButtonClicked(handler(self, self._onTabBtn2Clicked))
        :align(display.CENTER, 530, 530)
        :addTo(self)
    tab2.m_tabIndex = ShopUI.kTabCoin    

    local tab3 = ShopUI.newLabelButton("道具", {w = 80, h = 50}, 23)
    	:onButtonClicked(handler(self, self._onTabBtn3Clicked))
        :align(display.CENTER, 665, 530)
        :addTo(self)
    tab3.m_tabIndex = ShopUI.kTabOther     

    self.m_vecTabBtn = {}
    table.insert(self.m_vecTabBtn, tab1)
    table.insert(self.m_vecTabBtn, tab2)
    table.insert(self.m_vecTabBtn, tab3)

    -- 渠道列表
    self.m_lvProviders = cc.ui.UIListView.new {
            viewRect = cc.rect(0, 0, 260, 500),
            direction = cc.ui.UIScrollView.DIRECTION_VERTICAL}
        :onTouch(handler(self, self._onLvProviderTouchListener))
        :align(display.BOTTOM_LEFT, 11, 60)
        :addTo(self)

    -- 商品列表
    self.m_lvGoods = cc.ui.UIListView.new {
            viewRect = cc.rect(0, 0, 640, 450),
            direction = cc.ui.UIScrollView.DIRECTION_VERTICAL}
        :onTouch(handler(self, self._onLvGoodsTouchListener))
        :align(display.BOTTOM_LEFT, 295, 40)
        :addTo(self)

    -- 每次打开商店都要重新拉取商品信息
    lerna.Shop.requestShopInfo(self.m_strPackageId, handler(self, self._onShopInfoResp))
end

function ShopUI:_onShopInfoResp(success)
	if success then
		self:_updateProviderData()
		self:_updateGoodsData()
		self:_updateProviderDisplay()
		self:_updateGoodsDisplay()
	else
		self.m_pLabelNoData:show()
	end
end

function ShopUI:_updateProviderData()
	self.m_vecProviders = lerna.Shop.getSortedProviders()
end

function ShopUI:_updateGoodsData()
	local goodsList = Shop.getSortedGoodsListByProvider(self.m_vecProviders[self.m_nCurProvider].providerId)
	
	self.m_mapGoodsByTab = {
		[ShopUI.kTabDiamond] = {},
		[ShopUI.kTabCoin] = {},
		[ShopUI.kTabOther] = {}
	}	

	for k, v in pairs(goodsList) do
		local tab = self:getTabFromPropertyId(v.propertyId)
		table.insert(self.m_mapGoodsByTab[tab], v)
	end

	for k, v in pairs(self.m_mapGoodsByTab) do
		table.sort(v, Shop._compare)
	end
end

function ShopUI:_updateProviderDisplay()
	self.m_lvProviders:removeAllItems()

	local lvWidth = self.m_lvProviders:getContentSize().width
	local cellHeight = 85
    -- add items
    for i = 1, #self.m_vecProviders do
    	local provider = self.m_vecProviders[i]
        local item = self.m_lvProviders:newItem()
        local labelName = cc.ui.UILabel.new({
                text = provider.providerName,
                size = 24,
                align = cc.ui.TEXT_ALIGN_CENTER
            })
            :align(display.CENTER, lvWidth * 0.5, cellHeight * 0.5)

        if self.m_nCurProvider == i then
        	labelName:scale(1.2)
        	labelName:setColor(ccc3(0, 255, 0))
        end

        item.m_labelProviderName = labelName
        item:addContent(labelName)
        item:setItemSize(lvWidth, cellHeight)

        self.m_lvProviders:addItem(item)
    end
    self.m_lvProviders:reload()
end

function ShopUI:_updateSelectedProviderDisplay()
	local items = self.m_lvProviders.items_
	for i = 1, #items do
		local scale = 1
		local color = ccc3(255, 255, 255)
		if i == self.m_nCurProvider then
			scale = 1.2
			color = ccc3(0, 255, 0)
		end
		items[i].m_labelProviderName:scale(scale)
		items[i].m_labelProviderName:setColor(color)
	end
end

function ShopUI:_updateGoodsDisplay()
	for i = 1, #self.m_vecTabBtn do
		local scale = 1
		local color = ccc3(255, 255, 255)
		if i == self.m_nCurTab then
			scale = 1.2
			color = ccc3(0, 255, 0)	
		end
		self.m_vecTabBtn[i]:scale(scale)
		self.m_vecTabBtn[i]:setColor(color)
	end

	self.m_lvGoods:removeAllItems()

	local lvWidth = self.m_lvGoods:getContentSize().width
	local cellHeight = 90
    -- add items
    local goodsList = self.m_mapGoodsByTab[self.m_nCurTab]
    
    for i = 1, #goodsList do
    	local goodsItem = goodsList[i]
        local item = self.m_lvGoods:newItem()
        local content = display.newNode()
        content:setContentSize(cc.SizeMake(lvWidth, 0)) 
        local property = Shop.getPropertyById(goodsItem.propertyId)
        local provider = self.m_vecProviders[self.m_nCurProvider]
        local dy = 35
        -- 商品名
     	cc.ui.UILabel.new({
                text = goodsItem.goodsName,
                size = 24,
                align = cc.ui.TEXT_ALIGN_CENTER
            })
            :align(display.LEFT_CENTER, 0, 0 + dy)
            :addTo(content)
 
        -- 商品propertyName
        cc.ui.UILabel.new({
                text = property.propertyName,
                size = 24,
                align = cc.ui.TEXT_ALIGN_CENTER
            })
            :align(display.LEFT_CENTER, 0, -30 + dy)
            :addTo(content)

        
        -- 商品property数量
        local num = goodsItem.quantity + goodsItem.giftQuantity
        cc.ui.UILabel.new({
                text = '+' .. num,
                size = 24,
                align = cc.ui.TEXT_ALIGN_CENTER
            })
            :align(display.CENTER, 250, -30 + dy)
            :addTo(content)

        -- 商品price
        local currencyPrefix = ''
        local num = goodsItem.price

        if provider.currencyType == Shop.CurrencyCNY then
        	currencyPrefix = '￥'
        	num = goodsItem.price / 100
        elseif provider.currencyType == Shop.CurrencyUSD then
        	currencyPrefix = '$'
        end

        cc.ui.UILabel.new({
                text = currencyPrefix .. num,
                size = 24,
                align = cc.ui.TEXT_ALIGN_CENTER
            })
            :align(display.CENTER, 500, -30 + dy)
            :addTo(content)
               
        item:addContent(content)
        item:setItemSize(lvWidth, cellHeight)

        self.m_lvGoods:addItem(item)
    end
    self.m_lvGoods:reload()
end

function ShopUI:_onQuitBtnClicked()
	self:removeFromParent()
end

function ShopUI:_onTabBtn1Clicked(event)
	self:_onTabBtnClicked(event, ShopUI.kTabDiamond)
end

function ShopUI:_onTabBtn2Clicked(event)
	self:_onTabBtnClicked(event, ShopUI.kTabCoin)
end

function ShopUI:_onTabBtn3Clicked(event)
	self:_onTabBtnClicked(event, ShopUI.kTabOther)
end

function ShopUI:_onTabBtnClicked(event, index)
	if index == self.m_nCurTab then return end
	print("tab click " .. index)
	self.m_nCurTab = index
	self:_updateGoodsDisplay()
end

function ShopUI:_onLvGoodsTouchListener(event)
	--Shop.buyProduct(...)
	if 'clicked' == event.name then
		
        print("Goods event.itemPos = ".. event.itemPos .. " "..self.m_nCurTab)
        local provider = self.m_vecProviders[self.m_nCurProvider]
        local goodsItem = self.m_mapGoodsByTab[self.m_nCurTab][event.itemPos]
        self.labelDebug_:setString("begin buy " .. goodsItem.goodsId)
        Shop.buyProduct(provider, goodsItem, handler(self, self._onBNSDKResp))
    end
end

function ShopUI:_onBNSDKResp( errCode, msg )
	print("onBNSDKResp called")
	print(errCode)
	print(msg)
	--loginCtrlTmp._scene.labelDebug_:setString("errCode = " .. errCode .. " errMsg = " .. msg)
	self.labelDebug_:setString("[BNSDK] errCode = " .. errCode)
	local str = "[BNSDK] errCode = " .. errCode
	if msg then str = str .. " msg = " .. msg end
end

function ShopUI:_onLvProviderTouchListener(event)
	if 'clicked' == event.name then
        print("Provider event.itemPos = ".. event.itemPos)
        print("curProvider = " .. self.m_vecProviders[event.itemPos].providerId)
        if event.itemPos == self.m_nCurProvider then return end
        self.m_nCurProvider = event.itemPos
        self:_updateGoodsData()
		self:_updateSelectedProviderDisplay()
		self:_updateGoodsDisplay()
    end
end

-- 生成一个标签按钮 
function ShopUI.newLabelButton( texts, btnSize, btnFontSize )
	local sp = CCSprite:create()
	sp:setTextureRect(cc.RectMake(0, 0, btnSize.w, btnSize.h))
	local btnBg = sp:getTexture()
	btnBg:retain()
	--btnBg:setOriginalSize(cc.SizeMake(btnSize.w, btnSize.h))
    local button = cc.ui.UIPushButton.new(btnBg)

    if type(texts) == 'string' then
        button:setButtonLabel('normal', ui.newTTFLabel({
                text = texts,
                size = btnFontSize
            }))
    elseif type(texts) == 'table' then
        if texts.normal then
            button:setButtonLabel('normal', ui.newTTFLabel({
                text = texts.normal,
                size = btnFontSize
            }))
        end
        if texts.pressed then
            button:setButtonLabel('pressed', ui.newTTFLabel({
                text = texts.pressed,
                size = btnFontSize
            }))
        end
        if texts.disabled then
            button:setButtonLabel('disabled', ui.newTTFLabel({
                text = texts.disabled,
                size = btnFontSize
            }))
        end
    end

    return button
end

return ShopUI