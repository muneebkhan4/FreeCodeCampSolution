#!/bin/bash

# Check if an argument is provided
if [ $# -eq 0 ]; then
  echo "Please provide an element as an argument."
  exit 0
fi

# Function to fetch element details by atomic number, symbol, or name
get_element_details() {
  PSQL="psql --username=freecodecamp --dbname=periodic_table -t --no-align -c"

  # Check if the argument is a number (atomic number)
  if [[ $1 =~ ^[0-9]+$ ]]; then
    ELEMENT_QUERY="SELECT elements.atomic_number, elements.symbol, name, atomic_mass, melting_point_celsius, boiling_point_celsius, type FROM elements
                    JOIN properties ON elements.atomic_number = properties.atomic_number
                    JOIN types ON properties.type_id = types.type_id
                    WHERE elements.atomic_number = $1;"
  else
    # Otherwise, check if it's a symbol or name (case-insensitive)
    ELEMENT_QUERY="SELECT elements.atomic_number, elements.symbol, name, atomic_mass, melting_point_celsius, boiling_point_celsius, type FROM elements
                    JOIN properties ON elements.atomic_number = properties.atomic_number
                    JOIN types ON properties.type_id = types.type_id
                    WHERE UPPER(elements.symbol) = UPPER('$1') OR UPPER(elements.name) = UPPER('$1');"
  fi

  ELEMENT_DETAILS=$($PSQL "$ELEMENT_QUERY")

  # Check if the query returned any results
  if [ -z "$ELEMENT_DETAILS" ]; then
    echo "I could not find that element in the database."
  else
    # Extract element details and display the output
    IFS='|' read -ra ELEMENT_INFO <<< "$ELEMENT_DETAILS"
    atomic_number="${ELEMENT_INFO[0]}"
    symbol="${ELEMENT_INFO[1]}"
    name="${ELEMENT_INFO[2]}"
    atomic_mass="${ELEMENT_INFO[3]}"
    melting_point_celsius="${ELEMENT_INFO[4]}"
    boiling_point_celsius="${ELEMENT_INFO[5]}"
    type="${ELEMENT_INFO[6]}"

    echo "The element with atomic number $atomic_number is $name ($symbol). It's a $type, with a mass of $atomic_mass amu. $name has a melting point of $melting_point_celsius celsius and a boiling point of $boiling_point_celsius celsius."
  fi
}

# Call the function with the provided argument
get_element_details "$1"
