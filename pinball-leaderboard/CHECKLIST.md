# 🚀 Deployment Checklist

Use this checklist to deploy your pinball leaderboard kiosk step by step.

## Pre-Deployment

### [ ] Review Documentation
- [ ] Read PROJECT_SUMMARY.md (start here!)
- [ ] Read README.md (full overview)
- [ ] Skim DEPLOYMENT.md (deployment steps)
- [ ] Bookmark DATABASE_INTEGRATION.md (for later)

### [ ] Prepare Files
- [ ] Extract pinball-leaderboard.tar.gz
- [ ] Review directory structure
- [ ] Files look complete (app.py, config.json, static/, etc.)

### [ ] Customize Configuration
Open `config.json` and update:
- [ ] `bar_name`: Change to your bar/league name
- [ ] `logo_url`: Add your logo URL (or keep placeholder for now)
- [ ] `theme.primary_color`: Adjust if desired
- [ ] `theme.secondary_color`: Adjust if desired
- [ ] `theme.accent_color`: Adjust if desired
- [ ] `display.scene_duration`: Default 60 seconds (change if needed)

## Deployment to Docker Server

### [ ] Copy Files to Server
```bash
# On your local machine
scp -r pinball-leaderboard jdelay@jd-docker-01:/tmp/

# Then SSH to server
ssh jdelay@jd-docker-01

# Move to proper location
sudo mv /tmp/pinball-leaderboard /opt/
sudo chown -R jdelay:jdelay /opt/pinball-leaderboard
```

### [ ] Verify Port Availability
```bash
# Check port 5050 is free (should show nothing)
sudo netstat -tlnp | grep 5050
```

### [ ] Deploy Container
```bash
cd /opt/pinball-leaderboard

# Build and start
docker-compose up -d

# Verify it's running
docker-compose ps
# Should show "Up" status

# Check logs (Ctrl+C to exit)
docker-compose logs -f
# Should show Flask startup without errors
```

## Local Testing

### [ ] Test API Endpoints
```bash
# Test configuration
curl http://localhost:5050/api/config

# Test top 10 leaderboard
curl http://localhost:5050/api/leaderboard/top10

# Test game champions
curl http://localhost:5050/api/game-champions

# All should return JSON data
```

### [ ] Test Web Interface
```bash
# From server, test with curl
curl -I http://localhost:5050/
# Should return 200 OK

# Or from your workstation browser
http://jd-docker-01:5050
```

### [ ] Verify All Scenes Work
In browser at http://jd-docker-01:5050:
- [ ] Scene 1: Top 10 displays
- [ ] Scene 2: Game Champions displays
- [ ] Scene 3: Recent Activity displays
- [ ] Scene 4: Full Roster displays
- [ ] Scene 5: Statistics displays
- [ ] Previous button works
- [ ] Next button works
- [ ] Pause/Resume works
- [ ] Timer counts down
- [ ] Progress bar animates
- [ ] Scenes auto-rotate after 60 seconds

## Cloudflare Tunnel Setup

### [ ] Configure Tunnel
Find your Cloudflare tunnel configuration file and add:
```yaml
ingress:
  - hostname: pinball.thedelay.org
    service: http://localhost:5050
  # ... your other rules
```

### [ ] Restart Cloudflare Tunnel
```bash
sudo systemctl restart cloudflared
# or
sudo systemctl reload cloudflared
```

### [ ] Verify DNS
```bash
# Should resolve to your Cloudflare tunnel
nslookup pinball.thedelay.org

# Or test with curl
curl -I https://pinball.thedelay.org
# Should return 200 OK
```

## Public Access Testing

### [ ] Test from External Device
- [ ] Open https://pinball.thedelay.org on your phone
- [ ] Open https://pinball.thedelay.org on your laptop
- [ ] Verify all scenes load
- [ ] Verify controls work
- [ ] Check for any console errors (F12 Developer Tools)

### [ ] Performance Check
- [ ] Page loads quickly (< 2 seconds)
- [ ] Animations are smooth
- [ ] No lag when changing scenes
- [ ] Timer updates smoothly every second

## Bar Display Setup

### [ ] Hardware Setup
- [ ] Display/TV connected and powered on
- [ ] Set to portrait/vertical orientation (if supported)
- [ ] Display set to "Always On" (no sleep mode)
- [ ] Brightness adjusted for viewing across the bar

### [ ] Browser Setup
- [ ] Open Chrome/Firefox on the display device
- [ ] Navigate to https://pinball.thedelay.org
- [ ] Press F11 for full-screen mode
- [ ] Verify kiosk controls are visible at bottom
- [ ] Let it run through at least 2 full rotation cycles

