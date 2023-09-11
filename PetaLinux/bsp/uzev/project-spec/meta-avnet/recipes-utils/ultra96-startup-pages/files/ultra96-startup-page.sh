#! /bin/sh

### BEGIN INIT INFO
# Provides: Ultra96 startup script
# Required-Start:
# Required-Stop:
# Default-Start:S
# Default-Stop:
# Short-Description: Opens up ultra96 startup page upon boot
# Description:      Starts the flask server to display startup webpage upon boot.
### END INIT INFO

FLASK_SERVER="/usr/share/ultra96-startup-pages/webapp/webserver.py"
FLASK_CMD="python3 ${FLASK_SERVER}"
FLASK_PID_NAME="ultra96-startup-page"

test -e "$FLASK_SERVER" || exit 0

case "$1" in
  start)
    echo -n "Starting Flask server deamon to serve Ultra96 startup page"
    start-stop-daemon --start --quiet --background --make-pidfile --pidfile /var/run/$FLASK_PID_NAME.pid --exec $FLASK_CMD
    echo "."
    ;;
  stop)
    echo -n "Stopping Flask server deamon"
    start-stop-daemon --stop --quiet --pidfile /var/run/$FLASK_PID_NAME.pid
    ;;
  *)
    echo "Usage: /etc/init.d/ultra96-startup-page.sh {start|stop}"
    exit 1
esac

exit 0

