*install estout
capture ssc install estout

* install here
capture ado uninstall here
net install here, from(https://raw.githubusercontent.com/korenmiklos/here/v1.0)

capture ado uninstall eventbaseline
net install eventbaseline, from(https://raw.githubusercontent.com/codedthinking/eventbaseline/v0.7.2)