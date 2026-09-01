# Crazy Fruit — Documento Maestro de Diseño Visual

> **Versión:** 1.0 · **Motor:** Godot 4.5 (renderer GL Compatibility) · **Plataforma objetivo:** Android (referencia: Samsung Galaxy A56 2340×1080)
> **Base de coordinadas:** canvas lógico 720×1280, proyección `canvas_items` con aspecto `keep_width` (los anchos son fijos a 720 UX; el alto "sube" en móviles altos → el contenido vertical debe crecer con el alto real).
> **Alcance:** diagnóstico de la UI actual + nueva identidad visual + especificación de rediseño + design system + responsive. Sin código.

---

## 1. Pantallas y UI existentes

| # | Pantalla | Nodo/escena | Función | Elementos interactivos | Estado de apertura |
|---|----------|-------------|---------|------------------------|--------------------|
| 1 | **MainMenu** | `scenes/ui/MainMenu.tscn` | Portada: navegar al juego, prestigio, progreso, comodines, ajustes, reiniciar | Botones: JUGAR (dorado, 64px), MERCADO DE PRESTIGIO, VER PROGRESO, COMODINES, AJUSTES, REINICIAR PROGRESO (rojo tenue, 44px); versión abajo-derecha | visible al arrancar |
| 2 | **Gameplay** | `scenes/Main.tscn` + `GameWorld` | Frutas/piedras en parábola (Fruit Ninja), corte por swipe, obstáculos | Trazo de dedo/mouse (SwipeController), sin otros controles | tras JUGAR |
| 3 | **HUD** | `scenes/ui/HUD.tscn` | Info de partida en vivo | StatsButton (📊 Stats), PauseButton (⏸ Pausa); al pausar: CONTiNUAR / AJUSTES / SALIR + confirmación | juego abierto |
| 4 | **Pausa** | `HUD.tscn` (PausePanel) | Pausa la ronda; acceso a ajustes y salir | CONTiNUAR, ⚙️ AJUSTES (va a subvista con 3 sliders + ← VOLVER), 🚪 SALIR (confirmación) | menú de pausa |
| 5 | **Ajustes** | `SettingsSection.tscn` (reutilizable) + `ConfirmDialog.tscn` | Sliders General/Música/SFX + popups de confirmación | 3 HSliders 0-100 %, botones VOLVER/CANCELAR/ACEPTAR | desde menú y pausa |
| 6 | **CardSelectionModal** | `scenes/ui/CardSelectionModal.tscn` | Resumen del día (conseguido / impuesto / ganancia / objetivo del siguiente día) + elegir 1 de 3 comodines | 3 tarjetas con botón ELEGIR COMODÍN | al completar día |
| 7 | **RunUpgradeModal** | `scenes/ui/RunUpgradeModal.tscn` | Mercado entre días: 3 pestañas Mejoras / Frutería / Armas | Tabs, filas de compra ($), botones continuar y stats | tras elegir comodín |
| 8 | **ResultsModal** | `scenes/ui/ResultsModal.tscn` | Resumen del negocio al quebrar/renunciar + reputación ganada | Botón continuar | al finalizar negocio |
| 9 | **PrestigeShopModal** | `scenes/ui/PrestigeShopModal.tscn` | Mejoras permanentes con reputación ⭐ | Filas con botón de compra | desde menú |
| 10 | **ProgressModal** | `scenes/ui/ProgressModal.tscn` | Estadísticas históricas permanentes (solo lectura) | Cerrar | desde menú |
| 11 | **CardsModal** | `scenes/ui/CardsModal.tscn` | Galería de comodines descubiertos / activos (solo lectura) | Cerrar | desde menú y desde Stats |
| 12 | **StatsModal** | `scenes/ui/StatsModal.tscn` | Stats del negocio actual (daño, crítico, resistencia, frutas, economía, suerte, comodines) | Cerrar, abrir Comodines activos | desde HUD / mercado |
| 13 | **FloatingText / JuiceSplash / 3D overlay** | `scenes/game/*` | Feedback de cortes (texto flotante, salpicadura, espejo 3D de frutas) | — (efectos) | en gameplay |

**Flujo actual:** `Menú → JUGAR → HUD/gameplay → (completa día) CardSelection → RunUpgrade → siguiente día … → quebrar/renunciar → ResultsModal → Menú`.

---

## 2. Auditoría de la UI actual

### Layout y medidas (canvas 720×1280)

