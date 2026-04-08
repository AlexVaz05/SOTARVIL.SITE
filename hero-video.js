/**
 * Sotarvil Hero Video Background (Frame Sequence)
 * Plays 192 frames from SUPER FRAMES/ folder on a canvas
 */

class HeroVideo {
    constructor(canvasId, framePath, totalFrames) {
        this.canvas = document.getElementById(canvasId);
        if (!this.canvas) return;
        this.ctx = this.canvas.getContext('2d');
        this.framePath = framePath;
        this.totalFrames = totalFrames;
        this.frames = [];
        this.currentFrame = 0;
        this.loadedCount = 0;
        this.isPlaying = false;
        
        this.init();
    }

    init() {
        this.resize();
        window.addEventListener('resize', () => this.resize());
        this.preloadFrames();
    }

    resize() {
        // High DPI support
        const dpr = window.devicePixelRatio || 1;
        this.canvas.width = this.canvas.offsetWidth * dpr;
        this.canvas.height = this.canvas.offsetHeight * dpr;
        this.ctx.scale(dpr, dpr);
        
        // Redraw current frame if resizing while playing
        if (this.frames[this.currentFrame]) {
            this.drawFrame(this.currentFrame);
        }
    }

    preloadFrames() {
        for (let i = 1; i <= this.totalFrames; i++) {
            const img = new Image();
            // Naming convention: ezgif-frame-001.jpg
            const frameNum = String(i).padStart(3, '0');
            img.src = `${this.framePath}ezgif-frame-${frameNum}.jpg`;
            img.onload = () => {
                this.loadedCount++;
                if (this.loadedCount === this.totalFrames && !this.isPlaying) {
                    this.start();
                }
            };
            this.frames.push(img);
        }
        
        // Emergency start if some images fail but we have enough
        setTimeout(() => {
            if (!this.isPlaying && this.loadedCount > 20) {
                this.start();
            }
        }, 5000);
    }

    drawFrame(index) {
        const img = this.frames[index];
        if (!img || !img.complete) return;

        const canvasW = this.canvas.width / (window.devicePixelRatio || 1);
        const canvasH = this.canvas.height / (window.devicePixelRatio || 1);
        
        // Center/Cover logic
        const imgRatio = img.width / img.height;
        const canvasRatio = canvasW / canvasH;
        
        let drawW, drawH, drawX, drawY;
        
        if (imgRatio > canvasRatio) {
            drawH = canvasH;
            drawW = canvasH * imgRatio;
            drawX = (canvasW - drawW) / 2;
            drawY = 0;
        } else {
            drawW = canvasW;
            drawH = canvasW / imgRatio;
            drawX = 0;
            drawY = (canvasH - drawH) / 2;
        }
        
        this.ctx.clearRect(0, 0, canvasW, canvasH);
        this.ctx.drawImage(img, drawX, drawY, drawW, drawH);
    }

    animate(timestamp) {
        if (!this.lastTime) this.lastTime = timestamp;
        const elapsed = timestamp - this.lastTime;
        const fps = 24; // Cinematic frame rate
        const interval = 1000 / fps;

        if (elapsed >= interval) {
            this.currentFrame = (this.currentFrame + 1) % this.totalFrames;
            this.drawFrame(this.currentFrame);
            this.lastTime = timestamp - (elapsed % interval);
        }
        
        requestAnimationFrame((t) => this.animate(t));
    }

    start() {
        if (this.isPlaying) return;
        this.isPlaying = true;
        requestAnimationFrame((t) => {
            this.lastTime = t;
            this.animate(t);
        });
    }
}

document.addEventListener('DOMContentLoaded', () => {
    // Check if we are on the homepage
    const canvas = document.getElementById('hero-canvas');
    if (canvas) {
        // Simple singleton-ish check to avoid multiple instances
        if (!window.heroVideoInstance) {
            window.heroVideoInstance = new HeroVideo('hero-canvas', 'SUPER FRAMES/', 192);
        }
    }
});
