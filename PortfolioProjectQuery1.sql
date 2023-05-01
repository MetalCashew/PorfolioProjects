SELECT *
FROM PortfolioProject..CovidDeaths
order by 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--order by 3,4

-- Select the data we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS float)/CAST(total_cases AS float))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
order by 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got covid

SELECT location, date, Population, total_cases, (CAST(total_cases AS decimal)/CAST(population AS decimal))*100 AS CasePercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
order by 1, 2

-- Looking at countries ith the highest infection rate compared to population

SELECT location, Population, MAX(total_cases) as HighestInfectionCount, MAX(CAST(total_cases AS decimal)/CAST(population AS decimal))*100 AS CasePercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
Group by location, population
order by CasePercentage desc

-- Showing countries with the highest death count per population

SELECT location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
Group by location
order by TotalDeathCount desc

-- Let's break things down by continent
-- Showing continents with the highest death count per population

SELECT Location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is null
Group by Location
order by TotalDeathCount desc

-- Global Numbers

--SET ARITHABORT OFF
--SET ANSI_WARNINGS OFF
SELECT Date, SUM(new_cases) AS TotalNewCases, SUM(cast(new_deaths as int)) AS TotalNewDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP by date
order by 1,2


SELECT Date, SUM(new_cases) AS TotalNewCases, SUM(cast(new_deaths as int)) AS TotalNewDeaths, 
	CASE
		WHEN new_cases = NULL
		THEN 0
		ELSE SUM(cast(new_deaths as int))/SUM(new_cases)*100
	END AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP by date
order by 1,2

-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingVaccinatedCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
	and vac.new_vaccinations is not null
ORDER by 2,3

-- Using CTE

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingVaccinatedCount)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingVaccinatedCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
	and vac.new_vaccinations is not null
)
Select *, (RollingVaccinatedCount/Population)*100 as RollingVaccinatedPercentage
FROM PopvsVac
WHERE Location like '%states%'
Order by 2,3

-- TEMP TABLE

Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingVaccinatedCount numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingVaccinatedCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
	and vac.new_vaccinations is not null

Select *, (RollingVaccinatedCount/Population)*100 as RollingVaccinatedPercentage
FROM #PercentPopulationVaccinated
--WHERE Location like '%states%'
Order by 2,3

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingVaccinatedCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
	and vac.new_vaccinations is not null