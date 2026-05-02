use std::process::Command;
pub fn run_cmd(user_input: &str) {
    // Command Injection (if using sh -c)
    Command::new("sh")
        .arg("-c")
        .arg(format!("echo {}", user_input))
        .spawn()
        .expect("failed to execute process");
}\n