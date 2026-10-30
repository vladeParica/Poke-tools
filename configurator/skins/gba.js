// Handheld-console skin: indigo shell with the speaker grille as the background, panels like
// the dark screen bezel, light-purple buttons and the green power LED.
PT.registerSkin({
  id: 'gba',
  name: 'Game Boy Advance',
  author: 'Poke-tools',
  dark: true,
  vars: {
    '--bg': '#4b3d9e',
    '--bg-pattern': 'radial-gradient(circle, rgba(18, 10, 58, .32) 1.7px, transparent 2.3px), ' +
      'linear-gradient(160deg, rgba(255, 255, 255, .16), rgba(255, 255, 255, 0) 45%)',
    '--bg-size': '14px 14px, 100% 100%',
    '--surface': '#25212f',
    '--surface-2': '#2f2a3d',
    '--border': '#4b4368',
    '--text': '#efecf9',
    '--muted': '#b9b2da',
    '--accent': '#9c8cf5',
    '--accent-ink': '#1b1830',
    '--accent-2': '#3ad074',
    '--accent-soft': 'rgba(156, 140, 245, .16)',
    '--ok': '#3ad074',
    '--warn': '#f0b54a',
    '--error': '#ff6b6b',
    '--header-bg': '#1c1926',
    '--header-ink': '#e8e4f6',
    '--radius': '18px',
    '--radius-sm': '11px',
    '--shadow': '0 4px 0 rgba(24, 14, 70, .55)',
    '--font-display': '"Arial Black", "Segoe UI", system-ui, sans-serif',
    '--backdrop-opacity': '.18'
  }
});
