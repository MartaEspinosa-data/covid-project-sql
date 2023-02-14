SELECT *
FROM covidproject..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 3,4

--SELECT *
--FROM covidproject..CovidVaccinations
--ORDER BY 3,4

-- Select the data that we are going to be using

SELECT Location,date,total_cases,new_cases,total_deaths, population
FROM covidproject..CovidDeaths
ORDER BY 1,2

-- Looking at total cases vs total deaths
-- Shows tje likelihood of dying if you get covid in Spain

SELECT Location,date,total_cases,total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage 
FROM covidproject..CovidDeaths
WHERE location like '%spain%'
ORDER BY 1,2

-- Looking at total cases vs population
-- Shows what percentage of population got covid (7.54% at 2021/4)

SELECT Location,date,total_cases,population, (total_cases/population) * 100 AS CovidPercentage 
FROM covidproject..CovidDeaths
WHERE location like '%spain%'
ORDER BY 1,2

-- Country with the highest infection rate compared to population
-- Andorra is the country with the highest number of infection compared to population

SELECT Location,population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population) * 100 AS Percentofpopulationinfected
FROM covidproject..CovidDeaths
--WHERE location like '%spain%'
GROUP BY location,population
ORDER BY Percentofpopulationinfected DESC

-- Showing countries with highest death count per population. We have to delete the continents.
-- The United States have the highest number of deaths per population follow by Brazil

SELECT Location, MAX(CAST(total_deaths as int)) AS totaldeathcount
FROM covidproject..CovidDeaths
WHERE continent is NOT NULL
GROUP BY location
ORDER BY totaldeathcount DESC

-- Lets analyze the numbers by continent
-- Showing the continents with the highest death count per population

SELECT continent, MAX(CAST(total_deaths as int)) AS totaldeathcount
FROM covidproject..CovidDeaths
WHERE continent is not NULL
GROUP BY continent
ORDER BY totaldeathcount DESC

-- Global numbers

SELECT date, SUM(new_cases) AS totalcases, SUM(CAST(new_deaths AS int)) AS Totaldeaths, SUM(CAST(new_deaths AS int))/SUM(new_cases) *100 AS DeathPercentage
FROM covidproject..CovidDeaths
WHERE continent is NOT NULL
GROUP BY date
ORDER BY 1,2


-- total cases: 150574977

SELECT SUM(new_cases) AS totalcases, SUM(CAST(new_deaths AS int)) AS Totaldeaths, SUM(CAST(new_deaths AS int))/SUM(new_cases) *100 AS DeathPercentage
FROM covidproject..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 1,2

-- join the two tables

SELECT *
FROM covidproject..CovidDeaths dea
JOIN covidproject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date

-- Looking at total population vs total vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM covidproject..CovidDeaths dea
JOIN covidproject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 1,2,3


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS rollingpeoplevaccinated
FROM covidproject..CovidDeaths dea
JOIN covidproject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- USE CTE

WITH PopvsVac (Continent, Location, date, population, new_vaccionations, rollingpeoplevaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS rollingpeoplevaccinated
FROM covidproject..CovidDeaths dea
JOIN covidproject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
)

SELECT *, (rollingpeoplevaccinated/population) * 100
FROM PopvsVac

-- TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated

Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covidproject..CovidDeaths dea
Join covidproject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating view to store data for visualizatons

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covidproject..CovidDeaths dea
Join covidproject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

SELECT *
FROM PercentPopulationVaccinated
