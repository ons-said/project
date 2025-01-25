--Dim_Location
CREATE TABLE Dim_Location (
    locationID SERIAL PRIMARY KEY,
    Address TEXT,
    City TEXT,
    State TEXT,
    Country TEXT,
	distance NUMERIC,
    openDate DATE
);

-- Dim_Departments
CREATE TABLE Dim_Departments (
    departmentsID SERIAL PRIMARY KEY,
    hasGasDepartment BOOLEAN,
    hasTiresDepartment BOOLEAN,
    hasFoodDepartment BOOLEAN,
    hasHearingDepartment BOOLEAN,
    hasPharmacyDepartment BOOLEAN,
    hasOpticalDepartment BOOLEAN,
    hasBusinessDepartment BOOLEAN,
    hasPhotoCenterDepartment BOOLEAN
);

-- Dim_HoursOfOperation
CREATE TABLE Dim_HoursOfOperation (
    Hours_of_opID SERIAL PRIMARY KEY,
    warehouseHours VARCHAR(250),
    pharmacyHours VARCHAR(250),
    gasStationHours VARCHAR(250),
    tireCenterHours VARCHAR(250)
);

-- Dim_Service
CREATE TABLE Dim_Service (
    ServicesID SERIAL PRIMARY KEY,
    coreServices TEXT,
    specialtyDepartments TEXT
);
--Dim_StoreCapabilities
CREATE TABLE Dim_StoreCapabilities (
    CapabilityID SERIAL PRIMARY KEY,
    isShipToWarehouse BOOLEAN,
    isWarehousePickup BOOLEAN,
    enableShipToHome BOOLEAN,
    isBusinessWarehouse BOOLEAN
);
-- Create the Fact Table

CREATE TABLE LocationOperations (
    stlocID SERIAL PRIMARY KEY,
    locationID INT REFERENCES Dim_Location(locationID),
    departmentsID INT REFERENCES Dim_Departments(departmentsID),
    Hours_of_opID INT REFERENCES Dim_HoursOfOperation(Hours_of_opID),
    ServicesID INT REFERENCES Dim_Service(ServicesID),
	CapabilityID INT REFERENCES Dim_StoreCapabilities(CapabilityID)
    
);

CREATE TEMP TABLE Temp_Staging (
    stlocID INT,
    Address VARCHAR(255),
    City VARCHAR(100),
    State VARCHAR(100),
    Country VARCHAR(100),
    openDate DATE,
    distance NUMERIC,
    hasGasDepartment BOOLEAN,
    hasTiresDepartment BOOLEAN,
    hasFoodDepartment BOOLEAN,
    hasHearingDepartment BOOLEAN,
    hasPharmacyDepartment BOOLEAN,
    hasOpticalDepartment BOOLEAN,
    hasBusinessDepartment BOOLEAN,
    hasPhotoCenterDepartment BOOLEAN,
    warehouseHours VARCHAR(250),
    pharmacyHours VARCHAR(250),
    gasStationHours VARCHAR(250),
    tireCenterHours VARCHAR(250),
    coreServices TEXT,
    specialtyDepartments TEXT,
    isShipToWarehouse BOOLEAN,
    isWarehousePickup BOOLEAN,
    enableShipToHome BOOLEAN,
    isBusinessWarehouse BOOLEAN,
    locationID INT,
	departmentsID INT,
	Hours_of_opID INT,
	ServicesID INT,
	CapabilityID INT
);

COPY Temp_Staging FROM 'C:\Program Files\PostgreSQL\17\lib\updated_cleaned_dataset.csv' DELIMITER ',' CSV HEADER;
SELECT *  FROM Temp_Staging limit 20

INSERT INTO Dim_Location (locationID, Address, City, State, Country, distance, openDate)
SELECT DISTINCT locationID, Address, City, State, Country, distance, openDate
FROM Temp_Staging;

INSERT INTO Dim_Departments (departmentsID, hasGasDepartment, hasTiresDepartment, hasFoodDepartment, 
                              hasHearingDepartment, hasPharmacyDepartment, hasOpticalDepartment, 
                              hasBusinessDepartment, hasPhotoCenterDepartment)
SELECT DISTINCT departmentsID, hasGasDepartment, hasTiresDepartment, hasFoodDepartment, 
                hasHearingDepartment, hasPharmacyDepartment, hasOpticalDepartment, 
                hasBusinessDepartment, hasPhotoCenterDepartment
FROM Temp_Staging;

INSERT INTO Dim_HoursOfOperation (Hours_of_opID, warehouseHours, pharmacyHours, gasStationHours, tireCenterHours)
SELECT DISTINCT Hours_of_opID, warehouseHours, pharmacyHours, gasStationHours, tireCenterHours
FROM Temp_Staging;

INSERT INTO Dim_Service (ServicesID, coreServices, specialtyDepartments)
SELECT DISTINCT ServicesID, coreServices, specialtyDepartments
FROM Temp_Staging;

INSERT INTO Dim_StoreCapabilities (CapabilityID,isShipToWarehouse, isWarehousePickup, enableShipToHome, isBusinessWarehouse )
SELECT DISTINCT CapabilityID,isShipToWarehouse, isWarehousePickup, enableShipToHome, isBusinessWarehouse
FROM Temp_Staging
INSERT INTO LocationOperations (stlocID, locationID, departmentsID, Hours_of_opID, ServicesID,
     CapabilityID)
SELECT 
    stlocID,
    (SELECT locationID 
     FROM Dim_Location 
     WHERE locationID = Temp_Staging.locationID 
       AND Address = Temp_Staging.Address 
       AND City = Temp_Staging.City 
     LIMIT 1) AS locationID,
    (SELECT departmentsID 
     FROM Dim_Departments 
     WHERE departmentsID = Temp_Staging.departmentsID 
       AND hasGasDepartment = Temp_Staging.hasGasDepartment 
       AND hasTiresDepartment = Temp_Staging.hasTiresDepartment 
     LIMIT 1) AS departmentsID,
    (SELECT Hours_of_opID 
     FROM Dim_HoursOfOperation 
     WHERE Hours_of_opID = Temp_Staging.Hours_of_opID 
       AND warehouseHours = Temp_Staging.warehouseHours 
       AND pharmacyHours = Temp_Staging.pharmacyHours 
     LIMIT 1) AS Hours_of_opID,
    (SELECT ServicesID 
     FROM Dim_Service 
     WHERE ServicesID = Temp_Staging.ServicesID 
       AND coreServices = Temp_Staging.coreServices 
       AND specialtyDepartments = Temp_Staging.specialtyDepartments 
     LIMIT 1) AS ServicesID,
    (SELECT CapabilityID 
     FROM Dim_StoreCapabilities 
     WHERE CapabilityID = Temp_Staging.CapabilityID 
       AND isShipToWarehouse = Temp_Staging.isShipToWarehouse 
       AND isWarehousePickup = Temp_Staging.isWarehousePickup 
       AND enableShipToHome = Temp_Staging.enableShipToHome 
       AND isBusinessWarehouse = Temp_Staging.isBusinessWarehouse 
     LIMIT 1) AS CapabilityID
FROM Temp_Staging;
TRUNCATE TABLE LocationOperations RESTART IDENTITY;

SELECT * FROM LocationOperations
SELECT * FROM Dim_Location;
SELECT * FROM Dim_Departments;
SELECT * FROM Dim_HoursOfOperation;
SELECT * FROM Dim_Service;
SELECT 
    ROUND(AVG(department_count), 2) AS avg_departments_per_location
FROM (
    SELECT 
        departmentsID,
        (CASE WHEN hasGasDepartment THEN 1 ELSE 0 END +
         CASE WHEN hasTiresDepartment THEN 1 ELSE 0 END +
         CASE WHEN hasFoodDepartment THEN 1 ELSE 0 END +
         CASE WHEN hasHearingDepartment THEN 1 ELSE 0 END +
         CASE WHEN hasPharmacyDepartment THEN 1 ELSE 0 END +
         CASE WHEN hasOpticalDepartment THEN 1 ELSE 0 END +
         CASE WHEN hasBusinessDepartment THEN 1 ELSE 0 END +
         CASE WHEN hasPhotoCenterDepartment THEN 1 ELSE 0 END
        ) AS department_count
    FROM Dim_Departments
) subquery;

WITH extracted_services AS (
    SELECT 
        ServicesID,
        jsonb_array_elements_text(
            -- Replace single quotes with double quotes to make it valid JSON
            REGEXP_REPLACE(coreServices, '''', '"', 'g')::jsonb
        ) AS service_name
    FROM Dim_Service
)
SELECT 
    service_name,
    COUNT(*) AS service_count
FROM extracted_services
GROUP BY service_name
ORDER BY service_count DESC
LIMIT 2;

WITH extracted_specialty_departments AS (
    SELECT 
        ServicesID,
        jsonb_array_elements_text(
            -- Replace single quotes with double quotes to make it valid JSON
            REGEXP_REPLACE(specialtyDepartments, '''', '"', 'g')::jsonb
        ) AS department_name
    FROM Dim_Service
)
SELECT 
    department_name,
    COUNT(*) AS department_count
FROM extracted_specialty_departments
GROUP BY department_name
ORDER BY department_count DESC
LIMIT 3;