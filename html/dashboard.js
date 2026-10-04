// ================= DASHBOARD SYSTEM =================

let speedUnit = 'kmh'; // 'kmh' or 'mph'
let vehicleData = {
    speed: 0,
    rpm: 0,
    fuel: 100,
    temp: 50,
    gear: 'N',
    engineRunning: false,
    engineHealth: 100,
    bodyHealth: 100,
    leftIndicator: false,
    rightIndicator: false,
    highbeam: false,
    lowbeam: false,
    hazard: false,
    seatbelt: false,
    abs: false,
    engineCheck: false,
    battery: false,
    oil: false,
    odometer: 0,
    doorsOpen: {}
};

let lastUpdateTime = Date.now();
let animationRequestId = null;
const layoutStorageKey = 'fighterjet_dashboard_free_layout_v3';
const defaultFreeLayout = {
    speed: { x: 93.5, y: 80.5, scale: 1 },
    rpm: { x: 87.5, y: 92.5, scale: .82 },
    gear: { x: 85.5, y: 77.5, scale: .86 },
    fuel: { x: 92.5, y: 97, scale: .9 },
    'turn-left': { x: 91, y: 89, scale: .8 },
    'turn-right': { x: 96, y: 89, scale: .8 },
    headlight: { x: 88, y: 83.5, scale: .82 },
    hazard: { x: 93.5, y: 89, scale: .82 },
    seatbelt: { x: 83, y: 95, scale: .78 },
    brake: { x: 80, y: 95, scale: .78 },
    engine: { x: 80.5, y: 89, scale: .78 },
    battery: { x: 83.5, y: 83.5, scale: .78 },
    oil: { x: 85.5, y: 83.5, scale: .78 },
    temperature: { x: 82.5, y: 89, scale: .78 },
    doors: { x: 75, y: 98, scale: .78 },
    clock: { x: 97, y: 3, scale: 1 },
    odometer: { x: 93.5, y: 92.5, scale: .82 }
};
let freeLayout = loadFreeLayout();
let layoutEditing = false;
let hudSettings = {
    showDashboard: true, showSpeed: true, showRpm: true, showCenter: true,
    showOdometer: true, showTurn: true, showHighbeam: true, showLowbeam: true, showHazard: true,
    showSeatbelt: true, showBrake: true, showEngine: true, showBattery: true,
    showOil: true, showTemperature: true, iconSize: 'large', hudColor: '#29e5cf',
    dashboardX: 83, dashboardY: 90, dashboardScale: 100
};

function setHudElement(selector, visible) {
    const element = document.querySelector(selector);
    if (element) element.classList.toggle('hud-option-hidden', !visible);
}

function applyHudSettings(settings) {
    hudSettings = Object.assign({}, hudSettings, settings || {});
    setHudElement('.speedometer', hudSettings.showSpeed);
    setHudElement('.rpm', hudSettings.showRpm);
    setHudElement('.center-panel', hudSettings.showCenter);
    setHudElement('.odo-panel', hudSettings.showOdometer);
    setHudElement('#ind-left', hudSettings.showTurn);
    setHudElement('#ind-right', hudSettings.showTurn);
    // OFF / low / high beam share one dashboard position.
    setHudElement('#ind-headlight', hudSettings.showHighbeam);
    setHudElement('#ind-hazard', hudSettings.showHazard);
    setHudElement('#ind-seatbelt', hudSettings.showSeatbelt);
    setHudElement('#ind-abs', hudSettings.showBrake);
    setHudElement('#ind-check', hudSettings.showEngine);
    setHudElement('#ind-battery', hudSettings.showBattery);
    setHudElement('#ind-oil', hudSettings.showOil);
    setHudElement('#ind-temp', hudSettings.showTemperature);
    document.body.classList.remove('hud-icons-small');
    document.body.classList.add('hud-icons-large');
    document.documentElement.style.setProperty('--hud-accent', hudSettings.hudColor || '#29e5cf');
    applyFreeLayout();
    if (!hudSettings.showDashboard) document.getElementById('dashboard').style.display = 'none';
}

function loadFreeLayout() {
    try { return Object.assign({}, defaultFreeLayout, JSON.parse(localStorage.getItem(layoutStorageKey) || '{}')); }
    catch (_) { return JSON.parse(JSON.stringify(defaultFreeLayout)); }
}

