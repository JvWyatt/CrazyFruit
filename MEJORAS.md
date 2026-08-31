# 📊 Catálogo de Mejoras — Crazy Fruit

Inventario completo de todo lo mejorable del juego, organizado por categoría.
Extraído de `StatsManager.gd`, `CardDatabase.gd`, `FruitDatabase.gd`,
`GameManager.gd` y `RunUpgradeModal.gd`.

## Índice
1. Mejoras del Mercado (por partida)
2. Comodines / Cartas
3. Prestigio (permanente)
4. Armas / Cuchillos
5. Frutas (Frutería)
6. Mecánicas base de balance
7. Ideas para proponer más mejoras

---

## 1) Mejoras del Mercado *(por partida, se pierden al quebrar)*

Se compran con el dinero del negocio (`run_money`); el precio crece geométricamente
con cada nivel: `costo = base × (multiplicador)ⁿ`. Se resetean en `reset_run_stats()`.

| Mejora | Ícono | Efecto por nivel | Costo base | Crecimiento |
|---|---|---|---|---|
| Afilado de Hoja | 💥 | +10% daño | 10 | ×1.35 |
| Resistencia | ⚡ | +10% resistencia máxima | 15 | ×1.35 |
| Golpe de Suerte | 🍀 | +0.3% probabilidad de Jackpot | 30 | ×1.45 |
| Negociación | 💰 | +10% multiplicador de ganancias | 40 | ×1.45 |
| Cosecha Veloz | 🚀 | +10% frecuencia de lanzamiento | 20 | ×1.40 |

---

## 2) Comodines / Cartas *(55 tarjetas, temporales por partida)*

Al completar un pedido se elige **1 de 3 cartas** aleatorias. Los bonos se pierden
al quebrar el negocio.

### ◆ Comunes (20)
| Carta | Efecto |
|---|---|
| Filo Ligero | +3% daño |
| Buen Aguante | +3% resistencia máxima |
| Cosecha Segura | +3% recompensa mínima |
| Fruta Valiosa | +3% recompensa máxima |
| Pequeña Fortuna | +0.3% probabilidad Jackpot |
| Premio Mayor | +0.1× multiplicador Jackpot |
| Buen Negocio | +3% multiplicador de ganancias |
| Punto Preciso | +1% probabilidad de Crítico |
| Ritmo Constante | +3% frecuencia de lanzamiento |
| Fruta Delicada | −3% vida de las frutas |
| Armas Baratas | −3% precio de armas |
| Frutas Baratas | −3% precio de frutas |
| Mejoras Baratas | −3% precio de mejoras |
| Buen Progreso | −3% objetivo del día |
| Filo Afortunado | +2% daño y +0.2% Jackpot |
| Cosecha Rentable | +2% recompensa mín. y +2% máx. |
| Golpe Valioso | +2% Crítico y +2% dinero |
| Corte Eficiente | +2% daño y +2% resistencia máx. |
| Lluvia Ligera | +2% frecuencia y +2% recompensa máx. |
| Cosecha Veloz | +2% frecuencia y +2% daño |

### ◆ Raras (15)
| Carta | Efecto |
|---|---|
| Filo Superior | +7% daño |
| Reserva Extra | +8% resistencia máxima |
| Cosecha Rica | +8% recompensa mínima |
| Fruta Dorada | +8% recompensa máxima |
| Fortuna Creciente | +1% Jackpot |
| Jackpot Mejorado | +0.3× multiplicador Jackpot |
| Negocio Próspero | +7% ganancias |
| Golpe Certero | +4% Crítico |
| Ritmo Fuerte | +7% frecuencia |
| Fruta Frágil | −7% vida de las frutas |
| Comerciante | −7% precio de armas, frutas y mejoras |
| Día Favorable | −7% objetivo del día |
| Racha de Cortes | +4% Crítico y +4% daño |
| Lluvia Rentable | +4% frecuencia y +4% recompensa mín. |
| Negocio Veloz | +4% frecuencia y +4% ganancias |

