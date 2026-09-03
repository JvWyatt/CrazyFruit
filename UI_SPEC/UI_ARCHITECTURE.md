# UI Architecture - Crazy Fruit

> **Fuente de verdad estructurada** para reconstruir, rediseñar o migrar la interfaz a herramientas externas (Figma, Stitch, IA).

---

## 1. Project

| Property | Value | Confidence |
|---|---|---|
| Engine | Godot 4.5 (GL Compatibility) | CONFIRMED |
| Project Name | Crazy Fruit | CONFIRMED |
| Version | 0.012 | CONFIRMED |
| Viewport Width | 720 | CONFIRMED |
| Viewport Height | 1280 | CONFIRMED |
| Orientation | Portrait (value=1 = portrait) | CONFIRMED |
| Stretch Mode | canvas_items | CONFIRMED |
| Stretch Aspect | keep_width | CONFIRMED |
| Platform | Android (mobile primary) | CONFIRMED |
| Renderer | gl_compatibility | CONFIRMED |
| Touch Emulation | pointing/emulate_touch_from_mouse=true | CONFIRMED |
| ETC2/ASTC | textures/vram_compression/import_etc2_astc=true | CONFIRMED |

### UI-relevant Project Configuration

- Base resolution: **720x1280** (portrait mobile)
- `keep_width`: Width stays at 720, height scales dynamically on taller devices
- `canvas_items`: UI scales proportionally with viewport
- Default clear color: `Color(0.08, 0.09, 0.13, 1)` (very dark blue-black `#141721`)
- Touch input emulated from mouse for desktop testing

---

## 2. Screens

### 2.1 Main Menu

| Property | Value |
|---|---|
| ID | `main_menu` |
| Scene | `res://scenes/ui/MainMenu.tscn` |
| Root Node | `MainMenu` (Control) |
| Script | `res://scripts/ui/MainMenu.gd` |
| Function | Landing screen with game entry points |
| Access | Initial screen on game start; returned after run ends |
| Navigates To | Game, Prestige Shop, Progress, Cards, Settings |
| Canvas Layer | Default (layer 0) |

### 2.2 Game HUD

| Property | Value |
|---|---|
| ID | `game_hud` |
| Scene | `res://scenes/ui/HUD.tscn` |
| Root Node | `HUD` (Control) |
| Script | `res://scripts/ui/HUD.gd` |
| Function | In-game overlay showing live stats |
| Access | Shown when game starts (via Main.gd) |
| Navigates To | Stats, Pause (which leads to Settings or Quit) |
| Canvas Layer | Default within GameWorld/HUDLayer (CanvasLayer) |

### 2.3 Run Upgrade Modal (Market)

| Property | Value |
|---|---|
| ID | `run_upgrade_modal` |
| Scene | `res://scenes/ui/RunUpgradeModal.tscn` |
| Root Node | `RunUpgradeModal` (Control) |
| Script | `res://scripts/ui/RunUpgradeModal.gd` |
| Function | Between-day shop with 3 tabs: Upgrades, Fruit Shop, Weapon Shop |
| Access | Opened after card selection (between days) |
| Navigates To | Stats, next day |
| Canvas Layer | Modals (layer 50) |
| z_index | 30 |

### 2.4 Stats Modal

| Property | Value |
|---|---|
| ID | `stats_modal` |
| Scene | `res://scenes/ui/StatsModal.tscn` |
| Root Node | `StatsModal` (Control) |
| Script | `res://scripts/ui/StatsModal.gd` |
| Function | Detailed view of all calculated stats |
| Access | From HUD or RunUpgradeModal |
| Navigates To | Cards (active cards) |
| Canvas Layer | Modals (layer 50) |
| z_index | 30 |

### 2.5 Prestige Shop Modal

| Property | Value |
|---|---|
| ID | `prestige_shop_modal` |
| Scene | `res://scenes/ui/PrestigeShopModal.tscn` |
| Root Node | `PrestigeShopModal` (Control) |
| Script | `res://scripts/ui/PrestigeShopModal.gd` |
| Function | Permanent upgrades bought with prestige points |
| Access | From Main Menu |
| Navigates To | None (closes back to Main Menu) |
| Canvas Layer | Modals (layer 50) |
| z_index | 30 |

### 2.6 Card Selection Modal

| Property | Value |
|---|---|
| ID | `card_selection_modal` |
| Scene | `res://scenes/ui/CardSelectionModal.tscn` |
| Root Node | `CardSelectionModal` (Control) |
| Script | `res://scripts/ui/CardSelectionModal.gd` |
| Function | Day completion screen: shows summary + pick a card |
| Access | After completing a day (order_completed signal) |
| Navigates To | Run Upgrade Modal |
| Canvas Layer | Modals (layer 50) |
| z_index | 35 |

### 2.7 Results Modal (Game Over)

| Property | Value |
|---|---|
| ID | `results_modal` |
| Scene | `res://scenes/ui/ResultsModal.tscn` |
| Root Node | `ResultsModal` (Control) |
| Script | `res://scripts/ui/ResultsModal.gd` |
| Function | Run summary when business goes bankrupt |
| Access | After failed run (energy or time runs out without meeting target) |
| Navigates To | Main Menu |
| Canvas Layer | Modals (layer 50) |
| z_index | 40 |

### 2.8 Progress Modal

| Property | Value |
|---|---|
| ID | `progress_modal` |
| Scene | `res://scenes/ui/ProgressModal.tscn` |
| Root Node | `ProgressModal` (Control) |
| Script | `res://scripts/ui/ProgressModal.gd` |
| Function | Permanent lifetime statistics |
| Access | From Main Menu |
| Navigates To | None (closes back to Main Menu) |
| Canvas Layer | Modals (layer 50) |
| z_index | 30 |

### 2.9 Cards Modal (Gallery)

| Property | Value |
|---|---|
| ID | `cards_modal` |
| Scene | `res://scenes/ui/CardsModal.tscn` |
| Root Node | `CardsModal` (Control) |
| Script | `res://scripts/ui/CardsModal.gd` |
| Function | Gallery of discovered or active cards |
| Access | From Main Menu or Stats Modal |
| Navigates To | None (closes back) |
| Canvas Layer | Modals (layer 50) |
| z_index | 40 |

### 2.10 Credits Modal

| Property | Value |
|---|---|
| ID | `credits_modal` |
| Scene | `res://scenes/ui/CreditsModal.tscn` |
| Root Node | `CreditsModal` (Control) |
| Script | `res://scripts/ui/CreditsModal.gd` |
| Function | Victory screen when completing day 100 |
| Access | After completing day 100 (WIN_DAY) |
| Navigates To | Card Selection (continue) or Main Menu (exit) |
| Canvas Layer | Modals (layer 50) |
| z_index | 35 |

### 2.11 Confirm Dialog

| Property | Value |
|---|---|
| ID | `confirm_dialog` |
| Scene | `res://scenes/ui/ConfirmDialog.tscn` |
| Root Node | `ConfirmDialog` (Control) |
| Script | `res://scripts/ui/ConfirmDialog.gd` (class_name ConfirmDialog) |
| Function | Reusable confirmation popup |
| Access | Opened programmatically via .open() method |
| Navigates To | Returns confirmed/canceled signal |
| z_index | Inherits from parent |

### 2.12 Settings Section (Reusable Component)

