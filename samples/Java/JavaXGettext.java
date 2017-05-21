import java.io.*;
import java.util.*;
import org.perl.inline.java.*;

class JavaXGettext extends InlineJavaPerlCaller {
    public JavaXGettext() throws InlineJavaException {
    }

    /* This method gets called for every input file found.  It is supposed
     * to parse the file, extract the PO entries and add them.
     */
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
    
    /* All of the following methods are optional.  You do not have to
     * implement them.  */
    
    /* This method gets called right after all input files have been
     * processed and before the PO entries are sorted.  That means that you
     * can add more entries here.  */
    public void extractFromNonFiles() throws InlineJavaException {
    }

    /* The following methods can also be implemented as class methods.  */

    /*
     * Return an array of arrays with the default keywords of this language.
     */
    public String[][] defaultKeywords() {
    	return new String[][] {
    			{"gettext", "1"},
    			{"ngettext", "1", "2"},
    			{"pgettext", "1c", "2"},
    			{"npgettext", "1c", "2", "3"}
    	};
    }
    
    /* Implement this method if you want to describe the type of input
     * files.  */
    public String fileInformation() {
    	return "Input files are plain text files and are converted into one"
    			+ " PO entry\nfor every non-empty line.";
    }
    
    /* You can add more language specific options here.  It is your
     * responsibility that the option names do not conflict with those of the
     * wrapper.
     */
    public String[][] getLanguageSpecificOptions() {
    	return new String[][] {
            {
            	/* The option specification for Getopt::Long.  If you would
            	 * expect a string argument, you would have to specify
            	 * "test-binding=s" here, see 
            	 * http://search.cpan.org/~jv/Getopt-Long/lib/Getopt/Long.pm 
            	 * for details!
            	 */
   		        "test-binding",
   		        
   		        /* The "name" of the option variable.  This is the argument
   		         * to getOption().
   		         */
   		        "test_binding", 
   		        
   		        /* The option as displayed in the usage description.  The
   		         * leading four spaces compensate for the missing short
   		         * option.
   		         */
   		        "    --test-binding",
   		        
   		        /* The explanation of the option in the usage information.  */
                "print additional information for testing the language binding"
	        }
            /* Add more option specifications here.  */
        };
    }
    
    /* Does the program honor the option -a, --extract-all?  The default
     * implementation returns false.
     */
    public boolean canExtractAll() {
    	return false;
    }
    
    /* Does the program honor the option -k, --keyword?  The default
     * implementation returns true.
     */
    public boolean canKeywords() {
    	return false;
    }
    
    /* Does the program honor the option --flag?  The default implementation 
     * returns true.
     */
    public boolean canFlags() {
    	return false;
    }
       
}
