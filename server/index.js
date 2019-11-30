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

async function poll_updates_from_prism() {
    await sql.connect('mssql://PortalLogReader:7BDq5O6mv2@10.0.0.129/PassFace_Repl');
    const result = await sql.query`
    select top (50) [Num],[LTime],U.DBName,U.Surname
    from [PassFace_Repl].[dbo].[UsesJournal] 
    inner join Keys K on K.ID = KID
    inner join Users U on U.ID = K.UserID
    where Num = 11 or Num = 30
    order by LTime desc`;
    console.log(result)

    for (let personLocation of result) {
        const person = personLocations.filter(p => p.last_name === personLocation.Surname && p.first_name === personLocation.DBName);

        if (person.length === 0 && result.Num === ENTER_REGULATOR) {
            const roomPerson = persons.filter(p => p.last_name === personLocation.Surname && p.first_name === personLocation.DBName)[0];
            if (roomPerson) {
                const locationRoom = roomNumber > 400 && roomNumber < 499 ? roomPerson.home : KITCHEN_NAME;

                personLocations.push({ room: locationRoom, first_name: personLocation.DBName, last_name: personLocation.Surname, date_time: new Date(personLocation.LTime) })

                updatePersonLocation(roomPerson.id, locationRoom);
                continue;
            }
        }

        if (person.length !== 0 && result.Num === EXIT_REGULATOR) {
            const index = personLocations.indexOf(person);

            if (index > -1) {
                personLocations.splice(index, 1);
                updatePersonLocation(person.id, EXIT_NAME);
                continue;
            }
        }

        if (person.length !== 0 && result.Num === ENTER_REGULATOR) {
            const index = personLocations.indexOf(person);

            personLocations[index].date_time = new Date(personLocation.LTime);
            updatePersonLocation(personLocations[index].id, personLocations[index].Dislocation);
            continue;
        }
    }
}

setInterval(() => {
    poll_updates_from_prism();
}, 60 * 1000)

const PRISM_URL = "http://prism/api/employees/all"
const PRISM_CURENT_LOCATION_URL = "http://prism/api/employees/currentlocation/?id="

const hakvelonRoomName = "407 - Hakvelon";

const PositionSchema = new mongoose.Schema({ x: Number, y: Number, z: Number });

const RoomSchema = new mongoose.Schema({
    id: Number,
    name: String,
    position_home: PositionSchema,
    position_door: PositionSchema,
});

const PersonSchema = new mongoose.Schema({
    prism_id: Number,
    passface_id: Number,
    login: String,
    name: String,
    surname: String,
    home: String,
    last_location: String,
    last_changed_location: Date,
})

const RoomModel = mongoose.model('Room', RoomSchema);

var persons = []
var room_names = new Set()

var personLocations = [];

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

            const locationResp = await fetch(PRISM_CURENT_LOCATION_URL);
            const employee_location = await locationResp.json();

            if (Id === 492 || Id === 530) {
                Dislocation = hakvelonRoomName;
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

    for (const person of persons) {
        ws.send({ event_type: 'load_person', person })
        await delay(500);
    }
})

app.get('/persons', async (req, res) => {
    res.json(persons)
})

app.get('/rooms', async (req, res) => {
    var rooms = await RoomModel.find({});
    res.json(rooms)
})

app.get('/room_names', async (req, res) => {
    res.json(Array.from(room_names))
})

app.post('/rooms', async (req, res) => {
    try {
        const { id, name, position } = req.body;
        console.log({ id, name, position });
        const new_room = RoomModel.create({ id, name, position });
        res.json({ ok: true, new_room });
    } catch (error) {
        res.status(400).json(error);
    }
})


app.post('/cam', function (req, res) {
    console.log(req.body.cam_id)
    console.log(req.body.room_id)
    res.json({ ok: true })
})

app.post('/person/:id/home', function (req, res) {
    console.log(req.params.id);
    print(req.body.position)
    res.json({ ok: true })
})

app.post('/person/:id/location', function (req, res) {
    try {
        console.log(req.params.id);
        print(req.body.position)
        updatePersonLocation()
        res.json({ ok: true })
    } catch (error) {
        console.log(error)
    }
})

app.listen(3000)

async function updatePersonLocation(personId, location) {
    const person = persons.find(p => p.id == personId);
    persons.last_location = location;
    wss.clients.forEach(ws => {
        let buffer = new gdCom.GdBuffer()
        buffer.putString(JSON.stringify({ event: 'change_loc', person_id: personId, location }))
        buffer.putVar(Math.random())
        ws.send(buffer.getBuffer())
        client.send()
    })
}




persist_rooms_users_list();

app.get('/ping', function (req, res) {
    res.json({ pong: 'pong' })
})