### ◆ Épicas (10)
| Carta | Efecto |
|---|---|
| Filo Devastador | +15% daño |
| Reserva Titánica | +20% resistencia máxima |
| Cosecha Abundante | +15% recompensa mín. y máx. |
| Fortuna Dorada | +2% Jackpot y +0.5× mult. Jackpot |
| Golpe Mortal | +7% Crítico y +15% daño |
| Mercado Dorado | +15% ganancias |
| Tormenta de Frutas | +15% frecuencia |
| Fruta Frágil II | −15% vida de las frutas |
| Cortes en Cadena | +8% Crítico y +10% frecuencia |
| Viento a Favor | +10% frecuencia y +10% recompensa máx. |

### ◆ Legendarias (5)
| Carta | Efecto |
|---|---|
| Filo Supremo | +30% daño |
| Resistencia Titánica | +35% res. máx. y +15% frecuencia |
| Fortuna Suprema | +3% Jackpot y +1× mult. Jackpot |
| Golpe Perfecto | +10% Crítico y +30% daño |
| Cosecha Torrencial | +30% frecuencia, +20% recompensa, +20% ganancias |

### ◆ Fruta Dorada (5)
| Carta | Rareza | Efecto |
|---|---|---|
| Brillo Dorado | Común | +0.0625% prob. de Fruta Dorada |
| Toque Dorado | Rara | +0.125% |
| Cosecha Dorada | Épica | +0.25% |
| Leyenda Dorada | Legendaria | +0.5% |
| **Oro Puro** | **Mítico** | +1% |

> ⚠️ **Hueco detectado:** el efecto `energy_cost` (reducir el gasto de energía del
> arma) está programado en `StatsManager._apply_card_effect()` pero **ninguna carta
> lo usa**. Es un candidato ideal para nuevas cartas.

---

## 3) Prestigio *(permanente)*

Se compra con **reputación** (puntos que sobreviven a la quiebra). Costo:
`base × 2.2ⁿ`. El nivel nunca se resetea.

| Mejora | Ícono | Efecto por nivel | Costo base |
|---|---|---|---|
| Maestría | ⚔️ | +20% daño inicial | 10 |
| Experiencia | 🧤 | +20% resistencia máxima | 25 |
| Buen Proveedor | 📦 | +20% multiplicador de ganancias | 50 |
| Buena Fortuna | ⭐ | +1% probabilidad de Jackpot | 100 |
| Ritmo Veloz | 🚀 | +25% frecuencia de lanzamiento | 60 |

**Cómo se gana reputación** (al finalizar/quebrar el negocio):
`10 pts por pedido completado + 1 pt por cada $50.000 generados`.

---

## 4) Armas / Cuchillos *(10)*

Se desbloquean/equipan por partida en la pestaña **Armas**.

| Arma | Ícono | Daño | Gasto energía | Precio |
|---|---|---|---|---|
| Puño | 👊 | 5 | 1.0 | gratis |
| Tenedor | 🍴 | 10 | 0.9 | $40 |
| Cuchillo de mesa | 🔪 | 15 | 0.8 | $90 |
| Tijera | ✂️ | 20 | 0.7 | $180 |
| Cúter | 🪒 | 25 | 0.6 | $340 |
| Cuchillo | 🔪 | 35 | 0.5 | $650 |
| Machete | 🗡️ | 50 | 0.4 | $1.250 |
| Hacha | 🪓 | 70 | 0.3 | $2.400 |
| Espada | ⚔️ | 95 | 0.2 | $4.600 |
| Motosierra | 🪚 | 130 | 0.1 | $9.000 |

---

## 5) Frutas *(Frutería, 20 en cadena)*

La Frutería está bloqueada en **cadena**: no puedes comprar una fruta sin haber
comprado la anterior. Desbloqueos por partida.

