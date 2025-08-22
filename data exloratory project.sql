-- ============================================================
-- EXPLORATORY DATA ANALYSIS (EDA) ON LAYOFFS DATA USING MYSQL
-- ==============================================================

-- Purpose: To explore the layoffs data after cleaning
-- We check totals, trends, and rankings step by step.

-- 1) Show all rows in the table.
SELECT * FROM layoffs_staging2;

-- 2) Find the biggest layoff in one record 
-- and the highest layoff percentage (1 = 100%)
SELECT MAX(total_laid_off), MAX(percentage_laid_off) 
FROM layoffs_staging2;

-- 3) Show companies where 100% of staff were laid off 
-- (company shutdowns), sorted by funds raised
SELECT * 
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- 4) Total layoffs by company (which company cut most people)
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2 
GROUP BY company
ORDER BY 2 DESC;

-- 5) First and last date in the data (time range)
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- 6) Total layoffs by industry
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2 
GROUP BY industry
ORDER BY 2 DESC;

-- 7) Total layoffs by country
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2 
GROUP BY country
ORDER BY 2 DESC;

-- 8) Total layoffs by each day
SELECT `date`, SUM(total_laid_off)
FROM layoffs_staging2 
GROUP BY `date`
ORDER BY 1 DESC;

-- 9) Total layoffs by year
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2 
GROUP BY YEAR(`date`)
ORDER BY 1 DESC; 

-- 10) Total layoffs by funding stage (Seed, Series A, IPO, etc.)
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2 
GROUP BY stage
ORDER BY 2 DESC; 

-- 11) Sum of layoff percentages by company 
-- (Note: better to use AVG instead of SUM for real meaning)
SELECT company, SUM(percentage_laid_off)
FROM layoffs_staging2 
GROUP BY company
ORDER BY 2 DESC;

-- 12) Monthly layoffs trend (YYYY-MM format)
SELECT SUBSTRING(`date`,1,7) AS month,
       SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY month
ORDER BY 1 ASC;

-- 13) Rolling total (cumulative) layoffs over months
WITH Rolling_Total AS (
    SELECT SUBSTRING(`date`,1,7) AS month,
           SUM(total_laid_off) AS total_off
    FROM layoffs_staging2
    WHERE SUBSTRING(`date`,1,7) IS NOT NULL
    GROUP BY month
)
SELECT month, 
       total_off,
       SUM(total_off) OVER (ORDER BY month) AS rolling_total
FROM Rolling_Total;

-- 14) Layoffs by company and year together
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2 
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC; 

-- 15) Ranking companies inside each year
-- Step 1: Get total layoffs per company per year
WITH company_year (company, years, total_laid_off) AS (
    SELECT 
        company, 
        YEAR(`date`), 
        SUM(total_laid_off)
    FROM layoffs_staging2
    GROUP BY company, YEAR(`date`)
), 
-- Step 2: Give rank (1 = highest layoffs) for each year
ranking AS (
    SELECT 
        company,
        years,
        total_laid_off,
        DENSE_RANK() OVER (
            PARTITION BY years 
            ORDER BY total_laid_off DESC
        ) AS rank_in_year
    FROM company_year 
    WHERE years IS NOT NULL
)
-- Step 3: Show companies ranked lower than Top 5
-- (If you want Top 5 → use <= 5 instead of > 5)
SELECT * 
FROM ranking 
WHERE rank_in_year > 5;