- **HUD superior:** panel 720 px de ancho × ~175 px de alto, anclado al borde superior con `offset_bottom = 175`, esquinas radii 18. Contiene, con separación 8: fila dinero/día, barra del pedido (26px, radius 8), barra de energía (22px, radius 8), fila de estado (20px) y timer (22px). Texto con outline negro 3-4px y fuente 22-24px.
- **HUD inferior:** fila anclada abajo (offsets −90 / −25), alineación centrada: info de cuchillo expandible + 2 botones 130×56 (📊 Stats, ⏸ Pausa).
- **MainMenu:** VBox central 600×960 (offsets ±300/±480), separación 22; icono 🍎🔪🍉 56px, título 42px dorado, subtítulo 18px; botones: JUGAR (64px, estilo dorado propio), resto 52px, reset 44px.
- **Modales:** todos con patrón *Scrim (negro α0.55–0.6) + panel centrado*: **ResultsModal** 620×720, **Stats/CardSelection/RunUpgrade** 640×840-860, **Progress/Cards** 640×860, **PrestigeShop** 640×760, **Ajustes** 620×440, **ConfirmDialog** 640×300, **Pausa** 600×560.
- **Ventanas/diálogos Godot nativos:** primer par ya sustituido por `ConfirmDialog` (reiniciar / renunciar); el resto de modales son `Control`s propios (sin título nativo).

### Paleta actual (colores exactos)

| Token | Hex | Comentario |
|---|---|---|
| Fondo general (clear color) | `#14171F` | `Color(0.08,0.09,0.13)` |
| Fondo pantalla menú | `#0E1220` | `ColorRect` del MainMenu |
| Azul/turquesa fondo scena Main | `#3EB2B9` | `Main.tscn` Background (choca con el resto) |
| BG panel | `#141A2E` | `COLOR_PANEL` |
| BG fila/card | `#1A2138` | `COLOR_ROW` |
| Borde | `#324068` / `#476394` | `COLOR_BORDER` / border global |
| Borde tarjeta settings/dialog/pausa | `#7388D9` | α 0.9-1 |
| BG tarjeta dialog/pausa | `#171E30` | α 0.98 |
| Acento dorado | `#FFD54A` | `COLOR_ACCENT` (títulos, money, grabber) |
| Texto principal | `#E6EDFA` | `COLOR_TEXT` |
| Texto tenue | `#A6B8D1` | `COLOR_TEXT_DIM` |
| Éxito/verde | `#4FD69E` | `COLOR_SUCCESS` (rellenos, ganancia, sliders) |
| Peligro/rojo | `#FF595E` | `COLOR_DANGER` (daño, salir, confirm destructivo) |
| Relleno pedido | `#BF7DFF` | barra progreso del día |
| Relleno energía | `#2EA6F2` | barra energía |
| Botón normal | bg `#29345C`, borde `#7388D9` | píldora radius 18, sombra 3 |
| Botón hover | bg `#3B4D80`, borde `#B8CDF7` | sombra 4 |
| Botón pressed | bg `#161C33`, borde `#F2C751` | sombra 1 |
| Cuchillo/piedra | grises `#73787F`/`#40464F` | polígono dibujado |

### Tipografía
- **FUENTE:** la del sistema por defecto de Godot (sin fuente embebida). Estilos: títulos 26-42px dorados con sombra; botones 14-26px; etiquetas 15-18px; mini-caption 12-14px. Outline negro 3-5px para texto sobre gameplay (HUD, fruit labels, floating texts).
- **Problema:** no hay familia propia ni pesos; las "itálicas/bold" no existen → jerarquía basada en tamaños y color.

### Iconografía
- **Emojis** para todo: frutas 🍓🍌🍑, armas 👊🔪⚔️🪚, mejoras 💥⚡🍀💰🚀, secciones 🏆🍓🃏💰🍀, botones ⚙️⭐🔄⏸📊. **Inconsistencia:** colores de emoji no siguen paleta, escala desigual (28-56px), render varía por SO.

### Botones, cards, barras, sombras
- Botones píldora radius 18, borde 2px, sombra inferior 1-4px, `content_margin` 24/10. Hover/pressed cambian bg + borde (dorado).
- Cards: `StyleBoxFlat` radius 14, borde 2px, shadow 6-10px violeta; filas de tienda: icono 28-32px + nombre 18px + desc 13-14px + botón 120-130×48 (estado disabled gris, texto BLOQUEADO/DISPONIBLE/EN USO).
- Barras: radius 8, bg `#101517`/borde tenue, relleno coloreado; barra de fruta en escena con fill verde `#33D959` y fondo `#1F1F29`.
- Sombras: negras α0.35-0.5, offset (0,2)-(0,4), tamaños 1-12.