function saveFreeLayout() { localStorage.setItem(layoutStorageKey, JSON.stringify(freeLayout)); }

function applyFreeLayout() {
    document.querySelectorAll('.hud-movable[data-layout-id]').forEach((element) => {
        const id = element.dataset.layoutId;
        const item = Object.assign({}, defaultFreeLayout[id], freeLayout[id] || {});
        element.style.left = `${item.x}%`;
        element.style.top = `${item.y}%`;
        element.style.right = 'auto';
        element.style.bottom = 'auto';
        element.style.transform = `translate(-50%, -50%) scale(${item.scale})`;
        element.style.transformOrigin = 'center';
    });
}

function setLayoutEditing(enabled) {
    layoutEditing = !!enabled;
    document.body.classList.toggle('layout-editing', layoutEditing);
}

document.addEventListener('pointerdown', (event) => {
    if (!layoutEditing) return;
    const element = event.target.closest('.hud-movable[data-layout-id]');
    if (!element) return;
    event.preventDefault();
    element.setPointerCapture(event.pointerId);
    const id = element.dataset.layoutId;
    const move = (moveEvent) => {
        freeLayout[id] = freeLayout[id] || Object.assign({}, defaultFreeLayout[id]);
        freeLayout[id].x = Math.max(3, Math.min(97, moveEvent.clientX / window.innerWidth * 100));
        freeLayout[id].y = Math.max(3, Math.min(97, moveEvent.clientY / window.innerHeight * 100));
        applyFreeLayout();
    };
    const stop = () => {
        element.removeEventListener('pointermove', move);
        element.removeEventListener('pointerup', stop);
        element.removeEventListener('pointercancel', stop);
        saveFreeLayout();
    };
    element.addEventListener('pointermove', move);
    element.addEventListener('pointerup', stop);
    element.addEventListener('pointercancel', stop);
});

document.addEventListener('wheel', (event) => {
    if (!layoutEditing) return;
    const element = event.target.closest('.hud-movable[data-layout-id]');
    if (!element) return;
    event.preventDefault();
    const id = element.dataset.layoutId;
    freeLayout[id] = freeLayout[id] || Object.assign({}, defaultFreeLayout[id]);
    freeLayout[id].scale = Math.max(.5, Math.min(1.6, (freeLayout[id].scale || 1) + (event.deltaY < 0 ? .05 : -.05)));
    applyFreeLayout();
    saveFreeLayout();
}, { passive: false });

// ================= GAUGE DRAWING =================

