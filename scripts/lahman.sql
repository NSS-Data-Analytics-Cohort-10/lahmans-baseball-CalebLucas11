-- **Initial Questions**

-- 1. What range of years for baseball games played does the provided database cover? 

SELECT MIN(yearid) AS earliest_year, MAX(yearid) AS oldest_year
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
ORDER BY total_salary DESC;

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

SELECT
    CONCAT(ROUND((yearid - 1920) / 10) * 10 + 1920, '-', ROUND((yearid - 1920) / 10) * 10 + 1929) AS decade,
    ROUND(AVG(so)/AVG(g), 2) AS avg_so,
    ROUND(AVG(hr)/AVG(g), 2) AS avg_hr
FROM teams
WHERE yearid >= 1920
GROUP BY ROUND((yearid - 1920) / 10)
ORDER BY decade;   

-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.
	
SELECT CONCAT(namefirst,' ', namelast) AS full_name, (SUM(sb)*100)/(SUM(sb)+SUM(cs)) AS ssb
FROM people AS p
LEFT JOIN appearances AS a
USING (playerid)
LEFT JOIN teams AS t
USING (teamid)
WHERE a.yearid = 2016
GROUP BY full_name
HAVING (SUM(sb)*100)/(SUM(sb)+SUM(cs)) >= 20
ORDER BY SUM(sb) DESC
LIMIT 1;

--Answer: Eric Fryer, 79

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

--- first part
SELECT yearid, teamid, franchname, MAX(w) AS largest_wins
FROM teams
LEFT JOIN teamsfranchises
USING (franchid)
WHERE yearid >= 1970
    AND wswin = 'N'
GROUP BY yearid, teamid, franchname
ORDER BY largest_wins DESC;

--- second part
SELECT yearid, teamid, franchname, MIN(w) AS largest_wins
FROM teams
LEFT JOIN teamsfranchises
USING (franchid)
WHERE yearid >= 1970
	AND yearid <> 1981
    AND wswin = 'Y'
GROUP BY yearid, teamid, franchname
ORDER BY largest_wins ASC;

--- Union of first and second
SELECT yearid, teamid, franchname, MAX(w) AS wins, 'Non-World Series Winner' AS result
FROM teams
LEFT JOIN teamsfranchises
USING (franchid)
WHERE yearid >= 1970
	AND yearid <> 1981
    AND wswin = 'N'
GROUP BY yearid, teamid, franchname
UNION
SELECT yearid, teamid, franchname, MIN(w) AS wins, 'World Series Winner' AS result
FROM teams
LEFT JOIN teamsfranchises
USING (franchid)
WHERE yearid >= 1970
    AND yearid <> 1981
    AND wswin = 'Y'
GROUP BY yearid, teamid, franchname
ORDER BY wins DESC;

--- Attempt at percentage.
WITH series_losers AS (SELECT yearid, MAX(w) AS maxwins_series_losers	
					FROM teams
						WHERE yearid BETWEEN 1970 AND 2016
								AND wswin='N'
					   			AND yearid <> 1981
					GROUP BY yearid
					ORDER BY yearid DESC),
series_winners AS (SELECT yearid, MIN(w) AS minwins_series_winners
					FROM teams
						WHERE yearid BETWEEN 1970 AND 2016
								AND wswin='Y'
				   				AND yearid <> 1981
					GROUP BY yearid
					ORDER BY yearid DESC)				
SELECT
	ROUND(SUM(CASE WHEN sl.maxwins_series_losers < sw.minwins_series_winners 							THEN 1.00 ELSE 0 END)/COUNT(sw.minwins_series_winners)*100,2) AS percent_of_greater_wins_of_series_winners,
	ROUND(SUM(CASE WHEN sl.maxwins_series_losers > sw.minwins_series_winners 							THEN 1.00 ELSE 0 END)/COUNT(sl.maxwins_series_losers)*100,2) AS percent_of_greater_wins_of_series_losers,
	ROUND(SUM(CASE WHEN sl.maxwins_series_losers = sw.minwins_series_winners 							THEN 1.00 ELSE 0 END)/COUNT(sw.minwins_series_winners)*100,2) AS percent_of_tie_between_losers_winners
FROM series_losers as sl
JOIN series_winners as sw
USING (yearid);

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

--TOP 5
WITH AvgAttendance AS (
    SELECT
        h.park,
        t.name AS team_name,
        SUM(h.attendance) / COUNT(t.ghome) AS average_attendance
    FROM homegames AS h
    JOIN teams AS t ON h.team = t.teamid
    WHERE t.yearid = 2016
    GROUP BY h.park, t.name
    HAVING COUNT(t.ghome) >= 10
)
SELECT park, team_name, average_attendance
FROM AvgAttendance
ORDER BY average_attendance DESC
LIMIT 5;

