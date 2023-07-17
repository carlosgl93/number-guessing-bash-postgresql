#!/bin/bash

echo "Enter your username:"
read USERNAME

PSQL="psql -X --username=freecodecamp --dbname=number_guess -t --no-align -c"

DB_USER=$($PSQL "select * from users where username = '$USERNAME'")

if [[ -z $DB_USER ]]
then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  INSERT_NEW_USER=$($PSQL "insert into users(username, games_played) values('$USERNAME', 0)")
else
  echo $DB_USER | while IFS="|" read USERID USERNAME GAMES_PLAYED BEST_GAME
  do
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done
fi

SECRET_NUMBER=$(( $RANDOM % 1000 + 1 ))
GUESSES_NUMBER=1
echo "Guess the secret number between 1 and 1000:"
read GUESS

GUESS_SECRET_NUMBER () {
  echo $SECRET_NUMBER
  if [[ ! $1 =~ ^[0-9]+$ ]]
    then 
    echo "That is not an integer, guess again:"
    read GUESS
    GUESS_SECRET_NUMBER $GUESS
  fi
  if [[ $1 > $SECRET_NUMBER ]]
  then 
    ((GUESSES_NUMBER+=1))
    echo "It's lower than that, guess again:"
    read GUESS
    GUESS_SECRET_NUMBER $GUESS
  elif [[ $1 < $SECRET_NUMBER ]]
  then
    ((GUESSES_NUMBER+=1))
    echo "It's higher than that, guess again:"
    read GUESS
    GUESS_SECRET_NUMBER $GUESS
  else
    ((GUESSES_NUMBER+=1))
    BEST_GAME=$($PSQL "select best_game from users where username = '$USERNAME'")
    echo "$BEST_GAME = best game, guesses number: $GUESSES_NUMBER"
    if [[ $GUESSES_NUMBER -lt $BEST_GAME ]]
    then
      UPDATE_USER_DATA=$($PSQL "UPDATE USERS SET best_game = $GUESSES_NUMBER where username = '$USERNAME'")
    fi
    GAMES_PLAYED_BEFORE=$($PSQL "SELECT games_played from users where username = '$USERNAME'")
    UPDATE_USER_GAMES=$($PSQL "UPDATE USERS SET games_played = (( $GAMES_PLAYED_BEFORE + 1 )) where username = '$USERNAME'")
    echo "You guessed it in $GUESSES_NUMBER tries. The secret number was $SECRET_NUMBER. Nice job!"
  fi
}

GUESS_SECRET_NUMBER $GUESS

