# 前端技术债务修复计划

> 更新日期: 2026-03-17
> 状态: 待开始
> 负责人: Trae AI
> 优先级: 高

---

## 一、任务概述

Trae AI 负责汇玉源项目的前端技术债务修复工作。主要目标是提升前端代码质量、用户体验和系统稳定性。

---

## 二、当前技术债务分析

### 2.1 主要问题
1. **硬编码测试账号**: `app_config.dart` 包含硬编码测试账号
2. **Mock数据使用**: 多个页面使用Mock数据而非真实API
3. **错误处理不完善**: 错误处理机制不统一
4. **用户体验待优化**: 页面转场、加载状态、交互反馈需要改进

### 2.2 影响范围
- **功能完整性**: 部分功能未对接真实API
- **用户体验**: 错误处理不友好，加载状态不明确
- **代码质量**: 硬编码数据影响代码可维护性
- **安全性**: 测试账号可能被误用

---

## 三、修复任务清单

### 3.1 移除硬编码测试账号 (优先级: 高)

#### 当前状态
- **文件**: `lib/config/app_config.dart`
- **问题**: 包含硬编码测试账号和密码
- **影响**: 安全风险，代码可维护性差

#### 具体任务
1. **移除硬编码账号**:
   ```dart
   // lib/config/app_config.dart
   class AppConfig {
     // 移除硬编码账号
     // static const String adminPhone = '18937766669';
     // static const String adminPassword = 'admin123';
     
     // 保留配置项
     static const String apiBaseUrl = 'http://47.112.98.191';
     static const bool useMockApi = false; // 生产环境设为false
   }
   ```

2. **登录页面优化**:
   ```dart
   // lib/screens/login_screen.dart
   class LoginScreen extends StatefulWidget {
     @override
     _LoginScreenState createState() => _LoginScreenState();
   }

   class _LoginScreenState extends State<LoginScreen> {
     final _phoneController = TextEditingController();
     final _passwordController = TextEditingController();
     
     @override
     void initState() {
       super.initState();
       // 开发环境显示提示，不预填账号
       if (kDebugMode) {
         WidgetsBinding.instance.addPostFrameCallback((_) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('开发环境：请使用测试账号登录')),
           );
         });
       }
     }
   }
   ```

3. **API服务统一认证**:
   ```dart
   // lib/services/api_service.dart
   class ApiService {
     static String? _authToken;
     
     static void setAuthToken(String token) {
       _authToken = token;
     }
     
     static Map<String, String> get headers {
       final headers = {
         'Content-Type': 'application/json',
       };
       if (_authToken != null) {
         headers['Authorization'] = 'Bearer $_authToken';
       }
       return headers;
     }
   }
   ```

#### 验证标准
- [ ] 硬编码测试账号已移除
- [ ] 登录页面不再预填测试账号
- [ ] API服务统一使用Token认证
- [ ] 安全扫描通过

### 3.2 实现真实API调用替代Mock数据 (优先级: 高)

#### 当前状态
- **问题**: 多个页面使用Mock数据
- **影响**: 功能不完整，数据不一致

#### 具体任务
1. **通知页面**:
   ```dart
   // lib/screens/notification/notification_screen.dart
   // BEFORE: _generateSampleData()
   // AFTER: API调用
   class NotificationScreen extends ConsumerWidget {
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final notifications = ref.watch(notificationsProvider);
       
       return notifications.when(
         data: (items) => _buildNotificationList(items),
         loading: () => const SkeletonLoader(),
         error: (e, _) => _buildEmptyState('加载失败'),
       );
     }
   }
   ```

2. **店铺雷达页面**:
   ```dart
   // lib/screens/shop/shop_radar.dart
   // BEFORE: _loadMockData()
   // AFTER: API调用
   class ShopRadarScreen extends ConsumerWidget {
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final shops = ref.watch(shopsProvider);
       
       return shops.when(
         data: (items) => _buildShopList(items),
         loading: () => const SkeletonLoader(),
         error: (e, _) => _buildEmptyState('加载失败'),
       );
     }
   }
   ```

3. **浏览历史页面**:
   ```dart
   // lib/screens/profile/browse_history_screen.dart
   // BEFORE: 显示 "商品 {id}"
   // AFTER: 显示真实商品信息
   class BrowseHistoryScreen extends ConsumerWidget {
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final history = ref.watch(browseHistoryProvider);
       
       return history.when(
         data: (items) => _buildHistoryList(items),
         loading: () => const SkeletonLoader(),
         error: (e, _) => _buildEmptyState('加载失败'),
       );
     }
   }
   ```