| Property | Value |
|---|---|
| ID | `settings_section` |
| Scene | `res://scenes/ui/SettingsSection.tscn` |
| Root Node | `SettingsSection` (VBoxContainer) |
| Script | `res://scripts/ui/SettingsSection.gd` (class_name SettingsSection) |
| Function | Volume sliders (Master, Music, SFX) |
| Access | Embedded in MainMenu and HUD PausePanel |
| Instances | 2 (MainMenu, HUD) |

### 2.13 Settings Panel (within Main Menu)

| Property | Value |
|---|---|
| ID | `settings_panel` |
| Scene | Inline in MainMenu.tscn |
| Root Node | `SettingsPanel` (Control) |
| Function | Settings overlay within Main Menu |
| Access | Settings button on Main Menu |
| Canvas Layer | Default (part of MainMenu) |

### 2.14 Pause Panel (within HUD)

| Property | Value |
|---|---|
| ID | `pause_panel` |
| Scene | Inline in HUD.tscn |
| Root Node | `PausePanel` (Control) |
| Function | Pause overlay with continue/settings/quit |
| Access | Pause button in HUD |
| Canvas Layer | Default (part of HUD) |

---

## 3. Node Hierarchy

### Main Scene Tree (Main.tscn)

```text
Main (Node) [script: Main.gd]
├── Background (ColorRect)
│   └── color: Color(0.24577132, 0.69673496, 0.7205561, 1) [teal]
├── MainMenu (instance: MainMenu.tscn)
├── GameWorld (Node2D)
│   ├── FruitSpawner (instance: FruitSpawner.tscn)
│   ├── SwipeController (instance: SwipeController.tscn)
│   └── HUDLayer (CanvasLayer)
│       └── HUD (instance: HUD.tscn)
├── Fruit3DLayer (SubViewportContainer)
│   └── Viewport (SubViewport)
│       └── Fruit3DWorld (instance, added dynamically)
└── Modals (CanvasLayer, layer=50)
    ├── RunUpgradeModal (instance, visible=false)
    ├── StatsModal (instance, visible=false)
    ├── CardSelectionModal (instance, visible=false)
    ├── ResultsModal (instance, visible=false)
    ├── PrestigeShopModal (instance, visible=false)
    ├── ProgressModal (instance, visible=false)
    ├── CardsModal (instance, visible=false)
    └── CreditsModal (instance, visible=false)
```

### MainMenu Hierarchy

```text
MainMenu (Control) [script: MainMenu.gd]
├── Background (ColorRect) [color: Color(0.07, 0.08, 0.12, 1)]
├── VersionLabel (Label) [text: "v0.013"]
├── CenterVBox (VBoxContainer) [anchors: center, 600x960, separation: 22, alignment: center]
│   ├── TitleVBox (VBoxContainer) [separation: 6]
│   │   ├── IconLabel (Label) [text: "🍎🔪🍉", font_size: 56]
│   │   ├── TitleLabel (Label) [text: "CRAZY FRUIT", font_size: 42]
│   │   ├── SubtitleLabel (Label) [text: "¡Rebana y Vende Frutas!", font_size: 18]
│   │   └── GoalLabel (Label) [text: "🎯 Objetivo: llegar al día 100 y batir récords", font_size: 16]
│   └── ButtonsVBox (VBoxContainer) [separation: 12]
│       ├── PlayButton (Button) [min_size: 0x64, text: "⚔️ JUGAR", font_size: 26]
│       ├── PrestigeShopButton (Button) [min_size: 0x52, text: "⭐ MERCADO DE PRESTIGIO", font_size: 18]
│       ├── ProgressButton (Button) [min_size: 0x52, text: "🏆 VER PROGRESO", font_size: 18]
│       ├── CardsButton (Button) [min_size: 0x52, text: "🃏 COMODINES", font_size: 18]
│       ├── SettingsButton (Button) [min_size: 0x52, text: "⚙️ AJUSTES", font_size: 18]
│       └── ResetButton (Button) [min_size: 0x44, text: "🔄 REINICIAR PROGRESO", font_size: 14]
├── ResetConfirmDialog (instance: ConfirmDialog.tscn)
└── SettingsPanel (Control) [visible: false]
    ├── Scrim (ColorRect) [color: Color(0, 0, 0, 0.55)]
    └── SettingsCard (PanelContainer) [620x440 centered]
        └── VBox (VBoxContainer) [separation: 16]
            ├── TitleLabel (Label) [text: "AJUSTES", font_size: 30]
            ├── SettingsSection (instance: SettingsSection.tscn)
            └── BackButton (Button) [min_size: 0x52, text: "← VOLVER", font_size: 18]
```

### HUD Hierarchy

```text
HUD (Control) [script: HUD.gd, mouse_filter: ignore]
├── TopContainer (PanelContainer) [anchors: top-stretch, height: 175]
│   └── VBox (VBoxContainer) [separation: 8]
│       ├── TopHBox (HBoxContainer) [alignment: center]
│       │   ├── MoneyContainer (HBoxContainer) [expand]
│       │   │   └── MoneyLabel (Label) [text: "💰 $0", font_size: 24]
│       │   └── OrderContainer (HBoxContainer) [expand, end-aligned]
│       │       └── OrderLabel (Label) [text: "📋 Día 1", font_size: 22]
│       ├── OrderProgressBar (ProgressBar) [min_height: 26, value: 40]
│       │   └── OrderProgressLabel (Label) [text: "$0 / $100", font_size: 15, centered]
│       ├── EnergyContainer (VBoxContainer)
│       │   └── EnergyBar (ProgressBar) [min_height: 22, value: 100]
│       │       └── EnergyLabel (Label) [text: "⚡ 100 / 100", font_size: 14, centered]
│       ├── StatusHBox (HBoxContainer)
│       │   ├── StatusInfoLabel (Label) [text: "💼 Negocio 1", font_size: 16, expand]
│       │   └── LaunchRateLabel (Label) [text: "🍉 1.0 frutas/s", font_size: 20, expand, end-aligned]
│       └── RoundTimeLabel (Label) [text: "⏱ 60s", font_size: 22, centered]
├── BottomContainer (HBoxContainer) [anchors: bottom, offset: 20,-90 to -20,-25, centered]
│   ├── KnifeInfoLabel (Label) [text: "👊 Utensilio básico", font_size: 18, expand]
│   └── ButtonsHBox (HBoxContainer) [separation: 10]
│       ├── StatsButton (Button) [130x56, text: "📊 Stats", font_size: 18]
│       └── PauseButton (Button) [130x56, text: "⏸ Pausa", font_size: 18]
├── PausePanel (Control) [visible: false]
│   ├── Scrim (ColorRect) [color: Color(0, 0, 0, 0.6)]
│   ├── Card (PanelContainer) [600x560 centered]
│   │   ├── PauseVBox (VBoxContainer) [separation: 16]
│   │   │   ├── PauseTitle (Label) [text: "⏸ PAUSA", font_size: 32, centered]
│   │   │   ├── PauseDayLabel (Label) [font_size: 16, centered]
│   │   │   ├── ContinueButton (Button) [min_size: 0x56, text: "▶ CONTINUAR", font_size: 20]
│   │   │   ├── SettingsButton (Button) [min_size: 0x56, text: "⚙️ AJUSTES", font_size: 20]
│   │   │   └── PauseQuitButton (Button) [min_size: 0x48, text: "🚪 SALIR", font_size: 16]
│   │   └── SettingsVBox (VBoxContainer) [visible: false]
│   │       ├── SettingsTitle (Label) [text: "AJUSTES", font_size: 28, centered]
│   │       ├── SettingsSection (instance: SettingsSection.tscn)
│   │       └── SettingsBackButton (Button) [min_size: 0x52, text: "← VOLVER", font_size: 18]
└── PauseConfirmDialog (instance: ConfirmDialog.tscn)
```

