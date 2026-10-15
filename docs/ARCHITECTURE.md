# Vellux OS Architecture Blueprint & Engineering Specification

**Document Version:** 1.0.0-PROPOSAL  
**Target:** Independent Modern Linux Operating System  
**Display Server:** Pure Wayland (Zero X11 Core)  
**Target Frame Latency:** < 8.3ms (120 Hz) / < 6.9ms (144 Hz)  

---

## 1. System Philosophy & Non-Negotiable Invariants

1. **No Artificial Linear Transitions:** Every movement (dock zoom, window open, control center slide, notification reveal) is mathematically computed via a mass-spring-damper differential equation solver.
2. **True Glassmorphism (Dual-Kawase Hardware Pipeline):** Background surfaces do not rely on flat opacity. The compositing engine samples the frame buffer behind the element, executes a multi-pass downsample/upsample Kawase blur on the GPU, applies a +15% saturation matrix, and adds a top-lit 1px specular reflection border.
3. **Flicker-Free Boot Orchestration:** No screen mode changes, no raw kernel TTY output, no blinking cursor during startup. Seamless handoff from UEFI GOP framebuffer -> Plymouth boot screen -> Wayland compositor login greeter.
4. **Independent Package Ecosystem:** Self-contained packages with declarative recipes (`Vpkgfile`), dependency resolution using modern SAT-solving logic, and deterministic build chroots.

---

## 2. Directory Structure Matrix

```
D:/Vellux-OS/
├── assets/                       # Branding, icons, audio, and visual assets
│   ├── branding/                 # Logos, banners, vector marks
│   ├── sound/                    # System acoustic identity (PipeWire audio events)
│   └── wallpapers/               # Dynamic day/night 5K glassmorphic backdrops
├── core/                         # Base system specifications & init definitions
│   ├── boot/                     # Plymouth theme, GRUB/systemd-boot configs
│   ├── kernel/                   # Low-latency Linux kernel configuration
│   └── services/                 # System service units (networking, audio, power)
├── shell/                        # Vellux Human Interface Environment (The UI)
│   ├── bar/                      # Top Status Bar & Global Menu Engine
│   ├── dock/                     # Floating Fluid Glass Dock (Spring Physics)
│   ├── control-center/           # Modular Quick Settings & Hardware Sliders
│   ├── launcher/                 # Spotlight-style Glass Application Search
│   └── theme/                    # Design tokens, CSS variables, typography
├── compositor/                   # Wayland Compositor engine & shaders
│   ├── shaders/                  # Dual-Kawase blur, specular borders, corner radii
│   ├── animations/               # Spring physics curve presets & easing
│   └── config/                   # Window management rules & input gesture maps
├── pkg/                          # Vellux Package Engine (`vellux-pkg`)
│   ├── bin/                      # CLI executable
│   ├── lib/                      # Core package resolver, unpacker, repo engine
│   └── recipes/                  # Package build recipes (Vpkgfile definitions)
│       ├── core/                 # Glibc, Linux-headers, Bash, Coreutils
│       ├── display/              # Wayland, Mesa, Seatd, PipeWire
│       └── desktop/              # Shell components, terminal, file manager
└── docs/                         # Developer documentation & contribution specs
```

---

## 3. The 8 Comprehensive Engineering Categories

| Category | Domain | Goal & Deliverables |
| :--- | :--- | :--- |
| **Category 1** | **Brand & Blueprint** | Brand vectors, visual design identity, architectural manifest, GitHub repository setup. |
| **Category 2** | **Design Tokens & Motion Engine** | Color scales, dynamic glass tokens, typography rules, spring physics math engine. |
| **Category 3** | **Human Interface Shell (UI)** | Floating Glass Dock (Fish-eye zoom), Top Status Bar, Modular Control Center. |
| **Category 4** | **Compositor & GPU Shader Engine** | Wayland configuration, GLSL Dual-Kawase blur passes, 1:1 gesture tracking. |
| **Category 5** | **Vellux Package Manager (`vellux-pkg`)** | CLI package manager, `.vpkg.tar.zst` format, repository indexing & dependency resolution. |
| **Category 6** | **Base System & Core Recipes** | Declarative build recipes for Linux Kernel, Glibc, Coreutils, NetworkManager, PipeWire. |
| **Category 7** | **Acoustic Design & Plymouth Boot** | Low-latency PipeWire sound themes and flicker-free Plymouth boot animations. |
| **Category 8** | **Live ISO & Calamares Glass Installer** | Complete bootable ISO creation pipeline with modern glass installer. |
