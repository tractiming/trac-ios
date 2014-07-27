import sys
import signal
from twisted.internet.protocol import Factory, Protocol
from twisted.protocols.basic import LineReceiver
from twisted.internet import reactor
from twisted.python import log
import rfid

# Timeout (in seconds) for dropped tcp connections.
TIMEOUT = 30

# TCP port.
PORT = 36740

# If DEBUG is set to True, simply echo out any incoming data, but do not process it.
DEBUG = False

class ReaderComm(LineReceiver):

    def __init__(self):
        self.reader_id = None
        self.tag = rfid.RFIDTag()
        self.db = rfid.Database(**rfid.DB_PARAMS)
        signal.signal(signal.SIGALRM, self.alarm_handler)

    def alarm_handler(self, signum, frame):
        """Handles timeouts from dropped tcp connections."""
        log.msg("Connection timeout.")
        self.transport.loseConnection()
 
    def lineReceived(self, line):
        signal.alarm(TIMEOUT)
        if DEBUG:
            log.msg(line)
        else:
            if (not rfid.handle_msg(self.db, self.tag, line)):
                log.msg("Tag read:"+ rfid.print_tag_info(self.tag))
            else:
    	        log.msg("Data received (no tag info)")
                
    def connectionMade(self):
        log.msg("Connection made!")
        signal.alarm(TIMEOUT)

    def connectionLost(self, reason):
        log.msg("Connection lost!"+ str(reason))

def main():
    """Creates factory and listens for incoming connections."""
    # Log all output to standard output. TODO: log to appropriate file.    
    log.startLogging(sys.stdout)
    factory = Factory()
    factory.protocol = ReaderComm

    reactor.listenTCP(PORT, factory)
    reactor.run()


if __name__ == "__main__":
    if '--debug' in sys.argv:
        DEBUG = True
    if DEBUG:
        bug_msg = "ON"
    else:
        bug_msg = "OFF"
    print "Server started! (DEBUG is %s)" %(bug_msg)
    main()
        
