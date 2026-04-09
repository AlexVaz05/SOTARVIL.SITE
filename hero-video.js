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
        // Pre-allocate array
        this.frames = new Array(this.totalFrames);
        
        // Load the first frame immediately so background isn't blank
        this.loadFrame(1).then(() => {
            this.drawFrame(0);
            
            // Start the animation loop and load the rest
            this.start();
            this.loadRemainingFrames();
        });
    }

    loadFrame(i) {
        return new Promise((resolve) => {
            const img = new Image();
            img.onload = () => {
                this.loadedCount++;
                resolve();
            };
            img.onerror = () => {
                // Resolve anyway so we don't block the sequence
                resolve();
            };
            const frameNum = String(i).padStart(3, '0');
            img.src = `${this.framePath}ezgif-frame-${frameNum}.jpg`;
            this.frames[i - 1] = img;
        });
    }

    async loadRemainingFrames() {
        const chunkSize = 8; // Load 8 images concurrently
        for (let i = 2; i <= this.totalFrames; i += chunkSize) {
            const promises = [];
            for (let j = 0; j < chunkSize && (i + j) <= this.totalFrames; j++) {
                promises.push(this.loadFrame(i + j));
            }
            await Promise.all(promises);
        }
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
            // Only advance frame if the *next* frame is fully loaded
            const nextFrame = (this.currentFrame + 1) % this.totalFrames;
            
            if (this.frames[nextFrame] && this.frames[nextFrame].complete) {
                this.currentFrame = nextFrame;
                this.drawFrame(this.currentFrame);
            }
            
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
