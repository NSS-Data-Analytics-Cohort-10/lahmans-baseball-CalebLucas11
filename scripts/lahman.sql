-- **Initial Questions**

-- 1. What range of years for baseball games played does the provided database cover? 

SELECT MIN(yearid), MAX(yearid)
FROM teams;

-- Answer: 1871-2016

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
 
SELECT namefirst, namelast, franchname, MIN(height) AS shortest_player, g_all
FROM people 
LEFT JOIN appearances 
USING (playerid)
LEFT JOIN teams 
USING(teamid)
LEFT JOIN teamsfranchises
USING (franchid)
GROUP BY namefirst, namelast, franchname, g_all
HAVING MIN(height) IS NOT NULL
ORDER BY shortest_player ASC
LIMIT 1;

-- Answer: Eddie Gaedel, 43 inches tall (3' 6"), Baltimore Orioles

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

-- How do i get around the repeating years in collegeplaying. 

SELECT CONCAT(namefirst, ' ', namelast) AS full_name, SUM(DISTINCT salary) AS total_salary
FROM people
LEFT JOIN salaries AS s
USING (playerid)
LEFT JOIN collegeplaying
USING (playerid)
LEFT JOIN schools AS sch
USING (schoolid)
WHERE schoolid ILIKE '%vandy%' 
GROUP BY full_name, playerid
HAVING SUM(salary) IS NOT NULL
ORDER BY total_salary DESC
LIMIT 1;

SELECT *
FROM people
LEFT JOIN salaries
USING (playerid)
LEFT JOIN collegeplaying
USING (playerid)
WHERE playerid LIKE 'priceda01'

-- Answer: David Price, $81,851,296
	
-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

SELECT 
	CASE WHEN pos = 'OF' THEN 'Outfield'
	WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
	WHEN pos IN ('P', 'C') THEN 'Battery'
	ELSE 'Other'
	END AS position,
	SUM(po) AS total_putouts
FROM fielding
WHERE yearid = 2016
GROUP BY position
ORDER BY position;

-- Answer: Battery (41,424), Infield (58,934), Outfield (29,560)
   
-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

--why does 1 pull decade, but 2 pulls year?

SELECT
    CONCAT(ROUND((yearid - 1920) / 10) * 10 + 1920, '-', ROUND((yearid - 1920) / 10) * 10 + 1929) AS decade,
    ROUND(AVG(so)/AVG(g), 2) AS avg_strikeouts,
    ROUND(AVG(hr)/AVG(g), 2) AS avg_homeruns
FROM teams
WHERE yearid >= 1920
GROUP BY ROUND((yearid - 1920) / 10)
ORDER BY decade;

SELECT
    CONCAT(ROUND(yearid), '-', ROUND(yearid)) AS decade,
    ROUND(AVG(so)/AVG(g), 2) AS avg_strikeouts,
    ROUND(AVG(hr)/AVG(g), 2) AS avg_homeruns
FROM teams
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade;  
   

-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.
	
-- Need to double check this. 
SELECT CONCAT(namefirst,' ', namelast) AS full_name, (SUM(sb)*100)/(SUM(sb)+SUM(cs)) AS ssb
FROM people AS p
LEFT JOIN appearances AS a
USING (playerid)
LEFT JOIN teams AS t
USING (teamid)
WHERE a.yearid = 2016
GROUP BY full_name
HAVING (SUM(sb)*100)/(SUM(sb)+SUM(cs)) >= 20
ORDER BY SUM(sb) DESC;

--Answer: Eric Fryer, 79

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

SELECT yearid, teamid, franchname, MAX(w) AS largest_wins
FROM teams
LEFT JOIN teamsfranchises
USING (franchid)
WHERE yearID >= 1970
    AND wswin = 'N'
GROUP BY yearid, teamid, franchname
ORDER BY largest_wins DESC;

SELECT yearid, teamid, franchname, MIN(w) AS largest_wins
FROM teams
LEFT JOIN teamsfranchises
USING (franchid)
WHERE yearID >= 1970
    AND wswin = 'Y'
GROUP BY yearid, teamid, franchname
ORDER BY largest_wins ASC;

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.


-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.


-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.
--     <ol type="a">
--       <li>Does there appear to be any correlation between attendance at home games and number of wins? </li>
--       <li>Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.</li>
--     </ol>


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?

  
  
  
  
  
  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  