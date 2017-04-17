class PythonXGettext:
    def readFile(self, xgettext, filename):
        with open(filename) as f:
            for line in f:
                # You don't have to check that the line is empty.  The
                # PO header gets added after input has been processed.
                xgettext.addEntry({'msgid': line});

    # Optional methods.
    #def extractFromNonFiles(self, xgettext):

    def xdefaultKeywords(self, xgettext):
        return [
                   ['gettext', '1'],
                   ['ngettext', '1', '2']
               ];
