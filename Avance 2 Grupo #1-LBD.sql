IF DB_ID('ViajaSeguro') IS NULL
BEGIN
    CREATE DATABASE ViajaSeguro;
END;
GO
USE ViajaSeguro;
GO

-- Creaci n de tablas, se utiliza de esta forma para evitar errores de duplicado.
IF OBJECT_ID('Pagos', 'U') IS NOT NULL DROP TABLE Pagos;
IF OBJECT_ID('Reservas', 'U') IS NOT NULL DROP TABLE Reservas;
IF OBJECT_ID('Paquete_Proveedor', 'U') IS NOT NULL DROP TABLE Paquete_Proveedor;
IF OBJECT_ID('Paquetes', 'U') IS NOT NULL DROP TABLE Paquetes;
IF OBJECT_ID('Proveedores', 'U') IS NOT NULL DROP TABLE Proveedores;
IF OBJECT_ID('Clientes', 'U') IS NOT NULL DROP TABLE Clientes;
GO
--   ****TABLAS PRINCIPALES**** Creadas por Abby
CREATE TABLE Clientes (
    id_cliente INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL,
    correo NVARCHAR(100) UNIQUE NOT NULL,
    telefono NVARCHAR(20),
    pais NVARCHAR(50)
);
GO

CREATE TABLE Paquetes (
    id_paquete INT IDENTITY(1,1) PRIMARY KEY,
    nombre_paquete NVARCHAR(100) NOT NULL,
    destino NVARCHAR(100) NOT NULL,
    duracion INT,
    precio DECIMAL(10,2)
);
GO

CREATE TABLE Proveedores (
    id_proveedor INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL,
    servicio NVARCHAR(100),
    contacto NVARCHAR(50),
    correo NVARCHAR(100)
);
GO

CREATE TABLE Paquete_Proveedor (
    id_paquete INT NOT NULL,
    id_proveedor INT NOT NULL,
    PRIMARY KEY (id_paquete, id_proveedor),
    FOREIGN KEY (id_paquete) REFERENCES Paquetes(id_paquete),
    FOREIGN KEY (id_proveedor) REFERENCES Proveedores(id_proveedor)
);
GO

CREATE TABLE Reservas (
    id_reserva INT IDENTITY(1,1) PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_paquete INT NOT NULL,
    fecha_reserva DATE NOT NULL DEFAULT GETDATE(),
    monto_total DECIMAL(10,2),
    FOREIGN KEY (id_cliente) REFERENCES Clientes(id_cliente),
    FOREIGN KEY (id_paquete) REFERENCES Paquetes(id_paquete)
);
GO

CREATE TABLE Pagos (
    id_pago INT IDENTITY(1,1) PRIMARY KEY,
    id_reserva INT NOT NULL,
    metodo_pago NVARCHAR(50),
    fecha_pago DATE DEFAULT GETDATE(),
    estado NVARCHAR(50),
    FOREIGN KEY (id_reserva) REFERENCES Reservas(id_reserva)
);
GO

--- 5 paquetes
CREATE SCHEMA pkg_clientes;
GO
CREATE SCHEMA pkg_proveedores;
GO
CREATE SCHEMA pkg_paquetes;
GO
CREATE SCHEMA pkg_reservas;
GO
CREATE SCHEMA pkg_pagos;
GO

--PAQUETE DE CLIENTES
--  Primera Funci n: Para validar existencia de correo
IF OBJECT_ID('pkg_clientes.fn_ExisteCorreo','FN') IS NOT NULL
    DROP FUNCTION pkg_clientes.fn_ExisteCorreo;
GO
CREATE FUNCTION pkg_clientes.fn_ExisteCorreo(@correo NVARCHAR(100))
RETURNS BIT
AS
BEGIN
    DECLARE @existe BIT = 0;
    IF EXISTS(SELECT 1 FROM Clientes WHERE correo=@correo)
        SET @existe = 1;
    RETURN @existe;
END;
GO

-- Primer rocedimiento: Para insertar Cliente
IF OBJECT_ID('pkg_clientes.sp_InsertarCliente', 'P') IS NOT NULL
    DROP PROCEDURE pkg_clientes.sp_InsertarCliente;
GO
CREATE PROCEDURE pkg_clientes.sp_InsertarCliente
    @nombre NVARCHAR(100),
    @correo NVARCHAR(100),
    @telefono NVARCHAR(20),
    @pais NVARCHAR(50)
AS
BEGIN
    IF pkg_clientes.fn_ExisteCorreo(@correo) = 0
        INSERT INTO Clientes(nombre, correo, telefono, pais)
        VALUES (@nombre, @correo, @telefono, @pais);
