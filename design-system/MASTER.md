# Vellux Human Interface Guidelines (VHIG) & Design System Master Specification

**Document Authority:** Design Architecture Tier 1  
**Target:** Vellux OS Human Interface & Wayland Compositor  
**Platform Conventions:** Pure Wayland, High-DPI Fractional Scaling, 120Hz/144Hz Adaptive VRR  

---

## 1. Ergonomics & Visual Hierarchy Architecture

True professional operating system design does not rely on random glowing circles, excessive borders, or heavy illegible translucency. In Vellux OS:

1. **Content First, Material Second:** Translucency exists exclusively to provide spatial grounding—explaining which surface is floating above which without obscuring readability.
2. **Dynamic Vibrancy & Contrast Isolation:** Text rendering must pass WCAG AAA (contrast ratio >= 7.0:1). Translucent panels feature an opaque backing luminance clamp so dark/light content behind the panel never destroys font legibility.
3. **Restrained Specular Lighting:** Single-pixel hairline borders (`1.0px`) receive an angle-dependent directional gradient simulating top-down ambient light (sun/ceiling fixture). Bottom edges fall off into deep soft ambient occlusion.
4. **Physical Continuity:** Windows and sheets originate from their triggers (e.g. dock icon expands into the window; control center slides down seamlessly from the status pill).

---

## 2. Design Token System

### 2.1 Surfaces & Materials

| Token | Semantic Purpose | Real CSS Value | Compositor Pass |
| :--- | :--- | :--- | :--- |
| `--vx-mat-glass-thick` | Floating Dock & Control Center | `rgba(18, 22, 34, 0.72)` | Dual-Kawase 4-pass + 1.25 Vibrancy |
| `--vx-mat-glass-window`| Active App Windows | `rgba(14, 18, 28, 0.82)` | Dual-Kawase 2-pass + Opacity Clamp |
| `--vx-mat-elevated`    | Sliders, Switches & Menu Tiles | `rgba(255, 255, 255, 0.08)` | Fast Box Blur |
| `--vx-mat-elevated-hover`| Interactive Tile Hover | `rgba(255, 255, 255, 0.13)` | Immediate State Switch |
| `--vx-border-specular` | Top-lit 1px Edge Reflection | `linear-gradient(180deg, rgba(255,255,255,0.24) 0%, rgba(255,255,255,0.06) 100%)` | Hardware Stencil Border |
| `--vx-border-separator`| Inner Dividers & Menu Lines | `rgba(255, 255, 255, 0.08)` | 1px Direct Vector Line |

### 2.2 Typography Hierarchy

System font stack: `-apple-system, BlinkMacSystemFont, "SF Pro Display", "Inter Display", "Geist", system-ui, sans-serif`.

* **Large Display (28px / 34px line, -0.6px track, Weight 600):** System dialogues, hero headers.
* **Window Title (13px / 16px line, -0.2px track, Weight 600):** Window title bars, panel captions.
* **Status Bar & Menus (13px / 16px line, -0.1px track, Weight 500):** Menu items, top bar clocks.
* **Body Regular (13px / 18px line, 0.0px track, Weight 400):** General application text.
* **Caption / Meta (11px / 14px line, +0.2px track, Weight 500):** Subtitles, hardware metrics, badges.

### 2.3 Mathematical Motion Architecture (Spring Constants)

Animations are driven by monotonic time delta $\Delta t$ solving:

$$m \frac{d^2x}{dt^2} + c \frac{dx}{dt} + k(x - x_{\text{target}}) = 0$$

* **Window Open:** $k = 320$, $c = 26$, $m = 1.0$ (Gentle settling with 2.5% overshoot)
* **Dock Magnify:** $k = 480$, $c = 32$, $m = 0.8$ (High responsiveness, 0 overshoot)
* **Icon Pop:** $k = 260$, $c = 14$, $m = 1.0$ (Tactile bouncy launch feedback)
* **Sheet Transition:** $k = 360$, $c = 30$, $m = 1.1$ (Weighted natural drape)
