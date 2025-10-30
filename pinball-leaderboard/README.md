# Pinball Leaderboard Kiosk

A beautiful, vertical-oriented kiosk display for pinball league leaderboards with rotating scenes and real-time updates.

## Features

### 🎯 Kiosk Mode
- **Vertical/Portrait orientation** optimized for bar displays
- **Manual navigation** with Previous/Next buttons
- **60-second auto-advance** timer with visual countdown
- **Pause/Resume** functionality
- **Scene indicator** showing current position

### 🎬 Rotating Scenes
1. **Top 10 Champions** - Current leaderboard with rank change indicators
2. **Game Champions** - High scores by individual pinball machine
3. **Recent Activity** - Last 10-15 games played with personal bests highlighted
4. **Full Roster** - Complete scrolling list of all players
5. **Statistics** - League-wide metrics and achievements

### 🎨 Visual Features
- **Retro arcade aesthetic** with neon colors and animated effects
- **Smooth transitions** between scenes
- **Rank change animations** (↑↓ indicators)
- **Trophy badges** for top 3 players
- **Personal best highlights** in activity feed
- **Responsive design** for various screen sizes

## Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Port 5050 available (configurable)

### Deployment

1. **Clone/Copy the files** to your Docker server:
```bash
cd /opt
git clone <your-repo> pinball-leaderboard
cd pinball-leaderboard
```

2. **Edit configuration** (optional):
```bash
nano config.json
```

Update:
- `bar_name` - Your bar/league name
- `logo_url` - URL to your logo image
- `theme` colors - Customize the color scheme
- `scene_duration` - Time per scene in seconds

3. **Build and run**:
```bash
docker-compose up -d
```

4. **Access the kiosk**:
- Local: `http://localhost:5050`
- Network: `http://your-server-ip:5050`
- Domain: `https://pinball.thedelay.org` (via Cloudflare tunnel)

### Cloudflare Tunnel Setup

Add to your Cloudflare tunnel configuration:
```yaml
ingress:
  - hostname: pinball.thedelay.org
    service: http://localhost:5050
```

## Configuration

### config.json

```json
{
  "bar_name": "Your Bar Name",
  "logo_url": "https://yoursite.com/logo.png",
  "theme": {
    "primary_color": "#ff6b35",
    "secondary_color": "#f7931e",
    "background_color": "#1a1a2e",
    "text_color": "#ffffff",
    "accent_color": "#00d9ff"
  },
  "display": {
    "scene_duration": 60,
    "transition_speed": 800
  },
  "api": {
    "refresh_interval": 300000
  }
}
```

### Customization Options

- **Logo**: Replace the placeholder logo URL with your own
- **Colors**: Adjust theme colors to match your bar's branding
- **Scene Duration**: Change how long each scene displays (in seconds)
- **Refresh Interval**: How often data refreshes from the database (in milliseconds)

## Current Implementation

### Data Source
Currently using **sample/mock data** for demonstration purposes. The application generates:
- 24 sample players with realistic scores
- 6 pinball games with champions
- Recent activity feed
- League statistics

### Next Steps: Connect to PostgreSQL

To connect to your real database, modify `app.py`:

1. **Add database connection**:
```python
import psycopg2
from psycopg2.extras import RealDictCursor

def get_db_connection():
    return psycopg2.connect(
        host="your-postgres-host",
        database="your-database",
        user="your-user",
        password="your-password"
    )
```

2. **Replace sample data functions** with real queries:
```python
@app.route('/api/leaderboard/top10')
def top_10():
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT 
            rank,
            player_name as name,
            total_score as score,
            games_played,
            trend,
            trend_positions
        FROM your_leaderboard_view
        ORDER BY rank
        LIMIT 10
    """)
    players = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(players)
```

3. **Update docker-compose.yml** with database credentials:
```yaml
environment:
  - DB_HOST=your-db-host
  - DB_NAME=your-db-name
  - DB_USER=your-db-user
  - DB_PASSWORD=your-db-password
```

## File Structure

```
pinball-leaderboard/
├── app.py                  # Flask API server
├── config.json             # Configuration file
├── requirements.txt        # Python dependencies
├── Dockerfile             # Container build instructions
├── docker-compose.yml     # Docker deployment config
├── static/
│   ├── index.html         # Main kiosk interface
│   ├── css/
│   │   └── style.css      # Styling and animations
│   └── js/
│       └── app.js         # Frontend logic
└── README.md              # This file
```

## API Endpoints

- `GET /` - Main kiosk interface
- `GET /api/config` - Configuration settings
- `GET /api/leaderboard/top10` - Top 10 players
- `GET /api/leaderboard/full` - Complete player list
- `GET /api/game-champions` - High scores by game
- `GET /api/recent-activity` - Recent plays
- `GET /api/statistics` - League statistics

## Troubleshooting

### Port already in use
If port 5050 is taken, edit `docker-compose.yml`:
```yaml
ports:
  - "5051:5050"  # Use different external port
```

### Container won't start
Check logs:
```bash
docker-compose logs -f
```

### Data not updating
- Check `refresh_interval` in config.json
- Verify API endpoints are returning data
- Check browser console for errors

### Logo not displaying
- Verify logo URL is accessible
- Check image format (PNG, JPG, SVG supported)
- Test URL directly in browser

## Development

### Running locally (without Docker):
```bash
pip install -r requirements.txt
python app.py
```

### Making changes:
1. Edit files as needed
2. Rebuild container: `docker-compose up -d --build`
3. Or restart: `docker-compose restart`

## Performance

- **Lightweight**: ~50MB Docker image
- **Low CPU**: <5% on most systems
- **Low memory**: ~100MB RAM usage
- **Network**: Minimal - only API calls every 5 minutes

## Browser Recommendations

For kiosk mode:
- **Chrome/Chromium** - Best performance
- **Firefox** - Good alternative
- **Full-screen mode**: Press F11 on the display

### Kiosk Browser Settings
- Disable screensaver/sleep mode
- Set browser to start in full-screen
- Disable browser updates during operating hours

## Future Enhancements

- [ ] Connect to PostgreSQL database
- [ ] Player authentication/profiles
- [ ] Historical trend graphs
- [ ] Tournament mode
- [ ] QR code for player stats
- [ ] Sound effects (toggle-able)
- [ ] Multi-location support
- [ ] Admin dashboard
- [ ] Email notifications for rank changes
- [ ] Mobile app companion

## License

MIT License - Feel free to modify and use for your pinball league!

## Support

For issues or questions:
- Check the logs: `docker-compose logs`
- Review configuration: `cat config.json`
- Test endpoints: `curl http://localhost:5050/api/config`

## Credits

Built with:
- Flask (Python web framework)
- Vanilla JavaScript (no frameworks needed!)
- CSS3 animations
- Docker for easy deployment
