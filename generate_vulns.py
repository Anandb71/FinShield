import os

os.makedirs("multilang_vulns", exist_ok=True)

files = {
    "vuln.js": """
const exec = require('child_process').exec;
function doThing(userInput) {
    // Command Injection
    exec('ls ' + userInput);
}
""",
    "vuln.ts": """
import * as fs from 'fs';
export function readFile(userPath: string) {
    // Path Traversal
    return fs.readFileSync('/var/data/' + userPath);
}
""",
    "vuln.go": """
package main
import (
    "database/sql"
    "fmt"
)
func getUser(db *sql.DB, username string) {
    // SQL Injection
    query := fmt.Sprintf("SELECT * FROM users WHERE name = '%s'", username)
    db.Exec(query)
}
""",
    "vuln.rs": """
use std::process::Command;
pub fn run_cmd(user_input: &str) {
    // Command Injection (if using sh -c)
    Command::new("sh")
        .arg("-c")
        .arg(format!("echo {}", user_input))
        .spawn()
        .expect("failed to execute process");
}
""",
    "vuln.java": """
import java.io.ObjectInputStream;
public class Vuln {
    public void deserialize(java.io.InputStream in) throws Exception {
        // Insecure Deserialization
        ObjectInputStream ois = new ObjectInputStream(in);
        ois.readObject();
    }
}
""",
    "vuln.rb": """
def get_user(name)
  # SQL Injection
  User.where("name = '#{name}'")
  # Command Injection
  system("ping " + name)
end
""",
    "vuln.php": """
<?php
// XSS and Command Injection
$cmd = $_GET['cmd'];
echo "Results for: " . $cmd;
system($cmd);
?>
""",
    "vuln.cs": """
using System.Data.SqlClient;
public class Vuln {
    public void GetUser(string username) {
        // SQL Injection
        string query = "SELECT * FROM users WHERE name = '" + username + "'";
        SqlCommand cmd = new SqlCommand(query);
    }
}
""",
    "vuln.cpp": """
#include <iostream>
#include <cstring>
void process(char* input) {
    // Buffer Overflow
    char buffer[10];
    strcpy(buffer, input);
}
""",
    "vuln.c": """
#include <stdio.h>
void vuln(char *str) {
    // Format String Vulnerability
    printf(str);
}
""",
    "vuln.swift": """
import Foundation
func run(input: String) {
    // Insecure Web Request (SSRF potential)
    let url = URL(string: input)!
    let data = try! Data(contentsOf: url)
}
""",
    "vuln.kt": """
import java.io.File
fun readFile(filename: String) {
    // Path Traversal
    val file = File("/data/" + filename)
    file.readText()
}
""",
    "vuln.scala": """
import scala.sys.process._
object Vuln {
  def run(input: String): Unit = {
    // Command Injection
    s"ls $input".!
  }
}
""",
    "vuln.sh": """
#!/bin/bash
# Command Injection via eval
eval $1
"""
}

for name, content in files.items():
    with open(os.path.join("multilang_vulns", name), "w") as f:
        f.write(content.strip() + "\\n")
