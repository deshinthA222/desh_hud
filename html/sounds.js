(function () {
    'use strict';

    const sounds = {
        button: new Audio('./sounds/button_click.ogg'),
        indicator: new Audio('./sounds/indicator_click.ogg'),
        door: new Audio('./sounds/door_open.ogg'),
        engineStart: new Audio('./sounds/engine_start.ogg'),
        engineStop: new Audio('./sounds/engine_stop.ogg'),
        window: new Audio('./sounds/window_open.ogg'),
        warning: new Audio('./sounds/warning_beep.ogg')
    };

    function play(name, volume) {
        const audio = sounds[name];
        if (!audio) return;
        audio.pause();
        audio.currentTime = 0;
        audio.volume = volume || 0.4;
        audio.play().catch(function () {});
    }

    $(document).on('click', '#vehicleMenu .veh-btn', function () {
        const action = $(this).data('action');
        if (action === 'door' || action === 'hood' || action === 'trunk') {
            play('door', 0.45);
        } else if (action === 'window') {
            play('window', 0.35);
        } else if (action === 'leftIndicator' || action === 'rightIndicator') {
            play('indicator', 0.3);
        } else if (action === 'hazard') {
            play('warning', 0.45);
        } else if (action === 'engine') {
            play('engineStart', 0.55);
        } else {
            play('button', 0.3);
        }
    });
}());