### Jerarquía visual y problemas detectados
1. **Fondo incoherente:** el `Background` teal `#3EB2B9` de Main contrasta con los modales azul-noche → sin identidad ni continuidad de color.
2. **Paleta "noche fría" vs juego de frutas:** azules oscuros dejan el juego apagado; faltan acentos frutales saturados.
3. **Botones monocromos:** todos iguales salvo JUGAR → no se distingue acción primaria vs destructiva vs navegación.
4. **Tablas/rows genéricas:** las tiendas son listas de tarjetas planas sin rareza, sin nivel visual del precio.
5. **Font default:** jerarquía débil, sin rounded display para "casual premium".
6. **Espacios desaprovechados:** MainMenu VBox de 960px deja poco aire; modales usan toda la altura con listas (scroll necesario); el HUD superior concentra 6 datos en 175px.
7. **Feedback pobre:** poca animación de entrada (solo `pop_in`), sin haptics, sin estados de botón con "presionado → hacia abajo", cobros sin "flash" del dinero.
8. **Estados bloqueados** (🔒) dependen de texto en button pequeño; no hay tarjeta "bloqueada" diferenciada.
9. **El 3D overlay** duplica cada fruta (espejo) — coste de rendimiento en móvil bajo; también añade "ruido" visual si no está pulido con los sprites nuevos.
10. **Diálogos Godot nativos residuales:** ninguno (todos son Control propios) — correcto.

---

## 3. UX actual — flujo, claridad, feedback, accesibilidad

### Fortalezas
- Flujo core limpio: `JUGAR → cortar → completar día → comodín → mercado → siguiente día`.
- ConfirmationDialog nativos ya reemplazados por popups con la estética del juego.
- Pausa real (congela timer y spawns) con ajustes accesibles desde el juego.
- Feedback numérico inmediato en cada corte (floaters de daño/dinero, crítico dorado, sin energía, piedra).
- Audio: 3 buses (Master/Music/SFX) y dos temas procedurales; slider se oye al soltar.
- Destructivas con doble confirmación (reiniciar / renunciar).

### Problemas y oportunidades
1. **Meta del día poco prominente:** la barra del pedido es discreta arriba; el jugador corta sin un objetivo visual potente (falta un "cliente/objetivo" claro).
2. **Tres tiendas en tabs** (Mejoras/Frutería/Armas) muy densas; sin búsqueda/orden; el precio no se destaca.
3. **Comodines:** la selección 1 de 3 es el momento de mayor emoción → actualmente solo 3 cards alineadas verticalmente, sin rareza visual fuerte.
4. **Resultado del negocio:** resume números pero no cuenta un "run" (no hay animación de cierre, sin CTA claro además de volver).
5. **Accesibilidad:** no hay tamaños de botón mínimo universal garantizado (algunos botones de 44px); sin soporte de back button de Android; contraste tenue en textos dim (< 4.5:1 en muchos).
6. **Spacing/touch targets:** target mínimo Android = 48dp (~138px lógicos a 720 / 360dp). Varios elementos (filas de 48px, labels) tocan por debajo.
7. **Onboarding ausente:** el jugador ve frutas y obstáculos sin tutorial; el objetivo "impuesto" puede confundir.
8. **Feedback de "no puedes":** botones deshabilitados sin explicación (falta tooltip/reto) y sin SFX de bloqueo.
9. **Safe areas:** `screen/edge_to_edge=false` pero `immersive=true`; HUD usa offsets absolutos (−90/−25) → riesgo en notch/cutouts.

---

## 4. Nueva identidad visual — "casual mobile premium"

**Nombre/concepto:** *Crazy Fruit* — un mercado de frutas alocado, caramelizado y satisfactoriamente jugoso. Visual tan dulce como descender una sandía.

**Pilares visuales (4):**
1. **Jugoso (Juicy):** colores frutales saturados, gradientes vivos, partículas de jugo generosas, squash & stretch en UI.
2. **Caramelo (Candy):** formas redondas, radios grandes, brillos suaves ("specular" en cards/botones), sombras suaves tipo 2 capas, no planas.
3. **Moderno-arcade:** tipografía rounded con contorno, iconos consistentes, números grandes con sufijos (K/M), micro-animaciones bouncy.
4. **Claro (legible):** alto contraste texto/fondo, jerarquía por color+peso+tamaño, targets táctiles ≥ 48dp.

