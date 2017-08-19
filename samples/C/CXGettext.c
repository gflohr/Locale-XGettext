/*
 * "perl.h" that in turn includes "stdio.h" was automatically included by
 * Inline::C.
 */
#include <stdio.h>
#include <sys/types.h>
#include <limits.h>
#include <math.h>

/*
 * We inevitably have to use glue code between Perl and C here, even
 * if we are using Inline::C.  If you are really interested, read
 * "perldoc perlapi" and "perldoc perlcall" for FMTYEWTK.  But the
 * sample code should contain Cut & Paste templates for everything
 * that you need.  Note that we use stack macros from "INLINE.h" 
 * here that are a little bit more readable. see
 * http://search.cpan.org/~tinita/Inline-C/lib/Inline/C.pod#THE_INLINE_STACK_MACROS
 * for more details!
 *
 * All C functions are in the namespace of the extractor class and are
 * therefore automatically methods.
 */

/* Some helper functions and definitions.  Note that static functions are
 * not visible to Perl.
 */
struct keyword {
        /* The name of the method.  */
        const char *method;

        /* Position of singular form.  */
        unsigned int singular;

        /* Position of plural form or 0.  */
        unsigned int plural;

        /* Position of message context argument or 0.  */
        unsigned int context;

        /* Automatic comment for that keyword or NULL.  */
        const char *comment;
};

/* Get all keyword definitions (default keywords and those specified
 * on the commandline).  The list is NULL-terminated and should be 
 * freed with free_keywords().
 */
 static struct keyword **keywords(SV *self);
 
/* Free all resources associated with the set of keywords.  */
static void free_keywords(struct keyword **keywords);

/* Free all resources associated with one keyword.  */
static void free_keyword(struct keyword *keyword);

/* Get value of a certain option.  */
static SV *option(SV *self, const char *option);

/*
 * The most important method.
 */
void 
readFile(SV *self, const char *filename)
{
        FILE *fp = fopen(filename, "r");
        char *line = NULL;
        size_t linecap = 0;
        ssize_t linelen;
        unsigned lineno = 0;
        size_t reflen = strlen(filename) + 3 + (size_t) floor(log10(UINT_MAX));
        char *reference;

        if (!fp) {

               croak("Unable to open open '%s': %s", 
                     filename, strerror(errno));
        }

        reference = malloc(reflen);
        
        while ((linelen = getline(&line, &linecap, fp)) > 0) {
                /* When calling a Perl method we have to use the regular
                 * macros from the Perl API, not the Inline stack
                 * macros.
                 */
                dSP; /* Declares a local copy of the Perl stack.  */

                snprintf(reference, reflen, "%s:%u", filename, ++lineno);

                /* We have to call the method "addEntry().  For that we
                 * have to push the instance (variable "self") on the
                 * Perl stack followed by all the arguments.  
                 */

                ENTER;
                SAVETMPS;

                PUSHMARK(SP);

                /* Make space for five items on the stack.  That has to
                 * be 6 if you also want to pass a comment.
                 */
                EXTEND(SP, 5);

                /* The first item on the stack must be the instance
                 * that the method is called upon.
                 */
                PUSHs(self);

                /* The second argument to newSVpv is the length of the
                 * string.  If you pass 0 then the length is calculated
                 * using strlen().
                 */
                PUSHs(sv_2mortal(newSVpv("msgid", 5)));
                PUSHs(sv_2mortal(newSVpv(line, 0)));
                PUSHs(sv_2mortal(newSVpv("reference", 9)));
                PUSHs(sv_2mortal(newSVpv(reference, 0)));
                /* PUSHs(sv_2mortal(newSVpv(comment, 0))); */
                PUTBACK;

                call_method("addEntry", G_DISCARD);

                FREETMPS;
                LEAVE;
                /* Done calling the Perl method.  */
        }

        free(reference);
}

/* All of the following methods are optional.  You do not have to
 * implement them.  
 */

/* This method gets called right after all input files have been
 * processed and before the PO entries are sorted.  That means that you
 * can add more entries here.
 *
 * In this example we don't add any strings here but rather abuse the
 * method for showing advanced stuff like getting option values or
 * interpreting keywords.  Invoke the extractor with the option
 * "--test-binding" in order to see this in action.  
 */
void
extractFromNonFiles(SV *self)
{
        struct keyword **records;
        struct keyword **crs;
        struct keyword *keyword;

        if (!SvTRUE(option(self, "test_binding")))
               return;

        puts("Keyword definitions:");

        records = crs = keywords(self);

        while (*crs) {
                keyword = *crs;
                printf("method: %s\n", keyword->method);
                ++crs;
        }

        free_keywords(records);
}

/* Describe the type of input files.  */
char *
fileInformation(SV *self)
{
    /* For simple types like this, the return value is automatically
     * converted.  No need to use the Perl API.
     */
    return "\
Input files are plain text files and are converted into one PO entry\n\
for every non-empty line.";
}

/* Return an array with the default keywords.  This is only used if the
 * method canKeywords() (see below) returns a truth value.  For the lines
 * extractor you would rather return None or an empty array.
 */
