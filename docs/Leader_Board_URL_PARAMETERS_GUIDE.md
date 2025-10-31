# 🎯 Pinball Leaderboard - URL Parameters Guide

## Quick Start Examples

### For the Boss (Landscape Mode):
```
https://pinball.thedelay.com:5000?orientation=landscape
```

### Portrait Mode (Default):
```
https://pinball.thedelay.com:5000
```
or
```
https://pinball.thedelay.com:5000?orientation=portrait
```

### Custom Scene Duration:
```
https://pinball.thedelay.com:5000?duration=45
```
(Shows each scene for 45 seconds instead of default 60)

### Combination (Boss's Perfect Setup):
```
https://pinball.thedelay.com:5000?orientation=landscape&duration=45
```

### Paused on Start (Manual Control):
```
https://pinball.thedelay.com:5000?auto=false
```

---

## 📋 All Available Parameters

| Parameter | Values | Description | Example |
|-----------|--------|-------------|---------|
| `orientation` or `mode` | `landscape`, `wide`, `horizontal` OR `portrait`, `vert`, `vertical` | Sets the display orientation | `?orientation=landscape` |
| `duration` or `interval` | Number (1-300 seconds) | How long each scene displays | `?duration=30` |
| `auto` | `true`, `false`, `1`, `0` | Auto-advance scenes or manual | `?auto=false` |

---

## 🔗 Real-World Scenarios

### Scenario 1: Bar Display (Landscape, Slow)
```
https://pinball.thedelay.com:5000?orientation=landscape&duration=90
```
→ Landscape mode, 90 seconds per scene (for slower viewing)

### Scenario 2: Mobile Phone (Portrait, Fast)
```
https://pinball.thedelay.com:5000?orientation=portrait&duration=30
```
→ Portrait mode, 30 seconds per scene (quick browsing)

### Scenario 3: Kiosk Mode (Paused)
```
https://pinball.thedelay.com:5000?orientation=landscape&auto=false
```
→ Landscape mode, manual control only

### Scenario 4: Boss's Display
```
https://pinball.thedelay.com:5000?orientation=landscape&duration=60
```
→ Landscape mode with default timing

---

## 💡 Pro Tips

1. **Combine Multiple Parameters** using `&`:
   ```
   ?orientation=landscape&duration=45&auto=false
   ```

2. **Bookmark Different Configs** - Each URL is independent

3. **Toggle Button Still Works** - URL just sets the starting state

4. **Case Insensitive** - `landscape`, `LANDSCAPE`, `Landscape` all work

5. **Aliases Available**:
   - `orientation` = `mode`
   - `landscape` = `wide` = `horizontal`
   - `portrait` = `vert` = `vertical`
   - `duration` = `interval`

---

## 🚀 What's Next?

These URL parameters give you instant flexibility with zero infrastructure. When you're ready for an admin panel, these can become the defaults that the admin panel sets!

### Current Flow:
```
URL Params → Initial Settings → User Can Toggle
```

### Future Flow (with Admin Panel):
```
Admin Panel → Default Settings → URL Params Override → User Can Toggle
```

Perfect upgrade path! 🎯