**Dirección artística:**
- Fondo **degradado cálido fresco** (turquesa→verde lima→amarillo) en menú/resultados; en gameplay fondo **agua clara/frutal** con viñeta suave para que el corte destaque (la fruta se ve sobre fondo claro).
- UI siempre sobre **panel oscuro translúcido glamuroso** (navy frutal con acentos neón) para que el oro/dinero y los emojis resalten — el "escenario es luminoso, la interfaz es chocolate oscuro".
- **Acento estrella: dorado #FFC93C** (dinero/ja"); **verde jugo #3FE08A** (éxito); **rosa fresa #FF4D6D** (energía/vida); **violeta** (rareza épica); el resto de colores frutales de la base de datos.

**Emoji + ruta de arte:** mantener emojis como placeholder premium (escala uniforme, con sombra y contorno), con pipeline documentado para sustituir por sprites estilo *hipercasual 3D-baked 2D* (limpiar `res://assets/fruits/*.png` y los .glb de `assets/models/`).

---

## 5. Rediseño de cada pantalla

> Reglas transversales del nuevo sistema (tokens): ver §6. Todas las medidas en px lógicos del canvas 720.

### 5.1 MainMenu
- **Fondo:** degradado vertical `#3AC0C9 → #6FDB8F → #FFE37E` (turquesa→lima→limón) con nubes/fruta flotante decorativa (sprites de `assets/fruits` a baja opacidad, parallax lento). Mantener título sobre banderín.
- **Composición:** logo (emoji grandes + título) en tercio superior; columna central de botones; versión abajo.
- **Título:** "CRAZY FRUIT" 52px dorado con outline blanco/blanco y sombra jugosa; subtítulo 20px blanco al 90%.
- **Botones:** JUGAR = CTA grande dorado (`#FFC93C`) borde blanco, sombra rosa; los demás = botones "berry" violeta claro con icono a la izquierda y raya de color del destino (⭐ dorado, 🏆 azul, 🃏 morado, ⚙️ gris). Reiniciar = pequeño/quitar.
- **Animación:** entrada secuencial bounce de título y botones (stagger 60ms); pulso suave en JUGAR.

### 5.2 Gameplay + HUD
- **Fondo gameplay:** degradado cielo frutal (azul claro→menta) + suelo con banderines; el 3D overlay: mantener solo como "sombra de medio corte" opcional (off por defecto en móvil bajo rendimiento) — en alta representar el corte como dos mitades que giran.
- **HUD superior (altura 200px, glassmorphism):** panel oscuro `#16213A` α0.82 blur suave, radius 20, con **2 packs:** izquierda dinero (grande 30px, dorado, icono 💰) + día; derecha energía+tiempo en chips.
- **Barra de pedido:** pasa a **barra destacada con marcadores**: relleno dorado, hito 🎯 en el objetivo, texto `$1,2K / $2,5K`, animación de "punch" al subir; debajo el **objetivo del día** legible.
- **HUD inferior:** botones píldora con icono+texto 150×60; Stats lleva contador de cortes; Pausa con icono ⏸.
- **Frutas:** sprites `assets/fruits` centrados, radio visual ajustado al hitbox, anillo dorado pulsante en frutas doradas, barra de vida curva tipo "gota" sobre la fruta (verde→rojo con gradiente), nombre solo en frutas doradas.
- **Obstáculo:** piedra rediseñada con brillo + KI guarda (uniforme gris con flash al golpe; gajo de RPG 🥔).
- **Texto flotante:** dinero verde con contorno, daño rojo, crítico dorado 1.6x con rotación; salpicadura revisada (gotas redondas con núcleo) → mantener versión array de la original si el rendimiento lo permite.
- **Trazo de corte:** Line2D con gradiente (blanco→transparente), ancho 6-10, glow dorado en críticos.

### 5.3 Pausa / Ajustes / Confirmaciones
- **Pausa:** panel 620×600 "berry glass"; título ⏸ PAUSA 30px; tarjeta-ajustes (3 sliders con grabber grande 20x20, etiqueta con %); botones CONTINUAR (verde 56px), AJUSTES (violeta 56px), SALIR (rojo 48px); mini-card con el objetivo actual + reputación.
- **Cinco subvistas internas:** menú pausa ⇄ ajustes (con ← VOLVER). Mismo patrón que hoy, rediseñado.
- **ConfirmDialog:** scrim α0.65; card 640×320; título dorado, icono ⚠️; botón ACCEPTAR dorado (destructivo rojo si se pasa color), CANCELAR gris-violeta. Entrada pop-in + tween de sombra.

