#!/bin/bash

# Function to generate a random number between 1 and 1000
function generate_random_number {
  # Generate a random number using $RANDOM
  secret_number=$((RANDOM % 1000 + 1))
}

# Function to check if a username exists in the database
function check_username {
  local username=$1
  local query_result=$(eval "$PSQL -t --no-align -c \"SELECT COUNT(*) FROM users WHERE username = '$username';\"")
  if [ "$query_result" -eq 1 ]; then
    return 0 # Username exists
  else
    return 1 # Username does not exist
  fi
}

# Function to retrieve user information from the database
function get_user_info {
  local username=$1
  local query_result=$(eval "$PSQL -t --no-align -c \"SELECT games_played, best_game FROM users WHERE username = '$username';\"")
  read -r games_played best_game <<<$(echo "$query_result" | tr '|' ' ')
}

# Function to update user information in the database
function update_user_info {
  local username=$1
  local games_played=$2
  local best_game=$3
  eval "$PSQL -c \"UPDATE users SET games_played = $games_played, best_game = $best_game WHERE username = '$username';\" > /dev/null"
}

# Function to add a new user to the database
function add_new_user {
  local username=$1
  local best_game=$2
  eval "$PSQL -c \"INSERT INTO users (username, games_played, best_game) VALUES ('$username', 1, $best_game);\" > /dev/null"
}

# Function to play the Number Guessing Game
function play_game {
  local secret_number
  generate_random_number

  echo "Enter your username:"
  read username

  # Check if the username exists in the database
  check_username "$username"
  local user_exists=$?

  if [ $user_exists -eq 0 ]; then
    # If the username exists, retrieve user information
    get_user_info "$username"
    echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
    games_played=$((games_played + 1))
  else
    # If the username does not exist, add the new user to the database later when the game is completed
    echo "Welcome, $username! It looks like this is your first time here."
    games_played=1
  fi

  echo "Guess the secret number between 1 and 1000:"

  local number_of_guesses=0
  local guess

  while true; do
    read guess

    # Check if the input is an integer
    if ! [[ "$guess" =~ ^[0-9]+$ ]]; then
      echo "That is not an integer, guess again:"
      continue
    fi

    number_of_guesses=$((number_of_guesses + 1))

    if [ "$guess" -eq "$secret_number" ]; then
      echo "You guessed it in $number_of_guesses tries. The secret number was $secret_number. Nice job!"
      # Update user information if necessary
      if [ $user_exists -eq 0 ]; then
        if [ "$best_game" -eq 0 ] || [ "$number_of_guesses" -lt "$best_game" ]; then
          best_game=$number_of_guesses
        fi
        update_user_info "$username" "$games_played" "$best_game"
      else
        add_new_user "$username" "$number_of_guesses"
      fi
      break
    elif [ "$guess" -lt "$secret_number" ]; then
      echo "It's higher than that, guess again:"
    else
      echo "It's lower than that, guess again:"
    fi
  done
}

# Main script starts here
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align"

# Start the Number Guessing Game
play_game
