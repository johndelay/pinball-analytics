// Kiosk Application
class PinballKiosk {
    constructor() {
        this.currentScene = 0;
        this.scenes = [
            { id: 'scene-top10', name: 'Top 10', loader: this.loadTop10.bind(this) },
            { id: 'scene-champions', name: 'Game Champions', loader: this.loadChampions.bind(this) },
            { id: 'scene-activity', name: 'Recent Activity', loader: this.loadActivity.bind(this) },
            { id: 'scene-roster', name: 'Full Roster', loader: this.loadRoster.bind(this) },
            { id: 'scene-stats', name: 'Statistics', loader: this.loadStats.bind(this) }
        ];
        this.isPaused = false;
        this.sceneDuration = 60; // seconds
        this.countdownInterval = null;
        this.dataRefreshInterval = null;
        this.scrollInterval = null;
        this.scrollAnimationFrame = null;
        this.config = null;
        
        this.init();
    }
    
    async init() {
        // Load configuration
        await this.loadConfig();
        
        // Setup event listeners
        this.setupControls();
        
        // Load initial scene
        await this.showScene(0);
        
        // Start countdown timer
        this.startCountdown();
        
        // Setup periodic data refresh (every 5 minutes)
        this.dataRefreshInterval = setInterval(() => {
            this.refreshCurrentScene();
        }, this.config.api.refresh_interval);
        
        // Update last updated time
        this.updateLastUpdatedTime();
    }
    
    async loadConfig() {
        try {
            const response = await fetch('/api/config');
            this.config = await response.json();
            
            // Apply configuration
            document.getElementById('logo').src = this.config.logo_url;
            document.getElementById('barName').textContent = this.config.bar_name;
            this.sceneDuration = this.config.display.scene_duration;
            
            // Apply theme colors
            const root = document.documentElement;
            root.style.setProperty('--primary-color', this.config.theme.primary_color);
            root.style.setProperty('--secondary-color', this.config.theme.secondary_color);
            root.style.setProperty('--background-color', this.config.theme.background_color);
            root.style.setProperty('--text-color', this.config.theme.text_color);
            root.style.setProperty('--accent-color', this.config.theme.accent_color);
        } catch (error) {
            console.error('Failed to load config:', error);
        }
    }
    
    setupControls() {
        document.getElementById('prevBtn').addEventListener('click', () => {
            this.previousScene();
        });
        
        document.getElementById('nextBtn').addEventListener('click', () => {
            this.nextScene();
        });
        
        document.getElementById('pauseBtn').addEventListener('click', () => {
            this.togglePause();
        });
    }
    
    async showScene(index) {
        console.log('🎬 Showing scene:', index, this.scenes[index].name);
        
        // Stop any existing scroll animation
        this.stopScrollAnimation();
        
        // Hide all scenes
        document.querySelectorAll('.scene').forEach(scene => {
            scene.classList.remove('active');
            scene.scrollTop = 0; // Reset scroll position
        });
        
        // Show target scene
        this.currentScene = index;
        const scene = this.scenes[index];
        const sceneElement = document.getElementById(scene.id);
        sceneElement.classList.add('active');
        
        // Update scene indicator
        document.getElementById('sceneIndicator').textContent = 
            `Scene ${index + 1} of ${this.scenes.length}`;
        
        // Load scene data
        console.log('📥 Loading scene data...');
        await scene.loader();
        console.log('✅ Scene data loaded');
        
        // Start auto-scroll for this scene (after a short delay to let content render)
        setTimeout(() => {
            console.log('⏰ Starting scroll animation after delay');
            this.startScrollAnimation(sceneElement);
        }, 500);
        
        // Reset countdown
        this.resetCountdown();
    }
    
