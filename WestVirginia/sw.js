/**
 * WVDoc Service Worker - Advanced Caching & Offline Support
 * Version: 3.0.0
 * Features: Intelligent caching, background sync, push notifications, performance monitoring
 */

const CACHE_VERSION = 'WestVirginiaDoc-v3.0.0';
const RUNTIME_CACHE = 'WestVirginiaDoc-runtime-v3.0.0';
const STATIC_CACHE = 'WestVirginiaDoc-static-v3.0.0';
const DYNAMIC_CACHE = 'WestVirginiaDoc-dynamic-v3.0.0';

// Cache strategies
const CACHE_STRATEGIES = {
    CACHE_FIRST: 'cache-first',
    NETWORK_FIRST: 'network-first',
    STALE_WHILE_REVALIDATE: 'stale-while-revalidate',
    NETWORK_ONLY: 'network-only',
    CACHE_ONLY: 'cache-only'
};

// Resources to precache
const PRECACHE_URLS = [
    '/',
    '/index.html',
    '/privacy.html',
    '/terms.html',
    '/manifest.json'
];

// External resources to cache
const EXTERNAL_CACHE_PATTERNS = [
    /^https:\/\/fonts\.googleapis\.com/,
    /^https:\/\/fonts\.gstatic\.com/,
    /^https:\/\/cdn\.jsdelivr\.net/,
    /^https:\/\/unpkg\.com/
];

// API endpoints for network-first strategy
const API_PATTERNS = [
    /^https:\/\/api\.WestVirginiaDoc\.com/,
    /\/api\//
];

// Performance monitoring
let performanceMetrics = {
    cacheHits: 0,
    cacheMisses: 0,
    networkRequests: 0,
    offlineRequests: 0
};

/**
 * Service Worker Installation
 * Precaches essential resources and skips waiting
 */
self.addEventListener('install', event => {
    console.log('[SW] Installing service worker version:', CACHE_VERSION);
    
    event.waitUntil(
        Promise.all([
            // Precache static resources
            caches.open(STATIC_CACHE).then(cache => {
                console.log('[SW] Precaching static resources');
                return cache.addAll(PRECACHE_URLS);
            }),
            
            // Initialize performance metrics
            initializeMetrics()
        ]).then(() => {
            console.log('[SW] Installation complete');
            return self.skipWaiting();
        }).catch(error => {
            console.error('[SW] Installation failed:', error);
        })
    );
});

/**
 * Service Worker Activation
 * Cleans up old caches and claims clients
 */
self.addEventListener('activate', event => {
    console.log('[SW] Activating service worker version:', CACHE_VERSION);
    
    const currentCaches = [CACHE_VERSION, RUNTIME_CACHE, STATIC_CACHE, DYNAMIC_CACHE];
    
    event.waitUntil(
        Promise.all([
            // Clean up old caches
            caches.keys().then(cacheNames => {
                return Promise.all(
                    cacheNames.map(cacheName => {
                        if (!currentCaches.includes(cacheName)) {
                            console.log('[SW] Deleting old cache:', cacheName);
                            return caches.delete(cacheName);
                        }
                    })
                );
            }),
            
            // Claim all clients
            self.clients.claim()
        ]).then(() => {
            console.log('[SW] Activation complete');
        }).catch(error => {
            console.error('[SW] Activation failed:', error);
        })
    );
});

/**
 * Fetch Event Handler
 * Implements intelligent caching strategies based on request type
 */
self.addEventListener('fetch', event => {
    const { request } = event;
    const url = new URL(request.url);
    
    // Skip non-GET requests and chrome-extension requests
    if (request.method !== 'GET' || url.protocol === 'chrome-extension:') {
        return;
    }
    
    // Determine caching strategy based on request
    const strategy = getCachingStrategy(request, url);
    
    event.respondWith(
        handleRequest(request, strategy)
            .then(response => {
                // Update performance metrics
                updateMetrics(strategy, response);
                return response;
            })
            .catch(error => {
                console.error('[SW] Fetch error:', error);
                return handleFetchError(request, error);
            })
    );
});

