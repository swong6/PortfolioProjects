
/*
Cleaning Data in SQL Queries

*/

-- Standardize Date Format
SELECT SaleDateConverted, CONVERT(date, SaleDate) 
FROM PortfolioProject.dbo.NashvilleHousing

-- Populate Property Address Data

---- Identify Null Property Addresses
SELECT PropertyAddress 
FROM PortfolioProject.dbo.NashvilleHousing
WHERE PropertyAddress is NULL
ORDER BY ParcelID

---- Where ParcelID are the same but Unique ID is not, we'll copy the Property Address to Null Values

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a 
JOIN PortfolioProject.dbo.NashvilleHousing b 
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL

--- Updating from Null to the Copied Property Address
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a 
JOIN PortfolioProject.dbo.NashvilleHousing b 
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL

SELECT * 
FROM PortfolioProject.dbo.NashvilleHousing

--Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress 
FROM PortfolioProject.dbo.NashvilleHousing
--WHERE PropertyAddress is NULL
--ORDER BY ParcelID

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',' , PropertyAddress)-1) as Address -- gives a position, for LENGTH we put negative 1 to take the comma away (one step back)
, SUBSTRING(PropertyAddress, CHARINDEX(',' , PropertyAddress) +1, LEN(PropertyAddress)) as Address -- want to start AFTER the comma, so +1 step for POSITION
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',' , PropertyAddress)-1)

ALTER TABLE NashvilleHousing
Add PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET  PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',' , PropertyAddress) +1, LEN(PropertyAddress))

SELECT * 
FROM PortfolioProject.dbo.NashvilleHousing

-- Another method of separating 
-- Splitting the Owner Address Columns into Address, City, State

SELECT 
PARSENAME (REPLACE(OwnerAddress, ',', '.'), 3)
, PARSENAME (REPLACE(OwnerAddress, ',', '.'), 2)
, PARSENAME (REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME (REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


--- Change Y / N to Yes / No in 'Sold as Vacant' 
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM PortfolioProject.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END

-- Remove Duplicates
WITH RowNUMCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice, 
				SaleDate,
				LegalReference
				ORDER BY
					UniqueID
					) row_number

FROM PortfolioProject.dbo.NashvilleHousing
--ORDER BY ParcelID
)

Select *
from RowNUMCTE
Where row_number > 1 
Order by PropertyAddress


-- Delete Unused Columns
Select * from PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate






