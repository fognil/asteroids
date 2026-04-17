# 🚀 NEON ASTEROIDS — Game Design Document

> **Engine**: Godot 4.6 (Mobile Renderer)
> **Platform**: Android / iOS (Mobile-first)
> **Thể loại**: Neon Arcade Space Shooter
> **Orientation**: Landscape (1920×1080 base)
> **Phiên bản GDD**: 2.0
> **Ngày tạo**: 2026-04-16
> **Ngày cập nhật**: 2026-04-17

---

## Mục lục

1. [Tổng Quan Game](#1-tổng-quan-game)
2. [Core Gameplay Loop](#2-core-gameplay-loop)
3. [App Flow & Navigation](#3-app-flow--navigation)
4. [Hub Screen (Main Menu)](#4-hub-screen-main-menu)
5. [Player Ship](#5-player-ship)
6. [Asteroids System](#6-asteroids-system)
7. [Enemies — UFO System](#7-enemies--ufo-system)
8. [Power-ups & Collectibles](#8-power-ups--collectibles)
9. [Weapon System](#9-weapon-system)
10. [Scoring & Combo System](#10-scoring--combo-system)
11. [Level Progression & Difficulty](#11-level-progression--difficulty)
12. [Boss Battles](#12-boss-battles)
13. [Controls & Input](#13-controls--input)
14. [HUD & In-Game UI](#14-hud--in-game-ui)
15. [Visual Style & Art Direction](#15-visual-style--art-direction)
16. [Audio Design](#16-audio-design)
17. [Particle Effects & Juice](#17-particle-effects--juice)
18. [Meta-Progression Systems](#18-meta-progression-systems)
19. [Battle Pass / Season System](#19-battle-pass--season-system)
20. [Daily & Weekly Systems](#20-daily--weekly-systems)
21. [Social Features](#21-social-features)
22. [Monetization](#22-monetization)
23. [Save System & Persistence](#23-save-system--persistence)
24. [Analytics & Tracking](#24-analytics--tracking)
25. [Notifications & Re-engagement](#25-notifications--re-engagement)
26. [Accessibility](#26-accessibility)
27. [Localization](#27-localization)
28. [Technical Architecture (Godot)](#28-technical-architecture-godot)
29. [Scene Tree Structure](#29-scene-tree-structure)
30. [Performance & Optimization](#30-performance--optimization)
31. [Milestone & Roadmap](#31-milestone--roadmap)
32. [ASO & Store Listing](#32-aso--store-listing)
33. [Phụ Lục: Achievements](#33-phụ-lục-achievements)

---

## 1. Tổng Quan Game

### 1.1. Concept
Neon Asteroids là game **arcade space shooter** phong cách **neon wireframe** lấy cảm hứng từ Asteroids cổ điển (Atari, 1979) kết hợp với thẩm mỹ Geometry Wars và độ sâu progression của Nova Drift. Game được xây dựng hoàn toàn trên Godot 4.6 cho mobile.

**Core Identity:**
- 🎮 **Gameplay**: Arcade shooter thuần skill với inertia physics
- 🎨 **Visual**: Neon wireframe trên nền đen — mọi thứ phát sáng
- 📈 **Depth**: 6 tàu × 7 loại asteroid × 4 loại UFO × 11 power-ups × 5 boss
- 💰 **Model**: F2P — Rewarded Ads + IAP (No Pay-to-Win) + Battle Pass

### 1.2. Elevator Pitch
> "Điều khiển tàu vũ trụ neon phá hủy thiên thạch trong không gian vô tận. Mỗi viên đá vỡ ra thành mảnh nhỏ hơn, nhanh hơn, nguy hiểm hơn. Thu thập power-ups, xây combo, đánh boss, mở khóa tàu mới. Phong cách neon retro-futuristic, chơi offline mọi lúc mọi nơi."

### 1.3. Target Audience
| Tiêu chí | Chi tiết |
|---|---|
| **Độ tuổi** | 13–45 |
| **Profile** | Casual/Mid-core gamers thích arcade nhanh, dễ chơi khó master |
| **Session time** | 2–10 phút/lần chơi |
| **Platform** | Android (ưu tiên) → iOS |
| **Target devices** | Mid-range Android 2020+ (4GB RAM, Adreno 610+) |
| **Reference games** | Geometry Wars, Nova Drift, PewPew Live, Asteroids Neon |

### 1.4. Unique Selling Points (USP)
| # | USP | Mô tả |
|---|---|---|
| 1 | **Neon Wireframe Art** | Mọi thứ là outline phát sáng — đẹp, nhẹ, đặc trưng |
| 2 | **Combo System** | Phá hủy liên tục tăng combo multiplier → thỏa mãn |
| 3 | **Boss Battles** | 5 boss multi-phase với attack patterns riêng |
| 4 | **6 Ships + Abilities** | Mỗi tàu có special ability, tạo meta đa dạng |
| 5 | **Battle Pass** | Season Pass 30 ngày với cosmetics & rewards |
| 6 | **Deep Progression** | Upgrades vĩnh viễn + Ship unlocks + Achievements |
| 7 | **Juice Factor** | Screen shake, slow-mo, particle explosions, combo popups |
| 8 | **Offline Play** | Chơi hoàn toàn offline, không bắt buộc internet |

### 1.5. Competitive Analysis

| Feature | Asteroids Classic | Asteroids Blaster (GP) | PewPew Live | **Neon Asteroids (Ours)** |
|---|---|---|---|---|
| Weapons | 1 loại | 1 loại | 1 loại/mode | **5 loại + heat system** |
| Enemies | Asteroids + UFO | Asteroids only | Geometric shapes | **Asteroids + 4 UFO + 5 Boss** |
| Progression | Score only | Score/Level | Unlockable modes | **Ships + Upgrades + Battle Pass** |
| Visual | Vector B&W | Basic neon | Clean neon | **Rich neon + particles + juice** |
| Combo | Không | Không | Không | **Full combo system x2-x10** |
| Controls | 5 buttons | D-pad | Twin-stick | **3 modes: Joystick/Twin-stick/Classic** |
| Monetization | ¢25/play | Ads heavy | Premium | **F2P ethical: Rewarded + IAP + BP** |
| Boss | Không | Không | Không | **5 unique multi-phase bosses** |
| Offline | N/A | Yes | Yes | **Yes** |

---

## 2. Core Gameplay Loop

### 2.1. Micro Loop (trong 1 wave ~ 10-30 giây)
```
┌────────────────────────────────────────────────────────────┐
│                                                            │
│   Observe threats → Rotate/Thrust → Dodge → Shoot         │
│         │                                                  │
│         ▼                                                  │
│   Asteroids split → Collect coins/power-ups → Build combo  │
│         │                                                  │
│         ▼                                                  │
│   Clear all threats → Wave Complete! → Next Wave           │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 2.2. Session Loop (1 session ~ 2-10 phút)
```
Start Game → Wave 1 → Wave 2 → ... → Wave 5 (BOSS)
    │                                        │
    │         Collect coins & score           │
    │         Use power-ups                   │
    │         Survive & build combo           │
    │                                        │
    ▼                                        ▼
  Die → Continue (Ad/Gem)?              Boss defeated
         │         │                         │
         No        Yes → Resume         Next zone (Wave 6-10)
         │                                   │
         ▼                                   ...
    Game Over                                │
      │                                      ▼
      ▼                                 Loop until death
   Results Screen
   (Score, Coins, XP, Battle Pass progress)
```

### 2.3. Meta Loop (across sessions ~ hàng tuần/tháng)
```
Play game → Earn coins/XP → Level up Battle Pass
    │                              │
    ▼                              ▼
Unlock ships/upgrades ──→ Unlock exclusive cosmetics
    │                              │
    ▼                              ▼
Play better → Higher scores → Climb leaderboard
    │                              │
    ▼                              ▼
Complete missions → Earn more rewards → Play again
```

### 2.4. Engagement Loop (daily/weekly)
```
Open App
    │
    ▼
Daily Login Reward → Check Daily Missions
    │                        │
    ▼                        ▼
Play to complete missions → Earn Battle Pass XP
    │                        │
    ▼                        ▼
Weekly Challenge check → Special event check
    │                        │
    ▼                        ▼
Spend coins (Hangar/Upgrades) → Close app, return tomorrow
```

---

## 3. App Flow & Navigation

### 3.1. Full App Flow
```
┌─────────────────────────────────────────────────────────────┐
│                      APP LAUNCH                             │
│                         │                                   │
│                         ▼                                   │
│                  Splash Screen (2s)                          │
│                  (Studio logo + Godot)                       │
│                         │                                   │
│                         ▼                                   │
│              Loading Screen (assets)                        │
│              [Progress bar + tips]                           │
│                         │                                   │
│                         ▼                                   │
│          ┌─── First time? ───┐                              │
│          │                   │                              │
│         YES                  NO                             │
│          │                   │                              │
│          ▼                   │                              │
│   Onboarding Tutorial        │                              │
│   (3 screens + quick play)   │                              │
│          │                   │                              │
│          └───────┬───────────┘                              │
│                  │                                          │
│                  ▼                                          │
│          ╔══════════════════╗                                │
│          ║    HUB SCREEN    ║ ◀──────────────┐              │
│          ║   (Main Menu)    ║                │              │
│          ╚══════════════════╝                │              │
│           │  │  │  │  │  │                   │              │
│           ▼  ▼  ▼  ▼  ▼  ▼                  │              │
│         [Play][Hangar][Upgrades]              │              │
│         [Battle Pass][Shop][Settings]         │              │
│         [Missions][Leaderboard]               │              │
│                  │                            │              │
│                  ▼ (PLAY)                     │              │
│          Ship Selection (if >1)               │              │
│                  │                            │              │
│                  ▼                            │              │
│          Zone Selection                       │              │
│                  │                            │              │
│                  ▼                            │              │
│          Countdown 3-2-1-GO!                  │              │
│                  │                            │              │
│                  ▼                            │              │
│          ╔══════════════════╗                  │              │
│          ║    GAMEPLAY      ║                  │              │
│          ╚══════════════════╝                  │              │
│                  │                            │              │
│           ┌──────┴──────┐                     │              │
│           ▼             ▼                     │              │
│        Die      ──►  Pause Menu ──►  Resume   │              │
│           │                    └──►  Settings  │              │
│           ▼                    └──►  Quit ─────┘              │
│    Continue Screen                                          │
│     │           │                                           │
│    Yes(Ad)     No                                           │
│     │           │                                           │
│   Resume    Game Over                                       │
│              Results Screen ──── [Play Again] ──► Gameplay   │
│                    └──────────── [Hub] ──────────► HUB       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 3.2. Popups & Overlays (xuất hiện trên Hub)
```
Hub Screen mở lần đầu mỗi ngày:
  ┌─ Priority Queue (hiện 1 popup, đợi đóng rồi mới hiện tiếp):
  │
  │  1. ⚠️ Update Available (nếu có) — hiện 1 lần
  │  2. 🎁 Daily Reward — mỗi ngày
  │  3. 🎫 New Battle Pass Season — đầu season mới
  │  4. 🎯 New Event — khi có event mới
  │  5. 📢 Special Offer — targeted offer (max 1/session)
  │
  └─ Sau đó: Tự do navigate Hub
```

### 3.3. Onboarding Flow (First Time Only)
```
Screen 1: "Welcome, Commander!" + Ship animation
  │ [TAP TO CONTINUE]
  │
  ▼
Screen 2: "Destroy Asteroids" + Demo animation (asteroid splits)
  │ [TAP TO CONTINUE]
  │
  ▼
Screen 3: "Collect Power-ups & Build Combos" + Demo
  │ [LET'S GO!]
  │
  ▼
Quick Tutorial Game:
  Step 1: "Drag to MOVE" — Joystick highlight, 3 asteroids chậm
  Step 2: "Tap to SHOOT" — Fire button highlight
  Step 3: "Destroy ALL asteroids!" — Complete mini-wave
  Step 4: "Collect coins!" — Coins fly to counter
  Step 5: "GREAT JOB!" + 200 coins bonus
  │
  ▼
Hub Screen (first visit)
  │
  ▼
Contextual tooltips (1 lần duy nhất):
  - "👈 Upgrade your ship here" (Upgrades tab)
  - "🎫 Check your Battle Pass" (BP tab)
  - "🎯 Complete missions for rewards" (Missions tab)
```

---

## 4. Hub Screen (Main Menu)

### 4.1. Hub Layout — Landscape

```
┌──────────────────────────────────────────────────────────────────────┐
│  STATUS BAR                                                          │
│  💰 3,450   💎 12   🏆 Lv.7   ⚡ 5/5 Energy   ⚙️ Settings         │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│                                                                      │
│                    🚀 [Ship Preview — rotating slowly]               │
│                    ═══════════════════════════                        │
│                    "PHOENIX MK-I"                                    │
│                    ⭐⭐⭐☆☆  |  Speed 60  Fire 60  Shield 60        │
│                                                                      │
│                    ╔═══════════════════════╗                          │
│                    ║    ▶  P L A Y  ▶     ║  ← Nút lớn nhất, glow  │
│                    ╚═══════════════════════╝                          │
│                                                                      │
│                    Best Score: 69,220   Best Wave: 13                │
│                                                                      │
│                                                                      │
├──────────────────────────────────────────────────────────────────────┤
│  BOTTOM NAV BAR (5 tabs, icon + text)                                │
│  ┌────────┬────────┬────────┬────────┬────────┐                      │
│  │  🚀    │  ⬆️    │  🎫    │  🎯    │  🛒    │                      │
│  │ Hangar │Upgrade │ Pass   │Mission │ Shop   │                      │
│  └────────┴────────┴────────┴────────┴────────┘                      │
│                                                                      │
│  [🏆 Leaderboard]                            [🎁 Daily Reward (●)]  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

● = Notification dot (có phần thưởng chưa claim)
```

### 4.2. Hub Elements Chi Tiết

#### Status Bar (Top)
```
Coins:    💰 3,450     — earned in-game, spend on upgrades/ships
Gems:     💎 12        — premium currency, buy via IAP or earn rare
Level:    🏆 Lv.7      — player level (XP from playing)
Energy:   ⚡ 5/5       — optional energy system (see Section 22)
Settings: ⚙️           — gear icon, top-right

Behavior:
  - Tap coins → Show where to earn more (play / shop)
  - Tap gems → Open shop gem section
  - Tap level → Show XP progress bar to next level
  - Tap energy → Show timer until next energy refill
```

#### PLAY Button (Center)
```
Design:
  - Nút lớn nhất trên Hub (200×60dp)
  - Neon glow animation liên tục (pulse effect)
  - Gradient: Cyan (#00FFFF) → Blue (#0066FF)
  - Text: "▶ PLAY" hoặc "▶ CONTINUE" (nếu có progress)
  - Tap → Ship Selection → Zone Selection → Game Start

States:
  - Normal: Glow pulse mỗi 2 giây
  - No Energy: Grayed out, "Watch Ad for Energy?" overlay
  - Event active: Button text = "▶ PLAY EVENT" + event color
```

#### Ship Preview (Center background)
```
Display:
  - Ship hiện tại xoay chậm 360° (20 giây/vòng)
  - Neon glow effect theo màu tàu
  - Engine particles nhẹ (idle animation)
  - Ship name + star rating bên dưới
  - Quick stats: Speed | Fire | Shield

Interaction:
  - Tap ship → Open Hangar (ship selection)
  - Swipe left/right → Preview next/prev ship (quick switch)
```

#### Bottom Navigation Bar
```
5 tabs cố định, luôn hiện trên Hub:

Tab 1: 🚀 Hangar     — Ship selection & preview
Tab 2: ⬆️ Upgrade    — Permanent stat upgrades
Tab 3: 🎫 Pass       — Battle Pass / Season Pass
Tab 4: 🎯 Mission    — Daily/Weekly missions
Tab 5: 🛒 Shop       — Coins/Gems/Offers

Notification dots:
  - Hangar: Có đủ coins để unlock ship mới
  - Upgrade: Có đủ coins để upgrade
  - Pass: Có reward chưa claim
  - Mission: Có mission hoàn thành chưa claim
  - Shop: Có special offer mới
```

### 4.3. Hangar Screen (Tab 1)

```
┌──────────────────────────────────────────────────────────────────────┐
│  ← Back                    🚀 HANGAR                   💰 3,450     │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│                                                                      │
│              ◀  [Ship 3D/2D Preview — large, rotating]  ▶           │
│                   Engine trail particles active                      │
│                                                                      │
│              ═══════════════════════════════════                      │
│              "VIPER MK-I"                                           │
│              ⭐⭐⭐☆☆                                                │
│                                                                      │
│              Speed:    ███████████░░░  85%                           │
│              Fire Rate:██████░░░░░░░░  50%                           │
│              Shield:   ███░░░░░░░░░░░  30%                           │
│                                                                      │
│              Special: 💨 DASH                                       │
│              "Lướt nhanh xuyên qua asteroids"                       │
│              Cooldown: 8s | Duration: 0.5s                           │
│                                                                      │
│              ┌──────────────┐    ┌──────────────┐                    │
│              │  ✅ EQUIP     │    │ 🎨 SKINS     │                    │
│              └──────────────┘    └──────────────┘                    │
│                                                                      │
├──────────────────────────────────────────────────────────────────────┤
│  Ship Selector (horizontal scroll, snap to center):                  │
│                                                                      │
│  [Phoenix✅] [Viper 💰5K] [Nebula 💰12K] [Titan 💰25K]              │
│  [Shadow 💎100] [Omega 💎250]                                       │
│                                                                      │
│  ✅ = Unlocked & Equipped                                           │
│  💰 = Coin price (not yet unlocked)                                 │
│  💎 = Gem price (premium)                                           │
│  🔒 = Locked (gray, with price overlay)                             │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

#### Ship Skin System
```
Mỗi tàu có nhiều skins (cosmetic only, không thay đổi stats):

Skin tiers:
  🟢 Common:    2 skins/tàu — Unlock bằng coins (1000-3000)
  🔵 Rare:      2 skins/tàu — Unlock qua Battle Pass hoặc gems (50)
  🟣 Epic:      1 skin/tàu  — Battle Pass premium reward
  🟡 Legendary: 1 skin/tàu  — Special event hoặc shop exclusive (💎150)

Skin properties:
  - Thay đổi: Outline color, glow color, engine trail color
  - Không thay đổi: Ship shape, stats, ability
  - Preview: Real-time preview khi chọn skin

Total skins: 6 ships × 7 skins = 42 skins
```

### 4.4. Upgrades Screen (Tab 2)

```
┌──────────────────────────────────────────────────────────────────────┐
│  ← Back                   ⬆️ UPGRADES                 💰 3,450      │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Scrollable list of upgrade cards:                                   │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐      │
│  │  🔫 Fire Rate            Lv.3/10    ████████░░░░░░░░░░░░  │      │
│  │  +15% fire rate                                           │      │
│  │  Next: +18% fire rate                    [UPGRADE 💰500]  │      │
│  └────────────────────────────────────────────────────────────┘      │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐      │
│  │  🚀 Thrust Power         Lv.2/10    ██████░░░░░░░░░░░░░░  │      │
│  │  +10% acceleration                                        │      │
│  │  Next: +15% acceleration                 [UPGRADE 💰400]  │      │
│  └────────────────────────────────────────────────────────────┘      │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐      │
│  │  🛡️ Shield Duration      Lv.1/10    ███░░░░░░░░░░░░░░░░░  │      │
│  │  +5% shield duration                                      │      │
│  │  Next: +10% shield duration              [UPGRADE 💰600]  │      │
│  └────────────────────────────────────────────────────────────┘      │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐      │
│  │  💣 Bomb Power            Lv.2/10    ██████░░░░░░░░░░░░░░  │      │
│  │  +20% blast radius                                        │      │
│  │  Next: +25% blast radius                 [UPGRADE 💰800]  │      │
│  └────────────────────────────────────────────────────────────┘      │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐      │
│  │  🧲 Magnet Range          Lv.1/10    ███░░░░░░░░░░░░░░░░░  │      │
│  │  +15% pickup range                                        │      │
│  │  Next: +20% pickup range                 [UPGRADE 💰350]  │      │
│  └────────────────────────────────────────────────────────────┘      │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐      │
│  │  ❤️ Starting Lives        Lv.0/3     ░░░░░░░░░░░░░░░░░░░░  │      │
│  │  Start with 3 lives (base)                                 │      │
│  │  Next: Start with 4 lives               [UPGRADE 💰2000]  │      │
│  └────────────────────────────────────────────────────────────┘      │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐      │
│  │  💣 Starting Bombs        Lv.0/3     ░░░░░░░░░░░░░░░░░░░░  │      │
│  │  Start with 3 bombs (base)                                 │      │
│  │  Next: Start with 4 bombs               [UPGRADE 💰1500]  │      │
│  └────────────────────────────────────────────────────────────┘      │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐      │
│  │  ⭐ Score Bonus           Lv.1/10    ███░░░░░░░░░░░░░░░░░  │      │
│  │  +5% base score                                           │      │
│  │  Next: +8% base score                   [UPGRADE 💰300]   │      │
│  └────────────────────────────────────────────────────────────┘      │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐      │
│  │  🎯 Bullet Speed          Lv.0/10    ░░░░░░░░░░░░░░░░░░░░  │      │
│  │  Base bullet speed                                         │      │
│  │  Next: +10% bullet speed                [UPGRADE 💰400]   │      │
│  └────────────────────────────────────────────────────────────┘      │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐      │
│  │  ⏱️ Cooldown Speed        Lv.0/10    ░░░░░░░░░░░░░░░░░░░░  │      │
│  │  Base special ability cooldown                             │      │
│  │  Next: -5% cooldown time                 [UPGRADE 💰500]   │      │
│  └────────────────────────────────────────────────────────────┘      │
│                                                                      │
│  Total upgrade levels: 10 upgrades × 10 max = 100 levels            │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

Upgrade Cost Scaling:
  Level 1-3:   Base cost × 1.0
  Level 4-6:   Base cost × 1.5
  Level 7-9:   Base cost × 2.0
  Level 10:    Base cost × 3.0 (final tier, significant boost)
```

### 4.5. Settings Screen

```
┌──────────────────────────────────────────────────────────────────────┐
│  ← Back                   ⚙️ SETTINGS                               │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ─── CONTROLS ───                                                    │
│  Control Mode:     [🎮 Floating Joystick ▾]                         │
│                     • Fixed Joystick                                 │
│                     • Floating Joystick (default)                    │
│                     • Twin-Stick                                     │
│                     • Classic (Rotate + Thrust)                      │
│  Auto-Fire:        [━━━━━━━━━● ON]                                  │
│  Joystick Size:    [━━━━━●━━━━━ 60%]                                │
│  Joystick Opacity: [━━━━━━━●━━━ 70%]                                │
│  Left-handed Mode: [━━━━━━━━━━ OFF]                                 │
│                                                                      │
│  ─── AUDIO ───                                                       │
│  Master Volume:    [━━━━━━━●━━━ 80%]                                │
│  Music Volume:     [━━━━━●━━━━━ 60%]                                │
│  SFX Volume:       [━━━━━━━━●━━ 90%]                                │
│  Vibration:        [━━━━━━━━━● ON]                                  │
│                                                                      │
│  ─── DISPLAY ───                                                     │
│  Show FPS:         [━━━━━━━━━━ OFF]                                 │
│  Screen Shake:     [━━━━━━━━━● ON]                                  │
│  Particle Quality: [Low] [Med] [●Hi]                                │
│  Bloom Intensity:  [━━━━━━●━━━━ 60%]                                │
│                                                                      │
│  ─── ACCOUNT ───                                                     │
│  Google Play Login: [Connected ✅]                                  │
│  Cloud Save:        [Sync Now]                                       │
│  Reset Progress:    [RESET ⚠️]                                      │
│  Privacy Policy:    [View]                                           │
│  Terms of Service:  [View]                                           │
│  Support/Feedback:  [Contact]                                        │
│                                                                      │
│  ─── ABOUT ───                                                       │
│  Version: 1.0.0                                                      │
│  Credits: [View Credits]                                             │
│  Rate Us: [⭐ Rate on Play Store]                                   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### 4.6. Play Flow (Hub → Game)

```
Hub → Nhấn PLAY
  │
  ▼
Ship Selection (nếu unlocked > 1 tàu)
  ┌──────────────────────────────────────────┐
  │  SELECT YOUR SHIP                        │
  │                                          │
  │  ◀ [Ship carousel with stats] ▶         │
  │                                          │
  │  "VIPER MK-I" — Speed: 90 | Fire: 50    │
  │  Special: DASH                           │
  │                                          │
  │  [SELECT & PLAY]                         │
  └──────────────────────────────────────────┘
  │
  ▼
Zone Selection
  ┌──────────────────────────────────────────┐
  │  SELECT ZONE                             │
  │                                          │
  │  [1. Asteroid Belt ✅] Wave 1-5          │
  │  [2. Nebula Field  ✅] Wave 6-10         │
  │  [3. Comet Storm   ✅] Wave 11-15        │
  │  [4. Dark Sector   🔒] Wave 16-20        │
  │  [5. Black Hole    🔒] Wave 21-25        │
  │  [6. ∞ Infinite    🔒] Endless           │
  │                                          │
  │  ✅ = Unlocked   🔒 = Locked             │
  │                                          │
  │  [CONTINUE from Wave 7] (if applicable)  │
  │  [START FROM BEGINNING]                  │
  └──────────────────────────────────────────┘
  │
  ▼
Pre-Game Tip (random, 2 seconds)
  "💡 Tip: Explosive asteroids chain-react!"
  │
  ▼
Countdown: 3... 2... 1... GO!
  │
  ▼
═══ GAMEPLAY STARTS ═══
```

### 4.7. Game Over → Results Screen

```
Player dies (lives = 0)
  │
  ▼
Dramatic death explosion + slow-mo (1.5s)
  │
  ▼
"GAME OVER" text animation (neon flicker)
  │
  ▼
Continue Screen (5 giây countdown)
  ┌──────────────────────────────────────────┐
  │         CONTINUE?                        │
  │         ⏱️ 5... 4... 3... 2... 1...      │
  │                                          │
  │  [📺 Watch Ad to Revive]   (max 2/game) │
  │  [💎 Use 1 Gem to Revive]               │
  │                                          │
  │  [Give Up]                               │
  └──────────────────────────────────────────┘
  │
  ├── Revive → Resume with 1 life + 3s invincibility
  │
  └── Give Up ──▼

Results Screen:
  ┌──────────────────────────────────────────┐
  │            ⭐ RESULTS ⭐                 │
  │                                          │
  │   Score:        12,450                   │
  │   Best Score:   69,220                   │
  │   ⭐ NEW HIGH SCORE! ⭐  (nếu có)       │
  │                                          │
  │   Wave Reached:     13                   │
  │   Asteroids Destroyed: 87               │
  │   Max Combo:        23x                  │
  │   Accuracy:         72%                  │
  │   Time Played:      4:32                 │
  │                                          │
  │   ─── REWARDS ───                        │
  │   Coins Earned:  💰 340                  │
  │   XP Earned:     +120 XP                 │
  │   Battle Pass:   ████████░░ 8/10         │
  │                                          │
  │   [📺 x2 Coins — Watch Ad]              │
  │                                          │
  │   [▶ PLAY AGAIN]   [🏠 HUB]             │
  │   [📤 SHARE]       [🏆 LEADERBOARD]     │
  └──────────────────────────────────────────┘
```

### 4.8. Pause Flow

```
Nhấn Pause ⏸ (góc phải trên, hoặc Back gesture)
  │
  ▼
Game freeze (tất cả physics/animation dừng)
  │
  ▼
┌──────────────────────────────────────────┐
│           ⏸️ PAUSED                      │
│                                          │
│   Score: 5,230    Wave: 7                │
│   Lives: ❤️❤️     Bombs: 💣💣💣           │
│                                          │
│   [▶ RESUME]                             │
│   [🔄 RESTART]                           │
│   [⚙️ SETTINGS]                          │
│   [🏠 MAIN MENU]                         │
│                                          │
│   🔊 Sound  [ON ━━━━━━━━━●]             │
│   📳 Vibrate [ON ━━━━━━━━━●]            │
│                                          │
└──────────────────────────────────────────┘
```

---

## 5. Player Ship

### 5.1. Ship Stats
Mỗi tàu có 5 chỉ số cơ bản (ảnh hưởng bởi Upgrades):

| Stat | Mô tả | Base Range |
|---|---|---|
| **Speed** | Tốc độ thrust tối đa | 100–300 px/s |
| **Acceleration** | Gia tốc khi thrust | 50–150 px/s² |
| **Fire Rate** | Số đạn bắn/giây | 2–8 shots/s |
| **Bullet Speed** | Tốc độ đạn | 200–500 px/s |
| **Bullet Damage** | Damage mỗi viên đạn | 1–3 |

### 5.2. Danh Sách Tàu (6 Ships)

#### 🟢 Ship 1: Phoenix (Starter)
```
Unlock:    Mặc định (free)
Đặc điểm:  Cân bằng tất cả stats — best for learning
Special:   Không có
Stats:     Speed 60 | Fire 60 | Shield 60
Visual:    Tam giác classic, viền cyan (#00FFFF)
```

#### 🔵 Ship 2: Viper MK-I
```
Unlock:    💰 5,000 coins
Đặc điểm:  Nhanh nhất, yếu nhất — hit & run playstyle
Special:   💨 DASH — Lướt nhanh xuyên asteroids
           Cooldown: 8s | Duration: 0.5s | Invincible during dash
Stats:     Speed 90 | Fire 50 | Shield 30
Visual:    Tam giác nhọn dài, viền lime (#00FF88)
```

#### 🟣 Ship 3: Nebula
```
Unlock:    💰 12,000 coins
Đặc điểm:  Fire rate cao — spray & pray playstyle
Special:   ⚡ OVERCHARGE — x3 fire rate trong 3 giây
           Cooldown: 12s | No heat during overcharge
Stats:     Speed 50 | Fire 85 | Shield 45
Visual:    Hình thoi nhỏ, viền purple (#AA44FF)
```

#### 🟠 Ship 4: Titan
```
Unlock:    💰 25,000 coins
Đặc điểm:  Tank — chậm nhưng bền, crash into things playstyle
Special:   🛡️ FORTRESS — Shield bất tử 4 giây
           Cooldown: 15s | Block all damage
Stats:     Speed 35 | Fire 55 | Shield 95
Visual:    Pentagon, viền orange (#FF8800)
```

#### ⚫ Ship 5: Shadow
```
Unlock:    💎 100 gems
Đặc điểm:  Stealth — UFO không target khi stealth, sniper playstyle
Special:   👻 CLOAK — Tàng hình 5 giây
           Cooldown: 10s | UFOs lose targeting, still hit by asteroids
Stats:     Speed 75 | Fire 70 | Shield 50
Visual:    Tam giác mỏng, viền gray (#999999), nhấp nháy
```

#### 🔴 Ship 6: Omega
```
Unlock:    💎 250 gems
Đặc điểm:  Ultimate — stats cao, ultimate weapon
Special:   💀 ANNIHILATE — Tia laser xuyên màn hình
           Cooldown: 20s | Destroys everything in path | 1s duration
Stats:     Speed 70 | Fire 80 | Shield 75
Visual:    Hexagon + cánh, viền red-gold (#FF4444 + #FFD700)
```

### 5.3. Ship Physics

```gdscript
# === MOVEMENT MODEL ===

# Rotation (nếu Classic mode)
angular_velocity = rotation_speed * input_direction
rotation += angular_velocity * delta

# Thrust
if input_thrust:
    velocity += Vector2.UP.rotated(rotation) * acceleration * delta
    velocity = velocity.limit_length(max_speed)

# Drag (nhẹ để giữ inertia feel, nhưng đủ để dừng eventually)
velocity *= drag_factor  # 0.995 = drift nặng, 0.98 = kiểm soát tốt

# Position update
position += velocity * delta

# Screen wrap
position.x = wrapf(position.x, 0, viewport_width)
position.y = wrapf(position.y, 0, viewport_height)
```

### 5.4. Collision Response
| Va chạm với | Kết quả |
|---|---|
| Asteroid | Mất 1 life, 3s invincible, ship nhấp nháy |
| Enemy bullet | Mất 1 life, 3s invincible |
| UFO body | Mất 1 life, 3s invincible |
| Power-up | Collect, "+SHIELD!" popup |
| Coin | Thu thập, coin sound (pitch varies) |
| Boss attack | Mất 1 life (hoặc 2 cho boss mạnh) |
| Screen edge | Wrap to other side |

---

## 6. Asteroids System

### 6.1. Asteroid Sizes & Stats

| Size | HP | Điểm | Coins | Splits Into | Tốc độ | Radius |
|---|---|---|---|---|---|---|
| **Huge** | 3 | 20 | 3 | 2 Large | 30–60 px/s | 60–80px |
| **Large** | 2 | 50 | 2 | 2 Medium | 40–80 px/s | 40–55px |
| **Medium** | 1 | 100 | 1 | 2-3 Small | 60–120 px/s | 25–35px |
| **Small** | 1 | 150 | 1 | Nothing (explode) | 80–150 px/s | 12–18px |

### 6.2. Asteroid Types (7 loại)

#### 🪨 Normal (Trắng — #CCCCCC)
- Hình đa giác ngẫu nhiên 5-8 cạnh, outline only
- Trôi thẳng 1 hướng, xoay chậm (rotation varies)
- Spawn: Mọi wave

#### 🟡 Gold (Vàng — #FFD700)
- Viền vàng sáng, sparkle particles
- Drop x3 coins, guaranteed coin cluster
- Spawn: Wave 3+, 10% chance thay Normal
- Visual cue: Lấp lánh → player muốn nhắm vào

#### 🔴 Explosive (Đỏ — #FF4444)
- Viền đỏ, pulse animation (phình to-nhỏ nhẹ)
- Khi phá hủy → AOE explosion (bán kính 100px), phá hủy asteroids gần
- Spawn: Wave 5+, 8% chance
- Chiến thuật: Chain reaction khi bắn gần asteroids khác

#### 🟢 Toxic (Xanh lá — #44FF44)
- Viền xanh lá, khí bay xung quanh (green mist particles)
- Phá hủy → Vùng toxic 5s (radius 80px), player vào = mất life
- Spawn: Wave 7+, 6% chance
- Chiến thuật: Bắn từ xa, tránh vùng sau khi nổ

#### 🔵 Ice (Xanh dương — #4488FF)
- Viền xanh dương, tinh thể băng particles
- Phá hủy → Slow tất cả asteroids trong 150px (50% speed, 3s)
- Spawn: Wave 4+, 7% chance
- Chiến thuật: Bắn để slow down wave đông đúc

#### 🟣 Magnetic (Tím — #AA44FF)
- Viền tím, electric arc particles nhỏ
- Hút nhẹ player (gravity pull, rất nhẹ — force 20px/s)
- Phá hủy: Drop guaranteed power-up
- Spawn: Wave 6+, 5% chance

#### ⬛ Indestructible (Xám đậm — #666666)
- Viền xám đậm, solid fill nhẹ (10% opacity)
- KHÔNG thể phá hủy, đạn nảy lại
- Spawn: Wave 10+, 3% chance, chỉ Large
- Despawn sau 15s, screen wrap

### 6.3. Spawning Rules
```python
asteroids_per_wave = min(5 + wave * 2, 40)  # Cap at 40

# Spawn position: Random trên 4 cạnh màn hình
# Minimum distance from player: 200px
# Spawn direction: Hướng vào trong ± 45° random

# Size distribution per wave:
# Wave 1-3:  70% Large, 20% Medium, 10% Small
# Wave 4-8:  20% Huge, 40% Large, 30% Medium, 10% Small
# Wave 9+:   30% Huge, 30% Large, 25% Medium, 15% Small
```

### 6.4. Splitting Behavior
```
Khi asteroid bị phá hủy:
  1. Spawn 2 asteroids nhỏ hơn 1 size
  2. Hướng: Spread ± 30-60° từ hướng đạn
  3. Tốc độ: Random trong range size mới (nhanh hơn)
  4. Vị trí: Tại vị trí gốc ± 10px
  5. Visual: Particle explosion + screen shake (theo size)
  6. Audio: Crack sound (pitch tùy size)
  7. Coins: Drop tại vị trí (bay ra rồi slow down)
```

---

## 7. Enemies — UFO System

### 7.1. UFO Types (4 loại)

#### 👾 Scout UFO (Wave 3+)
```
HP: 2  |  Điểm: 200  |  Coins: 5
Speed: 100 px/s  |  Size: 25px
Color: Yellow-Green (#AAFF00)

Behavior:
  - Bay ngang qua màn hình (left→right hoặc right→left)
  - Bắn đạn random (không nhắm player)
  - Fire rate: 1 shot/2s
  - Despawn khi ra khỏi màn hình

Visual: Hình bán nguyệt nhỏ, neon glow
```

#### 👾 Hunter UFO (Wave 6+)
```
HP: 5  |  Điểm: 500  |  Coins: 10
Speed: 70 px/s  |  Size: 40px
Color: Orange (#FF6600)

Behavior:
  - Bay zigzag pattern
  - Bắn aimed shots (nhắm player)
  - Fire rate: 1 shot/1.5s
  - Moderate tracking

Visual: Hình bát giác, dual glow rings
```

#### 👾 Bomber UFO (Wave 10+)
```
HP: 3  |  Điểm: 350  |  Coins: 8
Speed: 50 px/s  |  Size: 35px
Color: Red (#FF4444)

Behavior:
  - Bay chậm qua màn hình
  - Thả mines (mine HP: 1, nổ sau 5s, bán kính 80px)
  - Drop rate: 1 mine/3s
  - Mines bắn được (50 điểm/mine)

Visual: Hình tam giác ngược, pulse glow
```

#### 👾 Interceptor UFO (Wave 15+)
```
HP: 4  |  Điểm: 600  |  Coins: 12
Speed: 120 px/s (chase) / 60 px/s (retreat)
Size: 30px
Color: Cyan (#00DDFF)

Behavior:
  - AI: Chase → Fire burst (3 shots) → Retreat → Repeat
  - Rất aggressive, đuổi theo player
  - Dangerous nhất trong các UFO

Visual: Hình mũi tên nhọn, lightning trail
```

### 7.2. UFO Spawn Rules
```
Max 2 UFO cùng lúc
Spawn từ cạnh trái/phải, random Y position
Spawn interval: max(25 - wave * 0.5, 8) giây

Type distribution:
  Wave 3-5:   Scout 100%
  Wave 6-9:   Scout 60%, Hunter 40%
  Wave 10-14: Scout 30%, Hunter 35%, Bomber 35%
  Wave 15+:   Scout 20%, Hunter 25%, Bomber 25%, Interceptor 30%
```

---

## 8. Power-ups & Collectibles

### 8.1. Power-up List (11 loại)

| Icon | Tên | Effect | Duration | Drop% | Từ Wave |
|---|---|---|---|---|---|
| 🛡️ | **Shield** | Bảo vệ 1 hit | 15s / 1 hit | 15% | 1 |
| 🔫 | **Multi-Shot** | 3 đạn spread (±20°) | 10s | 12% | 2 |
| ⚡ | **Rapid Fire** | Fire rate ×2 | 8s | 12% | 1 |
| ⭐ | **Score ×2** | Double all points | 12s | 10% | 3 |
| ⏱️ | **Slow-Mo** | Everything 50% speed (trừ player) | 5s | 8% | 4 |
| 🧲 | **Magnet** | Auto-collect coins & power-ups | 10s | 10% | 2 |
| ❤️ | **Extra Life** | +1 life (instant, max 5) | Instant | 5% | 5 |
| 💣 | **Bomb Pickup** | +1 bomb (instant, max 5) | Instant | 8% | 1 |
| 🔥 | **Piercing** | Bullets pierce through asteroids | 8s | 6% | 6 |
| 🌀 | **Orbital** | 3 orbiting spheres destroy on contact | 12s | 4% | 8 |
| 💫 | **Homing** | Bullets auto-seek nearest target | 6s | 3% | 10 |

### 8.2. Power-up Behavior
```
Spawn: Khi Medium/Large asteroid bị phá hủy
  - Base chance: 12% (tăng theo Magnet Range upgrade)
  - Magnetic asteroid: 100% guaranteed drop

Visual: 
  - Floating tại chỗ, xoay chậm
  - Neon glow theo type color
  - Nhấp nháy nhanh ở 3 giây cuối (despawn warning)
  
Lifetime: 8 giây
Collect radius: 30px (base), 200px (khi Magnet active)
```

### 8.3. Stacking Rules
```
Cùng loại:  Reset duration (không stack number)
Khác loại:  Stack (chạy đồng thời)

Combo đặc biệt (visual feedback khi combo):
  Multi-Shot + Piercing = 3 tia laser xuyên suốt ⚡
  Rapid Fire + Homing = Mưa đạn tự tìm mục tiêu 🌧️
  Slow-Mo + Score ×2 = Farm điểm cực mạnh 💰
  Shield + Orbital = Tank mode 🛡️
```

### 8.4. Coins System
```
Coin tiers:
  🥉 Bronze: 1 coin  (Small asteroid, phổ biến)
  🥈 Silver: 3 coins (Medium asteroid)
  🥇 Gold:   5 coins (Large/Gold asteroid)
  💎 Diamond: 10 coins (Boss, rare drops)

Behavior:
  - Spawn với physics nhẹ (fly out random → slow down)
  - Auto-collect range: 50px base / 200px with Magnet
  - Despawn sau 5 giây
  - Sound: Coin clink (pitch increases with consecutive pickups)
```

---

## 9. Weapon System

### 9.1. Default Weapon — Laser
```
Type:       Single shot, thẳng
Damage:     1
Fire rate:  4 shots/s (base, affected by upgrades)
Speed:      400 px/s
Lifespan:   1.5s (fade out cuối)
Visual:     Dải sáng ngắn, màu theo tàu, glow trail
Max on screen: 8 bullets
```

### 9.2. Heat System (Weapon Overheat)
```
Heat gauge: 0 → 100
  Mỗi shot: +5 heat
  Cooldown:  -15 heat/s (khi không bắn)
  Overheat (100): Locked 2 giây, "OVERHEAT!" warning

Visual feedback:
  0-50%:   Đạn màu bình thường (cyan/white)
  50-80%:  Đạn chuyển vàng, ship tint nhẹ cam
  80-99%:  Đạn đỏ, ship glow đỏ mạnh, warning beep
  100%:    Overheat animation, steam particles

Strategic purpose:
  Prevents hold-fire spam → Forces burst-fire rhythm
  Creates decision: "Do I keep shooting or cool down?"
```

### 9.3. Bomb System
```
Starting bombs: 3 (+ upgrades)
Max: 5

Effect khi kích hoạt:
  ✅ Phá hủy: Small & Medium asteroids
  ✅ Gây 2 damage: Large & Huge asteroids
  ✅ Phá hủy: Tất cả enemy bullets & mines
  ✅ Gây 3 damage: UFOs
  ❌ Không damage: Boss
  ❌ Không damage: Indestructible asteroids

Visual sequence:
  1. Flash trắng (0.3s)
  2. Shockwave ring expand từ center
  3. Heavy screen shake
  4. Slow-mo 0.5s
  5. Rain of coins from destroyed objects
  6. Fade to normal
```

---

## 10. Scoring & Combo System

### 10.1. Base Score Table

| Object | Base Score |
|---|---|
| Small Asteroid | 150 |
| Medium Asteroid | 100 |
| Large Asteroid | 50 |
| Huge Asteroid | 20 |
| Gold Asteroid (any) | Base × 3 |
| Explosive Asteroid | Base × 2 |
| Scout UFO | 200 |
| Hunter UFO | 500 |
| Bomber UFO | 350 |
| Interceptor UFO | 600 |
| Mine (shot) | 50 |
| Boss | 5,000–25,000 |

### 10.2. Combo System

```python
combo_counter = 0
combo_timer = 0
COMBO_TIMEOUT = 2.5  # giây giữa 2 kills

def on_kill():
    combo_counter += 1
    combo_timer = COMBO_TIMEOUT
    
    if combo_counter >= 50:
        multiplier = 10   # "🔥 LEGENDARY!" popup + screen flash
    elif combo_counter >= 20:
        multiplier = 5    # "💀 INSANE!" popup
    elif combo_counter >= 10:
        multiplier = 3    # "⚡ AMAZING!" popup
    elif combo_counter >= 5:
        multiplier = 2    # "✨ GREAT!" popup
    else:
        multiplier = 1
    
    final_score = base_score * multiplier * score_bonus * (2 if score_x2 else 1)

def on_frame(delta):
    combo_timer -= delta
    if combo_timer <= 0:
        combo_counter = 0  # "Combo Lost" fade out
```

### 10.3. Wave Clear Bonus
```
Time Bonus:     max(0, 30 - clear_time) × 50
Perfect Bonus:  1000 if no lives lost
Combo Bonus:    max_combo × 10
No Bomb Bonus:  500 if no bombs used

Total = (Time + Perfect + Combo + NoBomb) × wave_number
```

---

## 11. Level Progression & Difficulty

### 11.1. Zone System

| Zone | Waves | Tên | Background Theme | New Elements |
|---|---|---|---|---|
| 1 | 1–5 | **Asteroid Belt** | Clean stars | Tutorial, Normal asteroids |
| 2 | 6–10 | **Nebula Field** | Purple/blue nebula clouds | Gold, Explosive + Scout UFO |
| 3 | 11–15 | **Comet Storm** | Comet trails animated | Toxic, Ice + Hunter UFO |
| 4 | 16–20 | **Dark Sector** | Very dark, lightning | Magnetic + Bomber UFO |
| 5 | 21–25 | **Black Hole** | Distortion, warped stars | Indestructible + Interceptor + Gravity |
| 6+ | 26+ | **Infinite Void** | Random/dynamic | All mixed, difficulty cap, endless |

### 11.2. Difficulty Scaling

```python
def asteroids_per_wave(wave):
    return min(5 + wave * 2, 40)  # Cap at 40

def speed_multiplier(wave):
    return min(1.0 + wave * 0.03, 2.5)  # Cap at ×2.5

def ufo_interval(wave):
    return max(25 - wave * 0.5, 8)  # Min 8 seconds

def powerup_chance(wave):
    return min(12 + wave * 0.3, 25)  # Base 12%, cap 25%
```

### 11.3. Difficulty Curve
```
Difficulty
    │
100 │                                          _______________
    │                                    __---
 80 │                               __--
    │                          __--
 60 │                     __--
    │                __--
 40 │           __--
    │      __--        ← Smooth ramp, không đột ngột
 20 │  __--
    │-
  0 │───────────────────────────────────────────────────────
    0    5    10   15   20   25   30   35   40   45   50
                              Wave
```

### 11.4. Tutorial (Wave 1-2, First Time Only)
```
Wave 1:
  Step 1: "Drag left joystick to MOVE" → highlight joystick
  Step 2: "Tap FIRE to SHOOT" → highlight fire button
  Step 3: "Destroy all asteroids!" → 3 slow Large asteroids
  Step 4: "Collect coins!" → highlight dropped coins
  Guaranteed Shield drop

Wave 2:
  Tip: "Build COMBOS by destroying quickly!"
  5 asteroids, mixed sizes
  Guaranteed Rapid Fire drop
  
Tutorial flags saved → only shown once
```

---

## 12. Boss Battles

### Boss 1: "ROCK TITAN" (Wave 5)
```
Visual:  Asteroid khổng lồ (120px), viền vàng, cracks phát sáng
HP: 30  |  Điểm: 5,000  |  Coins: 50

Phase 1 (100%-50% HP):
  - Trôi chéo, bounce off edges
  - Attack: 3 fragment shots mỗi 4s (aimed)
  - Attack: Ring of 8 small asteroids mỗi 8s (360°)
  - Speed: 40 px/s

Phase 2 (50%-0% HP):
  - Speed ×1.5, cracks sáng đỏ hơn
  - Attacks faster (mỗi 3s)
  - NEW: Charge dash at player (telegraph: glow 1.5s → dash)

Defeat: Slow-mo 2s → explosion → 10 coins + rare power-up
Reward: Unlock Zone 2
```

### Boss 2: "NEBULA QUEEN" (Wave 10)
```
Visual:  UFO lớn bát giác (80px), viền tím, hexagonal shield
HP: 50 (Shield: 15 riêng)  |  Điểm: 10,000  |  Coins: 80

Phase 1 — Shield Active (Shield HP > 0):
  - Di chuyển pattern hình 8
  - Shield absorb all damage
  - Spawn 2 Scout UFO mỗi 10s
  - 5-way spread shot mỗi 5s
  - Weak point: Shield flicker mỗi 6s (1.5s window → ×2 damage)

Phase 2 — Exposed (Shield HP = 0):
  - Chuyển tím → đỏ, speed ×2
  - Aimed shots mỗi 1s
  - Teleport + explosion mỗi 8s
  - Ring of 8 mines mỗi 12s

Defeat: Chain explosion → 80 coins + 2 rare power-ups
Reward: Unlock Zone 3
```

### Boss 3: "COMET WORM" (Wave 15)
```
Visual:  Rắn gồm 8 segments (mỗi segment 30px tròn), head đỏ cam, body vàng
HP: 40 (chỉ Head nhận damage)  |  Điểm: 15,000  |  Coins: 120

Phase 1 (100%-60%):
  - Sine wave movement
  - Body segments follow head (snake)
  - Fireball aimed mỗi 3s
  - Chiến thuật: Find angle past body to hit head

Phase 2 (60%-30%):
  - Speed ×1.5
  - Cuộn thành vòng tròn + spin (3s), spawn small asteroids

Phase 3 (30%-0%):
  - Body segments detach (mỗi 5s → become Medium asteroid)
  - Head exposed more, speed ×2
  - Fireball mỗi 1.5s

Defeat: Chain explosion tail→head → massive coins
Reward: Unlock Zone 4
```

### Boss 4: "VOID SENTINEL" (Wave 20)
```
Visual:  Hình thoi lớn (100px), viền blue electric, 4 turret nodes
HP: 60 (Core) + 10×4 (Turrets)  |  Điểm: 20,000  |  Coins: 160

Phase 1 — Turrets Active:
  - Đứng giữa, xoay chậm
  - 4 turrets bắn aimed shots mỗi 2s each
  - Core invincible while turrets alive
  - Destroy all 4 turrets first

Phase 2 — Core Exposed:
  - Starts moving
  - Laser beam sweep (360° rotation, 2s)
  - EMP pulse mỗi 10s → disable player weapon 2s
  - Spawn 4 homing mines

Phase 3 (HP < 25%):
  - Regen 1 turret
  - All attacks ×1.5 speed
  - Continuous laser sweep

Defeat: Implosion → supernova | Unlock Zone 5
```

### Boss 5: "BLACK HOLE KING" (Wave 25)
```
Visual:  Accretion disk (150px), center dark, viền white→orange→red
HP: 100  |  Điểm: 25,000  |  Coins: 250

Phase 1 (100%-70%):
  - Constant gravity pull on player
  - Summon asteroids → fling random directions
  - Gravity pulse mỗi 8s (strong pull 1s)
  - 3 weak-point nodes orbiting boss

Phase 2 (70%-40%):
  - Gravity ×2
  - Event horizon ring (shrinking circle, touch = death)
  - Teleport asteroids randomly
  - Nodes spin faster

Phase 3 (40%-0%):
  - Gravity REVERSES (pushes player away → hard to shoot)
  - Asteroid rain from top
  - Mini black hole fragments
  - Continuous screen shake

Defeat: Epic implosion → supernova → 250 coins + 5 power-ups
"CONGRATULATIONS! INFINITE MODE UNLOCKED!"
Credits roll (skippable)
```

---

## 13. Controls & Input

### 13.1. Control Modes (4 options)

#### Mode A: Floating Joystick (Default)
```
Left side: Touch anywhere → joystick appears at touch point
  - Drag = move ship in direction
  - Release = joystick fades, ship keeps momentum
  - Dead zone: 10%

Right side:
  - [FIRE] button (80×80dp) — bottom right
  - [BOMB] button (60×60dp) — above fire
  - [SPECIAL] button (60×60dp) — between fire & bomb
  - [PAUSE] button (40×40dp) — top right corner

Ship rotation: Auto-rotate toward movement direction
```

#### Mode B: Fixed Joystick
```
Same as Floating but joystick always at bottom-left corner
Better for players who prefer consistent position
```

#### Mode C: Twin-Stick
```
Left joystick: Movement
Right joystick: Aim + auto-fire when active
  - Ship rotates toward right joystick direction
  - Bullets fire in right joystick direction
  - Release right joystick = stop firing

[BOMB] and [SPECIAL] buttons repositioned above right joystick
```

#### Mode D: Classic (Rotate + Thrust)
```
Left side:
  - [ROTATE LEFT] button
  - [ROTATE RIGHT] button
  - [THRUST] button

Right side:
  - [FIRE] button
  - [BOMB] button
  - [SPECIAL] button

Ship does NOT auto-rotate
Most challenging, authentic Asteroids feel
Hardcore mode
```

### 13.2. Button Specs
```
Touch target minimum: 44×44dp (accessibility)
Opacity: Adjustable 30%–100% (default 70%)
Position: Adjustable via Settings
Haptic feedback: Nhẹ khi tap (nếu Vibration ON)

FIRE button:
  Tap = single shot
  Hold = auto-fire (continuous, affected by heat)
  Visual: Glow khi active

BOMB button:
  Tap = instant bomb (no confirmation)
  Shows remaining count (e.g., "💣3")
  Gray when 0 bombs

SPECIAL button:
  Tap = activate ability
  Shows cooldown (circular progress overlay)
  Glow + pulse khi ready
  Gray + timer when cooling down
```

---

## 14. HUD & In-Game UI

### 14.1. HUD Layout

```
┌──────────────────────────────────────────────────────────────────┐
│ SCORE:12,450  HIGH:69,220   ❤️❤️❤️  💣×3  COMBO:12× (×3!)      │
│ WAVE: 7  "Nebula Field"         [Active Power-ups: 🛡️8s ⚡4s]  │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│                                                                  │
│                                                                  │
│                         GAME AREA                                │
│                                                                  │
│              × 12                                                │
│           "AMAZING!"  (combo popup, center, transparent)         │
│                                                                  │
│                                                                  │
│                                                                  │
│                                                                  │
│   ┌───┐           [HEAT BAR]                    [BOMB 💣3]      │
│   │JOY│           ████████░░                    [SPEC ⚡]       │
│   │   │                                         [FIRE 🔫]       │
│   └───┘                                                    ⏸    │
└──────────────────────────────────────────────────────────────────┘
```

### 14.2. HUD Elements

#### Score Display
```
Font: Monospace bold, neon glow
Size: 24px
Color: White (normal), Gold (Score ×2 active)
Animation: Smooth lerp (rolls up, doesn't jump)
```

#### Lives Display
```
Heart icons ❤️ (max 5)
Lose life: Heart explodes into red particles
Gain life: Heart scales in with bounce
Last life: Blinking + red glow + heartbeat SFX
```

#### Combo Counter
```
Position: Center-right, semi-transparent (40% opacity)
Font size scales with combo:
  1-4:   32px
  5-9:   48px + "GREAT!" text
  10-19: 64px + "AMAZING!" text  
  20-49: 80px + "INSANE!" text + screen edge glow
  50+:   96px + "LEGENDARY!" + full screen flash

Color: White → Yellow → Orange → Red (by level)
Animation: Scale punch on each increment
```

#### Heat Bar
```
Width: 150px  |  Height: 8px  |  Position: Bottom center
Color gradient: Blue (0%) → Yellow (50%) → Red (80%) → Flash Red (100%)
"OVERHEAT!" text flashes at 100%
```

#### Wave Announcement
```
"WAVE 7" — center screen, bold 64px
Scale: 0 → 1.2 → 1.0 → fade out (1.5s total)
Sub-text: Zone name in smaller font
```

### 14.3. Screen Effects
```
Damage:      Red flash (0.15s) + chromatic aberration + screen shake
Low HP:      Persistent red vignette + heartbeat SFX
Bomb:        White flash (0.3s) + heavy shake + slow-mo 0.5s + radial blur
Boss Warning: Red flash ×3 + siren SFX + "⚠️ WARNING ⚠️" text
Wave Clear:  Green flash + score popups + victory "ding!"
```

---

## 15. Visual Style & Art Direction

### 15.1. Art Style
- **Primary**: Neon Wireframe / Vector Art
- **Inspiration**: Asteroids (1979) + Geometry Wars + Tron Legacy
- **Rendering**: Outline-only shapes, neon glow, additive blending
- **Background**: Deep black (#0A0A0A) + subtle animated star field

### 15.2. Color Palette

| Element | Color | Hex | Glow |
|---|---|---|---|
| Player Ship | Cyan | `#00FFFF` | Strong |
| Player bullets | White→Cyan | `#FFFFFF` | Medium |
| Normal Asteroid | Light Gray | `#CCCCCC` | Subtle |
| Gold Asteroid | Gold | `#FFD700` | Strong + sparkle |
| Explosive Asteroid | Red | `#FF4444` | Pulse |
| Toxic Asteroid | Green | `#44FF44` | Mist particles |
| Ice Asteroid | Blue | `#4488FF` | Crystal particles |
| Magnetic Asteroid | Purple | `#AA44FF` | Electric arcs |
| Indestructible | Dark Gray | `#666666` | None |
| Scout UFO | Yellow-Green | `#AAFF00` | Steady |
| Hunter UFO | Orange | `#FF6600` | Dual rings |
| Bomber UFO | Red | `#FF4444` | Pulse |
| Interceptor UFO | Cyan | `#00DDFF` | Lightning trail |
| Coins | Gold | `#FFD700` | Sparkle |
| Power-ups | Per type | Various | Glow + rotate |
| UI Text | White | `#FFFFFF` | Subtle |
| Danger/Warning | Red | `#FF0000` | Flash |
| Success | Green | `#00FF00` | Pulse |
| Background | Black | `#0A0A0A` | — |
| Stars | White dim | `#FFFFFF` @20% | — |

### 15.3. Neon Glow Implementation (Godot)

```gdscript
# Method 1: WorldEnvironment HDR Bloom (recommended)
# Project Settings → Rendering → Viewport → HDR 2D = ON
# Add WorldEnvironment node with:
#   Background Mode: Canvas
#   Glow: Enabled
#   HDR Threshold: 1.0
#   Glow Intensity: 0.8
#   Glow Bloom: 0.1
# Set object modulate to RAW color values > 1.0 for glow

# Method 2: Custom CanvasItem Shader (for per-object control)
shader_type canvas_item;
uniform vec4 glow_color : source_color = vec4(0, 1, 1, 1);
uniform float glow_intensity : hint_range(0, 5) = 2.0;
uniform float glow_size : hint_range(0, 20) = 4.0;

void fragment() {
    vec4 base = texture(TEXTURE, UV);
    vec4 glow = vec4(0.0);
    float total = 0.0;
    for (float x = -glow_size; x <= glow_size; x += 1.0) {
        for (float y = -glow_size; y <= glow_size; y += 1.0) {
            float weight = 1.0 / (1.0 + length(vec2(x, y)));
            glow += texture(TEXTURE, UV + vec2(x, y) * TEXTURE_PIXEL_SIZE) * weight;
            total += weight;
        }
    }
    glow /= total;
    COLOR = base + glow * glow_color * glow_intensity;
}
```

### 15.4. Background Layers (Parallax)
```
Layer 1 (farthest): Tiny stars, 5% parallax speed
Layer 2:            Medium stars, 10% speed
Layer 3:            Nebula clouds (per zone), 15% speed
Layer 4 (nearest):  Space dust particles, 20% speed

Zone backgrounds:
  Zone 1: Clean stars only
  Zone 2: Stars + purple/blue nebula
  Zone 3: Stars + animated comet trails
  Zone 4: Very dark + occasional lightning
  Zone 5: Warped stars + center distortion
  Zone 6: Random mix + dynamic changes
```

### 15.5. Ship Designs
```
All ships: Neon wireframe outline, unique silhouettes

Phoenix:  Classic triangle (3 edges), cyan outline
Viper:    Long pointed arrow, lime outline
Nebula:   Small diamond, purple outline
Titan:    Pentagon (5 edges, larger), orange outline
Shadow:   Thin stealth triangle, gray flickering outline
Omega:    Hexagon with side wings, red-gold outline
```

---

## 16. Audio Design

### 16.1. Sound Effects

| Category | Sound | Description | Priority |
|---|---|---|---|
| Player | `ship_thrust` | Engine hum, continuous | Medium |
| Player | `ship_shoot` | Retro "pew" laser | High |
| Player | `ship_death` | Explosion + static | Critical |
| Player | `ship_respawn` | Shield woosh | High |
| Player | `ship_overheat` | Steam hiss + beep | Medium |
| Player | `ship_dash` | Whoosh burst | High |
| Asteroid | `asteroid_hit` | Impact crunch | High |
| Asteroid | `asteroid_split` | Rock crack | High |
| Asteroid | `asteroid_explode` | Small pop | Medium |
| Asteroid | `gold_hit` | Sparkle + coin | High |
| Asteroid | `explosive_boom` | Big explosion | Critical |
| Asteroid | `ice_shatter` | Glass break | Medium |
| Asteroid | `toxic_hiss` | Gas release | Medium |
| Power-up | `powerup_collect` | Satisfying "ding!" | High |
| Power-up | `shield_activate` | Force field hum | Medium |
| Power-up | `shield_break` | Glass shatter | High |
| Combo | `combo_5` | "Great!" jingle | Medium |
| Combo | `combo_10` | "Amazing!" jingle | Medium |
| Combo | `combo_20` | "Insane!" epic jingle | High |
| Combo | `combo_50` | Legendary fanfare | Critical |
| Combo | `combo_lost` | Sad descending tone | Low |
| UFO | `ufo_appear` | Eerie whoosh | Medium |
| UFO | `ufo_shoot` | Different laser | Medium |
| UFO | `ufo_death` | Mechanical explosion | High |
| Boss | `boss_warning` | Siren alarm | Critical |
| Boss | `boss_hit` | Heavy impact | High |
| Boss | `boss_death` | Epic explosion seq. | Critical |
| UI | `ui_tap` | Soft click | Low |
| UI | `wave_start` | Countdown beeps | Medium |
| UI | `wave_clear` | Victory jingle | High |
| UI | `game_over` | Dramatic ending | High |
| UI | `high_score` | Celebration fanfare | Critical |
| Coin | `coin_collect` | Clink (pitch varies) | Medium |
| Bomb | `bomb_activate` | Whoosh + explosion | Critical |
| BP | `bp_level_up` | Level up fanfare | High |
| BP | `bp_claim` | Reward claim ding | Medium |

### 16.2. Music Tracks

| Track | Context | Mood | BPM | Loop |
|---|---|---|---|---|
| `main_menu` | Hub | Chill synthwave | 90 | Yes |
| `zone_1` | Asteroid Belt | Light electronic | 110 | Yes |
| `zone_2` | Nebula Field | Deep mysterious synth | 120 | Yes |
| `zone_3` | Comet Storm | Fast urgent | 130 | Yes |
| `zone_4` | Dark Sector | Dark ambient bass | 125 | Yes |
| `zone_5` | Black Hole | Epic orchestral+electronic | 140 | Yes |
| `boss_battle` | Boss fights | Intense dramatic | 150 | Yes |
| `game_over` | Results | Melancholic synth | 80 | No |
| `victory` | Boss defeated | Triumphant fanfare | 130 | No |
| `shop` | Hangar/Upgrades/Shop | Chill lo-fi synth | 85 | Yes |
| `event` | Special events | Upbeat electronic | 135 | Yes |

### 16.3. Audio Bus Layout (Godot)
```
Master
├── Music (separate volume)
├── SFX
│   ├── Player
│   ├── Enemies
│   ├── Environment
│   └── UI
└── Ambient
```

---

## 17. Particle Effects & Juice

### 17.1. Particle Systems

| Effect | Trigger | Duration | Count | Visual |
|---|---|---|---|---|
| Engine Trail | Thrusting | Continuous | 20/s | Cyan dots fading behind |
| Bullet Trail | Bullet moving | Continuous | 10/s | Short trail |
| Asteroid Explode S | Small die | 0.5s | 15 burst | Small fragments |
| Asteroid Explode M | Medium die | 0.8s | 25 burst | Medium fragments + sparks |
| Asteroid Explode L | Large die | 1.0s | 40 burst | Large fragments + shockwave |
| Gold Sparkle | Gold exists | Continuous | 5/s | Gold star sparkles |
| Explosive Boom | Explosive die | 1.5s | 60 burst | Fire + smoke + shockwave |
| Toxic Cloud | Toxic die | 5.0s | 30/s | Green mist expanding |
| Ice Shatter | Ice die | 1.0s | 30 burst | Blue crystal fragments |
| Shield Bubble | Shield on | Continuous | 8/s | Hex particles orbiting |
| Shield Break | Shield destroyed | 0.5s | 20 burst | Glass shards |
| Coin Collect | Pickup | 0.3s | 8 burst | Gold sparkle inward |
| Player Death | Player die | 2.0s | 80 burst | Massive explosion |
| Bomb Shockwave | Bomb | 1.5s | 100 burst | White ring expand |
| Boss Aura | Boss exists | Continuous | 15/s | Glow particles orbit |
| Boss Death | Boss defeated | 3.0s | 200 burst | Epic multi-explosion |

### 17.2. Screen Shake
```
LIGHT:   2px,  0.10s  (small asteroid hit)
MEDIUM:  4px,  0.15s  (large asteroid hit)
HEAVY:   8px,  0.25s  (explosive asteroid, player hit)
EXTREME: 15px, 0.50s  (bomb, boss attack, boss defeat)
```

### 17.3. Slow Motion
```
Triggers: Boss phase change, Bomb, Player death, Combo milestone 50+
Duration: 0.3s–2.0s
Engine.time_scale = 0.2 → restore to 1.0
Player input remains responsive during slow-mo
```

---

## 18. Meta-Progression Systems

### 18.1. Player Level (XP System)
```
XP Sources:
  - Score earned in game: score / 100 = XP
  - Wave completed: 10 XP per wave
  - Boss defeated: 50 XP
  - Daily mission completed: 25 XP each
  - Weekly mission completed: 100 XP each

Level Formula:
  XP needed = 100 + (level * 50)
  Level 1→2: 150 XP
  Level 2→3: 200 XP
  Level 10→11: 600 XP
  Max level: 50

Level Rewards:
  Every level: 💰100 + 💎1
  Every 5 levels: Bonus 💰500 + ship skin unlock
  Level 10: Unlock Zone 2 shortcut
  Level 25: Exclusive ship skin "VETERAN"  
  Level 50: Exclusive ship skin "LEGEND" + profile frame

Purpose: Shows progression, gates some content softly, BP XP source
```

### 18.2. Achievement System
```
See Appendix (Section 33) for full list

Achievement rewards: Coins, Gems, Profile badges
Displayed on: Profile card, Leaderboard entry
Google Play Games Services integration
```

### 18.3. Stats Tracking
```
Lifetime stats (always tracked):
  - Total score (all time)
  - Total asteroids destroyed
  - Total UFOs destroyed
  - Total bosses defeated
  - Total coins earned
  - Total play time
  - Total games played
  - Best score
  - Best wave
  - Best combo
  - Total bombs used
  - Total power-ups collected
  - Total deaths
```

---

## 19. Battle Pass / Season System

### 19.1. Overview
```
Tên:        "GALACTIC PASS"
Duration:   30 ngày / season
Tracks:     Free Track + Premium Track
Tiers:      30 tiers (1 tier/ngày nếu active)
Price:      💎 300 gems ($4.99 equivalent) cho Premium Track
```

### 19.2. XP Sources (Battle Pass XP)
```
BP XP khác với Player XP:

Playing game:
  - Per wave completed: 5 BP XP
  - Per game over: 10 BP XP base
  - Per boss defeated: 25 BP XP

Missions:
  - Daily mission: 15 BP XP each (3 dailies = 45/day)
  - Weekly mission: 50 BP XP each (3 weeklies = 150/week)
  
Bonus:
  - Daily login: 10 BP XP
  - Watch ad: 5 BP XP (max 3/day = 15/day)

XP per tier: 100 BP XP
Daily cap estimate: ~70-100 BP XP (active player)
→ ~30 days to complete = 1 full season
```

### 19.3. Reward Tiers

```
┌──────────────────────────────────────────────────────────────────┐
│  🎫 GALACTIC PASS — Season 1: "NEON FRONTIER"                   │
│  Days remaining: 23    Tier: 8/30     BP XP: 45/100             │
│  ████████░░░░░░░░░░░░░░░░░░░░░░ 27%                            │
│                                                                  │
│  [🔓 UNLOCK PREMIUM — 💎300]                                    │
│                                                                  │
│  Tier │ Free Track              │ Premium Track                  │
│  ─────┼─────────────────────────┼────────────────────────────────│
│   1   │ 💰 200                  │ 💎 5                           │
│   2   │ 💰 200                  │ Ship Skin: Phoenix "EMBER"     │
│   3   │ 💣 ×2 (bombs)           │ 💰 500                        │
│   4   │ 💰 300                  │ Trail Effect: "FIRE"           │
│   5   │ 💎 3                    │ ⭐ Profile Frame: "BRONZE"     │
│   6   │ 💰 300                  │ 💎 10                          │
│   7   │ ❤️ ×1 (extra life)      │ Ship Skin: Viper "PHANTOM"    │
│   8   │ 💰 400                  │ 💰 1000                       │
│   9   │ 💰 400                  │ Explosion Effect: "SPARKLE"    │
│  10   │ 💎 5 + Ship Skin (R)    │ 💎 15 + Exclusive "WAVE" skin │
│  11   │ 💰 500                  │ Ship Skin: Nebula "COSMIC"     │
│  12   │ 💰 500                  │ 💰 1000                       │
│  13   │ 💣 ×3                   │ 💎 10                          │
│  14   │ 💰 600                  │ Trail Effect: "ICE"            │
│  15   │ 💎 5 + Random Power-up  │ 💎 20 + Exclusive skin         │
│  16   │ 💰 600                  │ Ship Skin: Titan "FORTRESS"    │
│  17   │ 💰 700                  │ 💰 1500                       │
│  18   │ 💰 700                  │ Explosion Effect: "NEON BURST" │
│  19   │ 💰 800                  │ 💎 15                          │
│  20   │ 💎 8 + Profile Badge    │ 💎 25 + Exclusive frame        │
│  21   │ 💰 800                  │ Ship Skin: Shadow "VOID"       │
│  22   │ 💰 900                  │ 💰 2000                       │
│  23   │ 💰 900                  │ Trail Effect: "LIGHTNING"      │
│  24   │ 💰 1000                 │ 💎 20                          │
│  25   │ 💎 10 + Skin (Rare)     │ 💎 30 + LEGENDARY Skin         │
│  26   │ 💰 1000                 │ Ship Skin: Omega "SUPERNOVA"   │
│  27   │ 💰 1200                 │ 💰 3000                       │
│  28   │ 💰 1200                 │ Explosion: "GALAXY BURST"      │
│  29   │ 💰 1500                 │ 💎 25                          │
│  30   │ 💎 15 + EPIC SKIN       │ 💎 50 + 🏆 SEASON CHAMPION    │
│       │                         │ (Animated legendary skin +      │
│       │                         │  exclusive animated frame +     │
│       │                         │  "Season 1 Veteran" badge)      │
│  ─────┴─────────────────────────┴────────────────────────────────│
│                                                                  │
│  Free Total:  ~💰12,000 + 💎46 + 4 skins + badges               │
│  Premium Total: ~💰10,000 + 💎225 + 10 exclusive skins +         │
│                 3 trail effects + 3 explosion effects +           │
│                 animated frame + badge                            │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### 19.4. Cosmetic Items (from Battle Pass)

#### Ship Skins
```
Thay đổi: Outline color, glow color, engine trail color
Không thay đổi: Ship shape, stats, ability

Tiers:
  🟢 Common:    Solid color variants (Red, Blue, Green...)
  🔵 Rare:      Gradient colors + enhanced glow
  🟣 Epic:      Animated outline (pulse/wave pattern)
  🟡 Legendary: Animated + unique particle trail + sound
```

#### Trail Effects
```
Replace engine trail particles with themed effects:
  "FIRE":      Orange/red flame trail
  "ICE":       Blue crystal particles
  "LIGHTNING": Yellow electric sparks
  "RAINBOW":   Cycling rainbow colors (Legendary)
```

#### Explosion Effects
```
Replace asteroid explosion particles:
  "SPARKLE":    Star-shaped particles
  "NEON BURST": Extra-bright neon ring
  "GALAXY":     Mini galaxy swirl (Legendary)
```

#### Profile Frames & Badges
```
Frames around player name on leaderboard/results screen
Badges shown next to name
Both purely cosmetic, show achievement/dedication
```

### 19.5. Season Transition
```
End of season:
  1. "Season 1 Complete!" celebration screen
  2. Unclaimed rewards → moved to inbox (7 day expiry)
  3. BP progress resets
  4. New season starts immediately
  5. Premium status resets (must re-purchase)
  6. Season-exclusive items cannot be obtained after

Between seasons (1-2 day break):
  - "Coming Soon: Season 2" teaser on Hub
  - Preview of new season theme & rewards
```

---

## 20. Daily & Weekly Systems

### 20.1. Daily Login Reward
```
┌──────────────────────────────────────────┐
│           🎁 DAILY REWARD                │
│                                          │
│  Day 1: 💰100  ✅                        │
│  Day 2: 💰150  ✅                        │
│  Day 3: 💰200  ◀── TODAY                │
│  Day 4: 💰300                            │
│  Day 5: 💎 5                             │
│  Day 6: 💰500                            │
│  Day 7: 💎15 + 🎨 Random Skin           │
│                                          │
│  [COLLECT]                               │
│  [📺 ×2 REWARD — Watch Ad]              │
│                                          │
│  Streak: 3 days 🔥                      │
│  Miss a day → streak resets to Day 1     │
└──────────────────────────────────────────┘

Total 7-day cycle: 💰1,250 + 💎20 + 1 random skin
Cycles indefinitely
```

### 20.2. Daily Missions (3/day, reset at midnight UTC)
```
Mission Pool (random 3 selected each day):

  "Destroy 50 asteroids"          → 💰100 + 15 BP XP
  "Reach Wave 5"                  → 💰100 + 15 BP XP
  "Build a 10× combo"            → 💰150 + 15 BP XP
  "Collect 3 power-ups in 1 game"→ 💰100 + 15 BP XP
  "Destroy 1 UFO"                → 💰120 + 15 BP XP
  "Use 1 bomb"                   → 💰80  + 15 BP XP
  "Play 3 games"                 → 💰100 + 15 BP XP
  "Earn 5,000 score in 1 game"   → 💰150 + 15 BP XP
  "Collect 100 coins in 1 game"  → 💰100 + 15 BP XP
  "Reach Wave 10"                → 💰200 + 15 BP XP

Bonus: Complete all 3 dailies → 💎3 + 30 BP XP extra
```

### 20.3. Weekly Missions (3/week, reset Monday 00:00 UTC)
```
Mission Pool (random 3 selected each week):

  "Destroy 500 asteroids"         → 💰500 + 50 BP XP
  "Defeat 1 boss"                 → 💎5   + 50 BP XP
  "Reach Wave 15"                 → 💰800 + 50 BP XP
  "Build a 30× combo"            → 💎5   + 50 BP XP
  "Destroy 10 UFOs"              → 💰600 + 50 BP XP
  "Play 15 games"                → 💰500 + 50 BP XP
  "Earn total 50,000 score"      → 💰800 + 50 BP XP
  "Collect 20 power-ups"         → 💰500 + 50 BP XP
  "Use 3 different ship types"   → 💰600 + 50 BP XP
  "Earn 1,000 coins total"       → 💎5   + 50 BP XP

Bonus: Complete all 3 weeklies → 💎10 + 100 BP XP extra
```

### 20.4. Mission UI

```
┌──────────────────────────────────────────────────────────────────┐
│  ← Back                    🎯 MISSIONS                          │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ─── DAILY (Resets in 14:23:45) ───                             │
│                                                                  │
│  ✅ Destroy 50 asteroids    32/50     💰100  [CLAIM]            │
│  ⬜ Reach Wave 5            0/1       💰100                     │
│  ⬜ Build 10× combo         Best: 7   💰150                     │
│                                                                  │
│  All 3 complete: 💎3 bonus   [0/3 done]                         │
│                                                                  │
│  ─── WEEKLY (Resets in 4d 14:23:45) ───                         │
│                                                                  │
│  ⬜ Destroy 500 asteroids   127/500   💰500                     │
│  ⬜ Defeat 1 boss           0/1       💎5                       │
│  ⬜ Play 15 games           4/15      💰500                     │
│                                                                  │
│  All 3 complete: 💎10 bonus  [0/3 done]                         │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 21. Social Features

### 21.1. Leaderboard
```
Google Play Games Services integration

Leaderboards:
  🏆 All-Time High Score
  🏆 Best Wave Reached  
  🏆 Best Combo
  🏆 Weekly Score (resets every Monday)

Display: Player name + score + rank + profile frame + badge
Filter: Global / Friends / Country
```

### 21.2. Share
```
Triggers:
  - Game Over screen: [📤 SHARE] button
  - New high score: Auto-prompt
  - Boss defeated: "Share your victory!"
  - Achievement earned: Optional share

Share content:
  - Auto-generated image (score, wave, ship used)
  - Text: "I scored 12,450 in Neon Asteroids! Can you beat me? 🚀"
  - Link to Play Store
```

### 21.3. Profile Card
```
┌──────────────────────────────────┐
│  ╔══════════════════════════╗    │
│  ║  [Avatar Frame]         ║    │
│  ║  Player Name             ║   │
│  ║  🏆 Level 12             ║   │
│  ║  🎖️ Season 1 Veteran     ║   │
│  ╚══════════════════════════╝    │
│                                  │
│  Best Score:    69,220           │
│  Best Wave:     23               │
│  Best Combo:    47×              │
│  Favorite Ship: Viper MK-I      │
│  Play Time:     12h 34m         │
│  Asteroids:     4,521 destroyed │
│                                  │
│  Achievements: 12/20            │
│  [🎖️] [🎖️] [🎖️] [🎖️] [⬜]     │
│                                  │
└──────────────────────────────────┘
```

---

## 22. Monetization

### 22.1. Philosophy
```
Nguyên tắc:
  ✅ F2P — Free to download and play ALL gameplay content
  ✅ No Pay-to-Win — IAPs are cosmetics + convenience only
  ✅ No forced ads — Only opted-in rewarded ads
  ✅ Fair progression — Everything unlockable through gameplay
  ✅ Respectful — Max 1 offer popup per session, skip = no penalty
```

### 22.2. Revenue Streams

```
Revenue Mix Target:
  💰 IAP:          50% of revenue
  📺 Rewarded Ads: 30% of revenue
  🎫 Battle Pass:  20% of revenue
```

### 22.3. In-App Purchases (IAP)

#### Coin Packs
| Pack | Coins | Price | Bonus | Best Value |
|---|---|---|---|---|
| Handful | 💰 500 | $0.99 | — | |
| Pile | 💰 1,200 | $1.99 | +20% | |
| Chest | 💰 3,500 | $4.99 | +40% | |
| Vault | 💰 8,000 | $9.99 | +60% | ⭐ |
| **Mega Vault** | 💰 20,000 | $19.99 | +100% | ⭐⭐ |

#### Gem Packs
| Pack | Gems | Price | Bonus |
|---|---|---|---|
| Few | 💎 10 | $0.99 | — |
| Bunch | 💎 25 | $1.99 | +25% |
| Pouch | 💎 60 | $4.99 | +50% |
| Hoard | 💎 150 | $9.99 | +100% |
| **Treasury** | 💎 400 | $19.99 | +150% |

#### Special Packs & Offers
| Offer | Content | Price | When |
|---|---|---|---|
| **Starter Pack** | 💰2000 + 💎20 + Viper Ship | $1.99 | First 48h |
| **Boss Buster** | 💣5 + ❤️3 + Shield | $0.99 | Before boss wave |
| **No Ads** | Remove ALL ad placements | $4.99 | Settings / Shop |
| **VIP Pass** | ×2 coins permanent + exclusive skin + no ads | $9.99 | Shop |
| **Gem Starter** | 💎50 (first gem purchase only, 5× value) | $0.99 | First time |
| **Weekend Bundle** | 💰5000 + 💎30 + Random Epic Skin | $4.99 | Weekends |

#### Battle Pass Premium
| Item | Price | Content |
|---|---|---|
| **Galactic Pass** | 💎300 ($4.99 equiv) | Unlock Premium track for current season |
| **Galactic Pass +10** | 💎500 ($7.99 equiv) | Premium + skip 10 tiers |

### 22.4. Rewarded Ads Placements

| Placement | Trigger | Reward | Cap |
|---|---|---|---|
| **Continue** | After death | Revive +1 life | 2×/session |
| **Double Coins** | Game Over screen | ×2 coins earned | 1×/game |
| **Daily ×2** | Daily reward popup | ×2 daily reward | 1×/day |
| **Free Bomb** | Out of bombs in-game | +1 bomb | 3×/session |
| **Bonus Coins** | Hub button | 💰100 coins | 5×/day |
| **BP XP Boost** | Mission screen | +5 BP XP | 3×/day |
| **Lucky Spin** | Hub mini-game | Random reward | 3×/day |
| **Energy Refill** | Out of energy | +1 energy | 3×/day |

### 22.5. Energy System (Optional — Soft Gate)
```
IMPORTANT: Energy is OPTIONAL and should be implemented CAREFULLY

Energy: 5 max
  - 1 energy per game
  - Refill: 1 energy every 20 minutes
  - Full refill: ~1 hour 40 minutes
  - Watch ad: +1 energy (3×/day)
  - IAP: Refill energia (💎5)

Purpose:
  - Soft session limiter (5 games then wait or pay)
  - Drives ad views (energy refill ads)
  - Does NOT block first session (start with full energy)

ALTERNATIVE (if testing shows energy hurts retention):
  - Remove energy entirely
  - Replace with "daily bonus games" (5 bonus games/day with ×2 coins)
  - After bonus games: normal play continues, just without ×2 bonus
```

### 22.6. Economy Balance
```
Average coins per session:
  Casual (wave 5):   ~200 coins
  Medium (wave 15):  ~600 coins
  Good (wave 25):    ~1200 coins
  + Daily missions:  ~300 coins/day
  + Weekly missions: ~2000 coins/week
  + Daily login:     ~200 coins/day average

Ship unlock timeline (casual player):
  Viper (5K):    ~5 days
  Nebula (12K):  ~10 days after Viper
  Titan (25K):   ~15 days after Nebula

Total coins for everything: ~120,000 coins
Total time: ~2-3 months casual play
  → Long enough to retain, short enough to not frustrate
  → IAP shortcuts available but never required
```

### 22.7. Shop UI

```
┌──────────────────────────────────────────────────────────────────┐
│  ← Back                      🛒 SHOP                            │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ─── ⭐ SPECIAL OFFERS ─── (time-limited)                       │
│                                                                  │
│  ┌─────────────────────────┐  ┌─────────────────────────┐       │
│  │ 🌟 STARTER PACK         │  │ 🎉 WEEKEND BUNDLE      │       │
│  │ 💰2000 + 💎20           │  │ 💰5K + 💎30 + Skin     │       │
│  │ + Viper Ship Unlock     │  │                         │       │
│  │ [$1.99]  ⏱️ 47:23:11    │  │ [$4.99]  ⏱️ 23:11:45  │       │
│  └─────────────────────────┘  └─────────────────────────┘       │
│                                                                  │
│  ─── 💰 COINS ───                                               │
│  [💰500 $0.99] [💰1.2K $1.99] [💰3.5K $4.99]                   │
│  [💰8K $9.99⭐] [💰20K $19.99⭐⭐]                              │
│                                                                  │
│  ─── 💎 GEMS ───                                                │
│  [💎10 $0.99] [💎25 $1.99] [💎60 $4.99]                        │
│  [💎150 $9.99] [💎400 $19.99]                                   │
│                                                                  │
│  ─── 🎫 BATTLE PASS ───                                        │
│  [Galactic Pass 💎300] [Pass +10 Tiers 💎500]                   │
│                                                                  │
│  ─── 🛡️ PREMIUM ───                                            │
│  [No Ads $4.99] [VIP Pass $9.99]                                │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 23. Save System & Persistence

### 23.1. Save Data Structure
```json
{
  "version": "2.0",
  "player": {
    "name": "Commander",
    "level": 7,
    "xp": 450,
    "coins": 3450,
    "gems": 12,
    "high_score": 69220,
    "best_wave": 13,
    "best_combo": 23,
    "total_asteroids": 1247,
    "total_coins_earned": 8900,
    "total_games": 45,
    "total_playtime_s": 7200,
    "total_bosses": 3,
    "total_ufos": 89,
    "total_deaths": 42
  },
  "ships": {
    "phoenix":  { "unlocked": true,  "equipped": true,  "skin": "default" },
    "viper":    { "unlocked": true,  "equipped": false, "skin": "phantom" },
    "nebula":   { "unlocked": false, "equipped": false, "skin": "default" },
    "titan":    { "unlocked": false, "equipped": false, "skin": "default" },
    "shadow":   { "unlocked": false, "equipped": false, "skin": "default" },
    "omega":    { "unlocked": false, "equipped": false, "skin": "default" }
  },
  "skins_owned": ["phoenix_default", "phoenix_ember", "viper_default", "viper_phantom"],
  "trail_effects_owned": ["default", "fire"],
  "explosion_effects_owned": ["default"],
  "upgrades": {
    "fire_rate": 3,
    "thrust_power": 2,
    "shield_duration": 1,
    "bomb_power": 2,
    "magnet_range": 1,
    "extra_life": 0,
    "extra_bomb": 0,
    "score_bonus": 1,
    "bullet_speed": 0,
    "cooldown_speed": 0
  },
  "zones_unlocked": [1, 2, 3],
  "battle_pass": {
    "season": 1,
    "premium": false,
    "tier": 8,
    "xp": 45,
    "claimed_free": [1,2,3,4,5,6,7],
    "claimed_premium": []
  },
  "missions": {
    "daily": [
      {"id": "destroy_50", "progress": 32, "claimed": false},
      {"id": "wave_5", "progress": 0, "claimed": false},
      {"id": "combo_10", "progress": 7, "claimed": false}
    ],
    "weekly": [
      {"id": "destroy_500", "progress": 127, "claimed": false},
      {"id": "defeat_boss", "progress": 0, "claimed": false},
      {"id": "play_15", "progress": 4, "claimed": false}
    ],
    "daily_reset": "2026-04-17T00:00:00Z",
    "weekly_reset": "2026-04-21T00:00:00Z"
  },
  "daily_reward": {
    "last_claim": "2026-04-16",
    "streak": 3,
    "day_index": 2
  },
  "settings": {
    "control_mode": "floating_joystick",
    "auto_fire": false,
    "left_handed": false,
    "joystick_size": 1.0,
    "joystick_opacity": 0.7,
    "master_volume": 0.8,
    "music_volume": 0.6,
    "sfx_volume": 1.0,
    "vibration": true,
    "screen_shake": true,
    "particle_quality": "high",
    "bloom_intensity": 0.6,
    "show_fps": false
  },
  "iap": {
    "no_ads": false,
    "vip": false,
    "starter_pack_available": true
  },
  "stats": {
    "ads_today": 2,
    "continues_session": 0,
    "energy": 5,
    "energy_timer": 0,
    "last_session": "2026-04-16T16:30:00Z",
    "first_install": "2026-04-10T12:00:00Z",
    "sessions_total": 23
  },
  "achievements": {
    "first_blood": true,
    "wave_rider": true,
    "combo_master": false
  },
  "cosmetics": {
    "active_trail": "fire",
    "active_explosion": "default",
    "active_frame": "bronze",
    "active_badge": "season1_vet"
  },
  "tutorial_completed": true,
  "onboarding_tips_shown": ["hangar", "battlepass"]
}
```

### 23.2. Save Implementation (Godot)
```gdscript
const SAVE_PATH = "user://save_data.json"
const BACKUP_PATH = "user://save_backup.json"
const ENCRYPTION_KEY = "neon_asteroids_2026_key"

# Auto-save triggers:
#   - Game over
#   - Purchase (coins, gems, unlocks)
#   - Settings changed
#   - Daily reward claimed
#   - Mission claimed
#   - Battle Pass tier claimed  
#   - App backgrounded

# Cloud save: Google Play Games saved games API
# Conflict resolution: Latest timestamp wins
```

---

## 24. Analytics & Tracking

### 24.1. Core Events

| Event | Parameters | Purpose |
|---|---|---|
| `session_start` | — | DAU |
| `session_end` | duration_s | Engagement |
| `game_start` | ship_id, zone_id | Preferences |
| `game_over` | score, wave, combo_max, coins, death_cause | Core loop |
| `wave_complete` | wave_num, time_s, lives | Difficulty |
| `boss_encounter` | boss_id | Reach rate |
| `boss_defeated` | boss_id, time_s, lives_used | Boss balance |
| `boss_failed` | boss_id, boss_hp_remaining | Too hard? |

### 24.2. Monetization Events

| Event | Parameters | Purpose |
|---|---|---|
| `ad_shown` | placement, watched/skipped | Ad perf |
| `iap_purchase` | product_id, price | Revenue |
| `bp_purchased` | tier_at_purchase | BP timing |
| `bp_tier_reached` | tier, days_since_start | BP pacing |

### 24.3. Engagement Events

| Event | Parameters | Purpose |
|---|---|---|
| `daily_reward` | day, doubled | Retention |
| `mission_completed` | mission_id, type | Engagement |
| `ship_unlocked` | ship_id, method | Progression |
| `upgrade_bought` | upgrade_id, level | Economy |
| `tutorial_step` | step_id | Onboarding |

### 24.4. Key Metrics
```
DAU / WAU / MAU
D1 / D7 / D30 Retention
ARPDAU (Average Revenue Per DAU)
LTV (Lifetime Value)
Session Length & Frequency
IAP Conversion Rate
Ad Fill Rate
Battle Pass Completion Rate
Wave Death Distribution
```

---

## 25. Notifications & Re-engagement

### 25.1. Push Notifications
```
Triggers (local notifications, no server needed):

  1. "Your energy is full! ⚡" — When energy refills to max
  2. "Don't lose your daily streak! 🔥" — 20:00 if not logged in today
  3. "New daily missions await! 🎯" — Next day at 09:00
  4. "Your Battle Pass is waiting! 🎫" — 3 days of inactivity
  5. "New season started! 🌟" — Season transition
  6. "Weekend bonus active! 🎉" — Friday evening

Rules:
  - Max 2 notifications per day
  - User can disable per-type in Settings
  - No notifications between 22:00–08:00 local time
  - Stop after 14 days inactivity (don't spam churned users)
```

### 25.2. In-App Re-engagement
```
Return after 3+ days:
  "Welcome back, Commander! Here's a bonus!"
  → 💰300 coins + 1 free energy refill

Return after 7+ days:
  "We missed you! Here's a special gift!"
  → 💰500 coins + 💎5 gems

Return after 14+ days:
  "The galaxy needs you, Commander!"
  → 💰1000 coins + 💎10 gems + 1 random skin
```

---

## 26. Accessibility

### 26.1. Visual
```
  - High contrast mode (increase outline thickness)
  - Color blind mode (shapes > colors for game elements)
  - Adjustable bloom/glow intensity
  - Larger text option
  - Screen shake toggle (ON/OFF)
  - Visual flash reduction mode
```

### 26.2. Motor
```
  - 4 control schemes (including simplified auto-aim)
  - Adjustable button sizes (small/medium/large)
  - Adjustable joystick sensitivity & dead zone
  - Auto-fire option
  - Left-handed mode
  - Minimum touch target: 44×44dp
```

### 26.3. Audio
```
  - Separate volume controls (Master/Music/SFX)
  - Visual indicators for important audio cues
  - Haptic feedback as audio alternative
```

---

## 27. Localization

### 27.1. Supported Languages (Phase 1)
```
  🇬🇧 English (default)
  🇻🇳 Vietnamese
  🇪🇸 Spanish
  🇧🇷 Portuguese (Brazil)
  🇷🇺 Russian
  🇯🇵 Japanese
  🇰🇷 Korean
```

### 27.2. Localization Notes
```
  - All UI text externalized to .csv translation files
  - No text in images/sprites
  - Support RTL layouts for future Arabic
  - Number formatting per locale  
  - Date/time formatting per locale
  - Godot: Use tr() for all displayed strings
```

---

## 28. Technical Architecture (Godot)

### 28.1. Project Settings
```
Engine:     Godot 4.6
Renderer:   Mobile (Compatibility for low-end fallback)
Physics:    Godot 2D Physics
Resolution: 1920×1080 (landscape)
Stretch:    Mode: canvas_items | Aspect: expand
Target FPS: 60
Audio:      OpenSL ES (Android), AVAudioEngine (iOS)
HDR 2D:     Enabled (for bloom/glow)
```

### 28.2. Scene Architecture
```
📁 res://
├── 📁 scenes/
│   ├── 📁 game/
│   │   ├── game.tscn
│   │   ├── game_manager.gd
│   │   ├── wave_manager.gd
│   │   └── difficulty_manager.gd
│   │
│   ├── 📁 player/
│   │   ├── player.tscn / player.gd
│   │   ├── bullet.tscn / bullet.gd
│   │   └── ship_visual.gd
│   │
│   ├── 📁 asteroids/
│   │   ├── asteroid_base.tscn / asteroid_base.gd
│   │   ├── asteroid_normal.gd
│   │   ├── asteroid_gold.gd
│   │   ├── asteroid_explosive.gd
│   │   ├── asteroid_toxic.gd
│   │   ├── asteroid_ice.gd
│   │   ├── asteroid_magnetic.gd
│   │   └── asteroid_indestructible.gd
│   │
│   ├── 📁 enemies/
│   │   ├── ufo_base.tscn / ufo_base.gd
│   │   ├── ufo_scout.gd / ufo_hunter.gd
│   │   ├── ufo_bomber.gd / ufo_interceptor.gd
│   │   └── enemy_bullet.tscn
│   │
│   ├── 📁 bosses/
│   │   ├── boss_base.gd
│   │   ├── boss_rock_titan.tscn/.gd
│   │   ├── boss_nebula_queen.tscn/.gd
│   │   ├── boss_comet_worm.tscn/.gd
│   │   ├── boss_void_sentinel.tscn/.gd
│   │   └── boss_blackhole_king.tscn/.gd
│   │
│   ├── 📁 powerups/
│   │   ├── powerup_base.tscn / powerup_base.gd
│   │   └── coin.tscn / coin.gd
│   │
│   ├── 📁 ui/
│   │   ├── hub.tscn / hub.gd
│   │   ├── hud.tscn / hud.gd
│   │   ├── hangar.tscn / hangar.gd
│   │   ├── upgrades.tscn / upgrades.gd
│   │   ├── battle_pass.tscn / battle_pass.gd
│   │   ├── missions.tscn / missions.gd
│   │   ├── shop.tscn / shop.gd
│   │   ├── settings.tscn / settings.gd
│   │   ├── game_over.tscn / game_over.gd
│   │   ├── pause_menu.tscn
│   │   ├── daily_reward.tscn
│   │   ├── leaderboard.tscn
│   │   ├── profile.tscn
│   │   └── 📁 components/
│   │       ├── virtual_joystick.tscn/.gd
│   │       ├── health_display.tscn
│   │       ├── combo_display.tscn
│   │       ├── score_popup.tscn
│   │       ├── heat_bar.tscn
│   │       ├── mission_card.tscn
│   │       └── bp_tier_card.tscn
│   │
│   └── 📁 effects/
│       ├── explosion.tscn
│       ├── shockwave.tscn
│       ├── screen_flash.tscn
│       └── warp_transition.tscn
│
├── 📁 scripts/
│   ├── 📁 autoload/
│   │   ├── game_data.gd         # Save/load, player state
│   │   ├── audio_manager.gd     # Sound playback
│   │   ├── scene_manager.gd     # Scene transitions
│   │   ├── event_bus.gd         # Signal bus
│   │   ├── analytics.gd         # Event tracking
│   │   ├── ad_manager.gd        # Ad mediation
│   │   ├── iap_manager.gd       # In-app purchases
│   │   ├── notification_manager.gd  # Local notifications
│   │   └── mission_manager.gd   # Daily/weekly missions
│   │
│   ├── 📁 resources/
│   │   ├── ship_data.gd
│   │   ├── asteroid_data.gd
│   │   ├── powerup_data.gd
│   │   ├── wave_data.gd
│   │   ├── upgrade_data.gd
│   │   ├── boss_data.gd
│   │   ├── bp_season_data.gd
│   │   ├── mission_data.gd
│   │   └── skin_data.gd
│   │
│   └── 📁 utils/
│       ├── screen_wrap.gd
│       ├── object_pool.gd
│       ├── math_utils.gd
│       └── shake_camera.gd
│
├── 📁 art/
│   ├── 📁 ships/         # Ship sprites
│   ├── 📁 asteroids/     # Asteroid sprites  
│   ├── 📁 effects/       # Particle textures
│   ├── 📁 ui/            # UI icons, buttons
│   ├── 📁 backgrounds/   # BG layers
│   └── 📁 skins/         # Cosmetic skins
│
├── 📁 audio/
│   ├── 📁 music/         # .ogg files
│   └── 📁 sfx/           # .wav files
│
├── 📁 shaders/
│   ├── neon_glow.gdshader
│   ├── screen_distortion.gdshader
│   ├── chromatic_aberration.gdshader
│   └── crt_filter.gdshader
│
├── 📁 data/
│   ├── ships.tres
│   ├── waves.tres
│   ├── powerups.tres
│   ├── upgrades.tres
│   ├── bp_season1.tres
│   ├── missions.tres
│   └── skins.tres
│
└── 📁 translations/
    └── translations.csv
```

### 28.3. Autoloads
```gdscript
[autoload]
GameData = "*res://scripts/autoload/game_data.gd"
AudioManager = "*res://scripts/autoload/audio_manager.gd"
SceneManager = "*res://scripts/autoload/scene_manager.gd"
EventBus = "*res://scripts/autoload/event_bus.gd"
Analytics = "*res://scripts/autoload/analytics.gd"
AdManager = "*res://scripts/autoload/ad_manager.gd"
IAPManager = "*res://scripts/autoload/iap_manager.gd"
NotificationManager = "*res://scripts/autoload/notification_manager.gd"
MissionManager = "*res://scripts/autoload/mission_manager.gd"
```

### 28.4. EventBus Signals
```gdscript
extends Node

# Game State
signal game_started
signal game_over(score, wave)
signal game_paused / game_resumed
signal wave_started(wave) / wave_completed(wave)

# Player
signal player_died / player_respawned
signal player_hit(lives)
signal score_changed(score)
signal coins_changed(coins)
signal combo_changed(combo, multiplier)
signal combo_lost
signal xp_gained(amount)
signal level_up(new_level)

# Combat
signal asteroid_destroyed(type, position, size)
signal enemy_destroyed(type, position)
signal boss_damaged(boss_id, hp)
signal boss_defeated(boss_id)
signal boss_phase_changed(boss_id, phase)

# Items
signal powerup_collected(type)
signal powerup_expired(type)
signal coin_collected(value)
signal bomb_used(remaining)

# Meta
signal ship_unlocked(ship_id)
signal skin_unlocked(skin_id)
signal upgrade_purchased(id, level)
signal achievement_earned(id)
signal bp_tier_reached(tier)
signal mission_completed(id)
signal daily_reward_claimed(day)
```

### 28.5. Object Pooling
```gdscript
class_name ObjectPool

var _scene: PackedScene
var _pool: Array[Node] = []
var _active: Array[Node] = []

func _init(scene: PackedScene, initial: int = 20):
    _scene = scene
    for i in initial:
        var inst = scene.instantiate()
        inst.set_process(false)
        inst.visible = false
        _pool.append(inst)

func get_instance() -> Node:
    var inst = _pool.pop_back() if _pool.size() > 0 else _scene.instantiate()
    inst.set_process(true)
    inst.visible = true
    _active.append(inst)
    return inst

func return_instance(inst: Node):
    inst.set_process(false)
    inst.visible = false
    _active.erase(inst)
    _pool.append(inst)

# Pool sizes:
#   Player bullets: 50
#   Enemy bullets: 30
#   Coins: 100
#   Particles: 200
#   Score popups: 20
#   Asteroids: 50
```

---

## 29. Scene Tree Structure

```
Game (Node2D)
├── ParallaxBackground
│   ├── ParallaxLayer1 (stars far)
│   ├── ParallaxLayer2 (stars near)
│   └── ParallaxLayer3 (nebula/zone effects)
│
├── WorldEnvironment (HDR Bloom settings)
│
├── GameWorld (Node2D)
│   ├── Player (CharacterBody2D)
│   │   ├── ShipSprite (Sprite2D + Shader)
│   │   ├── CollisionShape2D
│   │   ├── EngineTrail (GPUParticles2D)
│   │   ├── ShieldVisual
│   │   ├── OrbitalShield (3 orbiting nodes)
│   │   ├── InvincibilityTimer
│   │   └── ShootTimer
│   │
│   ├── Bullets (Node2D container)
│   ├── EnemyBullets (Node2D container)
│   ├── Asteroids (Node2D container)
│   ├── Enemies (Node2D container)
│   ├── PowerUps (Node2D container)
│   ├── Coins (Node2D container)
│   └── Effects (Node2D container)
│
├── Camera2D
│   └── ShakeComponent
│
├── CanvasLayer (HUD)
│   ├── HUD (scores, lives, combo, heat)
│   ├── Controls (joystick, buttons)
│   └── Overlays (pause, game over, boss warning)
│
├── GameManager
├── WaveManager
├── DifficultyManager
├── ComboManager
└── PowerUpManager
```

---

## 30. Performance & Optimization

### 30.1. Targets
```
Target: Android mid-range 2020+ (4GB RAM, Adreno 610+)
FPS:    60 stable
Nodes:  Max 200 active
Particles: Max 500 visible
Draw calls: < 50
APK size: < 80MB
Memory: < 200MB runtime
```

### 30.2. Optimization Strategies
```
1. Object Pooling: All frequently spawned objects
2. LOD Particles: Low/Med/High quality setting
3. Sprite Atlases: Batch similar sprites
4. Shader optimization: Minimal loop iterations in glow shader
5. Avoid PointLight2D: Use additive sprites instead
6. MultiMeshInstance2D: For coins, particles
7. Profile on real device: Not desktop
8. Reduce overdraw: Convert alpha-heavy sprites to Mesh2D
```

---

## 31. Milestone & Roadmap

### Phase 1: Core Prototype (2 weeks)
```
[ ] Project setup (Godot 4.6, resolution, HDR 2D, bloom)
[ ] Player ship movement (rotation + thrust + inertia + screen wrap)
[ ] Basic shooting (single bullet, lifetime, heat system)
[ ] Basic asteroid (1 type, random spawn, movement, splitting)
[ ] Collision detection
[ ] Basic scoring + HUD
[ ] Game over / restart
[ ] Neon wireframe visual prototype
```

### Phase 2: Core Polish (2 weeks)
```
[ ] All asteroid sizes (Huge/Large/Medium/Small)
[ ] Particle effects (explosions, engine trail)  
[ ] Screen shake + slow-mo
[ ] Neon glow shader + bloom
[ ] Basic SFX (shoot, explode, collect)
[ ] BGM (1 track)
[ ] Combo system
[ ] Virtual joystick controls
[ ] Bombs
```

### Phase 3: Content (3 weeks)
```
[ ] 7 asteroid types
[ ] 11 power-ups
[ ] Coin system
[ ] 4 UFO enemies
[ ] Wave + difficulty scaling
[ ] 5 zones + backgrounds
[ ] 5 boss battles
```

### Phase 4: Meta & UI (3 weeks)
```
[ ] Hub screen (main menu)
[ ] 6 ships + special abilities
[ ] Hangar (ship selection + skins)
[ ] Upgrade system (10 upgrades)
[ ] Battle Pass system
[ ] Daily/Weekly missions
[ ] Daily login rewards
[ ] Settings screen
[ ] Tutorial + onboarding
[ ] Game Over results screen
[ ] Scene transitions
[ ] Profile / Leaderboard
```

### Phase 5: Monetization & Polish (2 weeks)
```
[ ] AdMob integration (rewarded ads)
[ ] IAP integration (coins, gems, packs, bundles)
[ ] Shop UI
[ ] Battle Pass premium purchase
[ ] Energy system (if applicable)
[ ] Google Play Games Services
[ ] Analytics integration
[ ] Push notifications (local)
[ ] Performance optimization
[ ] Bug fixing + playtesting
```

### Phase 6: Localization & Release (2 weeks)
```
[ ] Localization (7 languages)
[ ] Accessibility features
[ ] App icons & screenshots
[ ] Store listing (ASO)
[ ] Privacy policy & terms
[ ] Build signing
[ ] Internal → Closed → Open beta
[ ] Launch! 🚀
```

### Total: ~14 weeks (~3.5 months)

---

## 32. ASO & Store Listing

### 32.1. Store Metadata
```
App Name:        Neon Asteroids: Space Shooter
Subtitle:        Destroy. Combo. Conquer.
Category:        Arcade / Action
Content Rating:  Everyone (PEGI 3 / ESRB E)
Price:           Free (with IAP)

Keywords:
  asteroids, neon, arcade, space shooter, retro,
  geometry wars, space game, asteroid destroyer,
  neon game, arcade shooter, mobile game

Short Description (80 chars):
  "Neon space arcade — destroy asteroids, build combos, defeat bosses! 🚀"

Long Description (4000 chars max):
  [Compelling description highlighting USPs, features, and gameplay]
```

### 32.2. Screenshots (required)
```
  1. Gameplay — Ship shooting asteroids, neon glow, combo counter
  2. Boss Battle — Epic boss with HP bar, dramatic effects
  3. Power-ups — Multiple power-ups active, particles everywhere
  4. Hub screen — Beautiful main menu with ship preview
  5. Battle Pass — Reward tiers with exclusive skins
  6. Hangar — Ship selection with skin preview
  7. Game Over — Results screen with stats
  8. Action shot — Bomb explosion, maximum juice
```

---

## 33. Phụ Lục: Achievements

| Achievement | Mô tả | Reward |
|---|---|---|
| 🎯 First Blood | Phá hủy asteroid đầu tiên | 💰 50 |
| 🌊 Wave Rider | Đạt Wave 10 | 💰 200 |
| 🏔️ Halfway There | Đạt Wave 25 | 💰 500 |
| ♾️ Endless Voyager | Đạt Wave 50 | 💎 10 |
| ✨ Combo Starter | Combo 5× | 💰 100 |
| ⚡ Combo Master | Combo 20× | 💰 300 |
| 🔥 Combo Legend | Combo 50× | 💎 5 |
| 💀 Boss Slayer | Đánh bại boss đầu tiên | 💰 200 |
| 🏆 Boss Hunter | Đánh bại tất cả 5 boss | 💎 20 |
| 🚀 Collector | Mở khóa tàu thứ 2 | 💰 150 |
| ⭐ Fleet Commander | Mở khóa tất cả tàu | 💎 30 |
| 🎯 Sharpshooter | Accuracy 90%+ trong 1 game | 💰 200 |
| ☮️ Pacifist Run | Clear wave chỉ dùng bomb | 💎 3 |
| 🛡️ No Damage | 5 waves liên tục không bị hit | 💎 5 |
| 💰 Millionaire | Tích lũy 100K coins | 💎 15 |
| 💥 Annihilator | Phá hủy 10,000 asteroids | 💎 10 |
| ⏱️ Marathon | Chơi tổng 10 giờ | 💰 1000 |
| 💣 Bomb Expert | Kill 10 asteroids bằng 1 bomb | 💰 200 |
| 🔗 Chain Reaction | Explosive asteroid phá 5 asteroids | 💰 300 |
| 🏅 Untouchable | Wave 10 không mất life | 💎 5 |
| 🎫 Pass Master | Hoàn thành 1 Battle Pass season | 💎 20 |
| 📅 Dedicated | Login 30 ngày liên tục | 💎 15 |
| 🎨 Fashionista | Sở hữu 10 ship skins | 💰 500 |
| 🌟 Completionist | Đạt tất cả achievements khác | 💎 50 + "MASTER" badge |

---

> **GDD này là tài liệu sống (living document).** Sẽ được cập nhật liên tục dựa trên playtesting, analytics data, và community feedback. Mọi số liệu (economy, timing, difficulty) là initial estimates và sẽ được fine-tune sau khi có real player data.
>
> **Version History:**
> - v1.0 (2026-04-16): Initial GDD
> - v2.0 (2026-04-17): Major overhaul — Added Battle Pass, Daily/Weekly Missions, Cosmetics System, Hub Flow, Enhanced Monetization, Accessibility, Localization, Social Features, Notifications, ASO
