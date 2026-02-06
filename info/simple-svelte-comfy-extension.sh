#!/bin/bash
# first try to implement a svelte extension for comfyui

set -e  # Exit on error

echo "🚀 ComfyUI Svelte Extension Setup Script"
echo "=========================================="

# Extension Name definieren
EXTENSION_NAME="svelte_preview"
EXTENSION_DIR="custom_nodes/${EXTENSION_NAME}"

# Prüfen ob wir im ComfyUI Verzeichnis sind
if [ ! -d "custom_nodes" ]; then
    echo "❌ Error: custom_nodes directory not found. Run this script from ComfyUI root directory."
    exit 1
fi

echo "📁 Creating directory structure..."
mkdir -p "${EXTENSION_DIR}/web/src/lib"
mkdir -p "${EXTENSION_DIR}/web/static"
mkdir -p "${EXTENSION_DIR}/web/dist"

# 1. Python Backend Dateien erstellen
echo "🐍 Creating Python backend files..."

cat > "${EXTENSION_DIR}/__init__.py" << 'EOF'
from .nodes import NODE_CLASS_MAPPINGS, NODE_DISPLAY_NAME_MAPPINGS

WEB_DIRECTORY = "./web/dist"

__all__ = ['NODE_CLASS_MAPPINGS', 'NODE_DISPLAY_NAME_MAPPINGS', 'WEB_DIRECTORY']
EOF

cat > "${EXTENSION_DIR}/nodes.py" << 'EOF'
import os
import numpy as np
from PIL import Image
import io
import base64
import json

class SveltePreviewNode:
    def __init__(self):
        self.preview_data = None

    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                "images": ("IMAGE",),
                "auto_preview": (["enabled", "disabled"], {"default": "enabled"}),
            },
            "optional": {
                "preview_data": ("PREVIEW_DATA", {"default": None}),
            }
        }

    RETURN_TYPES = ("IMAGE", "PREVIEW_DATA")
    RETURN_NAMES = ("image", "preview_data")
    FUNCTION = "preview"
    CATEGORY = "Svelte Nodes"
    OUTPUT_NODE = True

    def preview(self, images, auto_preview="enabled", preview_data=None):
        # Konvertiere Tensor zu PIL Image
        if len(images) > 0:
            image = images[0]  # Nimm erstes Bild
            image = 255.0 * image.cpu().numpy()
            image = Image.fromarray(np.clip(image, 0, 255).astype(np.uint8))

            # Konvertiere zu Base64 für das Frontend
            buffered = io.BytesIO()
            image.save(buffered, format="PNG")
            img_str = base64.b64encode(buffered.getvalue()).decode()
        else:
            img_str = None

        # Daten für Svelte Frontend vorbereiten
        preview_data = {
            "image_data": img_str,
            "timestamp": len(images),
            "auto_preview": auto_preview
        }

        return (images, preview_data)

NODE_CLASS_MAPPINGS = {
    "SveltePreviewNode": SveltePreviewNode,
}

NODE_DISPLAY_NAME_MAPPINGS = {
    "SveltePreviewNode": "Svelte Preview Node",
}
EOF

# 2. Frontend Package.json erstellen
echo "📦 Creating frontend package.json..."

cat > "${EXTENSION_DIR}/web/package.json" << 'EOF'
{
  "name": "svelte-preview-node",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite --port 3000",
    "build": "vite build",
    "preview": "vite preview"
  },
  "devDependencies": {
    "@sveltejs/vite-plugin-svelte": "^3.0.0",
    "svelte": "^4.2.0",
    "vite": "^5.0.0"
  }
}
EOF

# 3. Vite Konfiguration
echo "⚡ Creating Vite configuration..."

cat > "${EXTENSION_DIR}/web/vite.config.js" << 'EOF'
import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'

export default defineConfig({
  plugins: [svelte()],
  build: {
    lib: {
      entry: 'src/main.js',
      formats: ['es'],
      fileName: 'svelte-preview'
    },
    rollupOptions: {
      external: [],
      output: {
        dir: 'dist',
        entryFileNames: 'svelte-preview.js',
        chunkFileNames: 'chunks/[name]-[hash].js',
        assetFileNames: 'assets/[name]-[hash].[ext]'
      }
    }
  },
  server: {
    port: 3000,
    cors: true
  }
})
EOF

# 4. Svelte Bridge
echo "🔗 Creating ComfyUI bridge..."

cat > "${EXTENSION_DIR}/web/src/lib/comfy-bridge.js" << 'EOF'
export class ComfyBridge {
    constructor() {
        this.callbacks = new Map();
        this.socket = null;
        this.nodeId = null;
    }

    init(nodeId) {
        this.nodeId = nodeId;
        this.connectWebSocket();
    }

