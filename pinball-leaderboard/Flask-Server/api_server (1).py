"""
Pinball Leaderboard API Server
Serves data from PostgreSQL database to the frontend kiosk display
"""

from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS
import psycopg2
from psycopg2.extras import RealDictCursor
import os
from datetime import datetime, timedelta
from functools import wraps
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

app = Flask(__name__, static_folder='static', static_url_path='')
CORS(app)

# ==================== DATABASE CONNECTION ====================

DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('DB_PORT', '5432'),
    'database': os.getenv('DB_NAME', 'pinball_leaderboard'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', 'your_password_here')
}

def get_db_connection():
    """Create a database connection"""
    return psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)

def query_db(query, params=None, one=False):
    """Execute a query and return results"""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(query, params or ())
        
        if query.strip().upper().startswith('SELECT'):
            rv = cur.fetchall()
            return (rv[0] if rv else None) if one else rv
        else:
            conn.commit()
            return None
    except Exception as e:
        print(f"❌ Database query error: {type(e).__name__}: {e}")
        print(f"Query (first 300 chars): {query[:300]}...")
        if params:
            print(f"Parameters: {params}")
        import traceback
        traceback.print_exc()
        if query.strip().upper().startswith('SELECT'):
            return [] if not one else None
        return None
    finally:
        conn.close()

# ==================== API ENDPOINTS ====================

@app.route('/')
def index():
    """Serve the main HTML page"""
    return send_from_directory('static', 'index.html')

@app.route('/static/<path:path>')
def serve_static(path):
    """Serve static files"""
    return send_from_directory('static', path)

@app.route('/api/config')
def get_config():
    """Get configuration settings"""
    return jsonify({
        "bar_name": "Pinball Leaderboard",
        "logo_url": "/static/logo.png",
        "display": {
            "scene_duration": 60
        },
        "api": {
            "refresh_interval": 300000
        },
        "theme": {
            "primary_color": "#ff6b35",
            "secondary_color": "#f7931e",
            "background_color": "#1a1a2e",
            "text_color": "#ffffff",
            "accent_color": "#00d9ff"
        }
    })

@app.route('/api/leaderboard/top10')
def get_top10():
    """Get top 10 players from the leaderboard"""
    query = """
        WITH current_rankings AS (
            SELECT 
                player_id,
                combined_score,
                current_rank,
                ROW_NUMBER() OVER (ORDER BY combined_score DESC) as rank
            FROM leaderboard_cache
            ORDER BY combined_score DESC
            LIMIT 10
        ),
        player_games AS (
            SELECT 
                player_id,
                COUNT(DISTINCT machine_id) as games_played
            FROM high_scores_archive
            WHERE event_code = (SELECT event_code FROM events WHERE is_active = true LIMIT 1)
            GROUP BY player_id
        ),
        rank_history AS (
            SELECT DISTINCT ON (player_id)
                player_id,
                current_rank,
                LAG(current_rank) OVER (PARTITION BY player_id ORDER BY recorded_at DESC) as previous_rank
            FROM leaderboard_history
            WHERE recorded_at >= NOW() - INTERVAL '7 days'
            ORDER BY player_id, recorded_at DESC
        )
        SELECT 
            cr.rank,
            p.display_name as name,
            cr.combined_score as score,
            COALESCE(pg.games_played, 0) as games_played,
            CASE 
                WHEN rh.previous_rank IS NULL THEN 'neutral'
                WHEN rh.previous_rank > cr.current_rank THEN 'up'
                WHEN rh.previous_rank < cr.current_rank THEN 'down'
                ELSE 'neutral'
            END as trend,
            COALESCE(ABS(rh.previous_rank - cr.current_rank), 0) as trend_positions
        FROM current_rankings cr
        JOIN players p ON cr.player_id = p.player_id
        LEFT JOIN player_games pg ON cr.player_id = pg.player_id
        LEFT JOIN rank_history rh ON cr.player_id = rh.player_id
        ORDER BY cr.rank;
    """
    
    results = query_db(query)
    if results is None:
        print("⚠️ Top 10 query returned None - returning empty list")
        return jsonify([])
    
    return jsonify([dict(row) for row in results])

@app.route('/api/leaderboard/full')
def get_full_leaderboard():
    """Get complete leaderboard rankings"""
    query = """
        SELECT 
            ROW_NUMBER() OVER (ORDER BY combined_score DESC) as rank,
            p.display_name as name,
            lc.combined_score as score
        FROM leaderboard_cache lc
        JOIN players p ON lc.player_id = p.player_id
        ORDER BY lc.combined_score DESC;
    """
    
    results = query_db(query)
    if results is None:
        print("⚠️ Full leaderboard query returned None - returning empty list")
        return jsonify([])
    
    return jsonify([dict(row) for row in results])