SV *
defaultKeywords(SV *self)
{
        /* We have to return a hash of arrays which is not trivial.
         * Alternatively, you can define the method inside xgettext-lines.pl
         * in Perl.
         */
        HV *keywords = newHV();
        AV *gettext = newAV();
        AV *ngettext = newAV();
        AV *pgettext = newAV();
        AV *npgettext = newAV();

        av_push(gettext, newSViv(1));
        hv_store(keywords, "gettext", 7, newRV_noinc((SV *) gettext), 0);

        av_push(ngettext, newSViv(1));
        av_push(ngettext, newSViv(2));
        hv_store(keywords, "ngettext", 8, newRV_noinc((SV *) ngettext), 0);

        av_push(pgettext, newSVpv("1c", 0));
        av_push(pgettext, newSViv(2));
        hv_store(keywords, "pgettext", 8, newRV_noinc((SV *) pgettext), 0);

        av_push(npgettext, newSVpv("1c", 0));
        av_push(npgettext, newSViv(2));
        hv_store(keywords, "npgettext", 9, newRV_noinc((SV *) npgettext), 0);

        return newRV_noinc((SV *) keywords);

}

/*
 * You can add more language specific options here.  It is your
 * responsibility that the option names do not conflict with those of the
 * wrapper.
 *
 * This method should actually return an array of arrays.  But we
 * can also just return a flat list, that gets then promoted by the
 * Perl code.  When returning multiple or complex values it is best
 * to return them on the Perl stack.
 */
void 
languageSpecificOptions(SV *self) 
{
    Inline_Stack_Vars;

    Inline_Stack_Reset;

    Inline_Stack_Push(sv_2mortal(newSVpv("test-binding", 0)));
    Inline_Stack_Push(sv_2mortal(newSVpv("test_binding", 0)));
    Inline_Stack_Push(sv_2mortal(newSVpv("    --test-binding", 0)));
    Inline_Stack_Push(sv_2mortal(newSVpv("print additional information for testing the language binding", 0)));

    /* Add more groups of 4 items for more options.  */

    Inline_Stack_Done;
}

/* Does the program honor the option -a, --extract-all?  The default
 * implementation returns false.
 */
int
canExtractAll(SV *self)
{
        return 0;
}

/* Does the program honor the option -k, --keyword?  The default
 * implementation returns true.
 */
int 
canKeywords(SV *self)
{
        return 1;
}

/* Does the program honor the option --flag?  The default
 * implementation returns true.
 */
int
canFlags(SV *self)
{
        return 1;
}

static struct keyword **
keywords(SV *self)
{
        SV *records;
        HV *keyword_hash;
        HE *keyword_entry;
        int num_keywords, i;
        SV *sv_key;
        SV *sv_val;
        struct keyword **retval;
        struct keyword *keyword;

        setvbuf(stdout, NULL, _IONBF, 0);

        records = option(self, "keyword");
        if (!SvROK(records))
                croak("keywords is not a reference");

        keyword_hash = (HV*)SvRV(records);
        num_keywords = hv_iterinit(keyword_hash);

        size_t size = sizeof(struct keyword *);
        retval = calloc(sizeof(struct keyword *), 1 + num_keywords);
        if (!retval)
                croak("virtual memory exhausted");
                
        for (i = 0; i < num_keywords; ++i) {
                keyword = retval[i] = malloc(sizeof *keyword);
                if (!keyword)
                        croak("virtual memory exhausted");

                keyword_entry = hv_iternext(keyword_hash);
                sv_key = hv_iterkeysv(keyword_entry);

                keyword->method = strdup(SvPV(sv_key, PL_na));
                if (!keyword->method)
                        croak("virtual memory exhausted");
                        
                keyword->singular = 2;
                keyword->plural = 3;
                keyword->context = 1;
                keyword->comment = strdup("hello");
                
        //        keyword_entry = hv_iternext(keyword_hash);
        //        sv_key = hv_iterkeysv(keyword_entry);
        //        sv_val = hv_iterval(keyword_hash, keyword_entry);
        }
        retval[num_keywords] = (struct keyword *) NULL;

        return retval;
}

/* Get the value of a certain option.  Note that the return value can be
 * just about anything!
 */
static SV *
option(SV *self, const char *option)
{
        dSP;
        int count;
        SV *retval;

        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 2);

        PUSHs(self);
        PUSHs(sv_2mortal(newSVpv(option, 0)));
        PUTBACK;

        count = call_method("option", G_SCALAR);

        SPAGAIN;

        if (count != 1)
                croak("option() returned %d values.\n", count);

        retval = newSVsv(POPs);

        PUTBACK;
        FREETMPS;
        LEAVE;

        return retval;
}


static void
free_keywords(struct keyword **keywords)
{
        struct keyword **current = keywords;

        while (*current) {
                free_keyword(*current);
                ++current;
        }

        if (keywords)
                free(keywords);
}

static void
free_keyword(struct keyword *self)
{
        if (!self)
                return;
        
        if (self->method)
                free(self->method);

        if (self->comment)
                free(self->comment);
        
        free(self);
}