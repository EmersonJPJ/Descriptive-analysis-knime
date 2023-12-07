Create Database DW_Proyecto
USE master
Use DW_Proyecto

CREATE TABLE DIM_Pais (
  id_pais INT IDENTITY(1,1) PRIMARY KEY,
  iso_code VARCHAR(10) NOT NULL,
  continent VARCHAR(50) NOT NULL,
  location VARCHAR(100) NOT NULL
);

CREATE TABLE DIM_Fecha (
  id_fecha int IDENTITY PRIMARY KEY,
  fecha varchar(30) not null
);



CREATE TABLE DIM_Casos (
  id_caso INT IDENTITY(1,1) PRIMARY KEY,
  total_cases_per_million INT NOT NULL,
  new_cases_per_million INT NOT NULL, 
  new_cases_smoothed_per_million INT NOT NULL,
  reproduction_rate DECIMAL(10,2) NOT NULL
);

CREATE TABLE DIM_Muertes (
  id_muerte INT IDENTITY(1,1) PRIMARY KEY,
  total_deaths_per_million INT NOT NULL,
  new_deaths_per_million INT NOT NULL,
  new_deaths_smoothed_per_million INT NOT NULL
);

CREATE TABLE Hechos_Casos (
  id_casos INT IDENTITY PRIMARY KEY,
  id_pais INT FOREIGN KEY REFERENCES DIM_Pais(id_pais),
  id_fecha int FOREIGN KEY REFERENCES DIM_Fecha(id_fecha),
  Ubicacion VARCHAR(100),
  total_cases INT ,
  new_cases INT,
  new_cases_smoothed INT,
  total_deaths INT,
  new_deaths INT,
  new_deaths_smoothed INT,
  id_muerte_dim INT FOREIGN KEY REFERENCES DIM_Muertes(id_muerte),
  id_caso_dim INT FOREIGN KEY REFERENCES DIM_Casos(id_caso)
);

USE DW_Proyecto

Delete from DIM_Muertes

DBCC CHECKIDENT (DIM_Muertes, RESEED, 0)

select * from DIM_Muertes;

select * from DIM_Casos;

select * from DIM_Pais;

SELECT * FROM DIM_Fecha;

SELECT * FROM Hechos_Casos;

CREATE OR ALTER PROCEDURE sp_llenar_nulos
AS
BEGIN
  DECLARE @id_pais int = 1
  WHILE @id_pais <= (SELECT MAX(id_pais) FROM DIM_Pais)
  BEGIN
    UPDATE top (1) Hechos_Casos 
    SET id_pais = @id_pais
    WHERE id_pais IS NULL
   
    SET @id_pais = @id_pais + 1
  END

  DECLARE @id_fecha int = 1
  WHILE @id_fecha <= (SELECT MAX(id_fecha) FROM DIM_Fecha) 
  BEGIN
    UPDATE top (1) Hechos_Casos
    SET id_fecha = @id_fecha
    WHERE id_fecha IS NULL

    SET @id_fecha = @id_fecha + 1
  END

  DECLARE @id_muerte int = 1
  WHILE @id_muerte <= (SELECT MAX(id_muerte) FROM DIM_Muertes)
  BEGIN 
    UPDATE top (1) Hechos_Casos
    SET id_muerte_dim = @id_muerte
    WHERE id_muerte_dim IS NULL
   
    SET @id_muerte = @id_muerte + 1
  END
   
  DECLARE @id_caso int = 1
  WHILE @id_caso <= (SELECT MAX(id_caso) FROM DIM_Casos)
  BEGIN
    UPDATE top (1) Hechos_Casos 
    SET id_caso_dim = @id_caso
    WHERE id_caso_dim IS NULL

    SET @id_caso = @id_caso + 1
  END  
END

EXEC sp_llenar_nulos


/* PROCEDIMIENTOS ALMACENADOS DE CONSULTAS */

--sp_casos_pais_tiempo: Obtiene los casos por país a través del tiempo. Útil para gráficos de tendencia.
CREATE PROCEDURE sp_casos_pais_tiempo
AS
SELECT p.iso_code, f.fecha, h.total_cases  
FROM Hechos_Casos h
INNER JOIN DIM_Pais p ON h.id_pais = p.id_pais
INNER JOIN DIM_Fecha f ON h.id_fecha = f.id_fecha

EXEC sp_casos_pais_tiempo


--sp_tasa_mortalidad: Obtiene la tasa de mortalidad por país.
CREATE PROCEDURE sp_tasa_mortalidad 
AS
SELECT p.iso_code,  
       (h.total_deaths * 100.0) / h.total_cases AS mortality_rate
FROM Hechos_Casos h 
INNER JOIN DIM_Pais p
  ON h.id_pais = p.id_pais

EXEC sp_tasa_mortalidad


--sp_comparacion_mortalidad Comparación de muerte entre paises 
CREATE PROCEDURE sp_comparacion_mortalidad 
AS
SELECT 
  p.iso_code,
  MAX(h.total_deaths) AS total_muertes, 
  MAX(h.total_cases) AS total_casos,
  (MAX(h.total_deaths)*100 / MAX(h.total_cases)) AS tasa_mortalidad
FROM Hechos_Casos h
INNER JOIN DIM_Pais p
  ON h.id_pais = p.id_pais  
GROUP BY p.iso_code
ORDER BY tasa_mortalidad DESC

EXEC sp_comparacion_mortalidad


--Tendencia reproducción del virus:
CREATE PROCEDURE sp_tendencia_reproduccion
AS
SELECT AVG(c.reproduction_rate) AS tasa_reproduccion, 
       DATEPART(month, f.fecha) AS mes
FROM Hechos_Casos h
INNER JOIN DIM_Casos c
  ON h.id_caso_dim = c.id_caso
INNER JOIN DIM_Fecha f
  ON h.id_fecha = f.id_fecha
WHERE f.fecha >= '2020-01-01'
GROUP BY DATEPART(month, f.fecha) 
ORDER BY mes

EXEC sp_tendencia_reproduccion


--Tendencias Globales de Casos:
CREATE PROCEDURE sp_ObtenerTendenciasGlobalesCasos
AS
BEGIN
    SELECT
        F.fecha AS Fecha,
        SUM(HC.total_cases) AS TotalCasos,
        SUM(HC.new_cases) AS NuevosCasos,
        SUM(HC.total_deaths) AS TotalMuertes,
        SUM(HC.new_deaths) AS NuevasMuertes
    FROM
        Hechos_Casos HC
        INNER JOIN DIM_Fecha F ON HC.id_fecha = F.id_fecha
    GROUP BY
        F.fecha;
END;

EXEC sp_ObtenerTendenciasGlobalesCasos


--DESKTOP-6PLKSGK
--DW_Proyecto

--Estadísticas Generales de Guatemala, Belice y el Salvador:
CREATE PROCEDURE sp_ObtenerEstadisticasGeneralesPorPais
AS
BEGIN
    SELECT
        P.location AS Pais,
        SUM(HC.total_cases) AS TotalCasos,
        SUM(HC.total_deaths) AS TotalMuertes
    FROM
        Hechos_Casos HC
        INNER JOIN DIM_Pais P ON HC.id_pais = P.id_pais
    GROUP BY
        P.location;
END;

EXEC sp_ObtenerEstadisticasGeneralesPorPais




