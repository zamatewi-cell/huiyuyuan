# 汇玉源 v3.0 功能实施计划

## 📋 概述

本文档记录汇玉源 App 三大核心功能的实施计划：
1. **真实后端API** - 替换模拟数据为后端接口
2. **图片上传** - OSS存储服务 + Gemini 3 Pro Image
3. **推送通知** - 推送服务配置

---

## 1. 真实后端API

### 1.1 技术栈
- **后端**: FastAPI + SQLAlchemy + MySQL
- **前端**: Dio HTTP Client
- **认证**: JWT Token

### 1.2 API 接口清单

| 模块 | 接口 | 方法 | 说明 |
|------|------|------|------|
| 认证 | `/api/auth/login` | POST | 用户登录 |
| 认证 | `/api/auth/logout` | POST | 用户登出 |
| 认证 | `/api/auth/refresh` | POST | 刷新Token |
| 商品 | `/api/products` | GET | 商品列表 |
| 商品 | `/api/products/{id}` | GET | 商品详情 |
| 商品 | `/api/products` | POST | 添加商品 |
| 商品 | `/api/products/{id}` | PUT | 更新商品 |
| 商品 | `/api/products/{id}` | DELETE | 删除商品 |
| 店铺 | `/api/shops` | GET | 店铺列表 |
| 店铺 | `/api/shops/{id}` | GET | 店铺详情 |
| 订单 | `/api/orders` | GET | 订单列表 |
| 订单 | `/api/orders` | POST | 创建订单 |
| 订单 | `/api/orders/{id}` | GET | 订单详情 |
| 用户 | `/api/users/profile` | GET | 用户信息 |
| 用户 | `/api/users/addresses` | GET/POST | 收货地址 |
| 评价 | `/api/reviews` | GET/POST | 商品评价 |
| 收藏 | `/api/favorites` | GET/POST/DELETE | 收藏管理 |
| 购物车 | `/api/cart` | GET/POST/PUT/DELETE | 购物车管理 |

### 1.3 实施文件
- `backend/main.py` - 后端主程序（扩展）
- `backend/models.py` - 数据库模型
- `backend/database.py` - 数据库配置
- `lib/services/api_service.dart` - 统一API服务
- `lib/config/api_config.dart` - API配置

---

## 2. 图片上传服务

### 2.1 技术栈
- **存储**: 阿里云 OSS
- **图片AI**: Google Gemini 3 Pro Image
- **Flutter库**: image_picker, dio

### 2.2 功能模块

| 功能 | 说明 |
|------|------|
| 图片选择 | 相册选择/相机拍摄 |
| 图片压缩 | 上传前压缩优化 |
| OSS上传 | 直传阿里云OSS |
| 进度显示 | 上传进度条 |
| AI识别 | Gemini 3 Pro 图片分析 |

### 2.3 实施文件
- `lib/services/oss_service.dart` - OSS上传服务
- `lib/services/gemini_image_service.dart` - Gemini图片分析
- `lib/widgets/image/image_picker_widget.dart` - 图片选择组件
- `backend/routes/upload.py` - 后端上传接口

---

## 3. 推送通知服务

### 3.1 技术栈
- **远程推送**: Firebase Cloud Messaging (FCM)
- **本地通知**: flutter_local_notifications
- **后台任务**: workmanager

### 3.2 通知类型

| 类型 | 触发场景 |
|------|----------|
| 订单通知 | 订单状态变更 |
| 促销通知 | 新品上架、限时优惠 |
| 系统通知 | 账户安全、系统维护 |
| 直播提醒 | 关注店铺开播 |
| 物流通知 | 发货、签收提醒 |

### 3.3 实施文件
- `lib/services/push_service.dart` - 推送服务
- `lib/services/notification_service.dart` - 本地通知
- `android/app/src/main/AndroidManifest.xml` - Android配置
- `ios/Runner/Info.plist` - iOS配置

---

## 📅 实施进度

| 阶段 | 任务 | 状态 |
|------|------|------|
| 1 | 后端API扩展 | ✅ 已完成 |
| 2 | API服务层重构 | ✅ 已完成 |
| 3 | OSS图片上传 | ✅ 已完成 |
| 4 | Gemini图片分析 | ✅ 已完成 |
| 5 | 推送服务配置 | ✅ 已完成 |
| 6 | 集成测试 | ⏳ 待开始 |

---

## 🔐 安全配置

敏感配置应存放在环境变量或安全配置文件中（不提交到Git）：

```dart
// lib/config/secrets.dart (gitignore)
class Secrets {
  static const String ossAccessKeyId = 'YOUR_OSS_ACCESS_KEY';
  static const String ossAccessKeySecret = 'YOUR_OSS_SECRET';
  static const String ossBucket = 'huiyuyuan-images';
  static const String ossEndpoint = 'oss-cn-hangzhou.aliyuncs.com';
  
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
  static const String fcmServerKey = 'YOUR_FCM_SERVER_KEY';
}
```

---

*文档创建时间: 2026-02-06*
*版本: v3.0.0*
