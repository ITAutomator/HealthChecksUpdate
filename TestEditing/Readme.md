# TestEditing

Use TestEditing.ps1 to bulk edit Healthchecks tests

- Creates a dated CSV file of tests (using the API)
- Includes an Action column: None, Delete, Update


## Action: None

This does nothing 

## Action: Delete

Deletes the named test

## Action: Update

Currently, looks in the following columns for changes to be made
- Test name
- Test period
- Test Grace time


