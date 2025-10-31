FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY api_server.py .
COPY static/ ./static/

# Expose port
EXPOSE 5050

# Use gunicorn for production
CMD gunicorn --bind 0.0.0.0:5050 --workers 2 --timeout 60 api_server:app
