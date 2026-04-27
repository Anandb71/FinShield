def get_user(name)
  # SQL Injection
  User.where("name = '#{name}'")
  # Command Injection
  system("ping " + name)
end\n