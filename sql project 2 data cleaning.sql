/*

I. Cleaning Data in SQL Queries

*/


Select *
From NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- 1) Standardize Date Format

-- methode 1

SELECT SaleDate, CONVERT(Date,SaleDate)
FROM NashvilleHousing

UPDATE NashvilleHousing						--UPDATE : to update the table values ; ALTER TABLE: to modify table structure 
SET SaleDate = CONVERT(Date, SaleDate)     

SELECT SaleDate FROM NashvilleHousing

-- If it doesn't Update properly (methode 2) 

ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE

SELECT SaleDateConverted FROM NashvilleHousing

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate)

 --------------------------------------------------------------------------------------------------------------------------

-- 2) Populate Property Address data

--Select *
--From NashvilleHousing
--Where PropertyAddress is null
--order by ParcelID

-- Comment: same ParcelID have the same PropertyAddress (However the UniqueID is different)
SELECT *
FROM NashvilleHousing
WHERE ParcelID = '019 13 0 037.00'

-- Solution: Using self-join to fill the empty PropertyAddress with others row, which having the same ParcelID and its Address is not null

SELECT a.UniqueID, b.UniqueID, a.ParcelID, b.ParcelID, a.PropertyAddress, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b ON (a.ParcelID = b.ParcelID) AND (a.UniqueID <> b.UniqueID)
WHERE b.PropertyAddress IS NULL


UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b ON (a.ParcelID = b.ParcelID) AND (a.UniqueID <> b.UniqueID)
WHERE a.PropertyAddress IS NULL


--------------------------------------------------------------------------------------------------------------------------

-- 3) Breaking out Address into Individual Columns (Address, City, State)

-- 2 methodes: substring & Parsename



-- methode 1: using substring to split "PropertyAddress"
Select PropertyAddress
From NashvilleHousing

-- extract the city 
SELECT SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1  , LEN(PropertyAddress))   
FROM NashvilleHousing    -- RE: CHARINDEX Function will give the index of the special of character that we are looking for 

-- extract the adresse
SELECT SUBSTRING(PropertyAddress,1, CHARINDEX(',', PropertyAddress) - 1)
FROM NashvilleHousing

--SELECT CHARINDEX(',', PropertyAddress) FROM NashvilleHousing   

-- Add the city & adresse to the table 

ALTER TABLE NashvilleHousing
ADD PropertyAddressSplitCity Nvarchar(255)

UPDATE NashvilleHousing
SET PropertyAddressSplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1  , LEN(PropertyAddress))   

ALTER TABLE NashvilleHousing
ADD PropertyAddressSplitAdresse Nvarchar(255)

UPDATE NashvilleHousing
SET PropertyAddressSplitAdresse = SUBSTRING(PropertyAddress,1, CHARINDEX(',', PropertyAddress) - 1)  

Select *
From NashvilleHousing



-- 2nd method: PARSENAME
--In SQL Server, the PARSENAME function is used to extract specific parts of an object name, such as a database name, schema name, table name, or column name. It can be particularly useful when working with fully qualified object names that are delimited by a period (".").

SELECT OwnerAddress
FROM NashvilleHousing

-- Extract adresse
SELECT PARSENAME(REPLACE(OwnerAddress,',', '.'), 3 )
FROM NashvilleHousing

-- Extract city
SELECT PARSENAME(REPLACE(OwnerAddress,',', '.'), 2 )
FROM NashvilleHousing

-- Extract State
SELECT PARSENAME(REPLACE(OwnerAddress,',', '.'), 1 )
FROM NashvilleHousing

-- Same process as methode 1, to update the table 

ALTER TABLE NashvilleHousing
ADD OwnerAddressSplitAdresse Nvarchar(255)

UPDATE NashvilleHousing
SET OwnerAddressSplitAdresse = PARSENAME(REPLACE(OwnerAddress,',', '.'), 3 )

ALTER TABLE NashvilleHousing
ADD OwnerAddressSplitCity Nvarchar(255)

UPDATE NashvilleHousing
SET OwnerAddressSplitCITY = PARSENAME(REPLACE(OwnerAddress,',', '.'), 2 )

ALTER TABLE NashvilleHousing
ADD OwnerAddressSplitState Nvarchar(255)

UPDATE NashvilleHousing
SET OwnerAddressSplitState = PARSENAME(REPLACE(OwnerAddress,',', '.'), 1 )

SELECT * FROM NashvilleHousing



--------------------------------------------------------------------------------------------------------------------------


-- 4) Change Y and N to Yes and No in "Sold as Vacant" field
-- methode: CASE statement 

-- step 1: check the distinct value of the column 
SELECT Distinct(SoldasVacant), COUNT(SoldasVacant) AS nomber
FROM NashvilleHousing
GROUP BY SoldasVacant
ORDER BY 2

-- step 2: using case statement to transform Y to Yes
SELECT SoldAsVacant, 
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N'THEN 'No' 
	ELSE SoldAsVacant
	END  
FROM NashvilleHousing

-- Step 3 Update table with the case statement
UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N'THEN 'No' 
	ELSE SoldAsVacant
	END  



-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- 5) Remove Duplicates

-- methode: Row number ;  we suppose that the records which have the same ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference are the duplicates, As a result, we are going to use ROWNUMBER OVER() and partition by these columns
-- To clarify, if the row number is 1, it indicates the first occurrence of a set of values for the partitioning columns, while a row number greater than 1 signifies duplicate rows with the same values for the partitioning columns.

-- Step 1: Assigne the row number
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS rownumber
FROM NashvilleHousing

-- Step 2:Create CTE and remove duplicate rows
WITH RowNum AS
(SELECT *, 
ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS rownumber
FROM NashvilleHousing)
DELETE   -- be careful, it will directly delete the duplicate from your table NashvilleHousing !!
FROM RowNum
WHERE rownumber > 2

-- Check again
WITH RowNum AS
(SELECT *, 
ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS rownumber
FROM NashvilleHousing)
SELECT * 
FROM RowNum
WHERE rownumber > 2


---------------------------------------------------------------------------------------------------------

-- 6) Delete Unused Columns

-- If you are afraid of impacting directly your row dataset(espacially when u have to delete something from ur table), you can create a view and manipulate on it firstly (Very important)
--CREATE VIEW myview AS 
--SELECT * FROM NashvilleHousing;
--SELECT * FROM myview; 


ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate;

SELECT * FROM NashvilleHousing; 















-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	

--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE PortfolioProject 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE PortfolioProject;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO

















