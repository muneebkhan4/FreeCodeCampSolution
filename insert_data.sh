#! /bin/bash

if [[ $1 == "test" ]]; then
  PSQL="psql --username=postgres --dbname=worldcuptest"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

# Truncate existing data from tables
$PSQL -c "TRUNCATE TABLE games, teams;"

# Create teams table
$PSQL -c "CREATE TABLE teams (
  team_id SERIAL PRIMARY KEY,
  name VARCHAR UNIQUE NOT NULL
);"

# Create games table
$PSQL -c "CREATE TABLE games (
  game_id SERIAL PRIMARY KEY,
  year INT NOT NULL,
  round VARCHAR NOT NULL,
  winner_id INT NOT NULL,
  opponent_id INT NOT NULL,
  winner_goals INT NOT NULL,
  opponent_goals INT NOT NULL,
  FOREIGN KEY (winner_id) REFERENCES teams (team_id),
  FOREIGN KEY (opponent_id) REFERENCES teams (team_id)
);"

# Read data from games.csv and insert unique teams into the teams table
awk -F, 'NR > 1 { print $3; print $4 }' games.csv | sort | uniq | while read -r team; do
  $PSQL -c "INSERT INTO teams (name) VALUES ('$team');"
done

# Insert data into games table with correct team IDs
awk -F, 'NR > 1 { print $1 "," $2 "," $3 "," $4 "," $5 "," $6 }' games.csv | while IFS=, read -r year round winner opponent winner_goals opponent_goals; do
  winner_id=$($PSQL -t -c "SELECT team_id FROM teams WHERE name = '$winner';")
  opponent_id=$($PSQL -t -c "SELECT team_id FROM teams WHERE name = '$opponent';")
  $PSQL -c "INSERT INTO games (year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES ($year, '$round', $winner_id, $opponent_id, $winner_goals, $opponent_goals);"
done
