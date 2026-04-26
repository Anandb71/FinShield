// Vulnerable Legacy JS
const args = process.argv.slice(2);
const payload = args[0];

if (payload) {
    // SINK: Arbitrary Code Execution in JS
    console.log(eval(payload));
}\n