#### 验证标准
- [ ] 所有页面使用真实API数据
- [ ] Mock数据已完全移除
- [ ] 数据一致性验证通过
- [ ] 功能完整性测试通过

### 3.3 错误处理机制完善 (优先级: 中)

#### 当前状态
- **问题**: 错误处理不统一
- **影响**: 用户体验差，调试困难

#### 具体任务
1. **统一错误处理**:
   ```dart
   // lib/services/api_service.dart
   class ApiException implements Exception {
     final int statusCode;
     final String message;
     final dynamic data;
     
     ApiException(this.statusCode, this.message, this.data);
     
     @override
     String toString() => 'ApiException($statusCode): $message';
   }

   class ApiService {
     static Future<T> _handleRequest<T>(Future<T> Function() request) async {
       try {
         return await request();
       } on DioException catch (e) {
         if (e.response != null) {
           throw ApiException(
             e.response!.statusCode ?? 500,
             e.response!.statusMessage ?? '请求失败',
             e.response!.data,
           );
         } else {
           throw ApiException(0, '网络连接失败', null);
         }
       } catch (e) {
         throw ApiException(500, '未知错误', e);
       }
     }
   }
   ```

2. **用户友好错误提示**:
   ```dart
   // lib/widgets/common/error_widget.dart
   class ErrorWidget extends StatelessWidget {
     final String message;
     final VoidCallback? onRetry;
     
     const ErrorWidget({
       Key? key,
       required this.message,
       this.onRetry,
     }) : super(key: key);
     
     @override
     Widget build(BuildContext context) {
       return Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(Icons.error_outline, size: 64, color: Colors.red),
             SizedBox(height: 16),
             Text(
               message,
               style: TextStyle(fontSize: 16),
               textAlign: TextAlign.center,
             ),
             if (onRetry != null) ...[
               SizedBox(height: 16),
               ElevatedButton(
                 onPressed: onRetry,
                 child: Text('重试'),
               ),
             ],
           ],
         ),
       );
     }
   }
   ```

3. **网络状态监控**:
   ```dart
   // lib/services/connectivity_service.dart
   class ConnectivityService {
     static final ConnectivityService _instance = ConnectivityService._internal();
     factory ConnectivityService() => _instance;
     ConnectivityService._internal();
     
     final Connectivity _connectivity = Connectivity();
     StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
     
     Stream<bool> get connectionStatus => _connectionStatusController.stream;
     
     Future<void> initialize() async {
       _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
       await _checkCurrentConnection();
     }
     
     Future<void> _checkCurrentConnection() async {
       final result = await _connectivity.checkConnectivity();
       _updateConnectionStatus(result);
     }
     
     void _updateConnectionStatus(ConnectivityResult result) {
       final isConnected = result != ConnectivityResult.none;
       _connectionStatusController.add(isConnected);
     }
     
     void dispose() {
       _connectionStatusController.close();
     }
   }
   ```

#### 验证标准
- [ ] 错误处理统一规范
- [ ] 用户友好错误提示
- [ ] 网络状态监控有效
- [ ] 错误日志记录完整

### 3.4 用户体验优化 (优先级: 中)

#### 当前状态
- **问题**: 页面转场、加载状态、交互反馈需要改进
- **影响**: 用户体验差

#### 具体任务
1. **页面转场优化**:
   ```dart
   // lib/widgets/animations/page_transitions.dart
   class FadePageRoute<T> extends PageRouteBuilder<T> {
     final Widget page;
     
     FadePageRoute({required this.page})
         : super(
           pageBuilder: (context, animation, secondaryAnimation) => page,
           transitionsBuilder: (context, animation, secondaryAnimation, child) {
             return FadeTransition(
               opacity: animation,
               child: child,
             );
           },
         );
   }
   
   class SlidePageRoute<T> extends PageRouteBuilder<T> {
     final Widget page;
     final Offset beginOffset;
     
     SlidePageRoute({
       required this.page,
       this.beginOffset = const Offset(1.0, 0.0),
     }) : super(
           pageBuilder: (context, animation, secondaryAnimation) => page,
           transitionsBuilder: (context, animation, secondaryAnimation, child) {
             return SlideTransition(
               position: Tween<Offset>(
                 begin: beginOffset,
                 end: Offset.zero,
               ).animate(animation),
               child: child,
             );
           },
         );
   }
   ```

