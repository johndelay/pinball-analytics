from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS
from datetime import datetime, timedelta
import json
import random
import os

app = Flask(__name__, static_folder='static')
CORS(app)

# Load configuration
def load_config():
    config_path = os.path.join(os.path.dirname(__file__), 'config.json')
    with open(config_path, 'r') as f:
        return json.load(f)

config = load_config()

# Sample data generator (will be replaced with PostgreSQL queries later)
def generate_sample_data():
    first_names = ["Mike", "Sarah", "John", "Emma", "Dave", "Lisa", "Tom", "Amy", 
                   "Chris", "Maria", "Dan", "Kate", "Rob", "Nina", "Paul", "Jen",
                   "Steve", "Zoe", "Mark", "Beth", "Alex", "Sam", "Ryan", "Lucy"]
    
    games = [
        "Medieval Madness",
        "Attack from Mars",
        "The Addams Family",
        "Twilight Zone",
        "Monster Bash",
        "Star Trek TNG"
    ]
    
    players = []
    base_score = 50000000
    
    for i, name in enumerate(first_names):
        # Generate trend: up, down, or stable
        if i < 8:
            trend = random.choice(['up', 'up', 'stable'])  # Top players more likely to be stable/up
        else:
            trend = random.choice(['up', 'down', 'stable'])
        
        trend_positions = {'up': random.randint(1, 5), 
                          'down': random.randint(1, 5), 
                          'stable': 0}
        
        players.append({
            'rank': i + 1,
            'name': name,
            'score': base_score - (i * random.randint(1000000, 5000000)),
            'games_played': random.randint(15, 200),
            'trend': trend,
            'trend_positions': trend_positions[trend],
            'last_played': (datetime.now() - timedelta(hours=random.randint(0, 72))).isoformat(),
            'favorite_game': random.choice(games)
        })
    
    return players

def generate_game_champions():
    games = [
        {"name": "Medieval Madness", "champion": "Mike", "score": 125000000},
        {"name": "Attack from Mars", "champion": "Sarah", "score": 98000000},
        {"name": "The Addams Family", "champion": "John", "score": 87000000},
        {"name": "Twilight Zone", "champion": "Emma", "score": 156000000},
        {"name": "Monster Bash", "champion": "Dave", "score": 78000000},
        {"name": "Star Trek TNG", "champion": "Lisa", "score": 92000000}
    ]
    return games

def generate_recent_activity():
    players = generate_sample_data()
    games = generate_game_champions()
    
    activity = []
    for i in range(15):
        player = random.choice(players[:15])  # Recent activity from active players
        game = random.choice(games)
        minutes_ago = random.randint(5, 300)
        
        activity.append({
            'player': player['name'],
            'game': game['name'],
            'score': random.randint(20000000, 100000000),
            'timestamp': (datetime.now() - timedelta(minutes=minutes_ago)).isoformat(),
            'minutes_ago': minutes_ago,
            'is_personal_best': random.random() > 0.7
        })
    
    return sorted(activity, key=lambda x: x['timestamp'], reverse=True)

def generate_statistics():
    return {
        'total_games_this_week': random.randint(180, 350),
        'total_games_this_month': random.randint(800, 1500),
        'active_players': random.randint(18, 24),
        'average_score': 45000000,
        'most_popular_game': 'Medieval Madness',
        'busiest_day': 'Saturday',
        'highest_score_today': 98500000
    }

# API Routes
@app.route('/')
def index():
    return send_from_directory('static', 'index.html')

@app.route('/api/config')
def get_config():
    return jsonify(config)

@app.route('/api/leaderboard/top10')
def top_10():
    players = generate_sample_data()
    return jsonify(players[:10])

@app.route('/api/leaderboard/full')
def full_leaderboard():
    players = generate_sample_data()
    return jsonify(players)

@app.route('/api/game-champions')
def game_champions():
    champions = generate_game_champions()
    return jsonify(champions)

@app.route('/api/recent-activity')
def recent_activity():
    activity = generate_recent_activity()
    return jsonify(activity)

@app.route('/api/statistics')
def statistics():
    stats = generate_statistics()
    return jsonify(stats)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5050, debug=True)