| Fruta | Vida | Recompensa | Precio |
|---|---|---|---|
| 🍓 Fresa | 18 | 1–10 | inicial |
| 🍌 Banana | 27 | 5–15 | $120 |
| 🍑 Melocotón | 41 | 8–25 | $260 |
| 🍒 Cereza | 61 | 15–45 | $550 |
| 🍊 Naranja | 91 | 25–80 | $1.100 |
| 🍎 Manzana | 137 | 45–135 | $2.200 |
| 🍐 Pera | 205 | 80–235 | $4.200 |
| 🥝 Kiwi | 308 | 140–420 | $8.000 |
| 🥭 Mango | 461 | 240–720 | $15.000 |
| 🍋 Limón | 692 | 420–1250 | $30.000 |
| 🍉 Sandía | 1400 | 750–2200 | $60.000 |
| 🍈 Melón | 1900 | 1300–3900 | $120.000 |
| 🍍 Piña | 2600 | 2250–6800 | $240.000 |
| 🥭 Papaya | 3500 | 4.000–12.000 | $480.000 |
| 🥥 Coco | 4700 | 7.000–21.000 | $960.000 |
| 🥑 Aguacate | 6300 | 12.000–36.000 | $1.900.000 |
| Pitahaya | 8500 | 21.000–64.000 | $3.800.000 |
| Guayaba | 11500 | 37.000–112.000 | $7.500.000 |
| Membrillo | 15500 | 65.000–195.000 | $15.000.000 |
| 🎃 Calabaza | 21000 | 114.000–340.000 | $30.000.000 |

> Otros 13 STATS que usan las frutas: penalización de vida/recompensa por comodines;
> el **crítico** siempre multiplica ×2 (fijo, no mejorable); hay **fruta dorada** (1%
> base) que paga recompensa extra.

---

## 6) Mecánicas base de balance

| Regla | Valor |
|---|---|
| Duración de ronda | **60 s** (fijo, no mejorable) |
| Energía inicial | 100 |
| Penalización por piedra | −25% de la resistencia máxima |
| Probabilidad de piedra | 8% base, +0.4% por pedido, máx 30% |
| Probabilidad de Fruta Dorada | 1% base (+bonus de cartas) |
| Multiplicador de Jackpot | ×5 (+bonus de cartas) |
| Multiplicador de Crítico | ×2 (fijo) |
| Objetivos de pedido | $30 inicio, ×1.75 por día (20 valores + fórmula) |

Fórmula de objetivos más allá del pedido 20: `1.239.500 × 1.75^(pedido−20)`.

---

## 7) Ideas para proponer más mejoras

**Cartas nuevas (de paso ya hay efectos programados sin usar):**
- `energy_cost`: −gasto de energía del arma por golpe (efecto vacío, listo para usar).
- Nuevas combinadas: Crítico + frecuencia, Jackpot + recompensa, energía + dinero, etc.
- Cartas "sacrificio/riesgo": +gran daño pero −resistencia, etc.

**Mejoras del mercado nuevas:**
- Regeneración de energía por corte.
- Bonus por racha (cortes seguidos sin fallar).
- Descuento del primer nivel del mercado (cap en la escalada ×1.35–1.45).
- Fruta dorada garantizada en pedidos complicados.

**Prestigio nuevo:**
- Descuento permanente en el mercado (multiplica `card_upgrade_price_multiplier` base).
- Empezar cada negocio con 1 fruta o arma extra desbloqueada.
- Recompensa mínima global (multiplicador de `reward_min` permanente).

**Sistema armas:**
- `KnifeShopModal` existe pero **no está conectado a ningún botón** (ver nota en
  `SaveManager.gd`): podría habilitarse como tienda permanente entre negocio.
- Armas especiales con efecto único (cuchillo que hace crítico garantizado 1 vez, etc.).

**Sistema frutas:**
- Frutas con efectos especiales (sandía que revienta daño en área, coco con rebote).
- Refresco de la cadena actual (sin desbloqueos es un "ruido" temporal).

---

*Este documento se mantiene manualmente; si cambias números en `StatsManager.gd`,
`CardDatabase.gd`, `FruitDatabase.gd`, `GameManager.gd` o `RunUpgradeModal.gd`,
actualízalo para que no se desincronice.*