### 5.4 Fin de día — CardSelection (momento estrella)
- **Composición:** scrim; card 660×900; header "¡Día #N completado!" 34px con 🎉 + confeti (ya existente); **bloque RESUMEN** como 4 chips (Conseguido ✅ / Impuesto 🧾 / Ganancia 💚rango / 🎯 Objetivo sup.); **3 comodines** en horizontal (fila 3-col) con:
  - marco por rareza (Común azul, Rara verde, Épica violeta, Legendaria dorada, Mítica rosa neón + borde animado),
  - icono en badge circular, nombre bold 20px, desc 14px, botón "CRECER" dorado.
- **Interacción:** flujo simple de ida (no se puede deshacer); elegir dispara confeti + pulso en la card seleccionada y salida animada a la tienda. Tarjetas con hit 210×230px para tacto cómodo.

### 5.5 Mercado entre días (RunUpgrade)
- Header: "🛒 MERCADO — Día N" + dinero grande + botones.
- **Tabs rediseñadas** (Mejoras/Frutería/Armas) como 3 píldoras segmentadas activas; cada fila-card:
  - Mejoras: icono en círculo de color, nombre + nivel (chips x1..xn), desc, precio a la derecha con estado (✓ comprada → ¡NIVEL N!).
  - Frutería: emoji grande 40px, stats en chips (Vida / Ganancias), estado: para comprar / ya desbloqueada (✓ verde) / bloqueada con cadena de 🔒 → siguiente fruta.
  - Armas: igual que frutas + botón EQUIPAR (dorado) / EN USO (chip verde).
- **Precios:** botones 150×52 con $ grande; sin dinero → se apaga y muestra "necesitas $X más" en tooltip.
- **Footer:** Stats (izq) + CONTINUAR DÍA (CTA).

### 5.6 Resultado (Results) 
- Fondo teal→lima con confeti; card 620×760; HEADER "💥 NEGOCIO CERRADO" + emoji; **stats en 2×2 grid** de tarjetas (Días, Ganancias, Frutas, Gran ventas + Mejor día); bloque REPUTACIÓN con +N ⭐ animados (contador); CTA único "⭐ AL MERCADO DE PRESTIGIO" + enlace pequeño "volver al menú".

### 5.7 Stats / Progreso / Comodines / Tienda Prestigio
- Listas de la misma card; Stats con secciones por color (título dorado, valores bold); Progress con barras de progreso (X/Y) en lugar de texto; Cards por rareza con marco; Prestigio igual que RunUpgrade (mejoras permanentes, precio en ⭐).

---

## 6. Design System (tokens y componentes)

### 6.1 Color
| Token | Hex | Uso |
|---|---|---|
| `--bg-scene` | `#EAF8FF`→`#D9F99E` (grad) | fondos gameplay/menú |
| `--bg-glass` | `#16213A` α .82 | HUD/paneles |
| `--bg-card` | `#1D2843` α .96 | cards |
| `--bg-row` | `#24304F` | filas |
| `--border-card` | `#3C4F7E` | bordes |
| `--gold` | `#FFC93C` | dinero/título CTA |
| `--gold-soft` | `#FFE08A` | hover gold |
| `--green-juice` | `#3FE08A` | éxito/sliders/progreso |
| `--red-heart` | `#FF4D6D` | vida/coste/energía crítica |
| `--blue-fruit` | `#4DA6FF` | info/azul raza común |
| `--violet-epic` | `#B97BFF` | épica |
| `--pink-mythic` | `#FF6BD6` | mítica |
| `--text` | `#F5F8FF` | texto principal |
| `--text-dim` | `#AAB8D8` | secundario |
| Raras: común `#4DA6FF` · rara `#4ADE80` · épica `#B97BFF` · legendaria `#FFC93C` (anim borde) · mítica `#FF6BD6` neón | | rarezas |

### 6.2 Tipografía
- Fuente placeholder: **system bold + outline**; recomendar importar `Baloo 2` o `Nunito ExtraBold` (500-800) cuando haya asset pipeline.
- Escala (px lógicos): Display 52 / Título 30-34 / Sub 20-22 / Cuerpo 16-18 / Caption 13-14 / Money 28-30.
- Regla: texto sobre gameplay SIEMPRE con outline 4-5px `#000000` α.85.

