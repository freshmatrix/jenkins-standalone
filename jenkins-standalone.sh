#!/bin/bash
set -e

# $JENKINS_VERSION should be an LTS release
JENKINS_VERSION="1.580.2"

# List of Jenkins plugins, in the format "${PLUGIN_NAME}/${PLUGIN_VERSION}"
#    "logstash/1.0.3"             \
JENKINS_PLUGINS=(\
    "credentials/1.18"           \
    "email-ext/2.39"             \
    "git/2.3.1"                  \
    "git-client/1.12.0"          \
    "greenballs/1.14"            \
    "hipchat/0.1.8"              \
    "metadata/1.1.0b"            \
    "mesos/0.5.0"                \
    "monitoring/1.54.0"          \
    "parameterized-trigger/2.25" \
    "saferestart/0.3"            \
    "scm-api/0.2"                \
    "script-security/1.12"       \
    "ssh-credentials/1.10"       \
    "token-macro/1.10"           \
)

JENKINS_WAR_MIRROR="http://mirrors.jenkins-ci.org/war-stable"
JENKINS_PLUGINS_MIRROR="http://updates.jenkins-ci.org"
JENKINS_PLUGINS_BASEURL="${JENKINS_PLUGINS_MIRROR}/download/plugins"

# Ensure we have an accessible wget
command -v wget > /dev/null
if [[ $? != 0 ]]; then
    echo "Error: wget not found in \$PATH"
    echo
    exit 1
fi

# Accept ZooKeeper paths on the command line
if [[ ! $# > 1 ]]; then
#    echo "Usage: $0 -z zk://10.132.188.212:2181[, ... ]/mesos -r redis.example.com"
    echo "Usage: $0 -z zk://10.132.188.212:2181[, ... ]/mesos"
    echo
    exit 1
fi

while [[ $# > 1 ]]; do
    key="$1"
    shift
    case $key in
        -z|--zookeeper)
            ZOOKEEPER_PATHS="$1"
            shift
            ;;
        -r|--redis-host)
            REDIS_HOST="$1"
            shift
            ;;
        *)
            echo "Unknown option: ${key}"
            exit 1
            ;;
    esac
done

# Jenkins WAR file
if [[ ! -f "jenkins.war" ]]; then
    wget -nc "${JENKINS_WAR_MIRROR}/${JENKINS_VERSION}/jenkins.war"
fi

# Jenkins plugins
[[ ! -d "plugins" ]] && mkdir "plugins"
for plugin in ${JENKINS_PLUGINS[@]}; do
    IFS='/' read -a plugin_info <<< "${plugin}"
    plugin_path="${plugin_info[0]}/${plugin_info[1]}/${plugin_info[0]}.hpi"
    wget -nc -P plugins "${JENKINS_PLUGINS_BASEURL}/${plugin_path}"
done

# Jenkins config files
sed -i "s!_MAGIC_ZOOKEEPER_PATHS!${ZOOKEEPER_PATHS}!" config.xml
#sed -i "s!_MAGIC_REDIS_HOST!${REDIS_HOST}!" jenkins.plugins.logstash.LogstashInstallation.xml
sed -i "s!_MAGIC_JENKINS_URL!http://${HOST}:8080!" jenkins.model.JenkinsLocationConfiguration.xml

# Start the master
#   instead of ${PORT}, try hard coded 8080 with Marathon payload port specified instead
#  define JENKINS_HOME with persistent volume. set ENV via Marathon
#   export JENKINS_HOME="$(pwd)"
if [[ -z "$JENKINS_HOME" ]]; then
    export JENKINS_HOME="$(pwd)"
fi

java -jar jenkins.war \
    -Djava.awt.headless=true \
    --webroot=war \
    --httpPort=8080 \
    --ajp13Port=-1 \
    --httpListenAddress=0.0.0.0 \
    --ajp13ListenAddress=127.0.0.1 \
    --preferredClassLoader=java.net.URLClassLoader \
    --logfile=../jenkins.log