@app.route('/api/game-champions')
def get_game_champions():
    """Get the champion (highest score) for each machine"""
    query = """
        WITH machine_champions AS (
            SELECT DISTINCT ON (machine_id)
                machine_id,
                player_id,
                high_score
            FROM high_scores_archive
            WHERE event_code = (SELECT event_code FROM events WHERE is_active = true LIMIT 1)
            ORDER BY machine_id, high_score DESC
        )
        SELECT 
            m.machine_name as name,
            p.display_name as champion,
            mc.high_score as score
        FROM machine_champions mc
        JOIN machines m ON mc.machine_id = m.machine_id
        JOIN players p ON mc.player_id = p.player_id
        WHERE m.is_active = true
        ORDER BY mc.high_score DESC;
    """
    
    results = query_db(query)
    if results is None:
        print("⚠️ Game champions query returned None - returning empty list")
        return jsonify([])
    
    return jsonify([dict(row) for row in results])

@app.route('/api/recent-activity')
def get_recent_activity():
    """Get recent game plays"""
    query = """
        WITH personal_bests AS (
            SELECT 
                player_id,
                machine_id,
                MAX(high_score) as best_score
            FROM high_scores_archive
            WHERE event_code = (SELECT event_code FROM events WHERE is_active = true LIMIT 1)
            GROUP BY player_id, machine_id
        )
        SELECT 
            p.display_name as player,
            m.machine_name as game,
            h.high_score as score,
            EXTRACT(EPOCH FROM (NOW() - h.date_set)) / 60 as minutes_ago,
            CASE 
                WHEN h.high_score = pb.best_score THEN true
                ELSE false
            END as is_personal_best
        FROM high_scores_archive h
        JOIN players p ON h.player_id = p.player_id
        JOIN machines m ON h.machine_id = m.machine_id
        LEFT JOIN personal_bests pb ON h.player_id = pb.player_id 
            AND h.machine_id = pb.machine_id
        WHERE h.event_code = (SELECT event_code FROM events WHERE is_active = true LIMIT 1)
        ORDER BY h.date_set DESC
        LIMIT 50;
    """
    
    results = query_db(query)
    
    if results is None:
        print("⚠️ Recent activity query returned None - returning empty list")
        return jsonify([])
    
    activities = []
    for row in results:
        activity = dict(row)
        activity['minutes_ago'] = int(activity['minutes_ago']) if activity['minutes_ago'] else 0
        activities.append(activity)
    
    return jsonify(activities)

@app.route('/api/statistics')
def get_statistics():
    """Get overall league statistics"""
    
    # Get active event
    event_query = "SELECT event_code FROM events WHERE is_active = true LIMIT 1"
    event = query_db(event_query, one=True)
    event_code = event['event_code'] if event else None
    
    if not event_code:
        print("⚠️ No active event found - returning zero stats")
        return jsonify({
            "total_games_this_week": 0,
            "total_games_this_month": 0,
            "active_players": 0,
            "average_score": 0,
            "most_popular_game": "N/A",
            "busiest_day": "N/A"
        })
    
    # Total games this week
    games_week_query = """
        SELECT COUNT(*) as count
        FROM high_scores_archive
        WHERE date_set >= NOW() - INTERVAL '7 days'
        AND event_code = %s;
    """
    games_week = query_db(games_week_query, (event_code,), one=True)
    
    # Total games this month
    games_month_query = """
        SELECT COUNT(*) as count
        FROM high_scores_archive
        WHERE date_set >= NOW() - INTERVAL '30 days'
        AND event_code = %s;
    """
    games_month = query_db(games_month_query, (event_code,), one=True)
    
    # Active players
    active_players_query = """
        SELECT COUNT(DISTINCT player_id) as count
        FROM high_scores_archive
        WHERE event_code = %s;
    """
    active_players = query_db(active_players_query, (event_code,), one=True)
    
    # Average score
    avg_score_query = """
        SELECT AVG(high_score)::bigint as avg
        FROM high_scores_archive
        WHERE event_code = %s;
    """
    avg_score = query_db(avg_score_query, (event_code,), one=True)
    
    # Most popular game
    popular_game_query = """
        SELECT m.machine_name, COUNT(*) as play_count
        FROM high_scores_archive h
        JOIN machines m ON h.machine_id = m.machine_id
        WHERE h.event_code = %s
        GROUP BY m.machine_name
        ORDER BY play_count DESC
        LIMIT 1;
    """
    popular_game = query_db(popular_game_query, (event_code,), one=True)
    
    # Busiest day of week
    busiest_day_query = """
        SELECT 
            TO_CHAR(date_set, 'Day') as day_name,
            COUNT(*) as play_count
        FROM high_scores_archive
        WHERE event_code = %s
        GROUP BY TO_CHAR(date_set, 'Day'), EXTRACT(DOW FROM date_set)
        ORDER BY play_count DESC
        LIMIT 1;
    """
    busiest_day = query_db(busiest_day_query, (event_code,), one=True)
    
    return jsonify({
        "total_games_this_week": games_week['count'] if games_week and 'count' in games_week else 0,
        "total_games_this_month": games_month['count'] if games_month and 'count' in games_month else 0,
        "active_players": active_players['count'] if active_players and 'count' in active_players else 0,
        "average_score": avg_score['avg'] if avg_score and avg_score.get('avg') else 0,
        "most_popular_game": popular_game['machine_name'] if popular_game and 'machine_name' in popular_game else "N/A",
        "busiest_day": busiest_day['day_name'].strip() if busiest_day and 'day_name' in busiest_day else "N/A"
    })