### StatsModal Hierarchy

```text
StatsModal (Control) [script: StatsModal.gd, z_index: 30]
├── Dimmer (ColorRect) [color: Color(0, 0, 0, 0.65)]
└── Panel (PanelContainer) [640x860 centered, StyleBoxFlat_modal_bg]
    └── VBox (VBoxContainer) [separation: 14]
        ├── HeaderHBox (HBoxContainer)
        │   ├── TitleLabel (Label) [text: "📊 Estadísticas", font_size: 24, expand]
        │   └── CloseButton (Button) [40x40, text: "✖", font_size: 18]
        ├── HSeparator
        ├── ScrollContainer [expand, script: TouchScrollContainer.gd]
        │   └── StatsVBox (VBoxContainer) [expand, separation: 12]
        ├── ContinueButton (Button) [min_size: 0x52, text: "CERRAR", font_size: 20]
        └── CardsButton (Button) [min_size: 0x48, text: "ⓘ Ver comodines activos", font_size: 18]
```

### RunUpgradeModal Hierarchy

```text
RunUpgradeModal (Control) [script: RunUpgradeModal.gd, z_index: 30]
├── Dimmer (ColorRect) [color: Color(0, 0, 0, 0.6)]
└── Panel (PanelContainer) [640x840 centered]
    └── VBox (VBoxContainer) [separation: 16]
        ├── HeaderHBox (HBoxContainer)
        │   ├── TitleLabel (Label) [text: "🛒 Mercado de mejoras", font_size: 22, expand]
        │   ├── MoneyLabel (Label) [text: "💰 $0", font_size: 20]
        │   └── CloseButton (Button) [36x36, text: "✖", font_size: 18]
        ├── HSeparator
        ├── TabContainer [expand, 3 tabs]
        │   ├── Mejoras (ScrollContainer) [script: TouchScrollContainer.gd]
        │   │   └── ItemsVBox (VBoxContainer) [expand, separation: 12]
        │   ├── Frutería (ScrollContainer) [visible: false]
        │   │   └── ItemsVBox (VBoxContainer) [expand, separation: 12]
        │   └── Armas (ScrollContainer) [visible: false]
        │       └── ItemsVBox (VBoxContainer) [expand, separation: 12]
        └── BottomHBox (HBoxContainer) [separation: 10]
            ├── StatsButton (Button) [130x56, text: "📊 Ver Stats", font_size: 18]
            └── ContinueButton (Button) [min_size: 0x56, expand, text: "⚔️ INICIAR SIGUIENTE DÍA", font_size: 20]
```

### PrestigeShopModal Hierarchy

```text
PrestigeShopModal (Control) [script: PrestigeShopModal.gd, z_index: 30]
├── Dimmer (ColorRect) [color: Color(0, 0, 0, 0.65)]
└── Panel (PanelContainer) [640x760 centered]
    └── VBox (VBoxContainer) [separation: 16]
        ├── HeaderHBox (HBoxContainer)
        │   ├── TitleLabel (Label) [text: "⭐ Mercado de Prestigio", font_size: 24, expand]
        │   ├── PrestigeLabel (Label) [text: "⭐ 0 Rep.", font_size: 18]
        │   └── CloseButton (Button) [40x40, text: "✖", font_size: 18]
        ├── HSeparator
        └── ScrollContainer [expand, script: TouchScrollContainer.gd]
            └── ItemsVBox (VBoxContainer) [expand, separation: 14]
```

### CardSelectionModal Hierarchy

```text
CardSelectionModal (Control) [script: CardSelectionModal.gd, z_index: 35]
├── Dimmer (ColorRect) [color: Color(0, 0, 0, 0.7)]
└── Panel (PanelContainer) [640x840 centered]
    └── VBox (VBoxContainer) [separation: 16]
        ├── TitleLabel (Label) [text: "🎉 ¡DÍA COMPLETADO!", font_size: 24, centered]
        ├── SubtitleLabel (Label) [text: "Selecciona 1 comodín...", font_size: 16, centered]
        ├── SummaryPanel (PanelContainer)
        │   └── SummaryVBox (VBoxContainer) [separation: 6]
        │       ├── SummaryTitle (Label) [text: "📊 RESUMEN DEL DÍA", font_size: 16, centered]
        │       ├── EarnedRow (HBoxContainer)
        │       │   ├── EarnedLabel (Label) [text: "Conseguido:", expand]
        │       │   └── EarnedValue (Label) [text: "$0", end-aligned]
        │       ├── TaxRow (HBoxContainer)
        │       │   ├── TaxLabel (Label) [text: "Impuesto:", expand]
        │       │   └── TaxValue (Label) [text: "$0", end-aligned]
        │       ├── ProfitRow (HBoxContainer)
        │       │   ├── ProfitLabel (Label) [text: "Ganancia:", expand]
        │       │   └── ProfitValue (Label) [text: "$0", end-aligned]
        │       └── NextTargetRow (HBoxContainer)
        │           ├── NextTargetLabel (Label) [text: "🎯 Objetivo del siguiente día:", expand]
        │           └── NextTargetValue (Label) [text: "$0", end-aligned]
        ├── HSeparator
        └── CardsScroll (ScrollContainer) [expand, script: TouchScrollContainer.gd]
            └── CardsVBox (VBoxContainer) [expand, separation: 14, centered]
```

### ResultsModal Hierarchy

```text
ResultsModal (Control) [script: ResultsModal.gd, z_index: 40]
├── Dimmer (ColorRect) [color: Color(0, 0, 0, 0.75)]
└── Panel (PanelContainer) [620x720 centered]
    └── VBox (VBoxContainer) [separation: 18]
        ├── TitleLabel (Label) [text: "💀 NEGOCIO TERMINADO", font_size: 28, centered, color: red]
        ├── HSeparator
        ├── StatsVBox (VBoxContainer) [separation: 10]
        │   ├── OrdersLabel (Label) [font_size: 18]
        │   ├── MoneyLabel (Label) [font_size: 18]
        │   ├── FruitsLabel (Label) [font_size: 18]
        │   ├── JackpotsLabel (Label) [font_size: 18]
        │   └── GoldenLabel (Label) [font_size: 18, color: gold]
        ├── PrestigeContainer (PanelContainer)
        │   └── VBox (VBoxContainer) [centered]
        │       ├── HeaderLabel (Label) [text: "Reputación Obtenida:", centered]
        │       ├── PrestigeEarnedLabel (Label) [text: "+ 0 ⭐", font_size: 32, centered]
        │       └── TotalPrestigeLabel (Label) [text: "⭐ Reputación total: 0", centered]
        └── ContinueButton (Button) [min_size: 0x56, text: "CONTINUAR", font_size: 22]
```