--BOTTOM 5
WITH AvgAttendance AS (
    SELECT
        h.park,
        t.name AS team_name,
        SUM(h.attendance) / COUNT(t.ghome) AS average_attendance
    FROM homegames AS h
    JOIN teams AS t ON h.team = t.teamid
    WHERE t.yearid = 2016
    GROUP BY h.park, t.name
    HAVING COUNT(t.ghome) >= 10
)
SELECT park, team_name, average_attendance
FROM AvgAttendance
ORDER BY average_attendance ASC
LIMIT 5;

--Added just to see if i could get this all into one query... doesnt look great. 
WITH AvgAttendance AS (
    SELECT
        h.park,
        t.name AS team_name,
        SUM(h.attendance) / COUNT(t.ghome) AS average_attendance
    FROM homegames AS h
    JOIN teams AS t ON h.team = t.teamid
    WHERE t.yearid = 2016
    GROUP BY h.park, t.name
    HAVING COUNT(t.ghome) >= 10
)
(
	SELECT park, team_name, average_attendance
FROM AvgAttendance
ORDER BY average_attendance ASC
LIMIT 5
)
UNION ALL
(
SELECT park, team_name, average_attendance
FROM AvgAttendance
ORDER BY average_attendance DESC
LIMIT 5
);

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

--Need to pull in team without duplicating. 

SELECT DISTINCT(CONCAT(namefirst, ' ', namelast)) AS full_name, a.yearid
FROM awardsmanagers AS a
LEFT JOIN people AS p
USING (playerid)
WHERE awardid = 'TSN Manager of the Year'
AND p.playerid IN (
    SELECT DISTINCT playerid
    FROM awardsmanagers
    WHERE awardid = 'TSN Manager of the Year'
	AND lgid IN ('AL', 'NL')
    GROUP BY playerid
);

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

SELECT CONCAT(p.namefirst, ' ', p.namelast) AS full_name, hr2016
FROM (
    SELECT playerid, MAX(hr) AS career_high_hr, SUM(hr) AS hr2016
    FROM batting
    WHERE yearid = 2016
    GROUP BY playerid
    HAVING SUM(hr) >= 1
) AS player_hr2016
JOIN people AS p ON player_hr2016.playerid = p.playerid
WHERE EXISTS (
    SELECT 1
    FROM (
        SELECT playerid, MAX(yearid) - MIN(yearid) AS years_played
        FROM batting
        GROUP BY playerid
    ) AS player_years
    WHERE player_years.playerid = player_hr2016.playerid
    AND player_years.years_played >= 10
);

-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

---- found CORR function on google, but to be honest im lost as to exactly what its doing. 

WITH WinsSalaries AS (
    SELECT t.yearID, t.teamID, SUM(t.W) AS total_wins, SUM(s.salary) AS total_salary
    FROM teams t
    JOIN salaries s ON t.teamID = s.teamID AND t.yearID = s.yearID
    WHERE t.yearID >= 2000
    GROUP BY t.yearID, t.teamID
)
SELECT yearID, CORR(total_wins, total_salary) AS correlation
FROM WinsSalaries
GROUP BY yearID
ORDER BY yearID;

-- 12. In this question, you will explore the connection between number of wins and attendance.
--     <ol type="a">
--       <li>Does there appear to be any correlation between attendance at home games and number of wins? </li>
--       <li>Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.</li>
--     </ol>

--Homegame Attendance vs. Wins

WITH WinsAttendance AS (
    SELECT
        t.teamID,
        t.yearID,
        SUM(t.W) AS total_wins,
        AVG(h.attendance) AS average_attendance
    FROM teams t
    JOIN homegames h ON t.teamID = h.team
    WHERE t.yearID = 2016
    GROUP BY t.teamID, t.yearID
)
SELECT
    CORR(total_wins, average_attendance) AS correlation
FROM WinsAttendance;

--World Series vs. Following Year Attendance

WITH WorldSeriesWins AS (
    SELECT
        teamID,
        yearID
    FROM teams
    WHERE WSWin = 'Y'  
)
SELECT
    t.teamID,
    wsw.yearID AS world_series_year,
    t.yearID AS attendance_year,
    AVG(h.attendance) AS average_attendance
FROM teams t
JOIN homegames h ON t.teamID = h.team
JOIN WorldSeriesWins wsw ON t.teamID = wsw.teamID
WHERE t.yearID IN (wsw.yearID - 1, wsw.yearID + 1)
GROUP BY t.teamID, wsw.yearID, t.yearID

--Playoffs vs. Following Year Attendance

WITH PlayoffTeams AS (
    SELECT
        teamID,
        yearID
    FROM teams
    WHERE DivWin = 'Y' OR WCWin = 'Y'  
)
SELECT
    t.teamID,
    pt.yearID AS playoff_year,
    t.yearID AS attendance_year,
    AVG(h.attendance) AS average_attendance
FROM teams t
JOIN homegames h ON t.teamID = h.team
JOIN PlayoffTeams pt ON t.teamID = pt.teamID
WHERE t.yearID IN (pt.yearID, pt.yearID + 1)
GROUP BY t.teamID, pt.yearID, t.yearID

-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?

  
  
  
  
  
  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  