"""
WSGI entry point for production deployment with Gunicorn.

Usage:
    gunicorn -w 4 -b 127.0.0.1:5001 wsgi:app
"""

import os
import sys

# Ensure UTF-8 output on all platforms
os.environ.setdefault('PYTHONIOENCODING', 'utf-8')

# Add backend directory to path so `app` package is importable
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app

app = create_app()