# ==================== HEALTH CHECK & DIAGNOSTICS ====================

@app.route('/api/health')
def health_check():
    """Health check endpoint"""
    try:
        query_db("SELECT 1", one=True)
        return jsonify({"status": "healthy", "database": "connected"})
    except Exception as e:
        return jsonify({"status": "unhealthy", "error": str(e)}), 500

@app.route('/api/diagnostics')
def diagnostics():
    """Diagnostic endpoint to check database status"""
    diagnostics_data = {
        "database_connection": "unknown",
        "tables": {},
        "active_event": None,
        "data_counts": {}
    }
    
    try:
        query_db("SELECT 1", one=True)
        diagnostics_data["database_connection"] = "✅ Connected"
        
        # Check for required tables (lowercase!)
        tables_to_check = ['events', 'players', 'machines', 'high_scores_archive', 
                          'leaderboard_cache', 'leaderboard_history']
        
        for table in tables_to_check:
            try:
                result = query_db(f"SELECT COUNT(*) as count FROM {table}", one=True)
                count = result['count'] if result and 'count' in result else 0
                diagnostics_data["tables"][table] = f"✅ {count} rows"
            except Exception as e:
                diagnostics_data["tables"][table] = f"❌ Error: {str(e)[:50]}"
        
        # Check for active event
        try:
            event = query_db("SELECT event_code, event_name FROM events WHERE is_active = true LIMIT 1", one=True)
            if event:
                diagnostics_data["active_event"] = f"✅ {event.get('event_name', 'Unknown')} ({event.get('event_code', 'N/A')})"
            else:
                diagnostics_data["active_event"] = "⚠️ No active event found"
        except Exception as e:
            diagnostics_data["active_event"] = f"❌ Error: {str(e)[:50]}"
        
        # Get data counts
        try:
            players = query_db("SELECT COUNT(*) as count FROM players", one=True)
            diagnostics_data["data_counts"]["total_players"] = players['count'] if players else 0
            
            machines = query_db("SELECT COUNT(*) as count FROM machines WHERE is_active = true", one=True)
            diagnostics_data["data_counts"]["active_machines"] = machines['count'] if machines else 0
            
            scores = query_db("SELECT COUNT(*) as count FROM high_scores_archive", one=True)
            diagnostics_data["data_counts"]["total_scores"] = scores['count'] if scores else 0
            
            leaderboard = query_db("SELECT COUNT(*) as count FROM leaderboard_cache", one=True)
            diagnostics_data["data_counts"]["leaderboard_entries"] = leaderboard['count'] if leaderboard else 0
        except Exception as e:
            diagnostics_data["data_counts"]["error"] = str(e)
        
        return jsonify(diagnostics_data)
        
    except Exception as e:
        diagnostics_data["database_connection"] = f"❌ Failed: {str(e)}"
        return jsonify(diagnostics_data), 500

@app.route('/api/test-schema')
def test_schema():
    """Test endpoint to check actual column names"""
    results = {}
    
    # Test simple query first
    try:
        sample = query_db("SELECT * FROM leaderboard_cache LIMIT 1", one=True)
        if sample:
            results["leaderboard_cache_columns"] = list(sample.keys())
            results["leaderboard_cache_sample"] = dict(sample)
        else:
            results["leaderboard_cache_columns"] = "No rows"
    except Exception as e:
        results["leaderboard_cache_error"] = str(e)
    
    # Test JOIN
    try:
        test_join = query_db("""
            SELECT lc.player_id, lc.combined_score, p.display_name
            FROM leaderboard_cache lc
            JOIN players p ON lc.player_id = p.player_id
            LIMIT 1
        """, one=True)
        if test_join:
            results["join_test"] = "✅ SUCCESS"
            results["join_sample"] = dict(test_join)
        else:
            results["join_test"] = "⚠️ No results"
    except Exception as e:
        results["join_test"] = f"❌ FAILED: {str(e)}"
    
    return jsonify(results)

# ==================== ERROR HANDLERS ====================

@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Not found"}), 404

@app.errorhandler(500)
def internal_error(e):
    return jsonify({"error": "Internal server error"}), 500

# ==================== MAIN ====================

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    
    print(f"🎮 Pinball Leaderboard API Server")
    print(f"📡 Starting on http://localhost:{port}")
    print(f"🗄️  Database: {DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}")
    print(f"📊 Frontend: http://localhost:{port}")
    print(f"🏥 Health check: http://localhost:{port}/api/health")
    
    app.run(
        host='0.0.0.0',
        port=port,
        debug=True
    )
