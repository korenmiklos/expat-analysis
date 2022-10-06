*install reghdfe 5.x
capture ado uninstall reghdfe
net install reghdfe, from("https://raw.githubusercontent.com/sergiocorreia/reghdfe/master/src/")

*install ftools (remove program if it existed previously)
cap ado uninstall moresyntax
cap ado uninstall ftools
net install ftools, from("https://raw.githubusercontent.com/sergiocorreia/ftools/master/src/")

*install estout
capture ssc install estout

* install here
capture ado uninstall here
net install here, from("https://raw.githubusercontent.com/korenmiklos/here/master/")

* install attgt
capture ado uninstall attgt
net install attgt, from(https://raw.githubusercontent.com/korenmiklos/attgt/v0.2.3/)