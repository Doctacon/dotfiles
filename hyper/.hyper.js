// Hyper Terminal Configuration
// ~/.hyper.js
// Documentation: https://hyper.is/#cfg

module.exports = {
  config: {
    // Choose either 'stable' for receiving highly polished,
    // or 'canary' for less polished but more frequent updates
    updateChannel: 'stable',

    // Default font size in pixels for all tabs
    fontSize: 14,

    // Font family with optional fallbacks
    fontFamily: '"Fira Code", "DejaVu Sans Mono", Consolas, "Lucida Console", monospace',

    // Enable ligatures
    fontWeightBold: 'bold',

    // Font weight for bold characters
    fontWeight: 'normal',

    // Line height as a relative unit
    lineHeight: 1.2,

    // Letter spacing as a relative unit
    letterSpacing: 0,

    // Terminal cursor background color and opacity (hex, rgb, hsl, hsv, hwb or cmyk)
    cursorColor: 'rgba(248,28,229,0.8)',

    // Terminal text color under BLOCK cursor
    cursorAccentColor: '#000',

    // `'BEAM'` for |, `'UNDERLINE'` for _, `'BLOCK'` for █
    cursorShape: 'BLOCK',

    // Set to `true` (without backticks) for blinking cursor
    cursorBlink: false,

    // Color of the text
    foregroundColor: '#eff0eb',

    // Terminal background color
    backgroundColor: '#282a36',

    // Terminal selection color
    selectionColor: 'rgba(248,28,229,0.3)',

    // Border color (window, tabs)
    borderColor: '#333',

    // Custom CSS to embed in the main window
    css: `
      .tabs_nav {
        overflow-x: auto;
        overflow-y: hidden;
      }
      .tabs_list {
        margin-left: 0;
      }
      .tab_tab {
        border: 0;
      }
      .tab_tab.tab_active {
        background: rgba(255, 255, 255, 0.05);
      }
      .tab_tab.tab_active::before {
        content: '';
        position: absolute;
        bottom: 0;
        left: 0;
        right: 0;
        height: 2px;
        background: #bd93f9;
      }
    `,

    // Custom CSS to embed in the terminal window
    termCSS: `
      x-screen {
        -webkit-font-smoothing: antialiased !important;
      }
    `,

    // Show hamburger menu on Windows and Linux
    showHamburgerMenu: '',

    // Set to `false` for no bell
    bell: 'SOUND',

    // If `true`, selected text will automatically be copied to the clipboard
    copyOnSelect: false,

    // If `true`, hyper will be set as the default terminal
    defaultSSHApp: true,

    // If `true`, on right click selected text will be copied or pasted if no selection
    quickEdit: false,

    // Choose either `'vertical'`, if you want the column mode when Option key is hold during selection (Default)
    // or `'force'`, if you want to force selection regardless of whether the terminal is in mouse events mode
    macOptionSelectionMode: 'vertical',

    // URL to custom bell sound (disabled by default)
    // bellSoundURL: 'http://example.com/bell.mp3',

    // Whether to use the WebGL renderer. Set it to false to use canvas-based
    // rendering (slower, but supports transparent backgrounds)
    webGLRenderer: true,

    // Snazzy theme inspired colors
    colors: {
      black: '#282a36',
      red: '#ff5c57',
      green: '#5af78e',
      yellow: '#f3f99d',
      blue: '#57c7ff',
      magenta: '#ff6ac1',
      cyan: '#9aedfe',
      white: '#f1f1f0',
      lightBlack: '#686868',
      lightRed: '#ff5c57',
      lightGreen: '#5af78e',
      lightYellow: '#f3f99d',
      lightBlue: '#57c7ff',
      lightMagenta: '#ff6ac1',
      lightCyan: '#9aedfe',
      lightWhite: '#eff0eb'
    },

    // The shell to run when spawning a new session (i.e. /usr/local/bin/fish)
    // if left empty, your system's login shell will be used by default
    shell: '/bin/zsh',

    // Shell arguments (i.e. for using interactive shellArgs: `['-i']`)
    // by default `['--login']` will be used
    shellArgs: ['--login'],

    // Environment variables
    env: {},

    // Set to `false` for no bell
    bell: 'SOUND',

    // If `true`, hyper will be set as the default terminal
    defaultSSHApp: true,

    // Padding around the terminal window
    padding: '12px 14px',

    // The full list of colors to override
    // Format: `'#000000'`
    colors: {
      black: '#282a36',
      red: '#ff5555',
      green: '#50fa7b',
      yellow: '#f1fa8c',
      blue: '#6272a4',
      magenta: '#bd93f9',
      cyan: '#8be9fd',
      white: '#f8f8f2',
      lightBlack: '#44475a',
      lightRed: '#ff6e6e',
      lightGreen: '#69ff94',
      lightYellow: '#ffffa5',
      lightBlue: '#d6acff',
      lightMagenta: '#ff92df',
      lightCyan: '#a4ffff',
      lightWhite: '#ffffff'
    },
    cursorBlink: true,

    // Windows only options
    windowSize: [1024, 768],

    // Scrollback lines
    scrollback: 10000,

    // Enable hyperlinks
    hyperlinks: true,

    // Modifier keys for opening links (cmd or ctrl)
    modifierKeys: { cmdIsMeta: true, altIsMeta: true },
  },

  // A list of plugins to fetch and install from npm
  // Format: [@org/]project[#version]
  plugins: [
    // 'hyper-snazzy',           // Theme
    'hyper-search',            // Search functionality
    // 'hyper-pane',              // Enhanced pane navigation
    'hypercwd',                // Open new tabs in same directory
    'hyperpower',
    'hyper-aura-theme',
    'hyper-fading-scrollbar'
    // 'hyper-statusline',        // Status line
    // 'hyper-tab-icons',         // Tab icons
    // 'hyperterm-paste',         // Safe paste mode
    // 'hyper-confirm',           // Confirm before quit
  ],

  // In development, you can create a directory under
  // `~/.hyper_plugins/local/` and include it here
  // to load it and avoid it being `npm install`ed
  localPlugins: [],

  // Keymaps
  // Example:
  keymaps: {
    // 'window:devtools': 'cmd+alt+o',
    // 'window:reload': 'cmd+r',
    // 'window:reloadFull': 'cmd+shift+r',
    // 'window:preferences': 'cmd+,',
    // 'window:hamburgerMenu': 'alt',
    // 'zoom:reset': 'cmd+0',
    // 'zoom:in': 'cmd+plus',
    // 'zoom:out': 'cmd+-',
    // 'tab:new': 'cmd+t',
    // 'tab:next': ['cmd+shift+]', 'cmd+shift+right', 'cmd+alt+right', 'ctrl+tab'],
    // 'tab:prev': ['cmd+shift+[', 'cmd+shift+left', 'cmd+alt+left', 'ctrl+shift+tab'],
    // 'tab:jump:prefix': 'cmd',
    // 'pane:next': 'cmd+]',
    // 'pane:prev': 'cmd+[',
    // 'pane:splitVertical': 'cmd+d',
    // 'pane:splitHorizontal': 'cmd+shift+d',
    // 'pane:close': 'cmd+w',
  },
};
