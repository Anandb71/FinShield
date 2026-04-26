package main
import (
    "database/sql"
    "fmt"
)
func getUser(db *sql.DB, username string) {
    // SQL Injection
    query := fmt.Sprintf("SELECT * FROM users WHERE name = '%s'", username)
    db.Exec(query)
}\n