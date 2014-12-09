# jenkins-standalone
Everything needed to run a Jenkins master on Apache Mesos and Marathon.

This repo assumes that you want to run a cluster of Jenkins masters, with the
masters also holding the executors, so that you can horizontally scale your
CI system. It does not provision Mesos slaves (although it can).

## Usage
`jenkins-standalone.sh` takes one argument: the host Redis is running on.
Redis is used as the broker for Logstash and the Jenkins Logstash plugin.

When copying/pasting this command into Marathon, each line should be
concatenated with `&&`, so that it only proceeds if the previous command
was successful.

Example usage:
```
git clone https://github.com/rji/jenkins-standalone
cd jenkins-standalone
./jenkins-standalone.sh -r redis.example.com
```
