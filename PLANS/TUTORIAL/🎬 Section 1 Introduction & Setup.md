# 🎬 Section 1: Introduction & Setup

## EP01: What Is DRAW? — Overview & Philosophy

### 🎯 Goal: Understand what DRAW is and why it exists

### Pixel art editor written in QB64-PE (BASIC!)

### Unique feature: exports artwork as QB64 source code

### Open source — GitHub repo walkthrough

### Inspired by classic DPaint / ProMotion / Deluxe Paint

### Cross-platform: Windows, Linux, macOS

### Feature highlights reel — quick demo of capabilities

### 64 layers, 19 blend modes, full text system

### Theming, audio, custom brushes, symmetry drawing

### Native .draw format (PNG with embedded project data)

## EP02: Getting DRAW — Download, Build & Install

### 🎯 Goal: Get DRAW running on your machine

### Option A: Download Pre-Built Release

- GitHub Releases page walkthrough
  
- Choose your platform (Win/Linux/Mac)
  
- Extract and run — zero dependencies
  
### Option B: Build From Source

- Install QB64-PE compiler
  
- Clone the DRAW repo
  
- Build command: qb64pe -w -x DRAW.BAS -o DRAW.run
  
- Makefile targets explained
  
### Platform-Specific Setup

- Linux: .desktop file + MIME type registration
  
- Windows: Registry + Start Menu installer
  
- macOS: install-mac.command walkthrough
  
### First launch — auto-detection of display & scale

### DRAW.cfg — where settings live

## EP03: Your First 5 Minutes — UI Tour

### 🎯 Goal: Navigate the interface confidently

### Screen Layout Overview

- Menu Bar (11 menus: File → Audio)
  
- Toolbar (4×7 grid, 28 tool buttons)
  
- Canvas (center — your drawing area)
  
- Palette Strip (bottom — color swatches)
  
- Status Bar (info: coords, zoom, tool, grid)
  
- Layer Panel (right side)
  
### Hidden Panels (toggle on/off)

- Organizer Widget — brush presets & toggles
  
- Drawer Panel — 30 reusable brush/pattern slots
  
- Edit Bar (F5) — quick edit actions
  
- Advanced Bar (Shift+F5) — 26+ toggles
  
- Preview Window (F4) — magnifier or floating
  
- Character Map (Ctrl+M) — glyph grid
  
### Docking system — Ctrl+Shift+Click to swap sides

### F11 = Toggle ALL UI / Ctrl+F11 = Menu only

### Tab = Toggle Toolbar visibility

### Command Palette ( ? key) — searchable command list

