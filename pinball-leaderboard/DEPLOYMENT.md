# Quick Deployment Guide

## For Your Docker Server (jd-docker-01)

### Step 1: Copy Files
```bash
# SSH into your docker server
ssh jdelay@jd-docker-01

# Create directory
cd /opt
sudo mkdir pinball-leaderboard
sudo chown jdelay:jdelay pinball-leaderboard
cd pinball-leaderboard

# Copy all files here from your local machine
```

### Step 2: Customize Configuration
```bash
# Edit the config file
nano config.json
```

**Update these fields:**
- `bar_name`: "Your Bar Name Here"
- `logo_url`: "https://yoursite.com/path/to/logo.png"
- Adjust colors if desired

### Step 3: Deploy
```bash
# Build and start the container
docker-compose up -d

# Check if it's running
docker-compose ps

# View logs
docker-compose logs -f
```

### Step 4: Test Locally
```bash
# From the server
curl http://localhost:5050/api/config

# Or open in browser
# http://jd-docker-01:5050
```

### Step 5: Setup Cloudflare Tunnel

Add to your Cloudflare tunnel config (wherever it's configured):
```yaml
ingress:
  - hostname: pinball.thedelay.org
    service: http://localhost:5050
  # ... your other ingress rules
```

Then restart cloudflared:
```bash
sudo systemctl restart cloudflared
```

### Step 6: Access Your Kiosk!
Navigate to: **https://pinball.thedelay.org**

## Verification Checklist

- [ ] Container is running: `docker ps | grep pinball`
- [ ] Port 5050 is open: `sudo netstat -tlnp | grep 5050`
- [ ] Local access works: `curl http://localhost:5050`
- [ ] Cloudflare tunnel is configured
- [ ] Domain resolves: `https://pinball.thedelay.org`
- [ ] Logo displays correctly
- [ ] All scenes rotate properly
- [ ] Navigation buttons work

## Common Commands

```bash
# Stop the container
docker-compose down

# Restart after config changes
docker-compose restart

# Rebuild after code changes
docker-compose up -d --build

# View live logs
docker-compose logs -f

# Check container status
docker-compose ps

# Shell into container (for debugging)
docker-compose exec pinball-leaderboard /bin/bash
```

## Updating the Logo

1. Upload your logo image to a web server
2. Get the full URL (e.g., `https://yoursite.com/logo.png`)
3. Edit config.json: `nano config.json`
4. Update the `logo_url` field
5. Restart: `docker-compose restart`
6. Refresh browser - logo should appear

## Next Steps

Once you're happy with the display:

1. **Set up the bar display**:
   - Open browser in full-screen mode (F11)
   - Navigate to `https://pinball.thedelay.org`
   - Let it rotate!

2. **Connect to PostgreSQL** (when ready):
   - See README.md section "Connect to PostgreSQL"
   - Update app.py with real database queries
   - Add database credentials to .env file
   - Rebuild container

3. **Customize further**:
   - Adjust scene timing
   - Change colors/theme
   - Add/remove scenes
   - Modify what data is displayed

## Troubleshooting

**Container won't start:**
```bash
docker-compose logs
# Check for port conflicts or errors
```

**Can't access on port 5050:**
```bash
sudo netstat -tlnp | grep 5050
# Make sure nothing else is using it
```

**Changes not showing:**
```bash
# Clear browser cache or hard refresh (Ctrl+Shift+R)
docker-compose restart
```

**Database connection issues (future):**
```bash
# Test from container
docker-compose exec pinball-leaderboard python -c "import psycopg2; print('OK')"
```

## Support

If you run into issues:
1. Check the logs: `docker-compose logs -f`
2. Verify config.json is valid JSON
3. Test API endpoints manually
4. Check Cloudflare tunnel status

Enjoy your awesome pinball leaderboard! 🎯🎮
