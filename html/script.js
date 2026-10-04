$(document).ready(function() {
    // Preparing sounds
    var stallAlert = new Audio("./sounds/stall.mp3");
    var altitudeAlert = new Audio("./sounds/altitude.mp3");
    var missileAlert = new Audio("./sounds/missile.mp3");

    function playAlert(audio) {
        audio.play().catch(function() {});
    }

    // Appending steps in degrees and current direction
    for (let i = 0; i < 3; i ++) {
        $(".direction").append(`<div class="single-direction bold">N</div>`);
        separateDirections();
        $(".direction").append(`<div class="single-direction bold">NE</div>`);
        separateDirections();
        $(".direction").append(`<div class="single-direction bold">E</div>`);
        separateDirections();
        $(".direction").append(`<div class="single-direction bold">SE</div>`);
        separateDirections();
        $(".direction").append(`<div class="single-direction bold">S</div>`);
        separateDirections();
        $(".direction").append(`<div class="single-direction bold">SW</div>`);
        separateDirections();
        $(".direction").append(`<div class="single-direction bold">W</div>`);
        separateDirections();
        $(".direction").append(`<div class="single-direction bold">NW</div>`);
        separateDirections();
    }

    // Separate letters
    function separateDirections() {
        for (let i = 0; i < 3; i++) {
            $(".direction").append(`<div class="single-direction">&nbsp;</div>`);
        }
    }

    // Append horizontal Pitch lines
    for (let i = 18; i > 0; i--) {
        $("#main > .hud > .pitchroll > .pitch").append(`
        <div class="pitchline">
            <div class="leftline">
                <div class="pitch-number">
                    ${i * 5}
                </div>
                <div class="line"></div>
            </div>
            <div class="rightline">
                <div class="line"></div>
                <div class="pitch-number">
                    ${i * 5}
                </div>
            </div>
        </div>
        `)
    }
    $("#main > .hud > .pitchroll > .pitch").append(`
        <div class="pitchline">
            <div class="leftline">
                <div class="pitch-number">
                    ${0}
                </div>
                <div class="line full"></div>
            </div>
            <div class="rightline">
                <div class="line full"></div>
                <div class="pitch-number">
                    ${0}
                </div>
            </div>
        </div>
    `)
    for (let i = 1; i <= 18; i++) {
        $("#main > .hud > .pitchroll > .pitch").append(`
        <div class="pitchline">
            <div class="leftline">
                <div class="pitch-number">
                    ${i * -5}
                </div>
                <div class="linedown"></div>
            </div>
            <div class="rightline">
                <div class="linedown"></div>
                <div class="pitch-number">
                    ${i * -5}
                </div>
            </div>
        </div>
        `)
    }

    // Handle HUD movement
    function ChangeYaw(value) {
        let deg = value;
        let px = (deg * 2.22) - 273;
        $(".direction").css("left", `${px}px`);
        $("#heading-text").text(deg);
    }
    ChangeYaw(0);

    function ChangeRoll(value) {
        let deg = value * -1;
        let contr = value;
        $("#main > .hud > .pitchroll").css("transform", `translate(-50%, -50%) rotate(${deg}deg)`);
        $("#main > .hud > .pitchroll .pitch-number").css("transform", `rotate(${contr}deg)`);
    }
    ChangeRoll(0);

    function ChangePitch(value) {
        let deg = value;
        let px = (deg * 13.65) - 1115;
        $("#main > .hud > .pitchroll > .pitch").css("margin-top", `${px}px`);
    }
    ChangePitch(0);

    function setAircraftHudMode(data) {
        if (data && (data.aircraftType !== undefined || data.isHelicopter !== undefined)) {
            const isHelicopter = data.aircraftType === "helicopter"
                || data.isHelicopter === true
                || data.isHelicopter === 1
                || data.isHelicopter === "true";
            $("#main").toggleClass("helicopter-mode", isHelicopter);
            $("#main > .speed, #main > .heading, #main > .compass, #main > .hud, #main > .altitude, #main > .altitude-meter")
                .css("display", isHelicopter ? "none" : "");
        }
    }

    window.addEventListener('message', function (event) {
        if (event.data.action === "statusUpdate") {
            const clamp = value => Math.max(0, Math.min(100, Number(value) || 0));
            $("#health-value").text(Math.round(clamp(event.data.health)) + "%");
            $("#food-value").text(Math.round(clamp(event.data.food)) + "%");
            $("#drink-value").text(Math.round(clamp(event.data.drink)) + "%");
            $("#armor-value").text(Math.round(clamp(event.data.armor)) + "%");
            $("#stamina-value").text(Math.round(clamp(event.data.stamina)) + "%");
        }
        if (event.data.action === "weaponUpdate") {
            if (event.data.visible) {
                $("#weapon-name").text(event.data.name || "WEAPON");
                $("#weapon-clip").text(event.data.clip !== undefined ? event.data.clip : "--");
                $("#weapon-reserve").text(event.data.reserve !== undefined ? event.data.reserve : "--");
                $("#weaponHud").show();
            } else {
                $("#weaponHud").hide();
            }
        }
        if (event.data.action === "fireModeUpdate") {
            const mode = String(event.data.mode || "SAFE").toUpperCase();
            const icons = { SAFE: "#fm-safe", SEMI: "#fm-semi", BURST: "#fm-burst", AUTO: "#fm-auto" };
            $("#weapon-fire-mode").attr("title", mode).attr("aria-label", mode);
            $("#weapon-fire-mode-use").attr("href", icons[mode] || icons.SAFE);
        }
        if (event.data.action == "show") {
            setAircraftHudMode(event.data);
            $("#main").fadeIn();
            $("#main").removeClass("red");
            $("#main").removeClass("orange");
            $("#main").removeClass("green");
            $("#main").removeClass("blue");
            $("#main").addClass(event.data.color);
        }
        if (event.data.action == "hide") {
            $("#main").fadeOut();
        }
        if (event.data.action == "update") {
            setAircraftHudMode(event.data);
            $("#speed").text(event.data.speed);
            $("#alt").text(event.data.altitude);
            let alt = event.data.rawAlt;
            alt = (285 - ((alt / 2400) * 285));
            $(".altitude-pointer").css("margin-top", `${alt}px`);
            if (event.data.gear == "STATIC") {
                $(".gear-info").hide();
            } else {
                $(".gear-info").show();
                $("#gear-state").text(event.data.gear);
            }
            if (event.data.hasWeapon == true) {
                if (event.data.weaponType == "missiles") {
                    $(".gun-crosshair").hide();
                    $(".missile-crosshair, .missile-target").hide();
                    if (event.data.hasLock == false) {
                        $(".missile-info").hide();
                        $(".missile-dist").hide();
                    } else {
                        $(".missile-info").show();
                        $(".missile-dist").show();
                        $(".missile-dist").text(event.data.targetDist);
                    }
                    $(".missile-info").css("left", `${event.data.x_target * 100}%`);
                    $(".missile-info").css("top", `${event.data.y_target * 100}%`);
                } else if (event.data.weaponType == "machinegun") {
                    $(".missile-info").hide();
                    $(".gun-crosshair").hide();
                }
            } else {
                $(".missile-info").hide();
                $(".gun-crosshair").hide();
            }
            if (event.data.hasVtol == false) {
                $(".vtol-info").hide();
            } else {
                $(".vtol-info").show();
                $("#vtol-state").text(event.data.vtol);
            }
            ChangeYaw(event.data.yaw);
            ChangeRoll(event.data.roll);
            ChangePitch(event.data.pitch);
        }
        if (event.data.action == "stall") {
            if (event.data.mode == "start") {
                playAlert(stallAlert);
                stallAlert.loop = true;
                $(".stall-warn").show();
            } else if (event.data.mode == "end") {
                stallAlert.pause();
                stallAlert.currentTime = 0;
                $(".stall-warn").hide();
            }
        }
        if (event.data.action == "altitude") {
            if (event.data.mode == "start") {
                playAlert(altitudeAlert);
                altitudeAlert.loop = true;
                $(".alt-warn").show();
            } else if (event.data.mode == "end") {
                altitudeAlert.pause();
                altitudeAlert.currentTime = 0;
                $(".alt-warn").hide();
            }
        }
        if (event.data.action == "missile") {
            if (event.data.mode == "start") {
                playAlert(missileAlert);
                missileAlert.loop = true;
                $(".missile-warn").show();
            } else if (event.data.mode == "end") {
                missileAlert.pause();
                missileAlert.currentTime = 0;
                $(".missile-warn").hide();
            }
        }
    });
});
