CC = gcc
SRC1 = create_arrival_window.c
BIN1 = create_arrival_window
SRC2 = event_file_to_params_mags.c
BIN2  = event_file_to_params_mags
SRC3 = year_month_day_to_jday.c
BIN3 = year_month_day_to_jday

all :: $(BIN1) $(BIN2) $(BIN3)

$(BIN1) ::
	$(CC) $(SRC1) -lm -Wall -O3 -o $(BIN1)

$(BIN2) ::
	$(CC) $(SRC2) -lm -Wall -O3 -o $(BIN2)

$(BIN3) ::
	$(CC) $(SRC3) -lm -Wall -O3 -o $(BIN3)

clean ::
	rm $(BIN1) $(BIN2) $(BIN3)
