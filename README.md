# SMTP to Prometheus Pushgateway / Loki

Sometimes, you may have limited network connectivity or an existing setup where data output is handled via email (such as for backups, reporting, or other tasks). In these scenarios, it can be challenging to integrate with modern monitoring and log tools that rely on real-time data collection.

So, here is the trick: send your metrics and logs trought email. This script push the metrics to Prometheus Pushgateway and the logs to Loki. 

![image](https://github.com/user-attachments/assets/88ba1202-6622-4597-b3bd-e30746495cf4)
Not much magic, its simple but might be helpfull for you 

The Loki part is curently in testing...

## Metrics
The Mail subject will be used as job name. everytime a message with this subject is recieved. the previous datta will be flushed. 

Keep in mind, that pushgateway does not allow timestamped meterics. Maybe something likt this can help:
```
meta{task="Task2", key="timestamp"} 1729082117
meta{task="Task2", key="count"} 93
```
 More about timestamps and more metrics samples can be found here https://github.com/prometheus/pushgateway
 

## Setup

Just create a pipe in postfix virtual/alias/master like:

`whateverXzhHash: "|/usr/local/bin/metrics-pipe"`
