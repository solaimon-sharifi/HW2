% Assignment Submission

# SQL Steps and Outputs

Below are the outputs from the automated scripts. For grading, please replace the image placeholders with your pgAdmin screenshots (Query Tool showing SQL and results).

## A) CREATE TABLES

![A - Create tables](../screenshots/step_A_create.png)

-- Console output:

{{STEP_A_CREATE_USERS}}

{{STEP_A_CREATE_CALCULATIONS}}

## B) INSERT RECORDS

![B - Insert records](../screenshots/step_B_insert.png)

-- Console output (users):

{{STEP_B_INSERT_USERS}}

-- Console output (calculations):

{{STEP_B_INSERT_CALCULATIONS}}

## C) QUERY DATA

-- Screenshot placeholder: SELECT * FROM users result grid

![C - Select users](../screenshots/step_C_select_users.png)

-- Users:

{{STEP_C_SELECT_USERS}}

-- Screenshot placeholder: SELECT * FROM calculations result grid

![C - Select calculations](../screenshots/step_C_select_calculations.png)

-- Calculations:

{{STEP_C_SELECT_CALCULATIONS}}

-- Screenshot placeholder: JOIN query result

![C - Join results](../screenshots/step_C_join.png)

-- JOIN results:

{{STEP_C_JOIN}}

## D) UPDATE A RECORD

![D - Update calculation](../screenshots/step_D_update.png)

-- Update console output:

{{STEP_D_UPDATE}}

-- Select updated row:

{{STEP_D_SELECT_UPDATED}}

## E) DELETE A RECORD

![E - Delete calculation](../screenshots/step_E_delete.png)


{{STEP_E_DELETE}}


{{STEP_E_SELECT_AFTER_DELETE}}

## API examples (curl)

-- API health check:

{{API_1_HEALTH}}

-- List users before:

{{API_2_LIST_USERS_BEFORE}}

-- Create user carol:

{{API_3_CREATE_USER_CAROL}}

-- List users after:

{{API_4_LIST_USERS_AFTER}}

-- Calculations before:

{{API_5_LIST_CALCULATIONS_BEFORE}}

-- Create calculation (carol):

{{API_6_CREATE_CALCULATION}}

-- Calculations after:

{{API_7_LIST_CALCULATIONS_AFTER}}

-- Join view:

{{API_8_CALCULATIONS_JOIN}}

-- Update calc id=1 via API:

{{API_9_UPDATE_CALC_1}}

-- Calculations after update:

{{API_9_SELECT_CALC_1}}

-- Delete calc id=2 via API:

{{API_10_DELETE_CALC_2}}

-- Calculations after delete:

{{API_10_SELECT_AFTER_DELETE}}

-- Update user id=3 via API:

{{API_11_UPDATE_USER_3}}

-- Users after update:

{{API_11_SELECT_USER_LIST}}

-- Delete user id=3 via API:

{{API_12_DELETE_USER_3}}

-- Users after delete:

{{API_12_SELECT_USER_LIST_AFTER_DELETE}}

## Screenshots

Please insert your pgAdmin screenshots here (or append them to the generated PDF).

1. pgAdmin login page screenshot
2. Server configuration screenshot
3. SELECT * FROM users result grid screenshot
4. JOIN query result screenshot

---

End of submission template.
