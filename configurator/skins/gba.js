// Handheld-console skin: glossy indigo plastic shell, near-black screen bezel as the top bar,
// grey LCD-like panels, light-grey buttons and the speaker slots in the bottom-left corner.
(function () {
  // Six diagonal speaker slots, drawn in pixels from the bottom-left corner of the page.
  var slots = '';
  for (var i = 0; i < 6; i++) slots += "<line x1='" + i * 15 + "' y1='46' x2='" + (i * 15 + 24) + "' y2='0'/>";
  var speaker = "<svg xmlns='http://www.w3.org/2000/svg' width='100%' height='100%'>" +
    "<svg x='0' y='100%' overflow='visible'><g transform='translate(34 -84)' stroke='rgba(28, 20, 88, .45)' " +
    "stroke-width='6' stroke-linecap='round'>" + slots + '</g></svg></svg>';

  PT.registerSkin({
    id: 'gba',
    name: 'Game Boy Advance',
    author: 'Poke-tools',
    vars: {
      '--bg': '#6a62d6',
      '--bg-pattern': 'url("data:image/svg+xml,' + encodeURIComponent(speaker) + '"), ' +
        'linear-gradient(150deg, #9b96ef 0%, #6d65d9 38%, #5047bd 100%)',
      '--bg-size': '100% 100%, 100% 100%',
      '--on-bg': '#ffffff',
      '--on-bg-muted': '#e2dffc',
      '--surface': '#cfd2ca',
      '--surface-2': '#c1c5bb',
      '--border': '#2a2a30',
      '--text': '#1c1e1b',
      '--muted': '#474b45',
      '--accent': '#4f45c2',
      '--accent-ink': '#ffffff',
      '--accent-2': '#e4e4ec',
      '--accent-soft': 'rgba(79, 69, 194, .16)',
      '--header-bg': '#26262c',
      '--header-ink': '#e6e6ee',
      '--radius': '22px',
      '--radius-sm': '12px',
      '--shadow': '0 6px 0 rgba(36, 26, 110, .38)',
      '--font-display': '"Arial Black", "Segoe UI", system-ui, sans-serif',
      '--backdrop-opacity': '.2'
    }
  });
})();