### ProgressModal Hierarchy

```text
ProgressModal (Control) [script: ProgressModal.gd, z_index: 30]
├── Dimmer (ColorRect) [color: Color(0, 0, 0, 0.65)]
└── Panel (PanelContainer) [640x860 centered]
    └── VBox (VBoxContainer) [separation: 14]
        ├── HeaderHBox (HBoxContainer)
        │   ├── TitleLabel (Label) [text: "🏆 Progreso del Puesto", font_size: 24, expand]
        │   └── CloseButton (Button) [40x40, text: "✖", font_size: 18]
        ├── HSeparator
        └── ScrollContainer [expand]
            └── ProgressVBox (VBoxContainer) [expand, separation: 10]
```

### CreditsModal Hierarchy

```text
CreditsModal (Control) [script: CreditsModal.gd, z_index: 35]
├── Dimmer (ColorRect) [color: Color(0, 0, 0, 0.7)]
└── Panel (PanelContainer) [660x600 centered]
    └── VBox (VBoxContainer) [separation: 20]
        ├── TitleLabel (Label) [text: "🎬 ¡CRÉDITOS!", font_size: 40, centered]
        ├── SubtitleLabel (Label) [text: "¡Completaste los 100 días!", font_size: 20, centered]
        ├── QuotaLabel (Label) [text: "Cuota del día 100: $1000.0M", font_size: 16, centered]
        ├── ContinueButton (Button) [min_size: 0x60, text: "▶ CONTINUAR (NUEVOS RÉCORDS)", font_size: 20]
        └── ExitButton (Button) [min_size: 0x52, text: "🚪 SALIR AL MENÚ", font_size: 18]
```

### ConfirmDialog Hierarchy

```text
ConfirmDialog (Control) [script: ConfirmDialog.gd, visible: false]
├── Scrim (ColorRect) [color: Color(0, 0, 0, 0.62)]
└── Card (PanelContainer) [640x300 centered]
    └── VBox (VBoxContainer) [separation: 20]
        ├── TitleLabel (Label) [text: "CONFIRMAR", font_size: 26, centered]
        ├── MessageLabel (Label) [text: "¿Estás seguro?", font_size: 17, centered, autowrap]
        └── ButtonsHBox (HBoxContainer) [separation: 14, centered]
            ├── CancelButton (Button) [180x52, text: "CANCELAR", font_size: 16]
            └── OkButton (Button) [180x54, text: "ACEPTAR", font_size: 17]
```

### SettingsSection Hierarchy

```text
SettingsSection (VBoxContainer) [script: SettingsSection.gd, separation: 16]
├── MasterRow (HBoxContainer) [separation: 12]
│   ├── MasterLabel (Label) [text: "Volumen general", min_width: 150, font_size: 17]
│   ├── MasterSlider (HSlider) [min_height: 40, expand, max: 100]
│   └── MasterValue (Label) [text: "100%", min_width: 52, font_size: 17, end-aligned]
├── MusicRow (HBoxContainer) [separation: 12]
│   ├── MusicLabel (Label) [text: "Música", min_width: 150, font_size: 17]
│   ├── MusicSlider (HSlider) [min_height: 40, expand, max: 100]
│   └── MusicValue (Label) [text: "100%", min_width: 52, font_size: 17, end-aligned]
└── SfxRow (HBoxContainer) [separation: 12]
    ├── SfxLabel (Label) [text: "Efectos (SFX)", min_width: 150, font_size: 17]
    ├── SfxSlider (HSlider) [min_height: 40, expand, max: 100]
    └── SfxValue (Label) [text: "100%", min_width: 52, font_size: 17, end-aligned]
```

---

## 4. Layout

### General Layout Strategy

- **No external theme file (.tres)**: All styling is done via:
  1. Inline `theme_override_*` properties on nodes
  2. SubResource StyleBoxFlat defined in .tscn files
  3. `UiTheme.gd` global Theme installed on `get_tree().root`
  4. `UiTheme.apply_card()` applied programmatically in scripts
- All modals use a centered PanelContainer approach (anchor preset 8: center)
- Top-level screens use full-viewport anchors (preset 15: top-left to bottom-right)

### Modal Panel Standard Size

| Modal | Width | Height | Total Size |
|---|---|---|---|
| StatsModal | 640 | 860 | 320,430 offsets |
| RunUpgradeModal | 640 | 840 | 320,420 offsets |
| PrestigeShopModal | 640 | 760 | 320,380 offsets |
| CardSelectionModal | 640 | 840 | 320,420 offsets |
| ResultsModal | 620 | 720 | 310,360 offsets |
| ProgressModal | 640 | 860 | 320,430 offsets |
| CardsModal | 640 | 860 | 320,430 offsets |
| CreditsModal | 660 | 600 | 330,300 offsets |
| ConfirmDialog | 640 | 300 | 320,150 offsets |

### Anchors

- Full-screen containers: `anchors_preset = 15` (top-left=0,0 to bottom-right=1,1)
- Top bar: `anchors_preset = 10` (top-stretch, bottom at offset 175)
- Bottom bar: `anchors_preset = 12` (bottom-stretch, with manual offsets)
- Centered panels: `anchors_preset = 8` (anchor_left=0.5, anchor_top=0.5, etc.)

### Separation Values (in use)

| Location | Separation |
|---|---|
| MainMenu CenterVBox | 22 |
| MainMenu TitleVBox | 6 |
| MainMenu ButtonsVBox | 12 |
| Settings VBox | 16 |
| Settings Rows | 12 |
| HUD TopContainer VBox | 8 |
| HUD BottomContainer | 10 |
| PauseCard VBox | 16 |
| Modal VBox (standard) | 14-16 |
| CardsVBox in modals | 10-14 |

---

## 5. Elements

### Labels

All labels use **default font only** (no custom TTF/OTF files found).

| Location | Font Size | Color | Notes |
|---|---|---|---|
| TitleLabel (main_menu) | 42 | gold | shadow, centered |
| SubtitleLabel (main_menu) | 18 | light blue | centered |
| GoalLabel (main_menu) | 16 | green | centered |
| IconLabel (main_menu) | 56 | default | emoji text |
| PlayButton text | 26 | dark brown | centered |
| Button text (standard) | 18 | default | centered |
| ResetButton text | 14 | muted pink | centered |
| MoneyLabel (HUD) | 24 | gold | outline |
| OrderLabel (HUD) | 22 | light | outline |
| RoundTimeLabel (HUD) | 22 | yellow | outline |
| LaunchRateLabel (HUD) | 20 | yellow | outline |
| StatusInfoLabel (HUD) | 16 | light | outline |
| KnifeInfoLabel (HUD) | 18 | light blue | outline |
| Modal title (standard) | 22-24 | gold | - |
| Modal close button text | 18 | default | - |
| Stat row label | 16 | light | - |
| Stat row value | 17 | colored per stat | - |
| Stat row description | 12 | dim blue | autowrap |
| VersionLabel | 16 | muted blue | - |
| Pause title | 32 | gold | centered |
| Credits title | 40 | gold | outline, centered |
| Confirm title | 26 | gold | centered |

### Buttons

