// Gengar skin: dark ghost purple with a shadowy haze, its red eyes as the highlight and
// Gengar itself behind every form.
PT.registerSkin({
  id: 'gengar',
  name: 'Gengar',
  author: 'Poke-tools',
  dark: true,
  backdrop: 'Gengar',
  vars: {
    '--bg': '#1c1430',
    '--bg-pattern': 'radial-gradient(circle at 12% 18%, rgba(150, 90, 255, .28), transparent 42%), ' +
      'radial-gradient(circle at 88% 92%, rgba(255, 70, 110, .14), transparent 38%), ' +
      'radial-gradient(circle at 60% 40%, rgba(110, 60, 200, .16), transparent 55%)',
    '--surface': '#291e42',
    '--surface-2': '#33264f',
    '--border': '#4d3a74',
    '--text': '#f2ecff',
    '--muted': '#bcaadf',
    '--accent': '#a46bff',
    '--accent-ink': '#170f26',
    '--accent-2': '#ff4d6d',
    '--accent-soft': 'rgba(164, 107, 255, .17)',
    '--ok': '#4ade80',
    '--warn': '#fbbf24',
    '--error': '#ff5c7a',
    '--header-bg': 'linear-gradient(90deg, #140d22, #2c1c4a 70%, #3a2163)',
    '--header-ink': '#efe8ff',
    '--shadow': '0 8px 28px rgba(8, 4, 20, .55)',
    '--backdrop-opacity': '.22'
  }
});
