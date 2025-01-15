

## What This Library Provides

This library defines a **piecewise** pricing function to model a token’s price based on its current supply. The price formula is split into two regimes:

1. **Logarithmic (for early-phase, lower supply)**  
2. **Exponential (for mature, higher supply)**  

and it transitions at a “threshold” supply (`T`).

---

## Why a “Hybrid” Bonding Curve?

Traditional bonding curves may use a **pure** formula (e.g., purely exponential or purely polynomial). But in many token systems, you want:

- A **steeper early-phase** so that the price grows quickly (logarithmically) when the liquidity token - in our case USDT - supply is small.  
- A **smooth transition** to an exponential formula once the liquidity token supply grows beyond a threshold.  

Hence, the library calls it a “hybrid” approach:  
- If `supply < T`, use a log-based formula.  
- Otherwise, use an exponential-based formula.

---

## Key Parameters

1. **`supply`**: Current USDT token supply.  
2. **`B`**: Base price scale factor. Essentially, it shifts or scales the entire curve up/down.  
3. **`L`**: Early-phase sensitivity. A higher `L` means slower initial price growth in the log region. A smaller `L` means the price climbs faster early on.  
4. **`E`**: Exponential steepness. Affects how quickly price accelerates once the supply crosses `T`.  
5. **`T`**: Transition supply. The supply amount at which the formula changes from the log regime to the exp regime.

All numeric outputs are handled in **1e18 scale**, meaning the function returns a price as a 1e18 fixed-point value.

---

## The Piecewise Formula

### 1) If `supply < T`:

```text
price = B * log(1 + supply/L)
```

- The code calculates `ratio = supply * 1e18 / L`.
- Calls `MathLib.log1p(ratio)` which approximates `log(1 + ratio)`.
- Multiplies by `B`, then divides by 1e18 to keep scale consistent.

**Interpretation:**  
- For small `supply`, the price grows in a **logarithmic** manner.  
- The presence of `L` adjusts how quickly the log curve rises.

### 2) If `supply >= T`:

```text
price = B * exp((supply - T) / E)
```

- It calculates `diff = supply - T`.
- Then `y = int256((diff * 1e18) / E)` to get a scaled exponent argument.
- Passes `y` to `MathLib.expWad(y)`, which returns e^(y / 1e18).
- Multiplies by `B`, and divides by 1e18 to stay in 1e18 scale.

**Interpretation:**  
- Once supply is beyond `T`, the price transitions to an **exponential** formula, often leading to steeper price growth if the supply keeps increasing.  
- `E` controls how steep the exponential portion is.

---

## Why the `MathLib`?

The code uses external library calls like `MathLib.log1p(...)` and `MathLib.expWad(...)`. These are specialized math functions for:

- **`log1p(ratio)`**: A numerically stable function computing \(\ln(1 + x)\).  
- **`expWad(y)`**: A function that computes \(e^{y / 1e18}\) accurately in fixed-point.

They ensure the bonding curve can handle large or small values without floating-point inaccuracies.

---

## Summary of Its Purpose

1. **Pricing**: Given a token supply, it returns a “price” in 1e18 scale. This is typically used in an AMM or bonding curve contract to decide how much to charge for new tokens or how much to pay when tokens are sold.  
2. **Smooth Early–Mature Transition**: By splitting the formula at `T`, the curve acts gently at first (logarithmic) but eventually transitions to an exponential region.  
3. **Easy Integration**: The function `getPrice(...)` can be called from other contracts (like **HybridExchange**) to get the current token price in real time.

In short, **the `HybridBondingCurve` library** is the core “price function” for a token that starts with a log-based approach at low supply and transitions to an exponential formula at a certain supply threshold, providing a “best of both worlds” effect for early-phase vs. mature-phase pricing.
