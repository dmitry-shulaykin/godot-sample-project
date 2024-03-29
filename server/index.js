var express = require('express')
const WebSocket = require('ws');
const gdCom = require('@gd-com/utils')
const fetch = require('node-fetch');
var mongoose = require('mongoose');
const sql = require('mssql')

mongoose.connect('mongodb://root:example@10.0.9.34/admin');

const ENTER_REGULATOR = 30;
const EXIT_REGULATOR = 11;

const KITCHEN_NAME = 'Kitchen';
const EXIT_NAME = 'Exit';

var db = mongoose.connection;
db.on('error', console.error.bind(console, 'connection error:'));
db.once('open', function () {
    console.log('connected mongoose')
});

async function poll_updates_from_prism(cam) {
    await sql.connect('mssql://PortalLogReader:7BDq5O6mv2@10.0.0.129/PassFace_Repl');
    const result = (await sql.query`
    select top (50) [Num],[LTime],U.DBName,U.Surname
    from [PassFace_Repl].[dbo].[UsesJournal] 
    inner join Keys K on K.ID = KID
    inner join Users U on U.ID = K.UserID
    where Num = 11 or Num = 30
    order by LTime desc`).recordset;
    console.log(result)

    for (let personLocation of result) {
        const person = personLocations.find(p => p.last_name === personLocation.Surname && p.first_name === personLocation.DBName);

        if (!person && result.Num === ENTER_REGULATOR) {
            const roomPerson = persons.find(p => p.last_name === personLocation.Surname && p.first_name === personLocation.DBName);
            if (roomPerson) {
                const locationRoom = roomNumber > 400 && roomNumber < 499 ? roomPerson.home : KITCHEN_NAME;

                personLocations.push({ room: locationRoom, first_name: personLocation.DBName, last_name: personLocation.Surname, date_time: new Date(personLocation.LTime) })

                updatePersonLocation(roomPerson.id, locationRoom);
            }

            if (cam) {
                cam.personId = person ? person.id : roomPerson.id;
            }

            continue;
        }

        if (person && result.Num === EXIT_REGULATOR) {
            const index = personLocations.indexOf(person);

            if (index > -1) {
                personLocations.splice(index, 1);
                updatePersonLocation(person.id, EXIT_NAME);
                continue;
            }
        }

        if (person && result.Num === ENTER_REGULATOR) {
            const index = personLocations.indexOf(person);

            personLocations[index].date_time = new Date(personLocation.LTime);
            updatePersonLocation(personLocations[index].id, personLocations[index].Dislocation);

            if (cam) {
                cam.personId = personLocations[index].id;
            }

            continue;
        }
    }

    for (const cam of cams) {
        const datetime = Date.now();
        if (datetime - cam > 5000) {
            const indexCam = cams.indexOf(cam);

            if (indexCam > -1) {
                cams.splice(indexCam, 1);
                continue;
            }
        }
    }
}

setInterval(() => {
    poll_updates_from_prism();
}, 60 * 1000)

const PRISM_URL = "http://prism/api/employees/all"
const PRISM_CURENT_LOCATION_URL = "http://prism/api/employees/currentlocation/?id="

const hakvelonRoomName = "407 - Hakvelon";

var persons = []
var room_names = new Set()

var personLocations = [];
var cams = [];

// Фичи сервера:
// 1. При старте сервера мы должны найти всех кто на этаже и посадить их по своим комнатам
// 2. Когда нам приходит инфа с камеры, мы должны найти наиболее подходящего чувака и послать его куда направляет камера
// 3. Когда человек уходит с этажа мы отправляем его на выход

async function persist_rooms_users_list() {
    try {
        console.log('persisting rooms state');
        const resp = await fetch(PRISM_URL);
        const employee_list = await resp.json();
        // console.log(json)
        for (const employee of employee_list) {
            let { Id, Dislocation, InBuilding, Login, FirstName, LastName } = employee;

            const locationResp = await fetch(PRISM_CURENT_LOCATION_URL + Id);
            const employee_location = await locationResp.json();

            if (Id === 492 || Id === 530) {
                Dislocation = hakvelonRoomName;
            }

            if (employee_location == null) {
                continue;
            }

            const locationMatch = employee_location['Info'].match(/On.*(2|3|4|5).*/);

            if (locationMatch && locationMatch[1] === '4') {
                const roomNumber = parseInt(Dislocation);
                const locationRoom = roomNumber > 400 && roomNumber < 499 ? Dislocation : KITCHEN_NAME;

                updatePersonLocation(Id, locationRoom);

                personLocations.push({ id: Id, room: locationRoom, first_name: FirstName, last_name: LastName, date_time: new Date(), home: Dislocation });
            }

            persons.push({ id: Id, home: Dislocation, inBuilding: InBuilding, login: Login, last_location: Dislocation, first_name: FirstName, last_name: LastName })


            room_names.add(Dislocation);
        }

        room_names.add(KITCHEN_NAME);
        room_names.add(EXIT_NAME);
    } catch (error) {
        console.error(error);
    }
}

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));
var app = express()
app.use(express.json())

