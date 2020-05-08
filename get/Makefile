%.zip: %.csv complex_data.py credentials.py
	python complex_data.py < $<
	zip $@ f*/*
	rm -rf f*