## Design System: HuiYuYuan
> 📍 **汇玉源珠宝智能交易平台** | 最后更新: 2026-02-22

### Pattern
- **Name:** Feature-Rich Showcase
- **CTA Placement:** Above fold
- **Sections:** Hero > Features > CTA

### Style
- **Name:** Liquid Glass
- **Keywords:** Flowing glass, morphing, smooth transitions, fluid effects, translucent, animated blur, iridescent, chromatic aberration
- **Best For:** Premium SaaS, high-end e-commerce, creative platforms, branding experiences, luxury portfolios
- **Performance:** ⚠ Moderate-Poor | **Accessibility:** ⚠ Text contrast

### Colors
| Role | Hex | Flutter 常量 | 用途 |
|------|-----|-------------|------|
| Primary | #2E8B57 | `JewelryColors.primary` | 主操作、强调色（海绿色） |
| Gold Accent | #FFD700 | `JewelryColors.gold` | 价格、评分、徽章 |
| CTA | #CA8A04 | `JewelryColors.ctaGold` | 按钮、购买行动 |
| Background Light | #FAFAF9 | `JewelryColors.bgLight` | 浅色模式背景 |
| Background Dark | #1A1A2E | `JewelryColors.bgDark` | 深色模式背景 |
| Text | #0C0A09 | — | 正文深色 |
| Glass Surface | rgba(255,255,255,0.15) | — | 毛玻璃卡片填充 |

*Notes: Sea-green primary + gold accent for premium jewelry brand*

### Typography
- **Heading:** Cormorant（Web） / 系统默认衬线（Flutter）
- **Body:** Montserrat（Web） / 系统默认（Flutter）
- **Mood:** luxury, high-end, fashion, elegant, refined, premium
- **Best For:** Fashion brands, luxury e-commerce, jewelry, high-end services
- **Google Fonts:** https://fonts.google.com/share?selection.family=Cormorant:wght@400;500;600;700|Montserrat:wght@300;400;500;600;700
- **CSS Import:**
```css
@import url('https://fonts.googleapis.com/css2?family=Cormorant:wght@400;500;600;700&family=Montserrat:wght@300;400;500;600;700&display=swap');
```

### Key Effects
Morphing elements (SVG/CSS), fluid animations (400-600ms curves), dynamic blur (backdrop-filter), color transitions

### Flutter 实现规范

#### 毛玻璃卡片
```dart
// 使用 GlassmorphicCard 组件
GlassmorphicCard(
  blur: 12,
  opacity: 0.15,
  borderRadius: 16,
  child: content,
)

// 或手动实现
ClipRRect(
  borderRadius: BorderRadius.circular(16),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
    ),
  ),
)
```

#### 自适应主题颜色
```dart
// 使用扩展方法，自动适配深色/浅色模式
context.adaptiveBackground   // 页面背景
context.adaptiveCard         // 卡片背景
context.adaptiveText         // 主文字
context.adaptiveSubtext      // 次级文字
context.adaptiveBorder       // 边框颜色
```

#### 渐变按钮
```dart
GradientButton(
  text: '立即购买',
  icon: Icons.shopping_cart,
  gradient: JewelryColors.primaryGradient,  // 绿色渐变
  // 或 JewelryColors.goldGradient          // 金色渐变（操作员专用）
  onPressed: () {},
)
```

### 动画规范
| 动效 | 时长 | 曲线 |
|------|------|------|
| 页面切换 | 300ms | `Curves.easeInOut` |
| 卡片悬停/点击 | 150ms | `Curves.easeOut` |
| 背景渐变循环 | 10s | `repeat` |
| 浮动装饰 | 3s | `Curves.easeInOut` (reverse) |
| 打字机效果 | 20ms/字符 | — |

### Avoid (Anti-patterns)
- Vibrant & Block-based backgrounds
- Playful colors (不符合高端珠宝调性)
- 未经 `adaptiveXxx` 扩展的硬编码颜色
- 深色模式下使用纯黑背景（应使用 #1A1A2E）

### Pre-Delivery Checklist
- [x] No emojis as icons (use Flutter Icons / SVG)
- [x] Hover states with smooth transitions (150-300ms)
- [x] Light mode: text contrast 4.5:1 minimum
- [x] Dark mode: fully adapted (all screens)
- [x] Responsive: tested on 360px-414px mobile widths
- [x] prefers-reduced-motion: Flutter platform check
- [ ] Focus states visible for keyboard nav (Web/Desktop)

