const DAYS   = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
const MONTHS = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

function updateClock() {
    const now  = new Date();
    const h    = String(now.getHours()).padStart(2, '0');
    const m    = String(now.getMinutes()).padStart(2, '0');
    const day  = DAYS[now.getDay()];
    const mon  = MONTHS[now.getMonth()];
    const date = String(now.getDate()).padStart(2, '0');

    document.getElementById('clock').textContent = `${h}:${m}`;
    document.getElementById('date').textContent  = `${day}, ${mon} ${date}`;
}

updateClock();
setInterval(updateClock, 10000);

window.addEventListener('message', ({ data }) => {
    if (data.type === 'toggleMenu') {
        document.getElementById('app').style.display = data.state ? 'flex' : 'none';
        if (data.state) updateStates(data.data);
    }
    if (data.type === 'updateTemp')      setEngineTemp(data.temp);
    if (data.type === 'signal')          setSignal(data.left, data.right);
    if (data.type === 'updateSeatbelt')  toggleItemActive('seatbelt', data.status);
});

document.addEventListener('keyup', e => {
    if (e.key === 'Escape' || e.key === 'g' || e.key === 'G') {
        post('closeMenu');
        document.getElementById('app').style.display = 'none';
    }
});

function post(endpoint, body = {}) {
    return fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        body: JSON.stringify(body)
    }).then(r => r.json());
}

function updateStates(data) {
    const f = data.features || {};

    setVisible('engine',        f.Engine);
    setVisible('seatbelt',      f.Seatbelt);
    setVisible('cruise',        f.Cruise);
    setVisible('hazard',        f.Hazard);
    setVisible('doors-group',   f.Doors);
    setVisible('windows-group', f.Windows);
    setVisible('neons-group',   f.Neons);

    if (f.Engine)   toggleItemActive('engine',   data.engine);
    if (f.Seatbelt) toggleItemActive('seatbelt', data.seatbelt);
    if (f.Cruise)   toggleItemActive('cruise',   data.cruise);
    if (f.Hazard)   toggleItemActive('hazard',   data.hazard);

    if (f.Doors)   for (let i = 0; i <= 5; i++) toggleItemActive(`door-${i}`,   data.doors[i]);
    if (f.Windows) for (let i = 0; i <= 3; i++) toggleItemActive(`window-${i}`, data.windows[i]);
    if (f.Neons)   for (let i = 0; i <= 3; i++) toggleItemActive(`neon-${i}`,   data.neons[i]);

    document.getElementById('veh-model').textContent = data.model || '—';
    document.getElementById('veh-plate').textContent = data.plate || '——';

    setEngineTemp(data.engineTemp ?? null);
}

function setEngineTemp(temp) {
    const el = document.getElementById('engine-temp');
    if (!el) return;
    el.textContent = temp !== null ? `${Math.round(temp)}°C` : '--°C';
    el.className   = temp >= 110 ? 'temp-hot' : temp >= 95 ? 'temp-warm' : '';
}

function setVisible(id, visible) {
    const el = document.getElementById(id);
    if (el) el.style.display = visible ? '' : 'none';
}

function toggleItemActive(id, active) {
    document.getElementById(id)?.classList.toggle('active', !!active);
}

function setSignal(left, right) {
    document.getElementById('signal-left')?.classList.toggle('active',  !!left);
    document.getElementById('signal-right')?.classList.toggle('active', !!right);
}

function action(name) {
    const idMap = { toggleEngine: 'engine', toggleSeatbelt: 'seatbelt', toggleCruise: 'cruise', toggleHazard: 'hazard' };
    post(name).then(resp => {
        if (resp.status !== undefined) toggleItemActive(idMap[name], resp.status);
        if (resp.hazard !== undefined) toggleItemActive('hazard', resp.hazard);
    });
}

function doorAction(index) {
    post('toggleDoor', { doorIndex: index }).then(resp => toggleItemActive(`door-${index}`, resp.open));
}

function windowAction(index) {
    post('toggleWindow', { windowIndex: index }).then(resp => toggleItemActive(`window-${index}`, resp.open));
}

function neonAction(index) {
    post('toggleNeon', { neonIndex: index }).then(resp => toggleItemActive(`neon-${index}`, resp.status));
}