    startScrollAnimation(sceneElement) {
        console.log('🔍 Starting scroll animation for scene:', sceneElement.id);
        
        // Find scrollable container within the scene
        const scrollableContainers = [
            sceneElement.querySelector('.full-roster'),
            sceneElement.querySelector('.activity-feed'),
            sceneElement.querySelector('.champions-grid')
        ].filter(el => el !== null);
        
        console.log('📦 Found scrollable containers:', scrollableContainers.length);
        
        if (scrollableContainers.length === 0) {
            console.log('⚠️ No scrollable containers found in this scene');
            return; // No scrollable content in this scene
        }
        
        const container = scrollableContainers[0];
        const maxScroll = container.scrollHeight - container.clientHeight;
        
        console.log('📏 Container dimensions:', {
            scrollHeight: container.scrollHeight,
            clientHeight: container.clientHeight,
            maxScroll: maxScroll
        });
        
        // Only scroll if there's overflow
        if (maxScroll <= 0) {
            console.log('⚠️ No overflow detected - content fits on screen');
            return;
        }
        
        console.log('✅ Starting auto-scroll! Speed:', maxScroll / (this.sceneDuration - 2), 'px/sec');
        
        // Calculate scroll speed (pixels per second)
        // We want to scroll through the entire content during the scene duration
        const scrollDuration = this.sceneDuration - 2; // Leave 2 seconds buffer
        const scrollSpeed = maxScroll / scrollDuration; // pixels per second
        
        let lastTimestamp = null;
        let currentScroll = 0;
        let direction = 1; // 1 for down, -1 for up
        let frameCount = 0;
        
        const animate = (timestamp) => {
            if (!lastTimestamp) {
                lastTimestamp = timestamp;
            }
            
            if (!this.isPaused) {
                const deltaTime = (timestamp - lastTimestamp) / 1000; // Convert to seconds
                lastTimestamp = timestamp;
                
                // Update scroll position
                currentScroll += scrollSpeed * deltaTime * direction;
                
                // Log every 60 frames (once per second at 60fps)
                frameCount++;
                if (frameCount % 60 === 0) {
                    console.log('🔄 Scrolling...', {
                        currentScroll: Math.round(currentScroll),
                        maxScroll: maxScroll,
                        direction: direction === 1 ? 'down' : 'up',
                        containerScrollTop: container.scrollTop
                    });
                }
                
                // Reverse direction at boundaries for smooth loop
                if (currentScroll >= maxScroll) {
                    currentScroll = maxScroll;
                    direction = -1; // Start scrolling back up
                    console.log('🔃 Reached bottom, reversing direction');
                } else if (currentScroll <= 0) {
                    currentScroll = 0;
                    direction = 1; // Start scrolling down again
                    console.log('🔃 Reached top, reversing direction');
                }
                
                container.scrollTop = currentScroll;
            } else {
                // If paused, just update the timestamp to prevent jump when resumed
                lastTimestamp = timestamp;
            }
            
            this.scrollAnimationFrame = requestAnimationFrame(animate);
        };
        
        this.scrollAnimationFrame = requestAnimationFrame(animate);
        console.log('🎬 Animation frame started');
    }
    
    stopScrollAnimation() {
        if (this.scrollAnimationFrame) {
            cancelAnimationFrame(this.scrollAnimationFrame);
            this.scrollAnimationFrame = null;
        }
    }
    
    async refreshCurrentScene() {
        const scene = this.scenes[this.currentScene];
        await scene.loader();
        this.updateLastUpdatedTime();
    }
    
    nextScene() {
        const nextIndex = (this.currentScene + 1) % this.scenes.length;
        this.showScene(nextIndex);
    }
    
    previousScene() {
        const prevIndex = (this.currentScene - 1 + this.scenes.length) % this.scenes.length;
        this.showScene(prevIndex);
    }
    
    togglePause() {
        this.isPaused = !this.isPaused;
        const pauseBtn = document.getElementById('pauseBtn');
        pauseBtn.textContent = this.isPaused ? '▶ Resume' : '⏸ Pause';
    }
    
    startCountdown() {
        let secondsLeft = this.sceneDuration;
        
        this.countdownInterval = setInterval(() => {
            if (!this.isPaused) {
                secondsLeft--;
                document.getElementById('countdown').textContent = secondsLeft;
                
                // Update progress bar
                const progress = (secondsLeft / this.sceneDuration) * 100;
                document.getElementById('timerProgress').style.width = `${progress}%`;
                
                if (secondsLeft <= 0) {
                    this.nextScene();
                    secondsLeft = this.sceneDuration;
                }
            }
        }, 1000);
    }
    
    resetCountdown() {
        document.getElementById('countdown').textContent = this.sceneDuration;
        document.getElementById('timerProgress').style.width = '100%';
    }
    
    updateLastUpdatedTime() {
        const now = new Date();
        const timeString = now.toLocaleTimeString('en-US', { 
            hour: '2-digit', 
            minute: '2-digit' 
        });
        document.getElementById('updateTime').textContent = timeString;
    }
    
    // Scene Loaders
    async loadTop10() {
        try {
            const response = await fetch('/api/leaderboard/top10');
            const players = await response.json();
            
            const container = document.getElementById('top10List');
            container.innerHTML = '';
            
            players.forEach((player, index) => {
                const card = this.createPlayerCard(player, index);
                container.appendChild(card);
            });
        } catch (error) {
            console.error('Failed to load top 10:', error);
        }
    }
    
