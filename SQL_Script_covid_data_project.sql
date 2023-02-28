----------------------------------------------------------------------------------------
-- WELCOME to Viranchi's SQL Covid Data Project Script
----------------------------------------------------------------------------------------
/*
Activities performed in this script:
	-visually inspect all data
	-choose data that will be used
	-show Total Cases vs Total Deaths
	-show Total Cases vs Total Deaths
	-show Total Cases vs Population
	-show Countries with Highest Infection Percentage
	-show Countries with Highest Death Count
	-show Continents with Highest Death Count
	-show Total Global Death %
	-JOIN CovidDeaths and CovidVaccinations tables on 'location' and 'date'
	-show Sum of People Vaccinated Partitioned By Location
	-show Percent of Vaccinated Population using CTE (Common Table Expression)
	-show Percent of Vaccinated Population using TEMP TABLE
	-create View to store data for later
*/



-- visually inspect all data
SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4


----------------------------------------------------------------------------------------
-- choose data that will be used
SELECT population, Location, date, total_cases, total_deaths
FROM PortfolioProject..CovidDeaths



----------------------------------------------------------------------------------------
-- show Total Cases vs Total Deaths
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like'%states%'
ORDER BY 1,2



----------------------------------------------------------------------------------------
-- show Total Cases vs Population
SELECT Location, date, total_cases, Population, ROUND((total_cases/population)*100, 2) AS CasesPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2



----------------------------------------------------------------------------------------
-- show Countries with Highest Infection Percentage 
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected desc



----------------------------------------------------------------------------------------
-- show Countries with Highest Death Count
SELECT location, MAX(cast(total_deaths as int))as TotalDeathCount -- total_deaths data type is "char" and so will not perform MAX() calculation. Convert data type to integer
FROM PortfolioProject..CovidDeaths
GROUP BY location
ORDER BY TotalDeathCount desc

-- Results: Location shows countries and other fields like world, high income, Europe, Asia. We only want countries.
-- After visually inspecting data columns, it is observed that Location fields which are not countries have "null" values in the continent column.
-- To exclude these fields add:  WHERE continent is not null.

SELECT location, MAX(cast(total_deaths as int))as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc



----------------------------------------------------------------------------------------
-- show Continents with Highest Death Count
SELECT continent, MAX(cast(total_deaths as int))as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc



----------------------------------------------------------------------------------------

-- show Total Global Death %
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2



----------------------------------------------------------------------------------------
-- JOIN CovidDeaths and CovidVaccinations tables on 'location' and 'date'
SELECT *
FROM PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date



----------------------------------------------------------------------------------------
-- show Sum of People Vaccinated Partitioned By Location
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100 This gives an error. We cannot use a column that we just created to perform calculations. Use CTE (Common Table Expressions).
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null AND new_vaccinations is not null
order by 2,3



----------------------------------------------------------------------------------------
-- show Percent of Vaccinated Population using 
-- CTE (Common Table Expression)

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



----------------------------------------------------------------------------------------
-- show Percent of Vaccinated Population using 
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



----------------------------------------------------------------------------------------
-- create View to store data for later

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