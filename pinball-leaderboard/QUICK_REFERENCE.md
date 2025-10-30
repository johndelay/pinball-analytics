# 📋 Quick Reference Card

## Essential Information

**Project Name**: Pinball Leaderboard Kiosk
**URL**: https://pinball.thedelay.org
**Server**: jd-docker-01
**Port**: 5050
**Location**: /opt/pinball-leaderboard

## Quick Commands

### Start/Stop
```bash
cd /opt/pinball-leaderboard
docker-compose up -d        # Start
docker-compose down         # Stop
docker-compose restart      # Restart
```

### Monitor
```bash
docker-compose ps           # Check status
docker-compose logs -f      # View logs (live)
docker-compose logs --tail 50  # Last 50 lines
```

### Update
```bash
# After editing files
docker-compose up -d --build
```

## File Locations

| File | Purpose | When to Edit |
|------|---------|--------------|
| `config.json` | Branding, colors, timing | Frequently |
| `app.py` | API and data logic | For database integration |
| `static/index.html` | Page structure | Rarely |
| `static/css/style.css` | Visual styling | For design tweaks |
| `static/js/app.js` | Interactivity | For new features |

## Configuration Quick Edit

```bash
cd /opt/pinball-leaderboard
nano config.json
# Edit what you need
docker-compose restart
```

## API Endpoints

- `GET /api/config` - Configuration
- `GET /api/leaderboard/top10` - Top 10 players
- `GET /api/leaderboard/full` - All players
- `GET /api/game-champions` - Game high scores
- `GET /api/recent-activity` - Recent plays
- `GET /api/statistics` - League stats

## Test Endpoints

```bash
# From server
curl http://localhost:5050/api/config | jq

# From browser
http://jd-docker-01:5050/api/leaderboard/top10
```

## Scenes Overview

1. **Top 10 Champions** (15s) - Leaders with rank changes
2. **Game Champions** (12s) - High scores per machine
3. **Recent Activity** (10s) - Latest games played
4. **Full Roster** (30s) - Complete rankings
5. **Statistics** (10s) - League metrics

**Total Loop**: ~77 seconds

## Kiosk Controls

- **◀ Previous**: Go to previous scene
- **⏸ Pause**: Stop auto-rotation
- **Next ▶**: Go to next scene
- **Timer**: Shows countdown to next scene

## Customization Quick Tips

### Change Colors
Edit `config.json` → `theme` section → restart

### Change Logo
Edit `config.json` → `logo_url` → restart

### Change Timing
Edit `config.json` → `display.scene_duration` → restart

### Change Refresh Rate
Edit `config.json` → `api.refresh_interval` → restart

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Container not starting | `docker-compose logs` |
| Port already in use | Check `netstat -tlnp \| grep 5050` |
| Can't access remotely | Check Cloudflare tunnel |
| Logo not showing | Verify URL is accessible |
| Data not updating | Check API endpoints with curl |
| Slow performance | Check container resources |

## Common Fixes

```bash
# Restart everything
docker-compose restart

# Rebuild from scratch
docker-compose down
docker-compose up -d --build

# Clear browser cache
Ctrl + Shift + R (hard refresh)

# Check if running
docker ps | grep pinball
```

## Monitoring Checklist

### Daily
- [ ] Kiosk is displaying
- [ ] Scenes are rotating

### Weekly
- [ ] Check logs: `docker-compose logs --tail 100`
- [ ] Verify remote access works

### Monthly
- [ ] Review any errors in logs
- [ ] Check disk space: `df -h`
- [ ] Update if needed

## Emergency Contacts

**If something breaks:**
1. Check logs: `docker-compose logs -f`
2. Try restart: `docker-compose restart`
3. Check documentation files
4. Ask Claude for help!

## Documentation Files

| File | What It's For |
|------|---------------|
| `PROJECT_SUMMARY.md` | **START HERE** - Overview |
| `README.md` | Complete documentation |
| `DEPLOYMENT.md` | Step-by-step deploy guide |
| `CHECKLIST.md` | Deployment checklist |
| `DATABASE_INTEGRATION.md` | Connect to PostgreSQL |
| `VISUAL_GUIDE.md` | Design and appearance |
| `QUICK_REFERENCE.md` | This file! |

## Version Info

**Current Version**: 1.0 (Sample Data)
**Data Source**: Mock/Sample data for demonstration
**Next Version**: Connect to PostgreSQL database

## Key Features

✅ Vertical/portrait orientation
✅ 5 rotating scenes
✅ Manual controls
✅ 60-second timer
✅ Beautiful animations
✅ Fully customizable
✅ Docker containerized
✅ Ready for production

## Performance Targets

- **Load Time**: < 2 seconds
- **Animation FPS**: 60fps
- **Memory Usage**: < 100MB
- **CPU Usage**: < 5%
- **Update Interval**: 5 minutes

## Browser Support

- ✅ Chrome (Recommended)
- ✅ Firefox
- ✅ Edge
- ✅ Safari
- ✅ Mobile browsers

## Network Ports

- **5050**: HTTP (leaderboard application)
- **5432**: PostgreSQL (database, when connected)

## Security Notes

- No authentication required (public display)
- Read-only database access
- No user input accepted
- Runs in isolated container
- Behind Cloudflare tunnel

## Backup Strategy

```bash
# Backup configuration
cp config.json config.json.backup

# Backup entire directory
cd /opt
tar -czf pinball-leaderboard-backup.tar.gz pinball-leaderboard/
```

## Update Strategy

1. Stop container: `docker-compose down`
2. Make changes to files
3. Test locally if possible
4. Rebuild: `docker-compose up -d --build`
5. Verify: Check https://pinball.thedelay.org
6. Monitor logs for 10 minutes

## Contact Info

**Project Owner**: jdelay
**Server**: jd-docker-01
**Domain**: thedelay.org
**Subdomain**: pinball.thedelay.org

---

## Bookmark This File!

Save this as a quick reference for when you need to:
- Make quick changes
- Troubleshoot issues
- Remember key commands
- Find documentation

**Pro Tip**: Print this page and keep it near your workstation for quick reference!