/**
 * Background Sync for offline actions
 */
self.addEventListener('sync', event => {
    console.log('[SW] Background sync triggered:', event.tag);
    
    if (event.tag === 'background-sync') {
        event.waitUntil(doBackgroundSync());
    }
});

/**
 * Push notification handler
 */
self.addEventListener('push', event => {
    console.log('[SW] Push notification received');
    
    const options = {
        body: event.data ? event.data.text() : 'New update available',
        icon: '/icon-192x192.png',
        badge: '/badge-72x72.png',
        vibrate: [100, 50, 100],
        data: {
            dateOfArrival: Date.now(),
            primaryKey: 1
        },
        actions: [
            {
                action: 'explore',
                title: 'View Update',
                icon: '/icon-explore.png'
            },
            {
                action: 'close',
                title: 'Close',
                icon: '/icon-close.png'
            }
        ]
    };
    
    event.waitUntil(
        self.registration.showNotification('WVDoc Update', options)
    );
});

/**
 * Notification click handler
 */
self.addEventListener('notificationclick', event => {
    console.log('[SW] Notification clicked:', event.action);
    
    event.notification.close();
    
    if (event.action === 'explore') {
        event.waitUntil(
            clients.openWindow('/')
        );
    }
});

/**
 * Determines the appropriate caching strategy for a request
 */
function getCachingStrategy(request, url) {
    // API requests - network first
    if (API_PATTERNS.some(pattern => pattern.test(url.href))) {
        return CACHE_STRATEGIES.NETWORK_FIRST;
    }
    
    // External resources - cache first
    if (EXTERNAL_CACHE_PATTERNS.some(pattern => pattern.test(url.href))) {
        return CACHE_STRATEGIES.CACHE_FIRST;
    }
    
    // Same origin requests
    if (url.origin === location.origin) {
        // HTML pages - stale while revalidate
        if (request.destination === 'document') {
            return CACHE_STRATEGIES.STALE_WHILE_REVALIDATE;
        }
        
        // Static assets - cache first
        if (request.destination === 'style' || 
            request.destination === 'script' || 
            request.destination === 'image') {
            return CACHE_STRATEGIES.CACHE_FIRST;
        }
    }
    
    // Default to network first
    return CACHE_STRATEGIES.NETWORK_FIRST;
}

/**
 * Handles requests based on caching strategy
 */
async function handleRequest(request, strategy) {
    const url = new URL(request.url);
    
    switch (strategy) {
        case CACHE_STRATEGIES.CACHE_FIRST:
            return cacheFirst(request);
            
        case CACHE_STRATEGIES.NETWORK_FIRST:
            return networkFirst(request);
            
        case CACHE_STRATEGIES.STALE_WHILE_REVALIDATE:
            return staleWhileRevalidate(request);
            
        case CACHE_STRATEGIES.CACHE_ONLY:
            return cacheOnly(request);
            
        case CACHE_STRATEGIES.NETWORK_ONLY:
            return networkOnly(request);
            
        default:
            return networkFirst(request);
    }
}

/**
 * Cache First Strategy
 */
