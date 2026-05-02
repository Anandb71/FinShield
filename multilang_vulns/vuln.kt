import java.io.File
fun readFile(filename: String) {
    // Path Traversal
    val file = File("/data/" + filename)
    file.readText()
}\n