function drawGauge(canvasId, currentValue, maxValue, label, color) {
    const canvas = document.getElementById(canvasId);
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const radius = Math.min(canvas.width, canvas.height) / 2 - 24;
    const centerX = canvas.width / 2;
    const centerY = canvas.height / 2;
    const startAngle = Math.PI * 0.75;
    const endAngle = Math.PI * 2.25;
    const totalAngle = endAngle - startAngle;
    const compactGauge = canvas.width <= 200;

    currentValue = Math.max(0, Math.min(Number(currentValue) || 0, maxValue));
    const progress = currentValue / maxValue;
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    const dialGradient = ctx.createRadialGradient(centerX, centerY, radius * 0.1, centerX, centerY, radius + 18);
    dialGradient.addColorStop(0, 'rgba(17, 32, 42, 0.94)');
    dialGradient.addColorStop(1, 'rgba(2, 9, 15, 0.88)');
    ctx.fillStyle = dialGradient;
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius + 18, 0, Math.PI * 2);
    ctx.fill();

    ctx.lineCap = 'round';
    ctx.strokeStyle = 'rgba(255,255,255,0.10)';
    ctx.lineWidth = 10;
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius, startAngle, endAngle);
    ctx.stroke();

    ctx.strokeStyle = color;
    ctx.shadowColor = color;
    ctx.shadowBlur = 12;
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius, startAngle, startAngle + totalAngle * progress);
    ctx.stroke();
    ctx.shadowBlur = 0;

    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';

    const tickCount = 24;
    for (let i = 0; i <= tickCount; i++) {
        const ratio = i / tickCount;
        const angle = startAngle + totalAngle * ratio;
        const major = i % 3 === 0;
        const outer = radius - 15;
        const inner = outer - (major ? 11 : 6);
        ctx.strokeStyle = ratio <= progress ? color : 'rgba(255,255,255,0.28)';
        ctx.lineWidth = major ? 2.2 : 1;
        ctx.beginPath();
        ctx.moveTo(centerX + Math.cos(angle) * outer, centerY + Math.sin(angle) * outer);
        ctx.lineTo(centerX + Math.cos(angle) * inner, centerY + Math.sin(angle) * inner);
        ctx.stroke();

        if (major && !compactGauge) {
            const labelRadius = radius - 40;
            let value = Math.round(ratio * maxValue);
            if (label === 'RPM') value = Math.round(value / 1000);
            ctx.fillStyle = 'rgba(220,245,250,0.68)';
            ctx.font = '600 13px Arial';
            ctx.fillText(value, centerX + Math.cos(angle) * labelRadius, centerY + Math.sin(angle) * labelRadius);
        }
    }

    let displayValue = Math.round(currentValue);
    let displayUnit = label;
    if (label === 'RPM') {
        displayValue = (currentValue / 1000).toFixed(1);
        displayUnit = 'x1000 RPM';
    } else if (label === 'SPEED') {
        displayUnit = speedUnit === 'mph' ? 'MPH' : 'KM/H';
    } else if (label === 'TEMP') {
        displayValue = Math.round(currentValue) + '°';
        displayUnit = 'TEMP';
    }

    ctx.fillStyle = '#ffffff';
    ctx.shadowColor = 'rgba(255,255,255,.35)';
    ctx.shadowBlur = 8;
    ctx.font = label === 'SPEED' ? '800 48px Arial' : (compactGauge ? '800 30px Arial' : '800 38px Arial');
    ctx.fillText(displayValue, centerX, centerY + 4);
    ctx.shadowBlur = 0;
    ctx.fillStyle = color;
    ctx.font = compactGauge ? '700 12px Arial' : '700 14px Arial';
    ctx.fillText(displayUnit, centerX, centerY + (compactGauge ? 27 : 31));
}

// ================= UPDATE FUNCTIONS =================

function updateGauges() {
    let speed = vehicleData.speed;
    if (speedUnit === 'mph') {
        speed = speed * 0.621371; // Convert KM/H to MPH
    }

    // Speedometer: 0-200 km/h
    drawGauge('speedCanvas', Math.min(speed, 200), 200, 'SPEED', hudSettings.hudColor || '#29e5cf');

    // RPM: 0-8000 (×1000)
    drawGauge('rpmCanvas', vehicleData.rpm, 8000, 'RPM', hudSettings.hudColor || '#29e5cf');

    // Update digital displays
    document.getElementById('gearValue').textContent = vehicleData.gear;
    document.getElementById('fuelPercent').textContent = Math.floor(vehicleData.fuel) + '%';
    const fuelLevel = document.getElementById('fuelLevel');
    const fuel = Math.max(0, Math.min(100, Number(vehicleData.fuel) || 0));
    fuelLevel.style.width = fuel + '%';
    fuelLevel.style.background = fuel < 20 ? '#ff4057' : (fuel < 45 ? '#ffb020' : '#27f59b');

    // Update odometer
    document.getElementById('odometer').textContent = Number(vehicleData.odometer || 0).toFixed(1).padStart(8, '0');

    // Update clock
    const now = new Date();
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    document.getElementById('clock').textContent = hours + ':' + minutes;

    // Update indicators
    updateIndicators();

    // Update door status
    updateDoorStatus();
}

function updateIndicators() {
    const headlight = document.getElementById('ind-headlight');
    if (headlight) {
        headlight.classList.remove('light-state-off', 'light-state-low', 'light-state-high');
        headlight.classList.add(vehicleData.highbeam
            ? 'light-state-high'
            : (vehicleData.lowbeam ? 'light-state-low' : 'light-state-off'));
    }

    const indicators = {
        'ind-left': vehicleData.leftIndicator,
        'ind-right': vehicleData.rightIndicator,
        'ind-hazard': vehicleData.hazard,
        'ind-seatbelt': vehicleData.seatbelt,
        'ind-abs': vehicleData.abs,
        'ind-check': vehicleData.engineCheck,
        'ind-battery': vehicleData.battery,
        'ind-oil': vehicleData.oil,
        'ind-temp': vehicleData.temp > 100
    };

    for (let id in indicators) {
        const elem = document.getElementById(id);
        if (!elem) continue;
        if (indicators[id]) {
            elem.classList.add('active');
        } else {
            elem.classList.remove('active');
        }
    }
}

