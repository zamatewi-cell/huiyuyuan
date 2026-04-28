# HuiYuYuan Figma Redesign Handoff

Last updated: 2026-04-28

## Purpose

This file is the design handoff for continuing the HuiYuYuan Figma redesign in a new Codex thread or a design-only workflow.

The Flutter implementation has already shipped to production on 2026-04-28. Future Figma work should align with the production UI and the design system in `docs/design/design_system.md`.

## Project Context

- Brand: HuiYuYuan / 汇玉源
- Product type: premium jewelry intelligent trading platform
- Stack context: Flutter frontend + FastAPI backend
- Design direction: dark theme + liquid glass + emerald brand color + restrained champagne gold
- Target feeling: premium, curated, intimate, elegant, refined

Production references:

- `https://汇玉源.top`
- `https://xn--lsws2cdzg.top`

Implementation notes:

- Web should update as static assets; do not design a web update modal.
- Mobile can keep update/download/install flows.
- Browser Service Worker cache can temporarily show older UI after release.

## Existing Good Direction

The earlier successful Figma direction was built around:

- `Home / Curation`
- `AI Concierge`

Those screens established the right visual language:

- cinematic dark background
- emerald glow instead of neon
- deep glass surfaces instead of white glass
- high-end editorial typography
- jewelry-brand atmosphere rather than generic e-commerce

If screenshots of those screens are available, they should be treated as higher priority than any abstract prompt.

## Visual Language

### Core Mood

- luxury jewelry brand, not SaaS
- quiet confidence, not loud promotion
- intimate concierge, not aggressive conversion funnel
- premium mobile shopping, not marketplace clutter

### Color Direction

- Primary emerald: `#2E8B57`
- Gold accent: restrained champagne gold, not saturated yellow
- Dark background base: `#1A1A2E` and adjacent deep blue-black / black-green tones
- Glass surface: dark translucent layers, not frosted white cards

### Typography

- Heading: `Cormorant`
- Body / UI text: `Montserrat`

Use serif display typography for hero headings, product names, and premium emphasis.
Use clean sans-serif for UI labels, metadata, buttons, and forms.

### Surface Rules

- Card radius: `20-24`
- Input radius: `14-16`
- Soft shadows only
- Thin light edge highlights
- Background blur should feel elegant and subtle
- Avoid overusing glow, gradients, or loud reflections

## Absolute Avoid List

- blue-purple AI aesthetic
- generic e-commerce template layout
- white-background jewelry detail pages
- generic BI/admin dashboard look
- candy colors
- playful or cute iconography
- heavy cyberpunk neon
- thick shadows and cheap glow effects
- multi-style exploration boards

Only one coherent design language should be produced.

## Community Reference Direction

The earlier direction was informed by these Figma Community references by name:

- `Tiger Jewelry - Shopping app`
- `APOLLONIAN - Jewelry Website`
- `Jewelry Inventory Management App`
- `Glassmorphism_All in one`

These are references for structure and mood only. The final design should feel custom and unified, not copied.

## Page Scope To Continue

Continue with these pages first:

1. `Login / Welcome`
2. `Product Detail`
3. `Admin / Dashboard`

## Page 1: Login / Welcome

### Required Frames

- Mobile: `390 x 844`
- Desktop: `1440 x 960`

### Composition

Mobile should feel like a premium onboarding screen:

- upper area: brand atmosphere, jewelry silhouette or jade-like abstract form
- lower area: dark glass login card

Desktop should be split layout:

- left: luxury mood visual
- right: login panel

### Required Content

- Title: `汇玉源`
- Subtitle: `AI 珠宝顾问与交易平台`
- Supporting line: `甄选、咨询、交易，一处完成`
- Inputs: phone number, verification code
- Actions:
  - primary CTA for login / code flow
  - secondary `密码登录`
  - tertiary `先逛逛`

### Trust Cues

Add 3 subtle trust points:

- `12 家合作店铺`
- `AI 智能挑选`
- `交易更安心`

### Tone

This page should feel like luxury brand onboarding, not a discount signup page.

## Page 2: Product Detail

### Required Frame

- Mobile: around `390 x 1200`

### Top Section

- immersive hero image area
- dark exhibition / product photography mood
- floating glass icon buttons for back, favorite, share

### Product Info Order

- product name
- material tags
- price
- spec summary
- inventory status

Use serif for the product title and restrained gold for price emphasis.

### AI Concierge Block

This block is mandatory.

Include:

- title: `问问 AI 这件适合谁`
- three quick chips:
  - `适合送长辈吗`
  - `日常佩戴会不会太张扬`
  - `同价位还有什么推荐`

### Detail Sections

Use dark glass content sections for:

- `材质与工艺`
- `寓意与送礼场景`
- `尺寸 / 证书 / 售后`

### Recommendation Section

Add a horizontal recommendation strip with 2-3 related items.

### Bottom Bar

Fixed bottom actions:

- `收藏`
- `咨询顾问`
- `立即购买`

The page should feel like assisted luxury decision-making, not hard-sell retail.

## Page 3: Admin / Dashboard

### Required Frame

- Desktop: `1440 x 1024`

### Structure

- left frosted dark sidebar
- top toolbar
- KPI row
- central operations workspace
- lower analytics / activity area

### Sidebar

- dark matte / frosted appearance
- emerald active indicator
- restrained icons
- no bright SaaS blue

### KPI Row

Use glass cards for:

- `今日订单`
- `待确认付款`
- `库存预警`
- `AI 咨询转化`

### Main Workspace

Do not make this a plain table dashboard.

Suggested middle layout:

- left: operations queue / order workbench
- right: payment reconciliation / inventory alerts
- bottom: activity stream or trend chart

The page should feel operational and restrained, while clearly belonging to the same luxury brand system.

## Motion / Polish Guidance

- page load: gentle stagger, not flashy
- product hero: subtle light sweep or soft reveal
- AI module: very soft breathing glow at most
- no exaggerated 3D
- no futuristic neon sci-fi effects

## Current Design Debt

- Build a proper Figma component library from production Flutter tokens.
- Map `GlassmorphicCard`, gradient buttons, status chips, product cards, and admin KPI cards to named Figma components.
- Add responsive desktop/mobile variants for login, product detail, and admin workbench.
- Capture production screenshots after each major release and attach them to the Figma draft.
