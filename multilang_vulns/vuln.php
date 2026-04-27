<?php
// XSS and Command Injection
$cmd = $_GET['cmd'];
echo "Results for: " . $cmd;
system($cmd);
?>\n