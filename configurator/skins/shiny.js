// "Shiny" skin: alternate colors and the shiny version of the mascot sprite.
PT.registerSkin({
  id: 'shiny',
  name: 'Shiny',
  author: 'Poke-tools',
  dark: true,
  vars: {
    '--bg': '#111a33',
    '--surface': '#18234a',
    '--surface-2': '#1e2b58',
    '--border': '#2f3f78',
    '--text': '#eef2ff',
    '--muted': '#a6b2dc',
    '--accent': '#ffb000',
    '--accent-ink': '#111a33',
    '--accent-2': '#3a7bff',
    '--accent-soft': 'rgba(255, 176, 0, .14)',
    '--header-bg': '#0b1226',
    '--bg-pattern': 'radial-gradient(circle at 20% 10%, rgba(58, 123, 255, .18), transparent 40%), radial-gradient(circle at 90% 80%, rgba(255, 176, 0, .10), transparent 35%)'
  },
  sprites: { mascot: 'mascot-shiny' }
});