function updateDoorStatus() {
    const doorStatus = document.getElementById('doorStatus');
    doorStatus.innerHTML = '';

    const doorNames = {
        '0': 'FL',
        '1': 'FR',
        '2': 'RL',
        '3': 'RR',
        '4': 'Hood',
        '5': 'Trunk'
    };

    for (let idx in vehicleData.doorsOpen) {
        if (vehicleData.doorsOpen[idx]) {
            const div = document.createElement('div');
            div.className = 'door-item';
            div.textContent = doorNames[idx] + ' OPEN';
            doorStatus.appendChild(div);
        }
    }
}

// ================= NUI MESSAGE HANDLER =================

window.addEventListener('message', function(event) {
    if (event.data.action === 'layoutEdit') { setLayoutEditing(event.data.enabled); return; }
    if (event.data.action === 'layoutReset') {
        freeLayout = JSON.parse(JSON.stringify(defaultFreeLayout));
        saveFreeLayout();
        applyFreeLayout();
        return;
    }
    if (event.data.action === 'hudSettingsApply') {
        applyHudSettings(event.data.settings);
        return;
    }

    if (event.data.action === 'dashboardUpdate') {
        // Update vehicle data
        if (event.data.speed !== undefined) vehicleData.speed = event.data.speed;
        if (event.data.rpm !== undefined) vehicleData.rpm = event.data.rpm;
        if (event.data.fuel !== undefined) vehicleData.fuel = event.data.fuel;
        if (event.data.temp !== undefined) vehicleData.temp = event.data.temp;
        if (event.data.gear !== undefined) vehicleData.gear = event.data.gear;
        if (event.data.engineRunning !== undefined) vehicleData.engineRunning = event.data.engineRunning;
        if (event.data.engineHealth !== undefined) vehicleData.engineHealth = event.data.engineHealth;
        if (event.data.bodyHealth !== undefined) vehicleData.bodyHealth = event.data.bodyHealth;
        if (event.data.leftIndicator !== undefined) vehicleData.leftIndicator = event.data.leftIndicator;
        if (event.data.rightIndicator !== undefined) vehicleData.rightIndicator = event.data.rightIndicator;
        if (event.data.highbeam !== undefined) vehicleData.highbeam = event.data.highbeam;
        if (event.data.lowbeam !== undefined) vehicleData.lowbeam = event.data.lowbeam;
        if (event.data.hazard !== undefined) vehicleData.hazard = event.data.hazard;
        if (event.data.seatbelt !== undefined) vehicleData.seatbelt = event.data.seatbelt;
        if (event.data.abs !== undefined) vehicleData.abs = event.data.abs;
        if (event.data.engineCheck !== undefined) vehicleData.engineCheck = event.data.engineCheck;
        if (event.data.battery !== undefined) vehicleData.battery = event.data.battery;
        if (event.data.oil !== undefined) vehicleData.oil = event.data.oil;
        if (event.data.odometer !== undefined) vehicleData.odometer = event.data.odometer;
        if (event.data.doorsOpen !== undefined) vehicleData.doorsOpen = event.data.doorsOpen;
    }

    if (event.data.action === 'dashboardShow') {
        document.getElementById('dashboard').style.display = hudSettings.showDashboard ? 'block' : 'none';
    }

    if (event.data.action === 'dashboardHide') {
        document.getElementById('dashboard').style.display = 'none';
    }

    if (event.data.action === 'setNightMode') {
        const dashboard = document.getElementById('dashboard');
        if (event.data.enabled) {
            dashboard.classList.add('night-mode');
        } else {
            dashboard.classList.remove('night-mode');
        }
    }

    if (event.data.action === 'setRainMode') {
        const dashboard = document.getElementById('dashboard');
        if (event.data.enabled) {
            dashboard.classList.add('rain-mode');
        } else {
            dashboard.classList.remove('rain-mode');
        }
    }
});

// ================= ANIMATION LOOP =================

function animationLoop() {
    updateGauges();
    animationRequestId = requestAnimationFrame(animationLoop);
}

// Start dashboard
window.addEventListener('load', function() {
    animationLoop();
});

// Optional: Hide dashboard if needed
// document.getElementById('dashboard').style.display = 'none';