2. **加载状态优化**:
   ```dart
   // lib/widgets/common/loading_widget.dart
   class LoadingWidget extends StatelessWidget {
     final String? message;
     final double size;
     
     const LoadingWidget({
       Key? key,
       this.message,
       this.size = 48.0,
     }) : super(key: key);
     
     @override
     Widget build(BuildContext context) {
       return Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             SizedBox(
               width: size,
               height: size,
               child: CircularProgressIndicator(
                 strokeWidth: 3.0,
                 valueColor: AlwaysStoppedAnimation<Color>(
                   Theme.of(context).primaryColor,
                 ),
               ),
             ),
             if (message != null) ...[
               SizedBox(height: 16),
               Text(
                 message!,
                 style: TextStyle(fontSize: 16),
                 textAlign: TextAlign.center,
               ),
             ],
           ],
         ),
       );
     }
   }
   ```

3. **交互反馈优化**:
   ```dart
   // lib/widgets/common/interactive_feedback.dart
   class InteractiveButton extends StatefulWidget {
     final Widget child;
     final VoidCallback? onPressed;
     final Duration duration;
     
     const InteractiveButton({
       Key? key,
       required this.child,
       this.onPressed,
       this.duration = const Duration(milliseconds: 150),
     }) : super(key: key);
     
     @override
     _InteractiveButtonState createState() => _InteractiveButtonState();
   }

   class _InteractiveButtonState extends State<InteractiveButton> {
     bool _isPressed = false;
     
     @override
     Widget build(BuildContext context) {
       return GestureDetector(
         onTapDown: (_) => setState(() => _isPressed = true),
         onTapUp: (_) => setState(() => _isPressed = false),
         onTapCancel: () => setState(() => _isPressed = false),
         onTap: widget.onPressed,
         child: AnimatedContainer(
           duration: widget.duration,
           transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
           child: widget.child,
         ),
       );
     }
   }
   ```

#### 验证标准
- [ ] 页面转场流畅自然
- [ ] 加载状态明确友好
- [ ] 交互反馈及时准确
- [ ] 用户体验测试通过

---

## 四、时间安排

### 4.1 第一周：硬编码账号移除 (2026-03-18 ~ 2026-03-22)
- Day 1: 分析硬编码账号使用情况
- Day 2: 移除硬编码账号配置
- Day 3: 优化登录页面
- Day 4: 统一API认证机制
- Day 5: 测试和验证

### 4.2 第二周：Mock数据替换 (2026-03-23 ~ 2026-03-29)
- Day 1-2: 通知页面API对接
- Day 3: 店铺雷达页面API对接
- Day 4: 浏览历史页面API对接
- Day 5: 其他页面API对接

### 4.3 第三周：错误处理完善 (2026-03-30 ~ 2026-04-05)
- Day 1-2: 统一错误处理机制
- Day 3: 用户友好错误提示
- Day 4: 网络状态监控
- Day 5: 错误日志记录

### 4.4 第四周：用户体验优化 (2026-04-06 ~ 2026-04-12)
- Day 1-2: 页面转场优化
- Day 3: 加载状态优化
- Day 4: 交互反馈优化
- Day 5: 用户体验测试

---

## 五、协作机制

### 5.1 与GPT-5.4协作
- **接口对接**: 确保前端API调用与后端接口一致
- **数据格式**: 统一数据格式和错误码
- **测试协调**: 协调前后端联调测试

### 5.2 与用户协作
- **需求确认**: 确认用户体验优化需求
- **进度汇报**: 定期汇报修复进度
- **验收测试**: 用户验收测试和反馈

### 5.3 与Gemini 3.1 Pro协作（可选）
- **UI设计**: 协助UI视觉设计
- **动画效果**: 协助动画效果实现
- **性能优化**: 协助前端性能优化

---

## 六、成功标准

### 6.1 技术指标
1. **代码质量**: 无硬编码数据，代码结构清晰
2. **功能完整性**: 所有功能对接真实API
3. **错误处理**: 统一规范，用户友好
4. **性能**: 页面加载时间 < 2秒

### 6.2 用户体验指标
1. **页面转场**: 流畅自然，无卡顿
2. **加载状态**: 明确友好，有进度提示
3. **交互反馈**: 及时准确，有视觉反馈
4. **错误提示**: 清晰易懂，有解决方案

### 6.3 质量指标
1. **测试覆盖率**: ≥ 60%
2. **代码规范**: 符合Flutter/Dart规范
3. **文档完整**: 技术文档和用户文档完整
4. **安全合规**: 通过安全扫描

---

*文档版本: v1.0*
*更新频率: 每周更新*
*下次更新: 2026-03-24*