| Type | Size | Style | Font Size |
|---|---|---|---|
| PlayButton (main) | 0x64 min | StyleBoxFlat pill (yellow) | 26 |
| Standard button | 0x52 min | Global theme pill (blue border) | 18 |
| ResetButton | 0x44 min | Global theme (muted) | 14 |
| Close button (X) | 36x36 - 40x40 | Global theme | 18 |
| Cancel button | 180x52 | Global theme | 16 |
| Ok button | 180x54 | Global theme | 17 |
| Buy button (shop) | 120x48 - 130x48 | Global theme | 16-17 |
| StatsButton | 130x56 | Global theme | 18 |
| PauseButton | 130x56 | Global theme | 18 |
| ContinueButton (modal) | 0x52 - 0x60 min | Global theme | 20-22 |

### Panels / PanelContainers

| Location | Style | Border | Corner Radius | Shadow |
|---|---|---|---|---|
| HUD TopContainer | StyleBoxFlat_panel | 2px blue border | 18 | 12px, offset(0,4) |
| Modal Panel (standard) | StyleBoxFlat_modal_bg | 2px blue border | 18 | 20-24px |
| SettingsCard | StyleBoxFlat_settings | 2px blue border | 18 | 10px, offset(0,4) |
| PauseCard | StyleBoxFlat_pause | 2px blue border | 18 | 10px, offset(0,4) |
| ConfirmDialog Card | StyleBoxFlat_dialog | 2px blue border | 18 | 10px, offset(0,4) |
| CardsModal Panel | StyleBoxFlat_modal_bg | 2px blue border | 18 | none |
| ResultsModal PrestigeBox | StyleBoxFlat_prestige_box | none | 12 | none |
| SummaryPanel (card_select) | StyleBoxFlat_summary | 1px green border | 10 | none |

### ProgressBars

| Location | Min Size | Fill Color | Background | Corner Radius |
|---|---|---|---|---|
| OrderProgressBar | 0x26 | purple `Color(0.75, 0.49, 1)` | dark `Color(0.06, 0.08, 0.13)` | 8 |
| EnergyBar | 0x22 | blue `Color(0.18, 0.65, 0.95)` | same as above | 8 |
| Global theme ProgressBar | default | green `Color(0.31, 0.84, 0.62)` | dark `Color(0.09, 0.11, 0.17)` | 8 |

### ScrollContainers

- All use `TouchScrollContainer.gd` script for finger-drag scrolling on mobile
- No horizontal scroll indicators visible

### TabContainer (RunUpgradeModal)

| Tab | Label | Index |
|---|---|---|
| Mejoras | Upgrades | 0 |
| Frutería | Fruit Shop | 1 |
| Armas | Weapon Shop | 2 |

---

## 6. Typography

| Property | Value |
|---|---|
| Font Family | **Default Godot font** (no custom fonts found) |
| Font Files (.ttf/.otf) | None |
| Font Files (.woff2) | None |

### Font Sizes Used (frequency order)

| Size | Usage |
|---|---|
| 18 | Standard button text, descriptions, most labels |
| 16 | Secondary labels, subtitles, settings |
| 24 | Modal titles, HUD money |
| 22 | HUD order, time, close buttons |
| 17 | Settings sliders, stat row values |
| 20 | Continue buttons, secondary titles |
| 14 | Small text, energy label, reset button |
| 28-32 | Pause/Credits titles |
| 40-42 | Main title, Credits title |
| 12 | Stat descriptions, card descriptions |
| 13 | Card rarity labels |
| 15 | Progress bar text, summary text |
| 26 | PlayButton text |
| 30 | Settings title, shop item icons |
| 38-40 | Card icons (emoji) |
| 56 | Main menu icon (emoji) |

### Text Alignment

| Node | Horizontal | Vertical |
|---|---|---|
| Title labels (modals) | Center (1) | Top |
| Button text | Center (1) | Center |
| Progress bar labels | Center (1) | Center |
| Stat row labels | Left (0) | Center |
| Stat row values | Right (2) | Center |
| Summary row labels | Left | Center |
| Summary row values | Right | Center |
| VersionLabel | Left | Top |

### Autowrap

- SubtitleLabel (MainMenu): none
- GoalLabel (MainMenu): none
- CardSelectionModal SubtitleLabel: AUTOWRAP_WORD_SMART (2)
- SummaryPanel descriptions: none
- Stat descriptions (programmatic): AUTOWRAP_WORD_SMART
- Card descriptions (programmatic): AUTOWRAP_WORD_SMART

---

## 7. Styles

### Color Palette (from UiTheme.gd + inline usage)

| Token | Hex | RGBA | Usage |
|---|---|---|---|
| COLOR_BG | `#0E1320` | (0.055, 0.071, 0.125) | Main background |
| COLOR_PANEL | `#141A2E` | (0.078, 0.102, 0.18) | Panel backgrounds |
| COLOR_ROW | `#1A2138` | (0.102, 0.129, 0.22) | Card/row backgrounds |
| COLOR_BORDER | `#32406B` | (0.196, 0.251, 0.42) | Borders (standard) |
| COLOR_ACCENT | `#FFD54A` | (1.0, 0.835, 0.29) | Gold accent, titles |
| COLOR_TEXT | `#E6EDFB` | (0.9, 0.93, 0.98) | Primary text |
| COLOR_TEXT_DIM | `#A6B8D1` | (0.65, 0.72, 0.82) | Dimmed/secondary text |
| COLOR_SUCCESS | `#4FD69E` | (0.31, 0.84, 0.62) | Green success, progress |
| COLOR_DANGER | `#FF5A5E` | (1.0, 0.35, 0.37) | Red danger, quit, error |
| MainMenu BG | `#12141F` | (0.07, 0.08, 0.12) | MainMenu background |
| Main BG (teal) | `#3FB2B8` | (0.246, 0.697, 0.721) | Main.tscn background |
| PlayButton BG | `#FAF838` | (0.98, 0.78, 0.22) | Yellow/gold play button |
| PlayButton Hover | `#FFDB61` | (1.0, 0.86, 0.38) | Lighter on hover |
| PlayButton Pressed | `#CC9A1F` | (0.8, 0.6, 0.12) | Darker on press |
| PlayButton Border | `#FFF19E` | (1.0, 0.95, 0.62) | Gold border |
| HUD Panel BG | `#141A2E` | (0.078, 0.102, 0.18) | Semi-transparent 0.94 |
| Order Progress Fill | `#BF7EFF` | (0.75, 0.49, 1.0) | Purple |
| Order Progress BG | `#0F1421` | (0.06, 0.08, 0.13) | Dark |
| Energy Fill | `#2EA6F2` | (0.18, 0.65, 0.95) | Blue |
| Scrim | `#000000` | various alpha | Overlay dims |
| Modal BG | `#141724` | (0.08, 0.09, 0.14) | Near-black |
| Modal Border | `#5269A1` | (0.32, 0.41, 0.63) | Blue border |
| Settings/Pause BG | `#171C30` | (0.09, 0.11, 0.19) | Dark blue |
| Settings/Pause Border | `#738CD9` | (0.45, 0.55, 0.85) | Bright blue border |
| Credits Border | `#FFE64D` | (1.0, 0.88, 0.3) | Gold border |
| Prestige Label | `#FFE64D` | (1.0, 0.85, 0.2) | Gold |
| Results Red | `#FF5959` | (1.0, 0.35, 0.35) | Red title |
| Summary Green BG | `#0F1E1A` | (0.06, 0.12, 0.1) | Dark green |
| Summary Green Border | `#59B380` | (0.35, 0.7, 0.5) | Green border |
| Prestige Box BG | `#282E47` | (0.16, 0.18, 0.28) | Dark purple-blue |

