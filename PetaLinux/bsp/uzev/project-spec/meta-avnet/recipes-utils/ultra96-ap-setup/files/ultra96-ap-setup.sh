#! /bin/sh

### BEGIN INIT INFO
# Provides: Access point on Ultra96
# Required-Start:
# Required-Stop:
# Default-Start:S
# Default-Stop:
# Short-Description: Starts access point(AP) on Ultra96
# Description:       This script runs a utility which will create a managed interface and runs
#     an AP using the new interface.
### END INIT INFO

DESC="ultra96-ap-setup.sh will start AP on ultra96"
APSETUPUTIL="/usr/share/wpa_ap/ap.sh"
APSETUPUTIL_PID_NAME="ultra96-ap-setup"

test -x "$APSETUPUTIL" || exit 0

case "$1" in
  start)
    echo -n "Starting Ultra96 AP setup daemon"
    start-stop-daemon --start --quiet --background --make-pidfile --pidfile /var/run/$APSETUPUTIL_PID_NAME.pid --exec $APSETUPUTIL start
    echo "."
    ;;
  stop)
    echo -n "Stopping Ultra96 AP setup daemon"
    start-stop-daemon --stop --quiet --pidfile /var/run/$APSETUPUTIL_PID_NAME.pid --exec $APSETUPUTIL stop
    ;;
  *)
    echo "Usage: /etc/init.d/ultra96-ap-setup.sh {start|stop}"
    exit 1
esac

exit 0