    createPlayerCard(player, index) {
        const card = document.createElement('div');
        card.className = `player-card ${index < 3 ? 'top-3' : ''}`;
        
        const rankClass = index === 0 ? 'gold' : index === 1 ? 'silver' : index === 2 ? 'bronze' : '';
        const trendIcon = player.trend === 'up' ? '↑' : player.trend === 'down' ? '↓' : '•';
        const trendClass = player.trend === 'up' ? 'trend-up' : player.trend === 'down' ? 'trend-down' : '';
        const trendText = player.trend_positions > 0 ? `${trendIcon}${player.trend_positions}` : trendIcon;
        
        card.innerHTML = `
            <div class="rank-badge ${rankClass}">${player.rank}</div>
            <div class="player-info">
                <div class="player-name">${player.name}</div>
                <div class="player-stats">
                    <span class="stat-item">💯 ${this.formatScore(player.score)}</span>
                    <span class="stat-item">🎮 ${player.games_played} games</span>
                </div>
            </div>
            <div class="trend-indicator ${trendClass}">${trendText}</div>
        `;
        
        return card;
    }
    
    async loadChampions() {
        try {
            const response = await fetch('/api/game-champions');
            const champions = await response.json();
            
            const container = document.getElementById('championsList');
            container.innerHTML = '';
            
            champions.forEach(game => {
                const card = document.createElement('div');
                card.className = 'champion-card';
                card.innerHTML = `
                    <div class="game-name">🎯 ${game.name}</div>
                    <div class="champion-info">
                        <div class="champion-name">${game.champion}</div>
                        <div class="champion-score">${this.formatScore(game.score)}</div>
                    </div>
                `;
                container.appendChild(card);
            });
        } catch (error) {
            console.error('Failed to load champions:', error);
        }
    }
    
    async loadActivity() {
        try {
            const response = await fetch('/api/recent-activity');
            const activities = await response.json();
            
            const container = document.getElementById('activityFeed');
            container.innerHTML = '';
            
            activities.slice(0, 10).forEach(activity => {
                const item = document.createElement('div');
                item.className = `activity-item ${activity.is_personal_best ? 'personal-best' : ''}`;
                
                const timeAgo = this.formatTimeAgo(activity.minutes_ago);
                const pbBadge = activity.is_personal_best ? '<span class="pb-badge">PERSONAL BEST!</span>' : '';
                
                item.innerHTML = `
                    <div class="activity-header">
                        <span class="activity-player">${activity.player}</span>
                        <span class="activity-time">${timeAgo}</span>
                    </div>
                    <div class="activity-game">${activity.game}</div>
                    <div class="activity-score">${this.formatScore(activity.score)}${pbBadge}</div>
                `;
                container.appendChild(item);
            });
        } catch (error) {
            console.error('Failed to load activity:', error);
        }
    }
    
    async loadRoster() {
        try {
            const response = await fetch('/api/leaderboard/full');
            const players = await response.json();
            
            const container = document.getElementById('fullRoster');
            container.innerHTML = '';
            
            players.forEach(player => {
                const item = document.createElement('div');
                item.className = 'roster-item';
                item.innerHTML = `
                    <span class="roster-rank">#${player.rank}</span>
                    <span class="roster-name">${player.name}</span>
                    <span class="roster-score">${this.formatScore(player.score)}</span>
                `;
                container.appendChild(item);
            });
        } catch (error) {
            console.error('Failed to load roster:', error);
        }
    }
    
    async loadStats() {
        try {
            const response = await fetch('/api/statistics');
            const stats = await response.json();
            
            const container = document.getElementById('statsGrid');
            container.innerHTML = '';
            
            const statCards = [
                { label: 'Games This Week', value: stats.total_games_this_week },
                { label: 'Games This Month', value: stats.total_games_this_month },
                { label: 'Active Players', value: stats.active_players },
                { label: 'Average Score', value: this.formatScore(stats.average_score) },
                { label: 'Most Popular', value: stats.most_popular_game },
                { label: 'Busiest Day', value: stats.busiest_day }
            ];
            
            statCards.forEach(stat => {
                const card = document.createElement('div');
                card.className = 'stat-card';
                card.innerHTML = `
                    <div class="stat-value">${stat.value}</div>
                    <div class="stat-label">${stat.label}</div>
                `;
                container.appendChild(card);
            });
        } catch (error) {
            console.error('Failed to load stats:', error);
        }
    }
    
    // Utility functions
    formatScore(score) {
        if (score >= 1000000) {
            return `${(score / 1000000).toFixed(1)}M`;
        } else if (score >= 1000) {
            return `${(score / 1000).toFixed(1)}K`;
        }
        return score.toLocaleString();
    }
    
    formatTimeAgo(minutes) {
        if (minutes < 60) {
            return `${minutes}m ago`;
        } else if (minutes < 1440) {
            const hours = Math.floor(minutes / 60);
            return `${hours}h ago`;
        } else {
            const days = Math.floor(minutes / 1440);
            return `${days}d ago`;
        }
    }
}

// Initialize the kiosk when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    new PinballKiosk();
});