async function cacheFirst(request) {
    const cachedResponse = await caches.match(request);
    
    if (cachedResponse) {
        performanceMetrics.cacheHits++;
        return cachedResponse;
    }
    
    performanceMetrics.cacheMisses++;
    const networkResponse = await fetch(request);
    
    if (networkResponse.ok) {
        const cache = await caches.open(DYNAMIC_CACHE);
        cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
}

/**
 * Network First Strategy
 */
async function networkFirst(request) {
    try {
        performanceMetrics.networkRequests++;
        const networkResponse = await fetch(request);
        
        if (networkResponse.ok) {
            const cache = await caches.open(DYNAMIC_CACHE);
            cache.put(request, networkResponse.clone());
        }
        
        return networkResponse;
    } catch (error) {
        performanceMetrics.offlineRequests++;
        const cachedResponse = await caches.match(request);
        
        if (cachedResponse) {
            return cachedResponse;
        }
        
        throw error;
    }
}

/**
 * Stale While Revalidate Strategy
 */
async function staleWhileRevalidate(request) {
    const cachedResponse = await caches.match(request);
    
    const fetchPromise = fetch(request).then(networkResponse => {
        if (networkResponse.ok) {
            const cache = caches.open(DYNAMIC_CACHE);
            cache.then(c => c.put(request, networkResponse.clone()));
        }
        return networkResponse;
    }).catch(() => {
        // Silently fail network requests in SWR
    });
    
    return cachedResponse || fetchPromise;
}

/**
 * Cache Only Strategy
 */
async function cacheOnly(request) {
    return caches.match(request);
}

/**
 * Network Only Strategy
 */
async function networkOnly(request) {
    return fetch(request);
}

/**
 * Handles fetch errors with fallbacks
 */
async function handleFetchError(request, error) {
    const url = new URL(request.url);
    
    // Try to serve from cache
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
        return cachedResponse;
    }
    
    // For navigation requests, serve offline page
    if (request.destination === 'document') {
        const offlinePage = await caches.match('/index.html');
        if (offlinePage) {
            return offlinePage;
        }
    }
    
    // Return a basic offline response
    return new Response(
        JSON.stringify({
            error: 'Network error',
            message: 'You appear to be offline. Please check your connection.',
            timestamp: new Date().toISOString()
        }),
        {
            status: 503,
            statusText: 'Service Unavailable',
            headers: {
                'Content-Type': 'application/json'
            }
        }
    );
}

/**
 * Background sync for offline actions
 */
async function doBackgroundSync() {
    console.log('[SW] Performing background sync');
    
    try {
        // Sync any pending data
        const pendingRequests = await getPendingRequests();
        
        for (const request of pendingRequests) {
            try {
                await fetch(request);
                await removePendingRequest(request);
            } catch (error) {
                console.error('[SW] Background sync failed for request:', error);
            }
        }
        
        console.log('[SW] Background sync completed');
    } catch (error) {
        console.error('[SW] Background sync error:', error);
    }
}

/**
 * Initialize performance metrics
 */
async function initializeMetrics() {
    try {
        const stored = await getStoredMetrics();
        if (stored) {
            performanceMetrics = { ...performanceMetrics, ...stored };
        }
    } catch (error) {
        console.error('[SW] Failed to initialize metrics:', error);
    }
}

/**
 * Update performance metrics
 */
function updateMetrics(strategy, response) {
    // Store metrics periodically
    if (Math.random() < 0.1) { // 10% chance to store metrics
        storeMetrics(performanceMetrics);
    }
}

/**
 * Storage helpers for IndexedDB operations
 */
async function getPendingRequests() {
    // Implementation would use IndexedDB to store pending requests
    return [];
}

async function removePendingRequest(request) {
    // Implementation would remove request from IndexedDB
}

async function getStoredMetrics() {
    // Implementation would retrieve metrics from IndexedDB
    return null;
}

async function storeMetrics(metrics) {
    // Implementation would store metrics to IndexedDB
    console.log('[SW] Performance metrics:', metrics);
}

/**
 * Message handler for communication with main thread
 */
self.addEventListener('message', event => {
    console.log('[SW] Message received:', event.data);
    
    if (event.data && event.data.type === 'SKIP_WAITING') {
        self.skipWaiting();
    }
    
    if (event.data && event.data.type === 'GET_METRICS') {
        event.ports[0].postMessage(performanceMetrics);
    }
    
    if (event.data && event.data.type === 'CLEAR_CACHE') {
        clearAllCaches().then(() => {
            event.ports[0].postMessage({ success: true });
        });
    }
});

/**
 * Clear all caches
 */
async function clearAllCaches() {
    const cacheNames = await caches.keys();
    return Promise.all(
        cacheNames.map(cacheName => caches.delete(cacheName))
    );
}

console.log('[SW] Service Worker loaded successfully - Version:', CACHE_VERSION);

