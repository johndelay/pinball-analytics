# Pinball Leaderboard Kiosk - Visual Guide

## Layout Overview

### Vertical/Portrait Orientation (optimized for 1080x1920 or similar)

```
┌─────────────────────────────────┐
│         [BAR LOGO]              │
│   PINBALL LEADERBOARD           │
│   Last updated: 3:45 PM         │
├─────────────────────────────────┤
│                                 │
│  🏆 Top 10 Champions            │
│                                 │
│  #1  Mike      125.5M    ↑2    │
│  👑  Gold Badge                 │
│  💯 125.5M  🎮 87 games         │
│                                 │
│  #2  Sarah     98.2M     ↓1    │
│  🥈  Silver Badge               │
│  💯 98.2M   🎮 134 games        │
│                                 │
│  #3  John      87.3M     •     │
│  🥉  Bronze Badge               │
│  💯 87.3M   🎮 92 games         │
│                                 │
│  [4-10 similar format...]       │
│                                 │
│                                 │
│                                 │
│                                 │
├─────────────────────────────────┤
│   ◀ Previous  ⏸ Pause  Next ▶  │
│   Scene 1 of 5    Next in: 45s │
│   ███████████████░░░░░          │
└─────────────────────────────────┘
```

## Color Scheme (Default)

- **Background**: Dark navy blue gradient (#1a1a2e → #16213e)
- **Primary**: Orange/red (#ff6b35) - Used for headers, rank badges
- **Secondary**: Golden orange (#f7931e) - Accents and highlights
- **Accent**: Cyan blue (#00d9ff) - Scores, special highlights
- **Success**: Bright green (#00ff88) - Rank increases, personal bests
- **Warning**: Hot pink (#ff3366) - Rank decreases

## Scene Descriptions

### Scene 1: Top 10 Champions (15 seconds)
- Large rank numbers with special styling for top 3
- Trophy/medal badges (🏆 👑 🥈 🥉)
- Player names in bold
- Scores formatted (125.5M style)
- Games played count
- Trend indicators: ↑ (green, animated bounce), ↓ (red), • (stable)
- Top 3 cards have glowing borders
- Smooth animations on load

### Scene 2: Game Champions (12 seconds)
- Grid layout of game cards
- Each card shows:
  - Game name with 🎯 icon
  - Champion's name in large text
  - High score
- Left border accent in golden orange
- Hover effect (slight shift)

### Scene 3: Recent Activity (10 seconds)
- Feed-style layout (like social media)
- Each activity shows:
  - Player name (large, colored)
  - Time ago (e.g., "25m ago")
  - Game name
  - Score
  - "PERSONAL BEST!" badge if applicable (green)
- Personal best items have green left border and subtle glow
- Smooth slide-in animation for each item

### Scene 4: Full Roster (30 seconds)
- Compact list showing all players
- Three columns: Rank, Name, Score
- Scrollable if more than screen height
- Subtle alternating row colors
- Clean, data-focused design

### Scene 5: Statistics (10 seconds)
- Grid of stat cards (2 columns on narrow screens)
- Each card shows:
  - Large number/value at top
  - Label below
- Cards have glowing borders
- Stats include:
  - Games this week
  - Games this month
  - Active players
  - Average score
  - Most popular game
  - Busiest day

## Animations & Effects

1. **Page Transitions**: Smooth 800ms fade in/out
2. **Rank Changes**: Bouncing up/down arrows
3. **Score Updates**: Number counting animation (future)
4. **Card Hover**: Subtle lift and glow
5. **Timer Progress**: Smooth linear animation
6. **Shimmer Effect**: Light sweep across cards
7. **Glow Effects**: Pulsing glow on headers and top players

## Typography

- **Headers**: Orbitron (futuristic, bold, uppercase)
- **Body Text**: Roboto (clean, readable)
- **Numbers/Scores**: Orbitron (for that digital/arcade feel)

## Interactive Elements

### Control Buttons
- Orange gradient background
- White text
- Rounded corners
- Drop shadow with orange glow
- Hover: Lifts up slightly with increased glow
- Active: Presses down

### Timer Display
- Countdown number in cyan
- Progress bar underneath
- Smooth 1-second intervals
- Bar color gradient (cyan to orange)

### Scene Indicator
- Shows "Scene X of Y"
- Gray text, subtle
- Updates instantly on navigation

## Responsive Design

- Adapts to various portrait screen sizes
- Tested on: 1080x1920, 1200x1920, 1440x2560
- Scrollable areas where content exceeds height
- Touch-friendly button sizes (44px minimum)
- Works on tablets and portrait monitors

## Accessibility Features

- High contrast text
- Large, readable fonts
- Clear visual hierarchy
- Colorblind-friendly (doesn't rely solely on color)
- Keyboard navigation support

## Performance

- Smooth 60fps animations
- Minimal JavaScript
- CSS-based animations
- Lazy loading of scenes
- Efficient DOM updates

## Browser Compatibility

- ✅ Chrome/Chromium (Recommended)
- ✅ Firefox
- ✅ Safari
- ✅ Edge
- 📱 Mobile browsers (portrait mode)

## Kiosk Mode Tips

1. **Full-screen**: Press F11 to hide browser chrome
2. **Prevent sleep**: Adjust power settings
3. **Auto-start**: Set browser to launch on boot
4. **Disable updates**: Schedule for off-hours
5. **Clear cache**: Prevent storage buildup

## Future Visual Enhancements

- [ ] Particle effects in background
- [ ] Game artwork thumbnails
- [ ] Player avatars
- [ ] Animated rank change transitions
- [ ] Confetti effect for new #1
- [ ] QR code overlay for players
- [ ] Tournament bracket visualization
- [ ] Historical trend mini-graphs

---

This leaderboard is designed to be eye-catching without being overwhelming, professional but fun, and most importantly - easy to read from across the bar!
