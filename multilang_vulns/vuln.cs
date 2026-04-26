using System.Data.SqlClient;
public class Vuln {
    public void GetUser(string username) {
        // SQL Injection
        string query = "SELECT * FROM users WHERE name = '" + username + "'";
        SqlCommand cmd = new SqlCommand(query);
    }
}\n