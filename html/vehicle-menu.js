// Update gauge needle rotation
function updateGaugeNeedle(selector, percentage) {
    percentage = Math.max(0, Math.min(Number(percentage) || 0, 100));
    const group = document.querySelector(selector);
    if (group) {
        const rotation = (percentage / 100) * 270 - 135; // 270 deg range
        group.style.transform = `rotate(${rotation}deg)`;
    }
}

// Update Speed
function updateSpeed(speed) {
    const speedPercent = Math.min(speed / 300 * 100, 100);
    updateGaugeNeedle('#speedNeedle', speedPercent);
    const el = document.getElementById('speedVal');
    if (el) el.textContent = Math.round(speed);
}

// Update RPM
function updateRPM(rpm) {
    const rpmPercent = Math.min(rpm / 10000 * 100, 100);
    updateGaugeNeedle('#rpmNeedle', rpmPercent);
    const el = document.getElementById('rpmVal');
    if (el) el.textContent = Math.round(rpm);
}

// Update Fuel
function updateFuel(fuel) {
    updateGaugeNeedle('#fuelNeedle', fuel);
    const el = document.getElementById('fuelVal');
    if (el) el.textContent = Math.round(fuel);
}

// Update Temperature
function updateTemperature(temp) {
    const tempPercent = Math.min(temp / 120 * 100, 100);
    updateGaugeNeedle('#tempNeedle', tempPercent);
    const el = document.getElementById('tempVal');
    if (el) el.textContent = Math.round(temp);
    document.getElementById('warn-temp').classList.toggle('active', temp > 100);
}

// Update Gear
function updateGear(gear) {
    document.getElementById('gearDisplay').textContent = gear || 'N';
}

// Update Health Bars
function updateHealthBars(engineHealth, bodyHealth) {
    document.getElementById('engHealth').style.height = Math.max(0, engineHealth) + '%';
    document.getElementById('bodHealth').style.height = Math.max(0, bodyHealth) + '%';
    document.getElementById('warn-engine').classList.toggle('active', engineHealth < 30);
}

// Update Indicators
function updateIndicators(left, right, high, hazard) {
    document.getElementById('ind-left').classList.toggle('active', left);
    document.getElementById('ind-right').classList.toggle('active', right);
    document.getElementById('ind-high').classList.toggle('active', high);
    document.getElementById('ind-hazard').classList.toggle('active', hazard);
}

// Update Warnings
function updateWarnings(oil, battery, abs, handbrake, seatbelt) {
    document.getElementById('warn-oil').classList.toggle('active', oil);
    document.getElementById('warn-battery').classList.toggle('active', battery);
    document.getElementById('warn-abs').classList.toggle('active', abs);
}

// Process NUI messages
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'updateVehicleDash') {
        updateSpeed(data.speed || 0);
        updateRPM(data.rpm || 0);
        updateFuel(data.fuel || 0);
        updateTemperature(data.temperature || 0);
        updateGear(data.gear || 'N');
        updateHealthBars(data.engineHealth || 100, data.bodyHealth || 100);
        updateIndicators(data.leftIndicator, data.rightIndicator, data.highBeam, data.hazard);
        updateWarnings(data.oilPressure, data.battery, data.abs, data.handbrake, data.seatbelt);
    }
    if (data.action === 'openVehicleMenu') $('#vehicleMenu').show();
    if (data.action === 'closeVehicleMenu') $('#vehicleMenu').hide();
    if (data.action === 'vehicleSeats') {
        const seats = $('#veh-seats').empty();
        (data.seats || []).forEach(function(index) {
            const label = index === -1 ? 'Driver' : `Seat ${index + 1}`;
            $('<button>', {
                class: 'veh-btn veh-btn-wide',
                html: `<img class="veh-icon-img" src="./icons/seat-front-left.svg" alt=""><span>${label}</span>`
            })
                .attr('data-action', 'seat').attr('data-index', index).appendTo(seats);
        });
        $('#veh-panel-doors').toggle(!data.isBoat && !data.isBike);
        $('.aircraft-only').toggle(!!data.isAircraft);
    }
});

// Button click handlers - already in vehicle_menu.lua
$(document).on("click", "#vehicleMenu .veh-btn", function() {
    let action = $(this).data("action");
    let index = $(this).data("index");

    if (action === 'window') {
        $(this).toggleClass('active');
    }

    if (action === "copyPlate") {
        let plateText = $("#veh-plate").text();
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(plateText).catch(function() {});
        }
        return;
    }

    fetch(`https://${GetParentResourceName()}/vehicleAction`, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify({ type: action, index: index })
    }).catch(function() {});
});

// Close button and Escape key
$(document).on("click", "#veh-close-btn", function() {
    $("#vehicleMenu").hide();
    fetch(`https://${GetParentResourceName()}/closeVehicleMenu`, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify({})
    });
});

document.addEventListener("keyup", function(event) {
    if (event.key === "Escape" && $("#vehicleMenu").is(":visible")) {
        $("#vehicleMenu").hide();
        fetch(`https://${GetParentResourceName()}/closeVehicleMenu`, {
            method: "POST",
            headers: { "Content-Type": "application/json; charset=UTF-8" },
            body: JSON.stringify({})
        });
    }
});