    connectWebSocket() {
        // Verbindung zum ComfyUI WebSocket
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        this.socket = new WebSocket(`${protocol}//${window.location.host}/ws`);

        this.socket.onopen = () => {
            console.log('ComfyUI WebSocket connected');
        };

        this.socket.onmessage = (event) => {
            try {
                const data = JSON.parse(event.data);
                this.handleMessage(data);
            } catch (error) {
                console.error('WebSocket message error:', error);
            }
        };
    }

    handleMessage(data) {
        if (data.type === 'executing' && data.data.node === this.nodeId) {
            this.trigger('node_executing', data);
        }
    }

    on(event, callback) {
        if (!this.callbacks.has(event)) {
            this.callbacks.set(event, []);
        }
        this.callbacks.get(event).push(callback);
    }

    trigger(event, data) {
        const callbacks = this.callbacks.get(event) || [];
        callbacks.forEach(callback => callback(data));
    }

    sendPreviewConfig(config) {
        if (this.socket && this.socket.readyState === WebSocket.OPEN) {
            this.socket.send(JSON.stringify({
                type: 'preview_config',
                node_id: this.nodeId,
                config: config
            }));
        }
    }
}
EOF

# 5. Svelte Component
echo "🎨 Creating Svelte component..."

cat > "${EXTENSION_DIR}/web/src/lib/preview-component.svelte" << 'EOF'
<script>
    import { onMount, onDestroy } from 'svelte';
    import { ComfyBridge } from './comfy-bridge.js';

    let bridge = new ComfyBridge();
    let imageData = $state(null);
    let isLoading = $state(false);
    let autoPreview = $state(true);

    let { nodeId, initialData } = $props();

    onMount(() => {
        bridge.init(nodeId);

        bridge.on('node_executing', (data) => {
            if (autoPreview) {
                isLoading = true;
            }
        });

        if (initialData) {
            imageData = initialData.image_data;
            autoPreview = initialData.auto_preview === 'enabled';
        }
    });

    function toggleAutoPreview() {
        autoPreview = !autoPreview;
        bridge.sendPreviewConfig({ auto_preview: autoPreview });
    }

    $effect(() => {
        console.log('AutoPreview changed:', autoPreview);
    });
</script>

<div class="svelte-preview">
    <div class="controls">
        <button class="btn" on:click={toggleAutoPreview} class:active={autoPreview}>
            {#if autoPreview}
                🔄 Auto Preview Enabled
            {:else}
                ⏸️ Auto Preview Disabled
            {/if}
        </button>
    </div>

    <div class="preview-container">
        {#if imageData}
            <img
                src={`data:image/png;base64,${imageData}`}
                alt="Preview"
                class="preview-image"
            />
        {:else if isLoading}
            <div class="loading">Loading preview...</div>
        {:else}
            <div class="no-preview">No preview available</div>
        {/if}
    </div>
</div>

<style>
    .svelte-preview {
        padding: 10px;
        border: 1px solid #ccc;
        border-radius: 8px;
        background: #f5f5f5;
        margin: 5px;
    }

    .controls {
        margin-bottom: 10px;
    }

    .btn {
        padding: 5px 10px;
        border: 1px solid #007acc;
        background: white;
        cursor: pointer;
        border-radius: 4px;
    }

    .btn.active {
        background: #007acc;
        color: white;
    }

    .preview-container {
        min-height: 200px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .preview-image {
        max-width: 100%;
        max-height: 300px;
        border-radius: 4px;
    }

    .loading, .no-preview {
        color: #666;
        font-style: italic;
    }
</style>
EOF

# 6. Main Entry Point
echo "📄 Creating main.js..."

cat > "${EXTENSION_DIR}/web/src/main.js" << 'EOF'
import PreviewComponent from './lib/preview-component.svelte';

export function createPreviewNode(element, nodeId, initialData) {
    new PreviewComponent({
        target: element,
        props: { nodeId, initialData }
    });
}

if (typeof window !== 'undefined') {
    window.SveltePreviewNode = { createPreviewNode };
}
EOF

# 7. Svelte Config
echo "🛠️ Creating svelte.config.js..."

cat > "${EXTENSION_DIR}/web/svelte.config.js" << 'EOF'
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte'

export default {
  preprocess: vitePreprocess(),
}
EOF

# 8. HTML Test File für Entwicklung
echo "🌐 Creating dev index.html..."

cat > "${EXTENSION_DIR}/web/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Svelte Preview Node Dev</title>
</head>
<body>
    <div id="test-node"></div>
    <script type="module">
        import { createPreviewNode } from './src/main.js';

        // Testdaten
        const testData = {
            image_data: null,
            auto_preview: 'enabled'
        };

        createPreviewNode(document.getElementById('test-node'), 'test-node-123', testData);
    </script>
</body>
</html>
EOF

# 9. README mit Anleitung
echo "📖 Creating README.md..."

cat > "${EXTENSION_DIR}/README.md" << 'EOF'
# Svelte Preview Node für ComfyUI

Eine Beispiel-Extension die Svelte 5 mit ComfyUI integriert.

## Entwicklung

```bash
cd web
npm install
npm run dev  # Entwicklungs-Server auf Port 3000
