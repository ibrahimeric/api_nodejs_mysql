const express = require('express');
const jwt = require('jsonwebtoken');
require('dotenv').config();
const cors = require('cors');
const mysql = require('mysql');
const bodyParser = require('body-parser');
const app = express()
app.use(cors())
app.use(bodyParser.json({limit: '10mb'}))

const secret = process.env.SECRET

app.get('/', function(req, res){
    res.send('Primera ruta de la Api')
})

const credentials = {
    host: 'localhost',
    user: 'root',
    password: 'admin',
    database: 'proyectolab3'
}

app.post('/register', (req, res) => {
    const { nombre, apellido, fechaNac, username, password } = req.body;
    const values = [nombre, apellido, fechaNac, username, password];
    var connection = mysql.createConnection(credentials);

    connection.query('call new_client(?,?,?,?,?);', values, (err, result) => {
        connection.end(); // Cerrar la conexión
        if (err)
            res.send('error');
        if (result[0][0].mensaje === 'existe')
            res.send('el usuario ya existe');
        else{
            const token = jwt.sign({
                username,
                exp: Date.now() + 600 * 1000
            }, secret);
            res.send({ token });
        }
    });
});

app.post('/login', (req, res) => {
    const {username, password} = req.body
    const values = [username, password]
    var connection = mysql.createConnection(credentials)
    connection.query("select * from credenciales where usuario = ? and contraseña = ?", values, (err, result) => {
        if(err){
            res.status(500).send(err)
        }else{
            if(result.length > 0){
                const token = jwt.sign({
                    username,
                    exp: Date.now() + 600 * 1000
                }, secret)

                res.status(200).send({token})
            }else{
                res.send('false')
            }
        }
    })
    connection.end()
})


app.post('/updateUser', (req, res) => {
    try{
        const token = req.headers.authorization.split(' ')[1]
        const payload = jwt.verify(token, secret)

        if(Date.now() > payload.exp){
            return res.send({ error: 'token expired'});
        }
        const { newPassword, passwordActual } = req.body;
        const values = [newPassword, payload.username, passwordActual];
        var connection = mysql.createConnection(credentials);
        // Codigo a ejecutar despues de verificar
        try{
            connection.query('UPDATE credenciales SET contraseña = ? WHERE usuario = ? and contraseña = ?;', values, (err, result) => {
                connection.end(); // Cerrar la conexión después de completar todas las consultas
    
                if (err)
                    res.send('error2');
                else{
                    if(result.affectedRows > 0)
                        res.status(200).send('exito');
                    else
                        res.send('error2');
                }
            })
        }
        catch{
            res.send('error2');
        }
    } catch (error) {
        res.send(error);
    }
});


app.post('/deleteUser', (req, res) => {
    try{
        const token = req.headers.authorization.split(' ')[1]
        const payload = jwt.verify(token, secret)

        if(Date.now() > payload.exp){
            return res.send('error1');
        }
        const body = req.body;
        const values = [payload.username, body.password];
        var connection = mysql.createConnection(credentials);
        // Codigo a ejecutar despues de verificar
        try{
            connection.query('call delete_client(?,?);', values, (err, result) => {
                connection.end(); // Cerrar la conexión
                if (err)
                    res.send('error2');
                else if (result[0][0].mensaje === 'inexistente')
                    res.status(500).send('inexistente');
                else if (result[0][0].mensaje === 'correcto')
                    res.status(500).send('correcto');
            })
        }
        catch{
            res.send('error2');
        }

    } catch (error) {
        res.send(error);
    }
});


app.post('/comentario', (req, res) => {
    try{
        const { comentario } = req.body;
        var connection = mysql.createConnection(credentials);

        const token = req.headers.authorization.split(' ')[1]
        const payload = jwt.verify(token, secret)

        if(Date.now() > payload.exp){
            return res.send('token expirado');
        }
        const values = [payload.username, comentario];


        connection.query('call comentario(?,?);', values, (err, result) => {
            connection.end(); // Cerrar la conexión
            if (err)
                res.send('error');
            else if (result[0][0].mensaje === 'inexistente')
                res.status(500).send('cliente inexistente');
            else if (result[0][0].mensaje === 'correcto')
                res.status(500).send('correcto');
        });
    }catch (error) {
        res.send({ error: error.message});
    }
});


app.post('/notification', (req, res) => {
    const { usuario, notificacion } = req.body;
    var connection = mysql.createConnection(credentials);

    const values = [usuario, notificacion];


    connection.query('call notificacion(?,?);', values, (err, result) => {
        connection.end(); // Cerrar la conexión
        if (err)
            res.send('error');
        else if (result[0][0].mensaje === 'inexistente')
            res.status(500).send('cliente inexistente');
        else if (result[0][0].mensaje === 'correcto')
            res.status(500).send('correcto');
    });
});


app.get('/token', (req, res) => {
    try{
        const token = req.headers.authorization.split(' ')[1]
        const payload = jwt.verify(token, secret)
        if(Date.now() > payload.exp){
            return res.send({ error: 'token expired'})
        }
        res.send('existe')
    } catch (error) {
        res.send({ error: error.message})
    }
})

app.get('/usuarios', (req, res) => {
    var connection = mysql.createConnection(credentials)
    connection.query('SELECT * FROM credenciales', (error, result) => {
        if (error)
            res.status(500).send(error)
        else
            res.status(200).send(result)
    })
    connection.end()
})

app.get('/nueva_ruta', (req, res) => {
    var connection = mysql.createConnection(credentials)
    connection.query('SELECT * FROM comentarios', (error, result) => {
        if (error)
            res.status(500).send(error)
        else
            res.status(200).send(result)
    })
    connection.end()
})



app.listen('5000', () =>{
    console.log('Aplicación iniciada en el puerto 5000')
})

