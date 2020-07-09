*install reghdfe 5.x
capture ado uninstall reghdfe
net install reghdfe, from("https://raw.githubusercontent.com/sergiocorreia/reghdfe/master/src/")

*install estout
capture ssc install estout