### Border Radius

| Context | Radius | Notes |
|---|---|---|
| Standard panels/modals | 18 | Consistent across modals |
| Cards/rows (programmatic) | 14 | UiTheme.card_style() |
| Progress bars | 8 | Standard |
| Summary panel | 10 | Slightly less rounded |
| Prestige box | 12 | Slightly less rounded |
| PlayButton | 999 | Full pill shape |
| Settings/Pause Card | 18 | Standard |
| Slider grabber | 999 | Circle |
| Scrollbar track | 4 | Subtle |
| Slider track | 5 | Subtle |
| Global theme panel | 14 | Default |

### Border Width

| Context | Width |
|---|---|
| Standard panels | 2px all sides |
| Summary panel | 1px all sides |
| Global theme buttons | 2px all sides |

### Shadow

| Context | Size | Offset | Color |
|---|---|---|---|
| Standard modals | 20 | (0, 0) | Black 0.6 |
| CardsModal | none | - | - |
| ResultsModal | 24 | - | Black 0.7 |
| SettingsCard | 10 | (0, 4) | Black 0.5 |
| PauseCard | 10 | (0, 4) | Black 0.5 |
| ConfirmDialog Card | 10 | (0, 4) | Black 0.5 |
| Global theme _box_style | configurable | (0, 2) | Black 0.35 |
| PlayButton normal | 6 | (0, 3) | Black 0.4 |
| PlayButton hover | 7 | (0, 3) | Black 0.4 |
| PlayButton pressed | 3 | (0, 2) | Black 0.3 |
| HUD TopContainer | 12 | (0, 4) | Black 0.4 |

### Content Margins (Modal Panels)

| Modal | Left | Top | Right | Bottom |
|---|---|---|---|---|
| StatsModal | 20 | 20 | 20 | 20 |
| RunUpgradeModal | 20 | 20 | 20 | 20 |
| PrestigeShopModal | 22 | 22 | 22 | 22 |
| CardSelectionModal | 22 | 22 | 22 | 22 |
| ResultsModal | 24 | 24 | 24 | 24 |
| ProgressModal | 20 | 20 | 20 | 20 |
| CreditsModal | 24 | 24 | 24 | 24 |
| SettingsCard | 28 | 24 | 28 | 24 |
| PauseCard | 28 | 24 | 28 | 24 |
| ConfirmDialog Card | 28 | 24 | 28 | 24 |
| Programmatic cards | 16 | 12 | 16 | 12 |

---

## 8. Interactions

### Signals

| Source | Signal | Connected In | Action |
|---|---|---|---|
| MainMenu | start_game_requested | Main.gd | Hide menu, show game |
| MainMenu | open_prestige_shop_requested | Main.gd | Open PrestigeShopModal |
| MainMenu | open_progress_requested | Main.gd | Open ProgressModal |
| MainMenu | open_cards_requested | Main.gd | Open CardsModal (discovered) |
| HUD | open_stats_requested | Main.gd | Pause game, open StatsModal |
| HUD | quit_run_requested | Main.gd | End run (bankrupt) |
| StatsModal | modal_closed | Main.gd | Resume game |
| StatsModal | open_cards_requested | Main.gd | Open CardsModal (active) |
| RunUpgradeModal | open_stats_requested | Main.gd | Open StatsModal |
| RunUpgradeModal | start_next_order_requested | Main.gd | Enable spawning, advance day |
| CardSelectionModal | card_chosen | Main.gd | Open RunUpgradeModal |
| CardSelectionModal | unpayable | Main.gd | End run (bankrupt) |
| ResultsModal | return_to_menu_requested | Main.gd | Show main menu |
| CreditsModal | continue_requested | Main.gd | Open CardSelection for day 100 |
| CreditsModal | exit_requested | Main.gd | Show main menu |
| GameManager | order_completed | Main.gd | Show CardSelection or Credits |
| GameManager | run_ended | Main.gd | Show ResultsModal |

### Button Press Handlers

| Button | Handler | Sound | Action |
|---|---|---|---|
| PlayButton | _on_play_pressed | click | Emit start_game_requested |
| PrestigeShopButton | _on_prestige_shop_pressed | click | Emit open_prestige_shop_requested |
| ProgressButton | _on_progress_pressed | click | Emit open_progress_requested |
| CardsButton | _on_cards_pressed | click | Emit open_cards_requested |
| SettingsButton | _on_settings_pressed | click | Show settings panel |
| ResetButton | _on_reset_pressed | click | Open confirm dialog |
| StatsButton (HUD) | _on_stats_button_pressed | click | Emit open_stats_requested |
| PauseButton | _on_pause_button_pressed | click | Pause game, show pause panel |
| ContinueButton (pause) | _on_continue_pressed | click | Hide pause, resume |
| SettingsButton (pause) | _on_settings_button_pressed | click | Show settings section |
| PauseQuitButton | _on_pause_quit_pressed | click | Open confirm dialog |
| CloseButton (X) | _on_close_pressed | click | Hide modal |
| ContinueButton (modal) | _on_close_pressed | click | Hide modal |
| CardsButton (stats) | _on_cards_pressed | click | Emit open_cards_requested |
| StatsButton (shop) | _on_stats_pressed | click | Emit open_stats_requested |
| ContinueButton (shop) | _on_continue_pressed | click | Hide, emit start_next_order_requested |
| ConfirmDialog Ok | lambda | click | Emit confirmed |
| ConfirmDialog Cancel | lambda | click | Emit canceled |

### Micro-interactions (UiTheme.gd)

| Animation | Function | Parameters |
|---|---|---|
| Pop-in (modal/panel) | `UiTheme.pop_in()` | scale 0.96->1.0, alpha 0->1, 0.22-0.28s |
| Pulse label | `UiTheme.pulse_label()` | scale amount: 1.12-1.14, 0.14-0.24s |
| Confetti burst | `UiTheme.confetti_burst()` | CPUParticles2D, 90-120 particles, 1.4s lifetime |
| Color shift (time) | _on_round_time_changed | Red when <=10s, yellow otherwise |

### UI Dynamics (Animated Content)

**Money Label Pulse (HUD)**

```
Node: MoneyLabel
Variable: GameManager.run_money
Script: HUD.gd
Initial Value: "$0"
Update: _on_money_changed(amount) -> text = "💰 $" + UiTheme.format_money(amount)
Event: GameManager.money_changed signal
Animation: pulse_label if amount > last_amount
```

**Order Progress Bar (HUD)**

```
Node: OrderProgressBar
Variable: GameManager.order_progress / GameManager.order_target
Script: HUD.gd
Initial Value: value=40, max=100
Update: _on_order_progress_changed(progress, target)
Event: GameManager.order_progress_changed signal
```

**Energy Bar (HUD)**

```
Node: EnergyBar
Variable: GameManager.current_energy / StatsManager.get_final_max_energy()
Script: HUD.gd
Initial Value: value=100, max=100
Update: _on_energy_changed(current, max)
Event: GameManager.energy_changed signal
```

**Round Time Label (HUD)**

