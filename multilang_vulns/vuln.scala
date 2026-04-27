import scala.sys.process._
object Vuln {
  def run(input: String): Unit = {
    // Command Injection
    s"ls $input".!
  }
}\n