#!/bin/ash

LOOKBUSY=/usr/local/bin/lookbusy

# parsing arguments
while [[ $# -gt 0 ]]
do
  key="$1"

  case $key in
      -h|--help)
        $LOOKBUSY --help; exit 0
      ;;
      -n|--ncpus)
        case $2 in
          ''|*[!0-9]*)
            echo "error: Argument $2 for -n|--ncpus is not a number" >&2; exit 1
          ;;
          *)
            CPU="$2"
            shift # past argument
          ;;
        esac
      ;;
      -c|--cpu-util)
        case $2 in
          ''|*[!0-9]*)
            echo "error: Argument $2 for -c|--cpu-util is not a number or a range (MIN-MAX) (default 50)" >&2; exit 1
          ;;
          *)
            CPUUTIL="$2"
            shift # past argument
          ;;
        esac
      ;;
      -r|--cpu-mode)
        case $2 in
          fixed|curve)
            CPUMODE="$2"
            shift # past argument
          ;;
          *)
            echo "error: Argument $2 for -r, --cpu-mode is not 'fixed' or 'curve' (default 'fixed')" >&2; exit 1
          ;;
        esac
      ;;
      -m|--mem-util)
        case $2 in
          [0-9]*KB|[0-9]*MB|[0-9]*GB|[0-9]*TB|[0-9]*)
            echo $2
            MEMORY="$2"
            shift # past argument
          ;;
          *)
            echo "error: Argument $2 for -m|--mem is not a number" >&2; exit 1
          ;;
        esac
      ;;
      -v|--verbose)
        VERBOSE="-v"
        echo "v"
      ;;
      *)
              # unknown option
      ;;
  esac
  shift # past argument or value
done

CPU=${CPU:-0}
CPUUTIL=${CPUUTIL:-50}
CPUMODE=${CPUMODE:-fixed}

SETTINGS="
startretries=100
startsecs=0
autorestart=true
"

while [[ $CPU -gt 0 ]]
do
  LOOKBUSY_THREADS=$LOOKBUSY_THREADS"
[program:lookbusy-cpu-$CPU]
command=$LOOKBUSY -n 1 -c $CPUUTIL -r $CPUMODE $VERBOSE
$SETTINGS
"
  CPU=$((CPU-1))
done

if [[ ! -z ${MEMORY} ]]
then
  LOOKBUSY_THREADS=$LOOKBUSY_THREADS"
[program:lookbusy-mem]
command=$LOOKBUSY -n 0 -m $MEMORY $VERBOSE
$SETTINGS
"
fi

mkdir -p /etc/supervisor/conf.d

cat <<EOF > /etc/supervisor/conf.d/supervisord.conf
[supervisord]
nodaemon=true

$LOOKBUSY_THREADS
EOF

cat /etc/supervisor/conf.d/supervisord.conf

/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