```
Node: RoundTimeLabel
Variable: GameManager.round_time_left
Script: HUD.gd
Initial Value: "⏱ 60s"
Update: _on_round_time_changed(time_left) -> text = "⏱ " + secs + "s"
Event: GameManager.round_time_changed signal
Color: Red (1.0, 0.4, 0.3) when <=10s, Yellow (1.0, 0.95, 0.6) otherwise
```

**Order Label (HUD)**

```
Node: OrderLabel
Variable: GameManager.current_order
Script: HUD.gd
Initial Value: "📋 Día 1"
Update: _on_order_progress_changed
Event: GameManager.order_progress_changed signal
```

**Status Info Label (HUD)**

```
Node: StatusInfoLabel
Variable: SaveManager.save_data["days_started"]
Script: HUD.gd
Initial Value: "💼 Negocio 1"
Update: _on_order_progress_changed
Event: GameManager.order_progress_changed signal
```

**Launch Rate Label (HUD)**

```
Node: LaunchRateLabel
Variable: StatsManager.get_final_launch_rate()
Script: HUD.gd
Initial Value: "🍉 1.0 frutas/s"
Update: _update_launch_rate_display()
Event: StatsManager.stats_updated signal
```

**Knife Info Label (HUD)**

```
Node: KnifeInfoLabel
Variable: StatsManager.get_equipped_knife_data(), StatsManager.get_final_damage()
Script: HUD.gd
Initial Value: "👊 Utensilio básico"
Update: _update_knife_display()
Event: GameManager.run_knife_equipped, StatsManager.stats_updated signals
```

**Pause Day Label (HUD)**

```
Node: PauseDayLabel
Variable: GameManager.current_order
Script: HUD.gd
Initial Value: ""
Update: _on_pause_button_pressed() -> text = "📋 Día " + current_order
Event: PauseButton pressed
```

---

## 9. Reusable Components

### ConfirmDialog

| Property | Value |
|---|---|
| ID | `confirm_dialog` |
| Scene | `res://scenes/ui/ConfirmDialog.tscn` |
| Root Node | `ConfirmDialog` (Control, class_name ConfirmDialog) |
| Properties | title, message, ok_text, cancel_text, ok_font_color |
| Inputs | open(title, message, ok_text, cancel_text, ok_font_color) |
| States | visible/hidden |
| Instances | MainMenu.ResetConfirmDialog, HUD.PauseConfirmDialog |

### SettingsSection

| Property | Value |
|---|---|
| ID | `settings_section` |
| Scene | `res://scenes/ui/SettingsSection.tscn` |
| Root Node | `SettingsSection` (VBoxContainer, class_name SettingsSection) |
| Properties | master/music/sfx volume |
| Inputs | sync() method to refresh from SettingsManager |
| States | static (always visible when parent is visible) |
| Instances | MainMenu SettingsPanel, HUD PausePanel |

### TouchScrollContainer

| Property | Value |
|---|---|
| ID | `touch_scroll_container` |
| Script | `res://scripts/ui/TouchScrollContainer.gd` |
| Root Node | Extends ScrollContainer |
| Properties | Finger-drag scroll |
| Inputs | Touch/drag events |
| Used By | StatsModal, RunUpgradeModal (3 tabs), PrestigeShopModal, CardSelectionModal |

### CardItem (Programmatic Component)

| Property | Value |
|---|---|
| ID | `card_item` |
| Created In | CardSelectionModal.gd, CardsModal.gd |
| Root Node | PanelContainer (created via `UiTheme.apply_card()`) |
| Properties | icon (emoji), rarity, title, description, color |
| Inputs | Card data dictionary from CardDatabase |
| Used By | CardSelectionModal, CardsModal |

### UpgradeItem (Programmatic Component)

| Property | Value |
|---|---|
| ID | `upgrade_item` |
| Created In | RunUpgradeModal.gd |
| Root Node | PanelContainer (created via `UiTheme.apply_card()`) |
| Properties | icon (emoji), name, level, description, price, buy button |
| Inputs | Upgrade definition from StatsManager |
| Used By | RunUpgradeModal (Mejoras tab) |

### FruitShopItem (Programmatic Component)

| Property | Value |
|---|---|
| ID | `fruit_shop_item` |
| Created In | RunUpgradeModal.gd |
| Root Node | PanelContainer (created via `UiTheme.apply_card()`) |
| Properties | emoji, name, HP, reward range, price, locked/unlocked state |
| Inputs | Fruit data from FruitDatabase |
| Used By | RunUpgradeModal (Frutería tab) |

### WeaponShopItem (Programmatic Component)

| Property | Value |
|---|---|
| ID | `weapon_shop_item` |
| Created In | RunUpgradeModal.gd |
| Root Node | PanelContainer (created via `UiTheme.apply_card()`) |
| Properties | icon, name, damage, energy cost, price, equipped/locked state |
| Inputs | Knife data from StatsManager.knives_db |
| Used By | RunUpgradeModal (Armas tab) |

### StatRow (Programmatic Component)

| Property | Value |
|---|---|
| ID | `stat_row` |
| Created In | StatsModal.gd, ProgressModal.gd |
| Root Node | PanelContainer (created via `UiTheme.apply_card()`) |
| Properties | label, value, description, color |
| Inputs | Stats from StatsManager |
| Used By | StatsModal, ProgressModal |

---

## 10. Data Bindings

### GameManager Signals -> UI

| Signal | Parameters | Consumed By | Updates |
|---|---|---|---|
| money_changed | current_money: float | HUD.gd | MoneyLabel text + pulse |
| order_progress_changed | progress: float, target: float | HUD.gd | OrderLabel, OrderProgressBar, OrderProgressLabel, StatusInfoLabel |
| energy_changed | current_energy, max_energy | HUD.gd | EnergyBar, EnergyLabel |
| round_time_changed | time_left: float | HUD.gd | RoundTimeLabel text + color |
| run_knife_equipped | knife_id: String | HUD.gd | KnifeInfoLabel |
| order_completed | order_num: int | Main.gd | Open CardSelection/Credits |
| run_ended | summary: Dictionary | Main.gd | Open ResultsModal |
| run_started | (none) | (internal) | - |

### StatsManager Signals -> UI

| Signal | Parameters | Consumed By | Updates |
|---|---|---|---|
| stats_updated | (none) | HUD.gd, StatsModal.gd, PrestigeShopModal.gd | Refresh stats display |

### SaveManager Signals -> UI

| Signal | Parameters | Consumed By | Updates |
|---|---|---|---|
| prestige_changed | new_amount: int | PrestigeShopModal.gd | PrestigeLabel text |

### Data Flow Architecture

```
VISUAL LAYER (UI Nodes)
    |
    | listens to signals
    |
DATA BINDING LAYER (Signals)
    |
    | emitted by
    |
GAME LOGIC LAYER (Autoloads / Singletons)
    ├── GameManager (run state, money, energy, orders)
    ├── StatsManager (stats, upgrades, cards, knives)
    ├── SaveManager (permanent progress, prestige)
    ├── SettingsManager (audio volumes)
    ├── SoundManager (audio effects)
    ├── FruitDatabase (fruit definitions)
    └── CardDatabase (card definitions)
```

### Key Singletons and What They Provide to UI

| Singleton | UI Data Provided |
|---|---|
| GameManager | money, order progress, energy, round time, current order, game state, run stats |
| StatsManager | damage, energy, crit chance, launch rate, jackpot, all computed stats, active cards |
| SaveManager | prestige points, discovered cards, unlocked fruits/knives, lifetime stats |
| SettingsManager | master/music/sfx volume values |
| UiTheme | format_money(), pop_in(), pulse_label(), apply_card(), confetti_burst() |
| SoundManager | play_click(), play_coin(), play_victory(), play_game_over() |

---

## 11. Navigation Map

```json
{
  "main_menu": {
    "play": "game",
    "prestige_shop": "prestige_shop_modal",
    "progress": "progress_modal",
    "cards": "cards_modal",
    "settings": "settings_panel",
    "reset": "confirm_dialog"
  },
  "game": {
    "stats": "stats_modal",
    "pause": "pause_panel"
  },
  "pause_panel": {
    "continue": "game",
    "settings": "settings_section",
    "quit": "confirm_dialog"
  },
  "stats_modal": {
    "close": "game",
    "cards": "cards_modal"
  },
  "run_upgrade_modal": {
    "stats": "stats_modal",
    "continue": "game"
  },
  "card_selection_modal": {
    "choose_card": "run_upgrade_modal"
  },
  "results_modal": {
    "continue": "main_menu"
  },
  "credits_modal": {
    "continue": "card_selection_modal",
    "exit": "main_menu"
  },
  "prestige_shop_modal": {
    "close": "main_menu"
  },
  "progress_modal": {
    "close": "main_menu"
  },
  "cards_modal": {
    "close": "back"
  }
}
```

---

## 12. Visual States

| State | Context | Visual Change |
|---|---|---|
| normal | All buttons | Default StyleBoxFlat from theme |
| hover | All buttons | Lighter bg, brighter border |
| pressed | All buttons | Darker bg, gold border |
| disabled | Buy buttons (can't afford) | Darker bg, muted text |
| focused | All buttons | Blue border outline |
| locked | Shop items (chain not met) | "🔒 BLOQUEADO" text, disabled |
| unlocked | Shop items (chain met, can't afford) | Price shown, disabled |
| available | Shop items (bought) | "DISPONIBLE" text, disabled |
| equipped | Weapons (in use) | "EN USO" text, disabled |
| low_time | RoundTimeLabel | Red color when <=10s |
| normal_time | RoundTimeLabel | Yellow color when >10s |

---

## 13. Responsive / Mobile Analysis

### Base Configuration

- Viewport: 720x1280 (portrait)
- Stretch mode: `canvas_items` (scales everything)
- Stretch aspect: `keep_width` (width fixed at 720, height adapts)

### Potential Issues

| Issue | Location | Description |
|---|---|---|
| Fixed offsets | All modals | Panels use fixed pixel offsets (e.g., `offset_left = -320`). On wider screens, panels won't stretch. On narrower screens, may overflow. |
| Fixed panel sizes | All modals | 640x860, 620x720 etc. are hardcoded. Taller phones get more whitespace; shorter phones get overflow. |
| BottomContainer | HUD | Manual offsets `offset_top = -90, offset_bottom = -25` are fragile on very short screens. |
| TopContainer height | HUD | Fixed `offset_bottom = 175` may be too tall on some devices or too short when status bar overlaps. |
| CenterVBox | MainMenu | Fixed 600x960 via offsets. On non-720-wide screens with different aspect ratios, this could be misaligned. |
| TouchScrollContainer | All scrollable modals | Works via custom script. No rubber-banding or momentum scrolling. |
| No safe area handling | Modals | Status bar / notch area not considered. |

### Elements Dependent on Resolution

- All fixed-offset panels (every modal, settings, pause)
- BottomContainer in HUD
- TopContainer in HUD
- CenterVBox in MainMenu
- All PanelContainer sizing

### Elements Using Proper Anchors

- Background (full viewport)
- Fruit3DLayer (full viewport)
- TopContainer (top-stretch anchor)
- BottomContainer (bottom anchor with offsets)
- Dimmer/Scrim layers (full viewport)
- Centered panels (anchor 8: center)

---

## 14. Current UI Issues

1. **No custom fonts**: Everything uses Godot's default font. No visual hierarchy through typography.
2. **Heavy programmatic UI**: StatsModal, RunUpgradeModal, PrestigeShopModal, ProgressModal, CardsModal, CardSelectionModal build their content entirely in code. Not inspectable in editor.
3. **Inconsistent modal heights**: 860, 840, 760, 720, 600 - no standard.
4. **Inconsistent content margins**: 20, 22, 24, 28 across modals.
5. **No theme file (.tres)**: Everything is code-generated or inline, making global changes difficult.
6. **Hardcoded colors everywhere**: Color overrides on individual nodes repeat values from UiTheme constants but aren't linked.
7. **Duplicated SettingsSection**: Two instances of the same component (MainMenu + HUD) could be a single shared resource.
8. **VersionLabel text mismatch**: Label shows "v0.013" hardcoded in scene, but project.godot says "0.012". Script overrides it at runtime.
9. **No loading/transition screens**: Direct visibility toggling between screens.
10. **No empty states for shop tabs**: If no upgrades available, tabs show empty VBoxContainers.
11. **PrestigeShopModal no BottomHBox**: Unlike RunUpgradeModal, no footer button area.
12. **CardsModal has no footer**: Unlike other modals, no close/continue button at bottom (relies on X button only).
13. **Inconsistent CloseButton sizing**: 36x36 vs 40x40 across modals.
14. **TouchScrollContainer**: Custom implementation vs native touch, may lack momentum/rubber-band feel.
15. **ResultsModal has no button styling**: ContinueButton uses default theme, not styled to match danger context.
16. **No asset-based UI**: All icons are emojis in text. No actual image/icon assets for UI elements.

---

## 15. Godot-to-External Concept Mapping

| Godot Node Type | External Concept (Figma/Stitch) |
|---|---|
| Control | Frame / Auto Layout container |
| VBoxContainer | Vertical Auto Layout |
| HBoxContainer | Horizontal Auto Layout |
| GridContainer | Grid Layout |
| MarginContainer | Frame with padding |
| PanelContainer | Card / Frame with fill |
| ColorRect | Rectangle / Background fill |
| Label | Text |
| TextureRect | Image |
| Button | Button component |
| ProgressBar | Progress bar component |
| ScrollContainer | Scrollable frame |
| TabContainer | Tab group |
| CanvasLayer | Layer / z-index grouping |
| SubViewportContainer | Embedded viewport / canvas |
| HSlider | Slider component |
| StyleBoxFlat | Fill + Stroke + Corner Radius + Shadow |
| CPUParticles2D | Particle effect (not directly mappable) |

---

## 16. Identification Rules

### ID Convention

Format: `screen.component.element`

Examples:
- `main_menu.header.title_label`
- `main_menu.buttons.play_button`
- `game_hud.top.money_label`
- `game_hud.top.order_progress_bar`
- `game_hud.bottom.stats_button`
- `game_hud.pause.pause_panel`
- `run_upgrade_modal.header.title_label`
- `run_upgrade_modal.tabs.upgrades_tab`
- `stats_modal.panel.stats_vbox`

---

*This document represents the actual current state of the CrazyFruit UI as of version 0.012. No modifications were made to any scene, script, or asset.*