const wss = new WebSocket.Server({ port: 8081 });

wss.on('connection', async ws => {
    console.log('connected')
    ws.on('message', (message) => {
        let recieve = new gdCom.GdBuffer(Buffer.from(message))
        console.log(recieve.getVar())
    })
    console.log('$$', personLocations.length)
    for (const person of personLocations) {
        console.log('sending ', person)
        // ws.send(JSON.stringify({event_type: 'load_person', person}))
        let buffer = new gdCom.GdBuffer()
        buffer.putString(JSON.stringify({ event_type: 'load_person', person }))
        ws.send(buffer.getBuffer())
        await delay(100);
    }
})

app.get('/persons', async (req, res) => {
    res.json(persons)
})

app.get('/names', async (req, res) => {
    res.json(persons.map(p => ({id: p.id, name: p.first_name + " " + p.last_name})))
})

app.get('/personLocations', async (req, res) => {
    res.json(personLocations)
})

app.get('/room_names', async (req, res) => {
    res.json(['kitchen', 'exit', ...Array.from(room_names)])
})

app.post('/cam', function (req, res) {
    const camId = req.body.camId;
    const roomId = req.body.roomId;
    console.log(camId);
    console.log(roomId);

    const datetime = Date.now();

    switch (roomId) {
        case 400:
            cams.push({ id: camId, room: roomId, date_time: datetime, personId: -1 });
            poll_updates_from_prism(cams[cams.length - 1]);
            break;
        case 401:
            var cam = cams.pop();
            if (cam.personId !== -1) {
                setTimeout(function changePosition(count, id) {
                    if (cams.length === count) {
                        updatePersonLocation(id, "401 - Admins");
                    }
                }, 5000, cams.length, cam.personId);
                if (datetime - cam.datetime < 5000) {
                    cams.push(cam);
                    cams.push({ id: camId, room: roomId, date_time: datetime, personId: cam.personId });
                    break;
                }
            }

            break;
        case 402:
            var cam = cams.pop();
            if (cam.personId !== -1) {
                setTimeout(function changePosition(count, id) {
                    if (cams.length === count) {
                        updatePersonLocation(id, "402 - CD2");
                    }
                }, 5000, cams.length, cam.personId);
                if (datetime - cam.datetime < 5000) {
                    cams.push(cam);
                    cams.push({ id: camId, room: roomId, date_time: datetime, personId: cam.personId });
                    break;
                }
            }
            break;
        case 499:
            var cam = cams.pop();
            if (cam.personId !== -1) {
                setTimeout(function changePosition(count, id) {
                    if (cams.length === count) {
                        updatePersonLocation(id, KITCHEN_NAME);
                    }
                }, 5000, cams.length, cam.personId);
                if (datetime - cam.datetime < 5000) {
                    cams.push(cam);
                    cams.push({ id: camId, room: roomId, date_time: datetime, personId: cam.personId });
                    break;
                }
            }
            break;
    }

    res.json({ ok: true });
})

app.post('/person/:id/home', function (req, res) {
    console.log(req.params.id);
    print(req.body.position)
    res.json({ ok: true })
})

app.post('/person/:id/location', function (req, res) {
    try {
        console.log(req.params.id);
        console.log(req.body.position)
        updatePersonLocation(req.params.id, req.body.position)
        res.json({ ok: true })
    } catch (error) {
        console.log(error)
    }
})

app.listen(3000)

async function updatePersonLocation(personId, location) {
    
    wss.clients.forEach(ws => {
        let buffer = new gdCom.GdBuffer()
        const person = persons.find(p => p.id == personId);
        if (person) {
        // person.last_location = location;
            console.log('change_location', person, location, personId)
            buffer.putString(JSON.stringify({ event_type: 'change_location', person_id: personId, location, person }))
            buffer.putVar(Math.random())
            ws.send(buffer.getBuffer())
        }
    })
}

persist_rooms_users_list();

app.get('/ping', function (req, res) {
    res.json({ pong: 'pong' })
})