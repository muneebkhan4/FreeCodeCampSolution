#!/bin/bash

# Display the numbered list of services
echo "~~~~~ MY SALON ~~~~~"
echo "Welcome to My Salon, how can I help you?"
echo
services_query="SELECT * FROM services;"
services_result=$(psql --username=freecodecamp --dbname=salon -t -P format=unaligned -c "${services_query}")

# Display the services with numbers
while IFS='|' read -r service_id name; do
  echo "${service_id}) ${name}"
done <<< "$services_result"

while true; do
  # Prompt for service selection
  read SERVICE_ID_SELECTED

  # Validate the service selection
  service_validation_query="SELECT name FROM services WHERE service_id = ${SERVICE_ID_SELECTED};"
  service_name_result=$(psql --username=freecodecamp --dbname=salon -t -c "${service_validation_query}" | xargs)

  if [ -n "$service_name_result" ]; then
    # Service with the given id exists, store the service name
    SERVICE_NAME=$service_name_result
    break
  else
    echo
    echo "I could not find that service. What would you like today?"
    # Display the services with numbers again
    while IFS='|' read -r service_id name; do
      echo "${service_id}) ${name}"
    done <<< "$services_result"
  fi
done

# Prompt for phone number, name, and time
echo
echo -n "What's your phone number?"
echo
read CUSTOMER_PHONE

# Check if the phone number exists in the customers table
customer_id_query="SELECT customer_id, name FROM customers WHERE phone = '${CUSTOMER_PHONE}';"
customer_id_result=$(psql --username=freecodecamp --dbname=salon -t -c "${customer_id_query}")

if [ -z "$customer_id_result" ]; then
  # If the phone number does not exist, prompt for the customer name and insert into the customers table
  echo -n "I don't have a record for that phone number, what's your name? "
  read CUSTOMER_NAME
  insert_customer_query="INSERT INTO customers (name, phone) VALUES ('${CUSTOMER_NAME}', '${CUSTOMER_PHONE}') RETURNING customer_id;"
  customer_id=$(psql --username=freecodecamp --dbname=salon -t -c "${insert_customer_query}" | awk 'NR==1{print $1}')
else
  # If the phone number exists, extract the customer name and customer_id
  CUSTOMER_NAME=$(echo "$customer_id_result" | cut -d "|" -f 2 | tr -d ' ')
  customer_id=$(echo "$customer_id_result" | cut -d "|" -f 1 | tr -d ' ')
fi

# Prompt for service time and validate the time format
echo
echo -n "What time would you like your ${SERVICE_NAME}, ${CUSTOMER_NAME}?"
echo
read SERVICE_TIME

# Insert the appointment into the appointments table
insert_appointment_query="INSERT INTO appointments (customer_id, service_id, time) VALUES (${customer_id}, ${SERVICE_ID_SELECTED}, '${SERVICE_TIME}');"
psql --username=freecodecamp --dbname=salon -q -c "${insert_appointment_query}"

# Display the confirmation message
echo
echo "I have put you down for a ${SERVICE_NAME} at ${SERVICE_TIME}, ${CUSTOMER_NAME}."
