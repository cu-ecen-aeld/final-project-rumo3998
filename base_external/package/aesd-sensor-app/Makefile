TARGET = sensor_test
SRC = sensor_test.c

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -Wall -Wextra -O2 $(SRC) -o $(TARGET) $(LDFLAGS) -lgpiod

clean:
	rm -f $(TARGET)