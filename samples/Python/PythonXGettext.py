class PythonXGettext:
    def __init__(self, xgettext):
        self.xgettext = xgettext

    def readFile(self, filename):
        with open(filename) as f:
            for line in f:
                self.xgettext.addEntry({'msgid': line})
