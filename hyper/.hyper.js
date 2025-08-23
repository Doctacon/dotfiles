// Hyper Configuration
// Documentation: https://hyper.is/#cfg

module.exports = {
  config: {
    // Terminal window size
    windowSize: [1024, 768],
    
    // Font family with fallbacks
    fontFamily: '"Fira Code", "DejaVu Sans Mono", Consolas, "Lucida Console", monospace',
    
    // Font size in pixels
    fontSize: 14,
    
    // Font weight
    fontWeight: 'normal',
    fontWeightBold: 'bold',
    
    // Line height
    lineHeight: 1.2,
    
    // Letter spacing
    letterSpacing: 0,
    
    // Terminal cursor configuration
    cursorColor: 'rgba(248,28,229,0.8)',
    cursorAccentColor: '#000',
    cursorShape: 'BLOCK',
    cursorBlink: true,
    
    // Terminal text color
    foregroundColor: '#fff',
    
    // Terminal background color
    backgroundColor: '#000',
    
    // Terminal selection color
    selectionColor: 'rgba(248,28,229,0.3)',
    
    // Border color (window, tabs, etc.)
    borderColor: '#333',
    
    // CSS to embed in the main window
    css: '',
    
    // CSS to embed in the terminal window
    termCSS: '',
    
    // Show hamburger menu on Windows and Linux
    showHamburgerMenu: '',
    
    // Show or hide window controls
    showWindowControls: '',
    
    // Custom padding
    padding: '12px 14px',
    
    // Shell to run when spawning a new session
    shell: '',
    
    // Arguments for the shell
    shellArgs: ['--login'],
    
    // Environment variables
    env: {},
    
    // Bell settings
    bell: 'SOUND',
    
    // Copy on select
    copyOnSelect: false,
    
    // Default working directory
    defaultSSHApp: true,
    
    // Enable WebGL renderer
    webGLRenderer: true,
    
    // Color scheme - Hyper Snazzy inspired
    colors: {
      black: '#000000',
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
    
    // Scrollback buffer size
    scrollback: 10000,
    
    // Enable vibrancy (macOS only)
    vibrancy: 'dark',
    
    // Opacity settings (requires hyper-opacity plugin)
    opacity: 0.95,
  },
  
  // List of plugins to install
  // Run `hyper i <plugin-name>` to install
  plugins: [
    // 'hyper-snazzy',           // Theme
    // 'hyper-opacity',          // Window transparency
    // 'hypercwd',               // Open new tabs in same directory
    // 'hyper-tab-icons',        // Tab icons based on process
    // 'hyper-search',           // Search functionality
    // 'hyper-pane',             // Enhanced pane navigation
    // 'hyperpower',             // Typing effects (fun but optional)
  ],
  
  // Development plugins (in development, not on npm)
  localPlugins: [],
  
  // Keymaps
  // You can extend or override default keymaps here
  keymaps: {
    // Example custom keymaps:
    // 'window:devtools': 'cmd+alt+o',
    // 'window:reload': 'cmd+r',
    // 'window:reloadFull': 'cmd+shift+r',
  },
};