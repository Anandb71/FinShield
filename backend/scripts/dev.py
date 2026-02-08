#!/usr/bin/env python3
"""
FinShield API - Development Server Launcher

Quick script to start the development server with hot-reload.
"""

import subprocess
import sys
from pathlib import Path


def main():
    """Launch uvicorn with hot-reload."""
    # Ensure we're in the backend directory
    backend_dir = Path(__file__).parent.parent
    
    cmd = [
        sys.executable, "-m", "uvicorn",
        "app.main:app",
        "--host", "0.0.0.0",
        "--port", "8000",
        "--reload",
        "--reload-dir", str(backend_dir / "app"),
    ]
    
    print("🛡️  FinShield API - Starting Development Server...")
    print(f"📍 API: http://localhost:8000")
    print(f"📚 Docs: http://localhost:8000/docs")
    print(f"🔄 Hot-reload enabled")
    print("-" * 50)
    
    subprocess.run(cmd, cwd=backend_dir)


if __name__ == "__main__":
    main()