### 6.3 Botones
- **Primario (CTA):** bg `--gold` #FFC93C, borde blanco 2px, texto #4A2E00 20px, radius 999, sombra `#FF4D6D` 30%; altura 60-64.
- **Secundario:** bg `--bg-card`, borde `--border-card`, radius 18, texto 18; hover sube borde dorado.
- **Destructivo:** texto rojo sobre card (como hoy), confirmación siempre.
- **Tamaño mínimo:** 60px alto en paneles, 48px en gameplay, ancho ≥120; área táctil efectiva ≥ 138px lógicos (48dp @720/360dp).
- Estados: normal/hover/pressed(desplazado 2px + escala 0.96)/disabled(card apagada α.5 + sin sombra).

### 6.4 Cards & componentes
- **Card:** radius 18, borde 2px `--border-card`, sombra 3 capas (0,0,26 α.25 + 0,6,12 α.15 + inset highlight blanco α.08 arriba).
- **Chips:** prefijo: `[tipo]` pill radius 999, font 13, padding 10×18; estados success/danger/lock.
- **Badge de icono:** círculo 56px, bg `--bg-row`, borde de rareza, emoji 30px centrado con sombra.
- **Barras:** height 14-22, radius 999; fill con gradiente + "shine" 1px; label centrada.
- **Slider:** track 8px, fill verde, grabber 24px dorado con borde blanco.
- **Modal:** scrim α0.6 + card centered radius 22, entrada `pop_in` (0.22s scale BACK).
- **Locked:** card a α.55 con patrón diagonal sutil, candado 🔒 en badge, requisito en caption.

### 6.5 Feedback/motion
- In/out: pop-in bounce para modales; stagger 60ms en menús; botones 0.08s scale .96; money pulse 0.14s; barra "punch" al sumar; confeti en triunfos; crítico: flash 0.1s + texto 1.35x; fruta dorada: anillo pulsante 1.2s∞.
- Sonido: click (UI), coin (pago), victory (compra/jackpot), crit, slice, thud, bloqueo (nuevo: tono grave).

### 6.6 Iconografía
- **Regla:** emoji placeholder normalizado: anclado en badge circular, font_size acorde (28 en filas, 40 en frutas/armas, 34 tarjetas), con `outline_size 4` y sombra. Sustituir por sprites de 2x (@4k) sin cambiar nodos.

---

## 7. Responsive (referencia Samsung Galaxy A56)

### Datos diana
- **A56:** 2340×1080 FHD+, ratio 19.5:9 (≈2.167), densidad ~390 ppi, dp ≈ 411×914 px gráficos → en canvas, ancho fijo 720 ⇒ alto lógico efectivo ≈ **1560 píxeles lógicos**.
- Otras dianas: 720×1280 (16:9) y rangos 16:9–20.5:9; `keep_width` garantiza ancho constante; hay que permitir que el alto "respire".
- `screen/immersive_mode=true`, `edge_to_edge=false`: **respetar notch/gesture**: reservar bandas superior ≥ 40px y inferior ≥ 32px lógicos donde no haya contenido interactivo (excepto HUD).

### Reglas
1. **Layouts "crecen del centro":** menús y modales centrados (como ahora) pero con `max` alto ≤ alto efectivo −100px y scroll interno si excede.
2. **HUD** fijo en bordes (top/bottom) con offsets a SAFE-AREA (no valores ciegos): top = 40px + panel 200px; bottom = gesture 32px + 90px.
3. **Grids flexibles:** comodines 3-col fijo en ≥720 (cada card ~196px); en ≤540 transformar a 1-col scroll.
4. **Modales:** ancho máx 640 (90% del viewport en <720); alto máx = alto_efectivo − 120 con `ScrollContainer` interno (ya usan TouchScrollContainer) para que el contenido nunca quede cortado.
5. **fuentes:** no escalar por docena; base en pixeles lógicos con "small phones" factor ≥0.9 si alto < 1280.
6. **Touch targets:** cualquier Control interactivo ≥ 138×138 px lógicos (48dp); separación entre opciones ≥ 16px.
7. **Orientación:** solo portrait (`orientation=1` ya configurado); no rotar.
8. **Rendimiento-preservación:** el 3D overlay reducido/off en bajo rango y en modales (ya hay `render_target_update_mode`; revisar al activar pausa); partículas CPU en cantidades moderadas.

---

*Fin del documento. Iterar aquí antes de generar mockups.*