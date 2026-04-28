# HuiYuYuan Figma Redesign Handoff

Last updated: 2026-04-22

## Purpose

This file is the design handoff for continuing the HuiYuYuan Figma redesign in a new Codex thread when the current thread cannot access `use_figma` / `create_new_file`.

The next thread should treat this file as the canonical art direction and execution brief.

## Project Context

- Brand: HuiYuYuan / 汇玉源
- Product type: premium jewelry intelligent trading platform
- Stack context: Flutter frontend + FastAPI backend
- Design system direction: dark theme + liquid glass + emerald brand color + restrained champagne gold
- Target feeling: premium, curated, intimate, elegant, refined

## Existing Good Direction

The earlier successful direction was built around:

- `Home / Curation`
- `AI Concierge`

Those screens established the right visual language:

- cinematic dark background
- emerald glow instead of neon
- deep glass surfaces instead of white glass
- high-end editorial typography
- jewelry-brand atmosphere rather than generic e-commerce

If screenshots of those screens are available, they should be treated as higher priority than any text instruction in this file.

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
- Background blur feel should be elegant and subtle
- Avoid overusing glow, gradients, or loud reflections

## Absolute Avoid List

Do not produce any of the following:

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

Continue with these three pages:

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
- Supporting line: something close to `甄选、咨询、交易，一处完成`
- Inputs: phone number, verification code
- Actions:
  - primary CTA for login / code flow
  - secondary `密码登录`
  - tertiary `先逛逛`

### Trust Cues

Add 3 subtle trust points:

- `12家合作店铺`
- `AI智能挑选`
- `交易更安心`

### Tone

This page should feel like luxury brand onboarding, not a discount signup page.

## Page 2: Product Detail

### Required Frame

- Mobile: around `390 x 1200`

### Top Section

- immersive hero image area
- dark exhibition / product photography mood
- floating glass icon buttons for:
  - back
  - favorite
  - share

### Product Info Order

- product name
- material tags
- price
- spec summary
- inventory status

Use serif for the product title and gold for price emphasis.

### AI Concierge Block

This block is mandatory.

Include:

- title: `问问 AI 这件适合谁`
- three quick chips:
  - `适合送长辈吗`
  - `日常佩戴会不会夸张`
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
- subtle emerald or gold selected state
- not a standard SaaS sidebar

### Top Bar

Include:

- search
- time range
- notifications
- current admin avatar

### KPI Cards

Four cards:

- `今日成交额`
- `待确认付款`
- `待发货订单`
- `AI咨询转化`

### Main Workspace

Do not make this a plain table dashboard.

Suggested middle layout:

- left: pending orders
- center: payment review and anomaly alerts
- right: store performance and low stock warnings

### Lower Section

Include:

- recent transaction activity timeline
- inventory / hot materials module

### Tone

This page should feel more restrained and operational than the consumer screens, but still clearly belong to the same brand system.

## Motion / Polish Guidance

- entry animation: slight rise + fade
- hover state: subtle edge highlight
- AI module: very soft breathing glow at most
- no exaggerated 3D
- no futuristic neon sci-fi effects

## Execution Rules For The Next Thread

The next thread should follow these rules exactly:

- do not invent a new visual direction
- do not produce multiple style branches
- do not default to a generic commerce or admin template
- keep all three pages in one coherent visual system
- prioritize polish, spacing, hierarchy, and material quality over quantity of UI elements

## Recommended New Thread Prompt

Use this as the opening message in the next thread:

```text
Please read D:/huiyuyuan_project/docs/design/figma_ui_redesign_handoff.md first and follow it as the design brief.

You are continuing an existing HuiYuYuan Figma redesign direction, not inventing a new style.

Important:
- strictly keep the dark + emerald + champagne gold + liquid glass luxury jewelry aesthetic
- do not use blue-purple AI visuals
- do not use generic e-commerce or admin dashboard templates
- produce only one coherent design direction

After reading the handoff file, continue the Figma work for these screens:
1. Login / Welcome
2. Product Detail
3. Admin / Dashboard

If screenshots of the previous Home / Curation and AI Concierge screens are provided, use those as the highest-priority visual reference.
```

## What The User Should Also Provide

To maximize visual continuity, the user should attach:

- screenshots of the earlier `Home / Curation` screen
- screenshots of the earlier `AI Concierge` screen

Those screenshots matter more than any abstract style prompt.
