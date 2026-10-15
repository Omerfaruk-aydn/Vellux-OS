/**
 * Vellux OS Design Tokens — Core Color Palette & Materials
 * Engineered for multi-layer glassmorphism, dynamic vibrance, and specular highlights.
 */

export const colors = {
  // Deep space base canvases (Backdrop layer)
  canvas: {
    black: '#000000',
    deepVoid: '#05070e',
    spaceDark: '#0a0d18',
    surfaceDark: '#0f1424',
    surfaceElevated: '#171e34',
  },

  // Glass Material System (Translucency + Top-Lit Highlights)
  glass: {
    ultraThin: 'rgba(255, 255, 255, 0.04)',
    thin: 'rgba(255, 255, 255, 0.08)',
    regular: 'rgba(255, 255, 255, 0.12)',
    thick: 'rgba(255, 255, 255, 0.18)',
    ultraThick: 'rgba(255, 255, 255, 0.28)',

    // Dark-tinted glass (for Control Center tiles & context menus)
    darkThin: 'rgba(15, 20, 36, 0.45)',
    darkRegular: 'rgba(15, 20, 36, 0.65)',
    darkThick: 'rgba(10, 13, 24, 0.85)',

    // Specular border highlights (simulates light catching 1px beveled edges)
    specularBorder: 'rgba(255, 255, 255, 0.18)',
    specularTopLight: 'rgba(255, 255, 255, 0.35)',
    specularSubtle: 'rgba(255, 255, 255, 0.08)',
  },

  // Vellux Brand Accents (Vibrant Apple-like System Colors)
  accent: {
    blue: '#0a84ff',
    blueGlow: 'rgba(10, 132, 255, 0.35)',
    cyan: '#30d158',
    indigo: '#5e5ce6',
    purple: '#bf5af2',
    pink: '#ff375f',
    teal: '#64d2ff',
    amber: '#ffd60a',
    red: '#ff453a',
  },

  // Human Interface Typography Grays
  text: {
    primary: '#ffffff',
    secondary: 'rgba(255, 255, 255, 0.70)',
    tertiary: 'rgba(255, 255, 255, 0.45)',
    quaternary: 'rgba(255, 255, 255, 0.25)',
  },
};

export const shadows = {
  glassSm: '0 4px 16px 0 rgba(0, 0, 0, 0.25)',
  glassMd: '0 8px 32px 0 rgba(0, 0, 0, 0.37)',
  glassLg: '0 16px 48px 0 rgba(0, 0, 0, 0.45)',
  glassFloatingDock: '0 20px 50px rgba(0, 0, 0, 0.55), 0 0 1px rgba(255, 255, 255, 0.4) inset',
};

export const radii = {
  subtle: '6px',
  sm: '10px',
  md: '14px',
  window: '16px',
  dock: '22px',
  pill: '9999px',
};
