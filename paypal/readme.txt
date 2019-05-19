第一步：
1、制作一个index.php 页面，包含支付信息
2、登录Paypal创建一个支付button
   2.1 选择 tools -> paypal buttons -> Create new button 
   2.2、Button 设置
	Choose a button type "Buy Now" 
	输入Item name 和 Item id
	输入Price
	去掉 "Save button at PayPal" 的勾选
	Can you custome add special intructions in a message to you ?
	选择no
	Do you need your customer's shipping address
	选择no
	Add advanced variables
	输入URL的listener.php页面地址notify_url=http://yourweb/PayPalGateway/listener.php
	最后点击Create Button
	会获取到一段Button的代码
3、把获取到的代码放到你的支付页面，预览后将出现一个button

第二步：
1、进入 https://developer.paypal.com
2、点击 IPN Simulator
3、配置
	IPN  handler url 输入
	http://yourweb/PayPalGateway/listener.php
	Transation type 
	选择web Accept
	Payment_status
	选择Completed
	business
	输入你组织的名称
	receiver_email 输入能接收邮件的Email
	item_name
	输入你支付项目的名称
	item_number
	输入你支付项目的名称
	shipping 与tax 下面的内容删除
	mc_gross下面输入你的销售金额
    删除mc_gross_1
    在Advanced and Custom Information下
    删除 custom 和 invoice 下面的内容
    
    最后点击 Send IPN 按钮
    会收到提示  IPN was sent and the handshake was verified
第三步： 创建listener.php文件

第四步：验证
        进入第三部，点击 Send IPN 按钮，
        打开http://yourweb/PayPalGateway/test.txt，当出现VERIFIED时候，可以进行下一步
第五步：
