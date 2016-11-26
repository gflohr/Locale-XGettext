import java.io.*;
import java.util.*;
import org.perl.inline.java.*;

class JavaXGettext extends InlineJavaPerlCaller {
    public JavaXGettext() throws InlineJavaException {
    }

    public void readFile(String filename) 
            throws InlineJavaException, InlineJavaPerlException,
                   FileNotFoundException, IOException {
        BufferedReader r = new BufferedReader(new FileReader(filename));
        int lineno = 0;

        for(String line; (line = r.readLine()) != null; ) {
            ++lineno;

            if (line.equals(""))
                continue;
            CallPerlStaticMethod("Locale::XGettext::Callbacks", 
                                 "addEntry", 
                                 new Object [] {
                                     "msgid", line + "\n",
                                     "reference", filename + ':' + lineno,
                                 }, 
                                 Integer.class);
        }
    }
    
    public static String[][] getLanguageSpecificOptions() {
    	String test_options[] = {
    		 "test-binding", "test_binding", "    --test-binding",
             "print additional information for testing the language binding"
    	};
    	
    	return new String[][] { test_options };
    }
}
