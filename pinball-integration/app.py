from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS
from datetime import datetime
import json
import os
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv
import logging

# Load environment variables
load_dotenv()

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__, static_folder='static')
CORS(app)

# Load configuration
def load_config():
    config_path = os.path.join(os.path.dirname(__file__), 'config.json')
    with open(config_path, 'r') as f:
        return json.load(f)

config = load_config()

# Database connection
def get_db_connection():
    """Create and return a database connection"""
    try:
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST', 'localhost'),
            port=os.getenv('DB_PORT', '5432'),
            database=os.getenv('DB_NAME'),
            user=os.getenv('DB_USER'),
            password=os.getenv('DB_PASSWORD')
        )
        return conn
    except Exception as e:
        logger.error(f"Database connection error: {e}")
        raise

def format_score(score):
    """Format large numbers with M/K suffixes"""
    if score >= 1_000_000:
        return f"{score / 1_000_000:.1f}M"
    elif score >= 1_000:
        return f"{score / 1_000:.1f}K"
    return str(score)

# API Routes
@app.route('/')
def index():
    return send_from_directory('static', 'index.html')

@app.route('/api/config')
def get_config():
    return jsonify(config)

@app.route('/api/leaderboard/top10')
def top_10():
    """Get top 10 players from database"""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute("""
            SELECT 
                rank,
                name,
                score,
                games_played,
                trend,
                trend_positions,
                last_seen
            FROM leaderboard_current
            WHERE rank <= 10
            ORDER BY rank
        """)
        
        players = cur.fetchall()
        
        # Convert timestamps to ISO format
        for player in players:
            if player.get('last_seen'):
                player['last_seen'] = player['last_seen'].isoformat()
        
        cur.close()
        conn.close()
        
        logger.info(f"Retrieved {len(players)} top players")
        return jsonify(players)
        
    except Exception as e:
        logger.error(f"Error fetching top 10: {e}")
        return jsonify({"error": "Database error", "message": str(e)}), 500

@app.route('/api/leaderboard/full')
def full_leaderboard():
    """Get all players from database"""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute("""
            SELECT 
                rank,
                name,
                score,
                games_played
            FROM leaderboard_current
            ORDER BY rank
        """)
        
        players = cur.fetchall()
        cur.close()
        conn.close()
        
        logger.info(f"Retrieved {len(players)} total players")
        return jsonify(players)
        
    except Exception as e:
        logger.error(f"Error fetching full leaderboard: {e}")
        return jsonify({"error": "Database error", "message": str(e)}), 500

@app.route('/api/game-champions')
def game_champions():
    """Get champions for each game/machine"""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute("""
            SELECT 
                name,
                champion,
                score
            FROM game_champions
            ORDER BY name
        """)
        
        champions = cur.fetchall()
        cur.close()
        conn.close()
        
        logger.info(f"Retrieved {len(champions)} game champions")
        return jsonify(champions)
        
    except Exception as e:
        logger.error(f"Error fetching game champions: {e}")
        return jsonify({"error": "Database error", "message": str(e)}), 500

@app.route('/api/recent-activity')
def recent_activity():
    """Get recent game activity"""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute("""
            SELECT 
                player,
                game,
                score,
                timestamp,
                minutes_ago,
                is_personal_best
            FROM recent_activity
            ORDER BY timestamp DESC
            LIMIT 15
        """)
        
        activities = cur.fetchall()
        
        # Convert timestamps to ISO format
        for activity in activities:
            if activity.get('timestamp'):
                activity['timestamp'] = activity['timestamp'].isoformat()
            # Round minutes_ago to integer
            if activity.get('minutes_ago'):
                activity['minutes_ago'] = int(activity['minutes_ago'])
        
        cur.close()
        conn.close()
        
        logger.info(f"Retrieved {len(activities)} recent activities")
        return jsonify(activities)
        
    except Exception as e:
        logger.error(f"Error fetching recent activity: {e}")
        return jsonify({"error": "Database error", "message": str(e)}), 500

@app.route('/api/statistics')
def statistics():
    """Get league statistics"""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute("""
            SELECT 
                games_this_week as total_games_this_week,
                games_this_month as total_games_this_month,
                active_players,
                average_score,
                most_popular_game,
                TRIM(busiest_day) as busiest_day
            FROM league_statistics
        """)
        
        stats = cur.fetchone()
        cur.close()
        conn.close()
        
        if stats:
            logger.info("Retrieved league statistics")
            return jsonify(stats)
        else:
            logger.warning("No statistics data available")
            return jsonify({
                "total_games_this_week": 0,
                "total_games_this_month": 0,
                "active_players": 0,
                "average_score": 0,
                "most_popular_game": "N/A",
                "busiest_day": "N/A"
            })
        
    except Exception as e:
        logger.error(f"Error fetching statistics: {e}")
        return jsonify({"error": "Database error", "message": str(e)}), 500

@app.route('/api/health')
def health_check():
    """Health check endpoint to verify database connection"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT 1')
        cur.close()
        conn.close()
        return jsonify({
            "status": "healthy",
            "database": "connected",
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return jsonify({
            "status": "unhealthy",
            "database": "disconnected",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }), 500

if __name__ == '__main__':
    # Verify database connection on startup
    try:
        conn = get_db_connection()
        logger.info("✓ Database connection successful")
        conn.close()
    except Exception as e:
        logger.error(f"✗ Database connection failed: {e}")
        logger.error("Please check your .env file and database credentials")
    
    # Start Flask app
    app.run(host='0.0.0.0', port=5050, debug=os.getenv('FLASK_DEBUG', 'False').lower() == 'true')
