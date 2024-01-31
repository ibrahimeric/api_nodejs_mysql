/* 
   ************
   *   CREACION DE BASE DE DATOS    *
   ************
*/ 
create database if not exists proyectoLab3;

use proyectoLab3;

/* 
   ************
   *    ELIMINACION DE LAS TABLAS   *
   ************
*/ 

drop table if exists comentarios;
drop table if exists credenciales;
drop table if exists notificaciones;
drop table if exists clientes;

/* 
   ************
   *   	 CREACION DE LAS TABLAS     *
   ************
*/ 

create table clientes(
	`id` int NOT NULL AUTO_INCREMENT PRIMARY KEY unique,
    `nombre` varchar(45) NOT NULL,
    `apellido` varchar(45) NOT NULL,
    `fechaNacimiento` date NOT NULL
);

create table comentarios(
	`id` int NOT NULL AUTO_INCREMENT PRIMARY KEY unique,
    `clienteId` int not null,
    `comentario` varchar(45) NOT NULL,
    FOREIGN KEY (clienteId) REFERENCES clientes(id)
);

create table credenciales(
	`id` int NOT NULL AUTO_INCREMENT PRIMARY KEY unique,
    `clienteId` int not null unique,
    `usuario` varchar(45) NOT NULL,
    `contraseña` varchar(45) NOT NULL,
    FOREIGN KEY (clienteId) REFERENCES clientes(id)
);

create table notificaciones (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY unique,
    `clienteId` INT,
    `mensaje` VARCHAR(255),
    FOREIGN KEY (clienteId) REFERENCES clientes(id)
);








/* 
   ************
   *   PROCEDIMIENTOS ALMACENADOS   *
   ************
*/ 

drop procedure if exists new_client;


DELIMITER //

CREATE PROCEDURE new_client (
    p_nombre VARCHAR(45),
    p_apellido VARCHAR(45),
    p_fecha_nacimiento DATE,
	p_usuario VARCHAR(45),
    p_password VARCHAR(45)
)
BEGIN
    DECLARE v_count INT;
    DECLARE v_cliente_id INT;
    DECLARE v_mensaje VARCHAR(100);

    -- Verificar si el usuario existe
    SELECT COUNT(*) INTO v_count FROM proyectolab3.credenciales WHERE usuario = p_usuario;

    IF v_count = 0 THEN
        -- Agregar el usuario si no existe
        INSERT INTO proyectolab3.clientes (nombre, apellido, fechaNacimiento) VALUES (p_nombre, p_apellido, p_fecha_nacimiento);
        
        -- Obtener el ID del cliente agregado
        SET v_cliente_id = LAST_INSERT_ID();
        
        -- Insertar en la tabla credenciales utilizando el ID del cliente
        INSERT INTO proyectolab3.credenciales (clienteId, usuario, contraseña) VALUES (v_cliente_id, p_usuario, p_password);
        
        SET v_mensaje ='correcto';
    ELSE
        SET v_mensaje = 'existe';
    END IF;
    -- Devolver el mensaje como resultado
    SELECT v_mensaje AS mensaje;
END //

DELIMITER ;






drop procedure if exists delete_client;


DELIMITER //

CREATE PROCEDURE delete_client (
	p_usuario VARCHAR(45),
    p_password VARCHAR(45)
)
BEGIN
    DECLARE cliente_Id INT;
    DECLARE v_mensaje VARCHAR(100);

    -- Verificar si el usuario existe
	SELECT clienteId INTO cliente_Id FROM proyectolab3.credenciales WHERE usuario = p_usuario and contraseña = p_password;

    IF cliente_Id != 0 THEN
        -- Si el usuario existe eliminarlo de la tabla credenciales y de la tabla clientes
        delete from proyectolab3.clientes where id = cliente_Id;
        
        SET v_mensaje ='correcto';
    ELSE
        SET v_mensaje = 'inexistente';
    END IF;
    -- Devolver el mensaje como resultado
    SELECT v_mensaje AS mensaje;
END //

DELIMITER ;




drop procedure if exists notificacion;


DELIMITER //

CREATE PROCEDURE notificacion (
	p_usuario VARCHAR(45),
    notificacion VARCHAR(45)
)
BEGIN
    DECLARE cliente_Id INT;
    DECLARE v_mensaje VARCHAR(100);

    -- Verificar si el usuario existe
	SELECT clienteId INTO cliente_Id FROM proyectolab3.credenciales WHERE usuario = p_usuario;

    IF cliente_Id != 0 THEN
        -- Si el usuario existe ingresa la notificacion en la tabla notificaciones con el id del cliente en la columna clienteId
        insert into proyectolab3.notificaciones (clienteId, mensaje) values (cliente_Id, notificacion);
        
        SET v_mensaje ='correcto';
    ELSE
        SET v_mensaje = 'inexistente';
    END IF;
    -- Devolver el mensaje como resultado
    SELECT v_mensaje AS mensaje;
END //

DELIMITER ;


drop procedure if exists comentario;


DELIMITER //

CREATE PROCEDURE comentario (
	p_usuario VARCHAR(45),
    comentario VARCHAR(45)
)
BEGIN
    DECLARE cliente_Id INT;
    DECLARE v_mensaje VARCHAR(100);

    -- Verificar si el usuario existe
	SELECT clienteId INTO cliente_Id FROM proyectolab3.credenciales WHERE usuario = p_usuario;

    IF cliente_Id != 0 THEN
        -- Si el usuario existe ingresa el comentario en la tabla comentarios con el id del cliente en la columna clienteId
        insert into proyectolab3.comentarios (clienteId, comentario) values (cliente_Id, comentario);
        
        SET v_mensaje ='correcto';
    ELSE
        SET v_mensaje = 'inexistente';
    END IF;
    -- Devolver el mensaje como resultado
    SELECT v_mensaje AS mensaje;
END //

DELIMITER ;

/* 
   ************
   *   EJECUCION DE PROCEDIMIENTOS  *
   ************
*/ 

call new_client('francisco', 'fernandez', '2023-12-11', 'user2', 'password'); -- tabla clientes y credenciales

call delete_client('user2', 'password'); -- tabla credenciales

call notificacion('user2', 'Debe validar su numero de celular'); -- tabla notificaciones

call comentario('user2', 'Exelente servicio'); -- tabla de comentario



/* 
   ************
   *          TRANSACCIÓN           *
   ************
*/ 

START TRANSACTION;

insert into comentarios (`clienteId`, `comentario`) values((
	SELECT clienteId
	FROM credenciales
	WHERE credenciales.usuario = 'usuario'
), 'Buen servicio');

ROLLBACK;
commit;
SELECT * FROM comentarios;



/* 
   ************
   *   			TRIGGER	   			*
   ************
*/

drop trigger if exists deleteCliente;

delimiter //
create trigger deleteCliente before delete on clientes
for each row
begin
	delete from credenciales where clienteId = old.id;
	delete from comentarios where clienteId = old.id;
    delete from notificaciones where clienteId = old.id;
end //
delimiter ;



select * from credenciales;
select * from clientes;
select * from comentarios;
select * from notificaciones;