SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4


-- Select DATA that we are going to be using

SELECT population, Location, date, total_cases, total_deaths
FROM PortfolioProject..CovidDeaths
--ORDER BY 1,2




-- Looking at Total Cases vs Total Deaths

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like'%states%'
ORDER BY 1,2




-- Looking at Total Cases vs Population

SELECT Location, date, total_cases, Population, ROUND((total_cases/population)*100, 2) AS CasesPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2




--Looking at Countries with Highest Infection Rate Compared to Population

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
GROUP BY location, population
ORDER BY PercentPopulationInfected desc




-- Showing countries with highest death count per population
-- total_deaths data type is "char" and so will not perform MAX() calculation. Convert data type to integer

SELECT location, MAX(cast(total_deaths as int))as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
GROUP BY location
ORDER BY TotalDeathCount desc

-- Results: location also shows continents and other items like world, high income, Europe, Asia. We only want countries.
-- add: WHERE continent is not null.

SELECT location, MAX(cast(total_deaths as int))as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc


-- SELECT & GROUP BY 'continent' instead location

SELECT continent, MAX(cast(total_deaths as int))as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc

-- Total GLOBAL Death %
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2





-- JOIN CovidDeaths and CovidVaccinations tables on 'location' and 'date'

SELECT *
FROM PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date



--Rolling count of total population vaccinated

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100 This gives an error. We cannot use a column that we just created to perform calculations. Use CTE (Common Table Expressions).
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3




-- NEW CONCEPT
-- USE CTE (Common Table Expression) to perform Calculation on Partition By in previous query

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100 cannot perform calculations on a variable that we just created. Use temp table.
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null AND new_vaccinations is not null
--ORDER BY RollingPeopleVaccinated
)
SELECT  *, ROUND((RollingPeopleVaccinated/population)*100, 3) AS Percent_Vaccinated_Poppulation
FROM PopvsVac
ORDER BY continent, location, date



-- TEMP TABLE

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100 cannot perform calculations on a variable that we just created. Use temp table.
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null AND new_vaccinations is not null
--ORDER BY RollingPeopleVaccinated

SELECT  *, ROUND((RollingPeopleVaccinated/population)*100, 3) AS Percent_Vaccinated_Poppulation
FROM #PercentPopulationVaccinated
ORDER BY continent, location, date




-- Creating View to store data for later

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100 cannot perform calculations on a variable that we just created. Use temp table.
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null AND new_vaccinations is not null
--ORDER BY RollingPeopleVaccinated