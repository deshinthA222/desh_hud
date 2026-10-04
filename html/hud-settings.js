(() => {
    const storageKey = 'fighterjet_hud_settings_v1';
    const statusLayoutStorageKey = 'fighterjet_status_free_layout_v1';
    const defaultStatusLayout = {
        health: { x: 2.3, y: 96.5, scale: .85 },
        food: { x: 5.7, y: 96.5, scale: .85 },
        drink: { x: 9.1, y: 96.5, scale: .85 },
        armor: { x: 12.5, y: 96.5, scale: .85 },
        stamina: { x: 15.9, y: 96.5, scale: .85 }
    };
    const defaults = {
        showDashboard: true, showSpeed: true, showRpm: true, showCenter: true,
        showOdometer: true, showTurn: true, showHighbeam: true, showLowbeam: true,
        showHazard: true, showSeatbelt: true, showBrake: true, showEngine: true,
        showBattery: true, showOil: true, showTemperature: true, iconSize: 'large', hudColor: '#29e5cf',
        dashboardX: 83, dashboardY: 90, dashboardScale: 100
    };
    let settings = loadSettings();
    let statusLayout = loadStatusLayout();
    let layoutEditing = false;

    function loadStatusLayout() {
        try {
            return Object.assign({}, defaultStatusLayout, JSON.parse(localStorage.getItem(statusLayoutStorageKey) || '{}'));
        } catch (_) {
            return JSON.parse(JSON.stringify(defaultStatusLayout));
        }
    }

    function saveStatusLayout() {
        localStorage.setItem(statusLayoutStorageKey, JSON.stringify(statusLayout));
    }

    function applyStatusLayout() {
        document.querySelectorAll('.status-movable[data-status-layout-id]').forEach((element) => {
            const id = element.dataset.statusLayoutId;
            const item = Object.assign({}, defaultStatusLayout[id], statusLayout[id] || {});
            element.style.left = `${item.x}%`;
            element.style.top = `${item.y}%`;
            element.style.right = 'auto';
            element.style.bottom = 'auto';
            element.style.transform = `translate(-50%, -50%) scale(${item.scale})`;
        });
    }

    function loadSettings() {
        try {
            return Object.assign({}, defaults, JSON.parse(localStorage.getItem(storageKey) || '{}'));
        } catch (_) {
            return Object.assign({}, defaults);
        }
    }

    function applySettings() {
        settings.iconSize = 'large';
        document.documentElement.style.setProperty('--hud-user-color', settings.hudColor || '#29e5cf');
        const statusHud = document.getElementById('statusHud');
        if (statusHud) {
            statusHud.classList.remove('hud-user-hidden');
            statusHud.style.display = 'flex';
        }
        applyStatusLayout();
        const frame = document.getElementById('dashboardFrame');
        if (frame && frame.contentWindow) {
            frame.contentWindow.postMessage({ action: 'hudSettingsApply', settings }, '*');
        }
    }

    function syncControls() {
        document.querySelectorAll('[data-hud-setting]').forEach((control) => {
            const key = control.dataset.hudSetting;
            if (control.type === 'checkbox') control.checked = settings[key] !== false;
            else control.value = settings[key];
        });
    }

    function saveFromControls() {
        document.querySelectorAll('[data-hud-setting]').forEach((control) => {
            const key = control.dataset.hudSetting;
            settings[key] = control.type === 'checkbox' ? control.checked : control.value;
        });
        localStorage.setItem(storageKey, JSON.stringify(settings));
        applySettings();
    }

    function closeSettings() {
        setLayoutEditing(false);
        document.getElementById('hudSettings').style.display = 'none';
        fetch(`https://${GetParentResourceName()}/closeHudSettings`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: '{}'
        }).catch(() => {});
    }

    function openSettings() {
        syncControls();
        document.getElementById('hudSettings').style.display = 'block';
        setLayoutEditing(true);
    }

    function setLayoutEditing(enabled) {
        layoutEditing = !!enabled;
        document.body.classList.toggle('status-layout-editing', layoutEditing);
        const frame = document.getElementById('dashboardFrame');
        if (!frame) return;
        frame.style.pointerEvents = enabled ? 'auto' : 'none';
        if (frame.contentWindow) frame.contentWindow.postMessage({ action: 'layoutEdit', enabled }, '*');
    }

    document.addEventListener('pointerdown', (event) => {
        if (!layoutEditing) return;
        const element = event.target.closest('.status-movable[data-status-layout-id]');
        if (!element) return;
        event.preventDefault();
        element.setPointerCapture(event.pointerId);
        const id = element.dataset.statusLayoutId;
        const move = (moveEvent) => {
            statusLayout[id] = statusLayout[id] || Object.assign({}, defaultStatusLayout[id]);
            statusLayout[id].x = Math.max(2, Math.min(98, moveEvent.clientX / window.innerWidth * 100));
            statusLayout[id].y = Math.max(2, Math.min(98, moveEvent.clientY / window.innerHeight * 100));
            applyStatusLayout();
        };
        const stop = () => {
            element.removeEventListener('pointermove', move);
            element.removeEventListener('pointerup', stop);
            element.removeEventListener('pointercancel', stop);
            saveStatusLayout();
        };
        element.addEventListener('pointermove', move);
        element.addEventListener('pointerup', stop);
        element.addEventListener('pointercancel', stop);
    });

    document.addEventListener('wheel', (event) => {
        if (!layoutEditing) return;
        const element = event.target.closest('.status-movable[data-status-layout-id]');
        if (!element) return;
        event.preventDefault();
        const id = element.dataset.statusLayoutId;
        statusLayout[id] = statusLayout[id] || Object.assign({}, defaultStatusLayout[id]);
        statusLayout[id].scale = Math.max(.5, Math.min(1.8, (statusLayout[id].scale || 1) + (event.deltaY < 0 ? .05 : -.05)));
        applyStatusLayout();
        saveStatusLayout();
    }, { passive: false });

    window.addEventListener('message', (event) => {
        if (event.data.action === 'openHudSettings') openSettings();
        if (event.data.action === 'closeHudSettings') {
            document.getElementById('hudSettings').style.display = 'none';
            setLayoutEditing(false);
        }
    });
    document.addEventListener('change', (event) => {
        if (event.target.matches('[data-hud-setting]')) saveFromControls();
    });
    document.addEventListener('input', (event) => {
        if (event.target.matches('input[type="range"][data-hud-setting]')) saveFromControls();
    });
    document.getElementById('hud-settings-save').addEventListener('click', () => {
        saveFromControls();
        closeSettings();
    });
    document.getElementById('hud-settings-close').addEventListener('click', closeSettings);
    document.getElementById('hud-settings-reset').addEventListener('click', () => {
        settings = Object.assign({}, defaults);
        localStorage.setItem(storageKey, JSON.stringify(settings));
        syncControls();
        applySettings();
    });
    document.getElementById('hud-layout-reset').addEventListener('click', () => {
        statusLayout = JSON.parse(JSON.stringify(defaultStatusLayout));
        saveStatusLayout();
        applyStatusLayout();
        const frame = document.getElementById('dashboardFrame');
        if (frame && frame.contentWindow) frame.contentWindow.postMessage({ action: 'layoutReset' }, '*');
    });
    document.addEventListener('keyup', (event) => {
        if (event.key === 'Escape' && document.getElementById('hudSettings').style.display !== 'none') closeSettings();
    });
    document.getElementById('dashboardFrame').addEventListener('load', applySettings);
    window.addEventListener('resize', applyStatusLayout);
    applySettings();
})();
