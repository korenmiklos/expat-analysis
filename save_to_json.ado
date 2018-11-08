program define save_to_json
args fname expression
	tempname output

	file open `output' using "`fname'.json", write text replace
	file write `output' (`expression')
	file close `output'

end