END;
GO

-- Segundo procedimiento: Leer Clientes
IF OBJECT_ID('pkg_clientes.sp_ConsultarClientes', 'P') IS NOT NULL
    DROP PROCEDURE pkg_clientes.sp_ConsultarClientes;
GO
CREATE PROCEDURE pkg_clientes.sp_ConsultarClientes
AS
BEGIN
    SELECT * FROM Clientes;
END;
GO

-- Tercer procedimiento: Para actualizar Cliente
IF OBJECT_ID('pkg_clientes.sp_ActualizarCliente', 'P') IS NOT NULL
    DROP PROCEDURE pkg_clientes.sp_ActualizarCliente;
GO
CREATE PROCEDURE pkg_clientes.sp_ActualizarCliente
    @id_cliente INT,
    @nombre NVARCHAR(100),
    @correo NVARCHAR(100),
    @telefono NVARCHAR(20),
    @pais NVARCHAR(50)
AS
BEGIN
    UPDATE Clientes
    SET nombre=@nombre, correo=@correo, telefono=@telefono, pais=@pais
    WHERE id_cliente=@id_cliente;
END;
GO

-- Cuarto procedimiento: Para eliminar Cliente
IF OBJECT_ID('pkg_clientes.sp_EliminarCliente', 'P') IS NOT NULL
    DROP PROCEDURE pkg_clientes.sp_EliminarCliente;
GO
CREATE PROCEDURE pkg_clientes.sp_EliminarCliente
    @id_cliente INT
AS
BEGIN
    DELETE FROM Clientes WHERE id_cliente=@id_cliente;
END;
GO

-- Quinto procedimiento con  1 Cursor: Para cumplir con el requerimiento de istar Clientes Frecuentes
IF OBJECT_ID('pkg_clientes.sp_ListarClientesFrecuentes','P') IS NOT NULL
    DROP PROCEDURE pkg_clientes.sp_ListarClientesFrecuentes;
GO
CREATE PROCEDURE pkg_clientes.sp_ListarClientesFrecuentes
AS
BEGIN
    DECLARE @nombre NVARCHAR(100), @total INT;
    DECLARE cur CURSOR FOR
    SELECT C.nombre, COUNT(R.id_reserva)
    FROM Clientes C
    JOIN Reservas R ON C.id_cliente=R.id_cliente
    GROUP BY C.nombre;
    OPEN cur;
    FETCH NEXT FROM cur INTO @nombre, @total;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT('Cliente: ' + @nombre + ' - Reservas: ' + CAST(@total AS NVARCHAR));
        FETCH NEXT FROM cur INTO @nombre, @total;
    END
    CLOSE cur;
    DEALLOCATE cur;
END;
GO
-- Primera Vista: Ver Clientes con reservas
IF OBJECT_ID('pkg_clientes.vw_ClientesFrecuentes', 'V') IS NOT NULL
    DROP VIEW pkg_clientes.vw_ClientesFrecuentes;
GO
CREATE VIEW pkg_clientes.vw_ClientesFrecuentes AS
SELECT C.id_cliente, C.nombre, COUNT(R.id_reserva) AS total_reservas
FROM Clientes C
JOIN Reservas R ON C.id_cliente=R.id_cliente
GROUP BY C.id_cliente, C.nombre;
GO

--PAQUETE DE PAQUETES TURISTICOS
-- Segunda Funci n para obtener el precio del paquete
IF OBJECT_ID('pkg_paquetes.fn_ObtenerPrecio','FN') IS NOT NULL
    DROP FUNCTION pkg_paquetes.fn_ObtenerPrecio;
