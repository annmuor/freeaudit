# freeaudit

This is a toolchain to freely audit your software for vulnerabilities.
With a great help of [vulners team](http://vulners.com) it finds vulnerabilities on package-based Linux distros to allow you get actual security risks of your environment.
### How it works
![FreeAudit scheme](https://habrastorage.org/files/200/c43/403/200c43403a2541a4a82c4857e1b7218b.png)
### Requirements
* perl5
* perl-JSON module
* perl-DBI module
* postgresql 9.2 or later
* any MQ service is able to collect jsons
### Setup
* setup postgresql database with db and schema
* setup mq server you like
* run a script like that: *while true; do get-json-from-mq|perl transform.pl; done*
* add crontab like that: *00 00 * * * perl audit.pl*
* add your favorite distros to grabber.pl
* install perl5 and perl-JSON onto the hosts
* copy grabber.pl to the hosts
* create crontab line like *00 3/* * * * perl grabber.pl|mq-sender my-mq-server*
* enjoy
