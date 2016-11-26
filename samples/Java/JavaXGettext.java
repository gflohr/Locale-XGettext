import java.util.*;
import org.perl.inline.java.*;

class JavaXGettext extends InlineJavaPerlCaller {
    public JavaXGettext() throws InlineJavaException {
    }

    public void readFile(String filename) 
            throws InlineJavaException, InlineJavaPerlException {
        CallPerlStaticMethod("Locale::XGettext::Callbacks", 
                             "addEntry", 
                             new Object [] {
                                 "msgid", "Hello, world!",
                                 "reference", filename + ":2304",
                             }, 
                             Integer.class);
    }
}
