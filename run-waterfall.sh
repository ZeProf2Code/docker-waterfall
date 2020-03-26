#!/bin/bash

WATERFALL_JAR=$WATERFALL_HOME/server.jar

if [[ ! -e $WATERFALL_JAR ]]; then
    echo "Downloading ${WATERFALL_JAR_URL:=${WATERFALL_BASE_URL}/${WATERFALL_JOB_ID:-lastSuccessfulBuild}/artifact/Waterfall-Proxy/bootstrap/target/Waterfall.jar}"
    if ! curl -o $WATERFALL_JAR -fsSL $WATERFALL_JAR_URL; then
        echo "ERROR: failed to download" >&2
        exit 2
    fi
fi

if [ -d /plugins ]; then
    echo "Copying Waterfall plugins over..."
    cp -r /plugins $WATERFALL_HOME
fi

# If supplied with a URL for a plugin download it.
if [[ "$PLUGINS" ]]; then
for i in ${PLUGINS//,/ }
do
  EFFECTIVE_PLUGIN_URL=$(curl -Ls -o /dev/null -w %{url_effective} $i)
  case "X$EFFECTIVE_PLUGIN_URL" in
    X[Hh][Tt][Tt][Pp]*.jar)
      echo "Downloading plugin via HTTP"
      echo "  from $EFFECTIVE_PLUGIN_URL ..."
      if ! curl -sSL -o /tmp/${EFFECTIVE_PLUGIN_URL##*/} $EFFECTIVE_PLUGIN_URL; then
        echo "ERROR: failed to download from $EFFECTIVE_PLUGIN_URL to /tmp/${EFFECTIVE_PLUGIN_URL##*/}"
        exit 2
      fi

      mkdir -p /server/plugins
      mv /tmp/${EFFECTIVE_PLUGIN_URL##*/} /server/plugins/${EFFECTIVE_PLUGIN_URL##*/}
      rm -f /tmp/${EFFECTIVE_PLUGIN_URL##*/}
      ;;
    *)
      echo "Invalid URL given for plugin list: Must be HTTP or HTTPS and a JAR file"
      ;;
  esac
done
fi

if [ -d /config ]; then
    echo "Copying Waterfall configs over..."
    cp -u /config/config.yml "$WATERFALL_HOME/config.yml"
fi

if [ $UID == 0 ]; then
  chown -R waterfall:waterfall $WATERFALL_HOME
fi

echo "Setting initial memory to ${INIT_MEMORY:-${MEMORY}} and max to ${MAX_MEMORY:-${MEMORY}}"
JVM_OPTS="-Xms${INIT_MEMORY:-${MEMORY}} -Xmx${MAX_MEMORY:-${MEMORY}} ${JVM_OPTS}"

if [ $UID == 0 ]; then
  exec sudo -u waterfall java $JVM_OPTS -jar $WATERFALL_JAR "$@"
else
  exec java $JVM_OPTS -jar $WATERFALL_JAR "$@"
fi
