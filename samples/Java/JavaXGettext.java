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
     * can add more entries here.
     *
     * In this example we don't add any strings here but rather abuse the
     * method for showing advanced stuff like getting option values or
     * interpreting keywords.  Invoke the extractor with the option
     * "--test-binding" in order to see this in action.  */
    public void extractFromNonFiles() throws InlineJavaException,
                                             InlineJavaPerlException {
        /* Check whether --test-binding was specified.  */
        Object test = CallPerlStaticMethod("Locale::XGettext::Callbacks",
                                            "option",
                                            new Object [] {
                                                "test_binding"
                                            });
        if (test != null) {
            JavaXGettextKeywords keywords = (JavaXGettextKeywords)
                    CallPerlStaticMethod("Locale::XGettext::Callbacks",
                            "option",
                            new Object [] {
                                    "keyword"
                            });

            Iterator it = keywords.entrySet().iterator();
            while (it.hasNext()) {
                Map.Entry kv = (Map.Entry) it.next();

                String method = (String) kv.getKey();
                JavaXGettextKeyword keyword = (JavaXGettextKeyword) kv.getValue();

                System.out.println("method: " + method);

                Integer context = keyword.context();
                if (context != null) {
                    System.out.println("  message context: argument #" + context);
                } else {
                    System.out.println("  message context: [none]");
                }

                int[] forms = keyword.forms();
                System.out.println("  singular form: " + forms[0]);
                if (forms.length > 1) {
                    System.out.println("  plural form: " + forms[1]);
                } else {
                    System.out.println("  plural form: [none]");
                }

                String comment = keyword.comment();
                System.out.println("  automatic comment: " + comment);
            }
        }
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
    public String[][] languageSpecificOptions() {
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

/**
 * The Java equivalent of the Perl class Locale::XGettext::Util::Keyword.
 */
class JavaXGettextKeyword {
    String method;
    int[] forms;
    Integer context;
    String comment;

    /**
     * Create one keyword definition.
     *
     * All indices used here are 1-based not 0-based!
     *
     * @param method                the name of the method
     * @param singular              the index of the argument containing the
     *                              singular form
     * @param plural                the index of the argument containing the
     *                              plural form or null
     * @param context               the index of the argument containing the
     *                              message context or null
     * @param comment               an automatic comment or null
     * @throws InlineJavaException  thrown for invalid usages
     */
    public JavaXGettextKeyword(String method, Integer singular, Integer plural,
                               Integer context, String comment)
            throws InlineJavaException {
        this.method = method;
        if (singular < 1)
            throw new InlineJavaException("Singular must always be defined");
        if (plural > 0) {
            this.forms = new int[2];
            this.forms[1] = plural;
        } else {
            this.forms = new int[1];
        }
        this.forms[0] = singular;
        if (context > 0)
            this.context = context;
        if (comment != null)
            this.comment = comment;
    }

    /**
     * The name of the method.
     *
     * @return  the method name
     */
    public String method() {
        return this.method;
    }

    /**
     * Return the indices of the singular and plural form.  The array has
     * either one or two elements, depending on whether a plural form is
     * defined.
     *
     * @return      indices of singular and plural forms
     */
    public int[] forms() {
        return this.forms;
    }

    /**
     * Argument for the message context.
     *
     * @return      index of the message context argument or null
     */
    public Integer context() {
        return this.context;
    }

    public String comment() {
        return this.comment;
    }
}

/* This is just here so that Perl knows about the class.  */
class JavaXGettextKeywords extends HashMap {
    public JavaXGettextKeywords() {

    }
}