### [ ] Browser Optimization
- [ ] Disable automatic browser updates
- [ ] Disable pop-up notifications
- [ ] Clear cache/cookies
- [ ] Set homepage to pinball.thedelay.org
- [ ] Configure to start on boot (if desired)

## Show the Bar Owner

### [ ] Presentation Points
- [ ] Explain the rotating scenes
- [ ] Show manual controls (prev/next/pause)
- [ ] Point out the visual effects
- [ ] Highlight rank change indicators
- [ ] Explain it updates every 5-10 minutes
- [ ] Mention it's using sample data for now
- [ ] Get feedback on:
  - [ ] Visual style
  - [ ] Scene duration
  - [ ] What data to show
  - [ ] Color scheme
  - [ ] Logo placement

### [ ] Get Approval
- [ ] Bar owner approves the design
- [ ] Agrees to display location
- [ ] Provides logo (if not already done)
- [ ] Discusses timeline for live data
- [ ] Any requested changes noted

## Post-Deployment

### [ ] Monitoring (First 24 Hours)
- [ ] Check after 1 hour - still running?
- [ ] Check after 4 hours - still running?
- [ ] Check next morning - still running?
- [ ] Review logs for any errors: `docker-compose logs`

### [ ] Document Feedback
Create a feedback file:
- [ ] Bar owner likes/dislikes
- [ ] Player reactions (if visible)
- [ ] Technical issues encountered
- [ ] Ideas for improvements
- [ ] Timeline for database integration

### [ ] Make Initial Adjustments
Based on feedback:
- [ ] Update colors in config.json
- [ ] Upload and link real logo
- [ ] Adjust scene timing
- [ ] Modify displayed statistics
- [ ] Rebuild if needed: `docker-compose up -d --build`

## Database Integration (Future Phase)

### [ ] Prerequisites Ready
- [ ] PostgreSQL schema documented
- [ ] Database accessible from Docker server
- [ ] Database credentials available
- [ ] n8n workflow populating data

### [ ] Follow DATABASE_INTEGRATION.md
- [ ] Create database views
- [ ] Update app.py with real queries
- [ ] Create .env file with credentials
- [ ] Test connection
- [ ] Deploy updated version
- [ ] Verify real data displays

## Success Metrics

### Week 1: Visual Success
- [ ] Kiosk runs for 7 days without issues
- [ ] Bar owner is happy with display
- [ ] No major bugs or crashes
- [ ] Players notice and comment

### Week 2: Technical Success
- [ ] Container auto-restarts if needed
- [ ] Remote access works consistently
- [ ] Performance remains smooth
- [ ] No memory leaks or slowdowns

### Month 1: Feature Success
- [ ] Database connected (if planned)
- [ ] Real data displaying accurately
- [ ] Updates happening on schedule
- [ ] Players actively checking rankings

## Troubleshooting Reference

### Container Won't Start
```bash
docker-compose logs
# Look for error messages
```

### Can't Access Locally
```bash
sudo netstat -tlnp | grep 5050
# Verify port is listening
```

### Can't Access Remotely
```bash
curl -I https://pinball.thedelay.org
# Check tunnel is working
```

### Data Not Updating
```bash
# Check API endpoints
curl http://localhost:5050/api/leaderboard/top10
```

### Visual Glitches
- Clear browser cache
- Try different browser
- Check console for JavaScript errors

## Quick Commands Reference

```bash
# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Restart
docker-compose restart

# Stop
docker-compose down

# Rebuild and start
docker-compose up -d --build

# Shell into container
docker-compose exec pinball-leaderboard /bin/bash
```

## Completion

### [ ] Final Verification
- [ ] All checklist items completed
- [ ] Kiosk running smoothly
- [ ] Bar owner satisfied
- [ ] Documentation reviewed
- [ ] Backup plan exists if issues occur

### [ ] Celebrate! 🎉
- [ ] You deployed a beautiful, professional leaderboard
- [ ] You impressed the bar owner
- [ ] You learned Docker, Flask, and web design
- [ ] You have a maintainable system
- [ ] You're ready for the next phase!

---

## Notes Section
Use this space for your own notes during deployment:

### Issues Encountered:


### Solutions Found:


### Changes Made:


### Next Steps:


### Contact Info:
- Server: jd-docker-01
- URL: https://pinball.thedelay.org
- Port: 5050
- Location: /opt/pinball-leaderboard

---

**Remember**: You can always ask Claude for help with any step!
