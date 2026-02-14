#!/usr/bin/env python3
"""
Entry point for running mcp_video_tutorial as a module.
Launches the MCP server.
"""

from .server import run_server

if __name__ == "__main__":
    run_server()
