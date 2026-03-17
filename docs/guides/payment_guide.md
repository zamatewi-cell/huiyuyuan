# 移动端支付集成指南 (WeChat / Alipay)

本指南详细说明了如何将微信支付和支付宝集成到汇玉源 Flutter 应用中。由于需要企业资质及其相关密钥，本项目目前使用模拟支付流程。

---

## 1. 微信支付集成 (WeChat Pay)

### 1.1 前置准备
1. 注册 **微信开放平台** 账号 (open.weixin.qq.com)。
2. 创建移动应用，获取 `AppID`。
3. 申请微信支付功能，获取 `MCHID` (商户号) 和 `API Key`。

### 1.2 Flutter 依赖
使用 `fluwx` 插件：

```yaml
dependencies:
  fluwx: ^3.13.1
```

### 1.3 Android 配置
在 `android/app/build.gradle` 中配置签名：
```gradle
signingConfigs {
    release {
        storeFile file("my-release-key.jks")
        storePassword "password"
        keyAlias "my-key-alias"
        keyPassword "password"
    }
}
```
*注意：微信支付校验应用签名，Debug 包的签名与 Release 不同，需在微信后台分别配置或只使用 Release 包测试。*

### 1.4 iOS 配置
在 `Info.plist` 中添加 URL Scheme：
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>weixin</string>
    <string>weixinULAPI</string>
</array>
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>weixin</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>wx[你的AppID]</string>
        </array>
    </dict>
</array>
```

### 1.5 代码实现

**初始化 SDK:**
```dart
import 'package:fluwx/fluwx.dart';

void initWeChat() async {
  await registerWxApi(
    appId: "wx8888888888888888",
    doOnAndroid: true,
    doOnIOS: true,
    universalLink: "https://your.domain.com/ulink/"
  );
}
```

**发起支付:**
后端需调用微信统一下单接口，返回 `prepayId` 等参数给前端。

```dart
Future<void> payWithWechat(Map<String, dynamic> data) async {
  bool isInstalled = await isWeChatInstalled;
  if (!isInstalled) {
    print("未安装微信");
    return;
  }

  requestPayment(
    timeStamp: data['timestamp'],
    nonceStr: data['noncestr'],
    packageValue: data['package'],
    sign: data['sign'],
    prepayId: data['prepayid'],
    appId: data['appid'],
    partnerId: data['partnerid'],
  );
}

// 监听结果
fluwx.weChatResponseEventHandler.listen((res) {
  if (res is WeChatPaymentResponse) {
    if (res.isSuccessful) {
      print("支付成功");
    }
  }
});
```

---

## 2. 支付宝集成 (Alipay)

### 2.1 前置准备
1. 注册 **蚂蚁金服开放平台** 账号。
2. 创建应用，配置密钥（应用公钥/私钥）。
3. 获取 `APPID`。

### 2.2 Flutter 依赖
使用 `tobias` 插件：

```yaml
dependencies:
  tobias: ^2.4.0
```

### 2.3 代码实现

**发起支付:**
后端需生成签名后的订单字符串 (`orderString`)。

```dart
import 'package:tobias/tobias.dart';

Future<void> payWithAlipay(String orderInfo) async {
  // orderInfo 是后端返回的签名字符串
  final result = await aliPay(orderInfo);
  
  // result['resultStatus'] 为 '9000' 表示支付成功
  if (result['resultStatus'] == '9000') {
    print("支付成功");
  } else {
    print("支付失败: ${result['memo']}");
  }
}
```

---

## 3. 后端集成 (Python FastAPI 示例)

后端不应直接存储私钥，建议使用中间件或密钥管理服务。

### 3.1 支付宝签名示例

```python
from alipay import AliPay

alipay = AliPay(
    appid="SPACE_001",
    app_notify_url="http://your-server.com/notify",
    app_private_key_path="private_key.pem",
    alipay_public_key_path="alipay_public_key.pem"
)

@app.post("/api/pay/alipay")
async def create_alipay_order(amount: float, order_id: str):
    order_string = alipay.api_alipay_trade_app_pay(
        out_trade_no=order_id,
        total_amount=amount,
        subject=f"订单 {order_id}",
        return_url="http://your-server.com/return"
    )
    return {"order_string": order_string}
```

---

## 4. 汇玉源当前模拟实现

由于缺少真实商户号，项目在 `BackendService` 和 `CartScreen` 中模拟了支付过程。

1. **CartScreen**: 点击"结算" -> 调用后端 `/api/orders/checkout`。
2. **Backend**: 接收请求 -> 返回成功状态。
3. **CartScreen**: 显示支付成功提示。
