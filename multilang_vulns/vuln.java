import java.io.ObjectInputStream;
public class Vuln {
    public void deserialize(java.io.InputStream in) throws Exception {
        // Insecure Deserialization
        ObjectInputStream ois = new ObjectInputStream(in);
        ois.readObject();
    }
}\n