GO
CREATE FUNCTION pkg_paquetes.fn_ObtenerPrecio(@id_paquete INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @precio DECIMAL(10,2);
    SELECT @precio = precio FROM Paquetes WHERE id_paquete=@id_paquete;
    RETURN ISNULL(@precio,0);
END;
GO

--CRUD DE PAQUETES 
-- Sexto procedimiento para insertar paquete
IF OBJECT_ID('pkg_paquetes.sp_InsertarPaquete','P') IS NOT NULL
    DROP PROCEDURE pkg_paquetes.sp_InsertarPaquete;
GO
CREATE PROCEDURE pkg_paquetes.sp_InsertarPaquete
    @nombre NVARCHAR(100), @destino NVARCHAR(100), @duracion INT, @precio DECIMAL(10,2)
AS
BEGIN
    INSERT INTO Paquetes(nombre_paquete, destino, duracion, precio)
    VALUES (@nombre, @destino, @duracion, @precio);
END;
GO

-- S ptimo procedimiento para consultar paquetes
CREATE PROCEDURE pkg_paquetes.sp_ConsultarPaquetes AS SELECT * FROM Paquetes; GO
--Octavo para actualizar
CREATE PROCEDURE pkg_paquetes.sp_ActualizarPaquete
    @id_paquete INT, @nombre NVARCHAR(100), @destino NVARCHAR(100), @duracion INT, @precio DECIMAL(10,2)
AS
BEGIN
    UPDATE Paquetes SET nombre_paquete=@nombre, destino=@destino, duracion=@duracion, precio=@precio
    WHERE id_paquete=@id_paquete;
END;
GO

--Noveno procedimiento para eliminar paquete
IF OBJECT_ID('pkg_paquetes.sp_EliminarPaquete','P') IS NOT NULL
    DROP PROCEDURE pkg_paquetes.sp_EliminarPaquete;
GO
CREATE PROCEDURE pkg_paquetes.sp_EliminarPaquete @id_paquete INT AS
BEGIN
    DELETE FROM Paquetes WHERE id_paquete=@id_paquete;
END;
GO
-- Segunda Vista: Para ver el promedio de precios por destino
IF OBJECT_ID('pkg_paquetes.vw_PromediosPorDestino', 'V') IS NOT NULL
    DROP VIEW pkg_paquetes.vw_PromediosPorDestino;
GO
CREATE VIEW pkg_paquetes.vw_PromediosPorDestino AS
SELECT destino, AVG(precio) AS promedio FROM Paquetes GROUP BY destino;
GO

--PAQUETE DE RESERVAS---Creado por Joselline
-- Tercera Función: Para calcular el monto total de una reserva
IF OBJECT_ID('pkg_reservas.fn_CalcularMontoTotal','FN') IS NOT NULL
    DROP FUNCTION pkg_reservas.fn_CalcularMontoTotal;
GO
CREATE FUNCTION pkg_reservas.fn_CalcularMontoTotal(@id_paquete INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @monto DECIMAL(10,2);
    SELECT @monto = precio FROM Paquetes WHERE id_paquete = @id_paquete;
    RETURN ISNULL(@monto, 0);
END;
GO

-- Décimo procedimiento: Para insertar Reserva
IF OBJECT_ID('pkg_reservas.sp_InsertarReserva', 'P') IS NOT NULL
    DROP PROCEDURE pkg_reservas.sp_InsertarReserva;
GO
CREATE PROCEDURE pkg_reservas.sp_InsertarReserva
    @id_cliente INT,
    @id_paquete INT,
    @fecha_reserva DATE
AS
BEGIN
    DECLARE @monto DECIMAL(10,2);
    SET @monto = pkg_reservas.fn_CalcularMontoTotal(@id_paquete);
    
    INSERT INTO Reservas(id_cliente, id_paquete, fecha_reserva, monto_total)
    VALUES (@id_cliente, @id_paquete, @fecha_reserva, @monto);
END;
GO

-- Undécimo procedimiento: Para consultar Reservas
IF OBJECT_ID('pkg_reservas.sp_ConsultarReservas', 'P') IS NOT NULL
    DROP PROCEDURE pkg_reservas.sp_ConsultarReservas;
GO
CREATE PROCEDURE pkg_reservas.sp_ConsultarReservas
AS
BEGIN
    SELECT * FROM Reservas;
END;
GO

-- Duodécimo procedimiento: Para actualizar Reserva
IF OBJECT_ID('pkg_reservas.sp_ActualizarReserva', 'P') IS NOT NULL
    DROP PROCEDURE pkg_reservas.sp_ActualizarReserva;
GO
CREATE PROCEDURE pkg_reservas.sp_ActualizarReserva
    @id_reserva INT,
    @id_cliente INT,
    @id_paquete INT,
    @fecha_reserva DATE
AS
BEGIN
    DECLARE @monto DECIMAL(10,2);
    SET @monto = pkg_reservas.fn_CalcularMontoTotal(@id_paquete);
    
    UPDATE Reservas
    SET id_cliente = @id_cliente, 
        id_paquete = @id_paquete, 
        fecha_reserva = @fecha_reserva,
        monto_total = @monto
    WHERE id_reserva = @id_reserva;
END;
GO

-- Decimotercer procedimiento: Para eliminar Reserva
IF OBJECT_ID('pkg_reservas.sp_EliminarReserva', 'P') IS NOT NULL
    DROP PROCEDURE pkg_reservas.sp_EliminarReserva;
GO
CREATE PROCEDURE pkg_reservas.sp_EliminarReserva
    @id_reserva INT
AS
BEGIN
    DELETE FROM Reservas WHERE id_reserva = @id_reserva;
END;
GO

-- Decimocuarto procedimiento con Cursor: Para listar Reservas por Cliente
IF OBJECT_ID('pkg_reservas.sp_ListarReservasPorCliente','P') IS NOT NULL
    DROP PROCEDURE pkg_reservas.sp_ListarReservasPorCliente;
GO
CREATE PROCEDURE pkg_reservas.sp_ListarReservasPorCliente
AS
BEGIN
    DECLARE @cliente NVARCHAR(100), @paquete NVARCHAR(100), @monto DECIMAL(10,2);
    DECLARE cur CURSOR FOR
    SELECT C.nombre, P.nombre_paquete, R.monto_total
    FROM Reservas R
    JOIN Clientes C ON R.id_cliente = C.id_cliente
    JOIN Paquetes P ON R.id_paquete = P.id_paquete;
    
    OPEN cur;
    FETCH NEXT FROM cur INTO @cliente, @paquete, @monto;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT('Cliente: ' + @cliente + ' - Paquete: ' + @paquete + ' - Monto: $' + CAST(@monto AS NVARCHAR));
        FETCH NEXT FROM cur INTO @cliente, @paquete, @monto;
    END
    CLOSE cur;
    DEALLOCATE cur;
END;
GO

-- Tercera Vista: Para ver el resumen de Reservas
IF OBJECT_ID('pkg_reservas.vw_ResumenReservas', 'V') IS NOT NULL
    DROP VIEW pkg_reservas.vw_ResumenReservas;
GO
CREATE VIEW pkg_reservas.vw_ResumenReservas AS
SELECT R.id_reserva, C.nombre AS cliente, P.nombre_paquete, P.destino, 
       R.fecha_reserva, R.monto_total
FROM Reservas R
JOIN Clientes C ON R.id_cliente = C.id_cliente
JOIN Paquetes P ON R.id_paquete = P.id_paquete;
GO

--PAQUETE DE PAGOS
-- Cuarta Función: Para verificar si existe una reserva
IF OBJECT_ID('pkg_pagos.fn_ExisteReserva','FN') IS NOT NULL
    DROP FUNCTION pkg_pagos.fn_ExisteReserva;
GO
CREATE FUNCTION pkg_pagos.fn_ExisteReserva(@id_reserva INT)
RETURNS BIT
AS
BEGIN
    DECLARE @existe BIT = 0;
    IF EXISTS(SELECT 1 FROM Reservas WHERE id_reserva = @id_reserva)
        SET @existe = 1;
    RETURN @existe;
END;
GO

-- Decimoquinto procedimiento: Para insertar Pago
IF OBJECT_ID('pkg_pagos.sp_InsertarPago', 'P') IS NOT NULL
    DROP PROCEDURE pkg_pagos.sp_InsertarPago;
GO
CREATE PROCEDURE pkg_pagos.sp_InsertarPago
    @id_reserva INT,
    @metodo_pago NVARCHAR(50),
    @estado NVARCHAR(50)
AS
BEGIN
    IF pkg_pagos.fn_ExisteReserva(@id_reserva) = 1
        INSERT INTO Pagos(id_reserva, metodo_pago, fecha_pago, estado)
        VALUES (@id_reserva, @metodo_pago, GETDATE(), @estado);
    ELSE
        PRINT('Error: La reserva no existe');
END;
GO

-- Decimosexto procedimiento: Para consultar Pagos
IF OBJECT_ID('pkg_pagos.sp_ConsultarPagos', 'P') IS NOT NULL
    DROP PROCEDURE pkg_pagos.sp_ConsultarPagos;
GO
CREATE PROCEDURE pkg_pagos.sp_ConsultarPagos
AS
BEGIN
    SELECT * FROM Pagos;
END;
GO

-- Decimoséptimo procedimiento: Para actualizar Pago
IF OBJECT_ID('pkg_pagos.sp_ActualizarPago', 'P') IS NOT NULL
    DROP PROCEDURE pkg_pagos.sp_ActualizarPago;
GO
CREATE PROCEDURE pkg_pagos.sp_ActualizarPago
    @id_pago INT,
    @metodo_pago NVARCHAR(50),
    @estado NVARCHAR(50)
AS
BEGIN
    UPDATE Pagos
    SET metodo_pago = @metodo_pago, estado = @estado
    WHERE id_pago = @id_pago;
END;
GO

-- Decimoctavo procedimiento: Para eliminar Pago
IF OBJECT_ID('pkg_pagos.sp_EliminarPago', 'P') IS NOT NULL
    DROP PROCEDURE pkg_pagos.sp_EliminarPago;
GO
CREATE PROCEDURE pkg_pagos.sp_EliminarPago
    @id_pago INT
AS
BEGIN
    DELETE FROM Pagos WHERE id_pago = @id_pago;
END;
GO

-- Decimonoveno procedimiento con Cursor: Para listar Pagos Pendientes
IF OBJECT_ID('pkg_pagos.sp_ListarPagosPendientes','P') IS NOT NULL
    DROP PROCEDURE pkg_pagos.sp_ListarPagosPendientes;
GO
CREATE PROCEDURE pkg_pagos.sp_ListarPagosPendientes
AS
BEGIN
    DECLARE @cliente NVARCHAR(100), @monto DECIMAL(10,2), @estado NVARCHAR(50);
    DECLARE cur CURSOR FOR
    SELECT C.nombre, R.monto_total, P.estado
    FROM Pagos P
    JOIN Reservas R ON P.id_reserva = R.id_reserva
    JOIN Clientes C ON R.id_cliente = C.id_cliente
    WHERE P.estado = 'Pendiente';
    
    OPEN cur;
    FETCH NEXT FROM cur INTO @cliente, @monto, @estado;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT('Cliente: ' + @cliente + ' - Monto: $' + CAST(@monto AS NVARCHAR) + ' - Estado: ' + @estado);
        FETCH NEXT FROM cur INTO @cliente, @monto, @estado;
    END
    CLOSE cur;
    DEALLOCATE cur;
END;
GO

-- Cuarta Vista: Para ver el estado de Pagos
IF OBJECT_ID('pkg_pagos.vw_EstadoPagos', 'V') IS NOT NULL
    DROP VIEW pkg_pagos.vw_EstadoPagos;
GO
CREATE VIEW pkg_pagos.vw_EstadoPagos AS
SELECT P.id_pago, C.nombre AS cliente, R.monto_total, 
       P.metodo_pago, P.fecha_pago, P.estado
FROM Pagos P
JOIN Reservas R ON P.id_reserva = R.id_reserva
JOIN Clientes C ON R.id_cliente = C.id_cliente;
GO


--PAQUETE DE PROVEEDORES



-- P r ultimo insertar datos en las tablas

-- =============================
-- FUNCIONES (validación y cálculos) -- Creado por Andrea
-- =============================
IF OBJECT_ID('pkg_clientes.fn_EmailValido','FN') IS NOT NULL DROP FUNCTION pkg_clientes.fn_EmailValido;
GO

CREATE FUNCTION pkg_clientes.fn_EmailValido (@correo NVARCHAR(320))
RETURNS BIT
AS
BEGIN
    RETURN CASE WHEN @correo LIKE '%_@_%._%' THEN 1 ELSE 0 END;
END;
GO

IF OBJECT_ID('pkg_clientes.fn_TelefonoValido','FN') IS NOT NULL DROP FUNCTION pkg_clientes.fn_TelefonoValido;
GO

CREATE FUNCTION pkg_clientes.fn_TelefonoValido (@telefono NVARCHAR(50))
RETURNS BIT
AS
BEGIN
    DECLARE @digits NVARCHAR(50) = '';
    SELECT @digits = CONCAT(@digits, SUBSTRING(@telefono, number, 1))
    FROM master..spt_values
    WHERE type='P' AND number BETWEEN 1 AND LEN(@telefono)
      AND SUBSTRING(@telefono, number, 1) LIKE '[0-9]';
    RETURN CASE WHEN LEN(@digits) BETWEEN 8 AND 12 THEN 1 ELSE 0 END;
END;
GO

IF OBJECT_ID('pkg_pagos.fn_TotalPagadoReserva','FN') IS NOT NULL DROP FUNCTION pkg_pagos.fn_TotalPagadoReserva;
GO

CREATE FUNCTION pkg_pagos.fn_TotalPagadoReserva (@id_reserva INT)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @monto DECIMAL(12,2) = 0;
    SELECT @monto = r.monto_total
    FROM Reservas r
    WHERE r.id_reserva = @id_reserva;
    -- Criterio: si existe al menos un pago 'Pagado' consideramos el total cubierto
    IF EXISTS(SELECT 1 FROM Pagos WHERE id_reserva=@id_reserva AND estado='Pagado')
        RETURN ISNULL(@monto,0);
    RETURN 0;
END;
GO

IF OBJECT_ID('pkg_reservas.fn_SaldoPendienteReserva','FN') IS NOT NULL DROP FUNCTION pkg_reservas.fn_SaldoPendienteReserva;
GO

CREATE FUNCTION pkg_reservas.fn_SaldoPendienteReserva (@id_reserva INT)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @monto DECIMAL(12,2) = 0;
    SELECT @monto = r.monto_total FROM Reservas r WHERE r.id_reserva=@id_reserva;
    RETURN ISNULL(@monto,0) - ISNULL(pkg_pagos.fn_TotalPagadoReserva(@id_reserva),0);
END;
GO

-- =============================
-- CRUD PROVEEDORES -- Creado por Andrea
-- =============================
IF OBJECT_ID('pkg_proveedores.sp_InsertarProveedor','P') IS NOT NULL DROP PROCEDURE pkg_proveedores.sp_InsertarProveedor;
GO

CREATE PROCEDURE pkg_proveedores.sp_InsertarProveedor
    @nombre NVARCHAR(100),
    @servicio NVARCHAR(100),
    @contacto NVARCHAR(50),
    @correo NVARCHAR(100)
AS
BEGIN
    IF pkg_clientes.fn_EmailValido(@correo)=0
        THROW 51020, 'Correo inválido', 1;
    IF pkg_clientes.fn_TelefonoValido(@contacto)=0
        THROW 51021, 'Contacto telefónico inválido', 1;
    INSERT INTO Proveedores(nombre,servicio,contacto,correo)
    VALUES(@nombre,@servicio,@contacto,@correo);
END;
GO

IF OBJECT_ID('pkg_proveedores.sp_ConsultarProveedores','P') IS NOT NULL DROP PROCEDURE pkg_proveedores.sp_ConsultarProveedores;
GO

CREATE PROCEDURE pkg_proveedores.sp_ConsultarProveedores
AS
BEGIN
    SELECT * FROM Proveedores;
END;
GO

IF OBJECT_ID('pkg_proveedores.sp_ActualizarProveedor','P') IS NOT NULL DROP PROCEDURE pkg_proveedores.sp_ActualizarProveedor;
GO

CREATE PROCEDURE pkg_proveedores.sp_ActualizarProveedor
    @id_proveedor INT,
    @nombre NVARCHAR(100)=NULL,
    @servicio NVARCHAR(100)=NULL,
    @contacto NVARCHAR(50)=NULL,
    @correo NVARCHAR(100)=NULL
AS
BEGIN
    IF @correo IS NOT NULL AND pkg_clientes.fn_EmailValido(@correo)=0
        THROW 51022, 'Correo inválido', 1;
    IF @contacto IS NOT NULL AND pkg_clientes.fn_TelefonoValido(@contacto)=0
        THROW 51023, 'Contacto telefónico inválido', 1;

    UPDATE p SET
        nombre   = COALESCE(@nombre, p.nombre),
        servicio = COALESCE(@servicio, p.servicio),
        contacto = COALESCE(@contacto, p.contacto),
        correo   = COALESCE(@correo, p.correo)
    FROM Proveedores p
    WHERE p.id_proveedor=@id_proveedor;
END;
GO

IF OBJECT_ID('pkg_proveedores.sp_EliminarProveedor','P') IS NOT NULL DROP PROCEDURE pkg_proveedores.sp_EliminarProveedor;
GO

CREATE PROCEDURE pkg_proveedores.sp_EliminarProveedor
    @id_proveedor INT
AS
BEGIN
    IF EXISTS(SELECT 1 FROM Paquete_Proveedor WHERE id_proveedor=@id_proveedor)
        THROW 51024, 'No se puede eliminar: proveedor asociado a paquetes', 1;
    DELETE FROM Proveedores WHERE id_proveedor=@id_proveedor;
END;
GO

-- =============================
-- CRUD relación PAQUETE_PROVEEDOR -- Creado por Andrea
-- =============================
IF OBJECT_ID('pkg_proveedores.sp_InsertarPaquete_Proveedor','P') IS NOT NULL DROP PROCEDURE pkg_proveedores.sp_InsertarPaquete_Proveedor;
GO

CREATE PROCEDURE pkg_proveedores.sp_InsertarPaquete_Proveedor
    @id_paquete INT,
    @id_proveedor INT
AS
BEGIN
    IF NOT EXISTS(SELECT 1 FROM Paquetes WHERE id_paquete=@id_paquete)
        THROW 51030, 'Paquete no existe', 1;
    IF NOT EXISTS(SELECT 1 FROM Proveedores WHERE id_proveedor=@id_proveedor)
        THROW 51031, 'Proveedor no existe', 1;
    IF EXISTS(SELECT 1 FROM Paquete_Proveedor WHERE id_paquete=@id_paquete AND id_proveedor=@id_proveedor)
        THROW 51032, 'La relación ya existe', 1;

    INSERT INTO Paquete_Proveedor(id_paquete,id_proveedor) VALUES(@id_paquete,@id_proveedor);
END;
GO

IF OBJECT_ID('pkg_proveedores.sp_EliminarPaquete_Proveedor','P') IS NOT NULL DROP PROCEDURE pkg_proveedores.sp_EliminarPaquete_Proveedor;
GO

CREATE PROCEDURE pkg_proveedores.sp_EliminarPaquete_Proveedor
    @id_paquete INT,
    @id_proveedor INT
AS
BEGIN
    DELETE FROM Paquete_Proveedor WHERE id_paquete=@id_paquete AND id_proveedor=@id_proveedor;
END;
GO

-- =============================
-- VISTAS adicionales (reportes) -- Creado por Andrea
-- =============================
IF OBJECT_ID('pkg_pagos.vw_PagosPendientes','V') IS NOT NULL DROP VIEW pkg_pagos.vw_PagosPendientes;
GO

CREATE VIEW pkg_pagos.vw_PagosPendientes
AS
SELECT c.nombre AS cliente, r.id_reserva, r.monto_total,
       p.id_pago, p.metodo_pago, p.fecha_pago, p.estado
FROM Pagos p
JOIN Reservas r ON r.id_reserva=p.id_reserva
JOIN Clientes c ON c.id_cliente=r.id_cliente
WHERE p.estado='Pendiente';
GO

IF OBJECT_ID('pkg_paquetes.vw_TopDestinos','V') IS NOT NULL DROP VIEW pkg_paquetes.vw_TopDestinos;
GO

CREATE VIEW pkg_paquetes.vw_TopDestinos
AS
SELECT p.destino, COUNT(*) AS reservas
FROM Reservas r
JOIN Paquetes p ON p.id_paquete=r.id_paquete
GROUP BY p.destino;
GO

-- =============================
-- TRIGGERS (protección + auditoría) -- Creado por Andrea
-- =============================
IF OBJECT_ID('dbo.trg_Clientes_ProtectDelete','TR') IS NOT NULL DROP TRIGGER dbo.trg_Clientes_ProtectDelete;
GO

CREATE TRIGGER dbo.trg_Clientes_ProtectDelete
ON dbo.Clientes
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS(SELECT 1 FROM deleted d JOIN Reservas r ON r.id_cliente=d.id_cliente)
        THROW 52001, 'No se puede eliminar el cliente: tiene reservas', 1;

    DELETE c FROM Clientes c JOIN deleted d ON d.id_cliente=c.id_cliente;
END;
GO

IF OBJECT_ID('dbo.Pagos_AUD','U') IS NULL
BEGIN
    CREATE TABLE dbo.Pagos_AUD(
        audit_id INT IDENTITY PRIMARY KEY,
        id_pago INT,
        id_reserva INT,
        metodo_pago NVARCHAR(50),
        fecha_pago DATE,
        estado NVARCHAR(50),
        accion NVARCHAR(10),
        audit_ts DATETIME2 DEFAULT SYSUTCDATETIME()
    );
END;
GO

IF OBJECT_ID('dbo.trg_Pagos_AUD','TR') IS NOT NULL DROP TRIGGER dbo.trg_Pagos_AUD;
GO

CREATE TRIGGER dbo.trg_Pagos_AUD
ON dbo.Pagos
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    -- INSERT / UPDATE
    INSERT INTO dbo.Pagos_AUD(id_pago,id_reserva,metodo_pago,fecha_pago,estado,accion)
    SELECT i.id_pago,i.id_reserva,i.metodo_pago,i.fecha_pago,i.estado,
           CASE WHEN EXISTS(SELECT 1 FROM deleted) THEN 'UPDATE' ELSE 'INSERT' END
    FROM inserted i;

    -- DELETE
    INSERT INTO dbo.Pagos_AUD(id_pago,id_reserva,metodo_pago,fecha_pago,estado,accion)
    SELECT d.id_pago,d.id_reserva,d.metodo_pago,d.fecha_pago,d.estado,'DELETE'
    FROM deleted d
    WHERE NOT EXISTS(SELECT 1 FROM inserted i WHERE i.id_pago=d.id_pago);
END;
GO

-- =============================
-- REPORTES CON CURSORES (adicionales) -- Creado por Andrea
-- =============================
IF OBJECT_ID('pkg_proveedores.sp_Reporte_ProveedoresConPaquetes','P') IS NOT NULL DROP PROCEDURE pkg_proveedores.sp_Reporte_ProveedoresConPaquetes;
GO

CREATE PROCEDURE pkg_proveedores.sp_Reporte_ProveedoresConPaquetes
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @id INT, @nombre NVARCHAR(100), @cnt INT;
    DECLARE cur CURSOR FAST_FORWARD FOR SELECT id_proveedor, nombre FROM Proveedores;
    CREATE TABLE #tmp_prov (proveedor NVARCHAR(100), paquetes INT);

    OPEN cur;
    FETCH NEXT FROM cur INTO @id, @nombre;
    WHILE @@FETCH_STATUS=0
    BEGIN
        SELECT @cnt = COUNT(*) FROM Paquete_Proveedor WHERE id_proveedor=@id;
        INSERT INTO #tmp_prov VALUES(@nombre, @cnt);
        FETCH NEXT FROM cur INTO @id, @nombre;
    END
    CLOSE cur; DEALLOCATE cur;

    SELECT * FROM #tmp_prov ORDER BY paquetes DESC, proveedor;
END;
GO

IF OBJECT_ID('pkg_paquetes.sp_Reporte_IngresosPorDestino','P') IS NOT NULL DROP PROCEDURE pkg_paquetes.sp_Reporte_IngresosPorDestino;
GO

CREATE PROCEDURE pkg_paquetes.sp_Reporte_IngresosPorDestino
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @dest NVARCHAR(100), @ingreso DECIMAL(12,2);
    DECLARE cur CURSOR FAST_FORWARD FOR SELECT DISTINCT destino FROM Paquetes;
    CREATE TABLE #tmp_ing (destino NVARCHAR(100), ingreso DECIMAL(12,2));

    OPEN cur; FETCH NEXT FROM cur INTO @dest;
    WHILE @@FETCH_STATUS=0
    BEGIN
        SELECT @ingreso = ISNULL(SUM(r.monto_total),0)
        FROM Reservas r JOIN Paquetes p ON p.id_paquete=r.id_paquete
        WHERE p.destino=@dest;
        INSERT INTO #tmp_ing VALUES(@dest, @ingreso);
        FETCH NEXT FROM cur INTO @dest;
    END
    CLOSE cur; DEALLOCATE cur;

    SELECT * FROM #tmp_ing ORDER BY ingreso DESC, destino;
END;
GO

IF OBJECT_ID('pkg_clientes.sp_TopClientesPorReservas','P') IS NOT NULL DROP PROCEDURE pkg_clientes.sp_TopClientesPorReservas;
GO

CREATE PROCEDURE pkg_clientes.sp_TopClientesPorReservas
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @nombre NVARCHAR(100), @n INT;
    DECLARE cur CURSOR FAST_FORWARD FOR
        SELECT TOP 5 c.nombre, COUNT(*) n
        FROM Reservas r JOIN Clientes c ON c.id_cliente=r.id_cliente
        GROUP BY c.nombre
        ORDER BY n DESC;
    OPEN cur; FETCH NEXT FROM cur INTO @nombre, @n;
    WHILE @@FETCH_STATUS=0
    BEGIN
        PRINT('TOP Cliente: '+@nombre+' => '+CAST(@n AS NVARCHAR)+' reservas');
        FETCH NEXT FROM cur INTO @nombre, @n;
    END
    CLOSE cur; DEALLOCATE cur;
END;
GO

IF OBJECT_ID('pkg_reservas.sp_Reporte_ReservasPorMes','P') IS NOT NULL DROP PROCEDURE pkg_reservas.sp_Reporte_ReservasPorMes;
GO

CREATE PROCEDURE pkg_reservas.sp_Reporte_ReservasPorMes
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mes INT, @anio INT, @total DECIMAL(12,2);
    DECLARE cur CURSOR FAST_FORWARD FOR
        SELECT MONTH(fecha_reserva) m, YEAR(fecha_reserva) y FROM Reservas GROUP BY YEAR(fecha_reserva), MONTH(fecha_reserva);
    CREATE TABLE #tmp_mes (anio INT, mes INT, total DECIMAL(12,2));

    OPEN cur; FETCH NEXT FROM cur INTO @mes, @anio;
    WHILE @@FETCH_STATUS=0
    BEGIN
        SELECT @total = ISNULL(SUM(monto_total),0) FROM Reservas WHERE MONTH(fecha_reserva)=@mes AND YEAR(fecha_reserva)=@anio;
        INSERT INTO #tmp_mes VALUES(@anio, @mes, @total);
        FETCH NEXT FROM cur INTO @mes, @anio;
    END
    CLOSE cur; DEALLOCATE cur;

    SELECT * FROM #tmp_mes ORDER BY anio DESC, mes DESC;
END;
GO
