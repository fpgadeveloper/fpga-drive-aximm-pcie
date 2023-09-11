APP = user-switch-test

# Add any other object files to this list below
APP_OBJS = linux_user_switch_test.o

all: build

build: $(APP)

$(APP): $(APP_OBJS)
	$(CXX) $(LDFLAGS) -o user-switch-test $(APP_OBJS) $(LDLIBS) -lgpio

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<

clean:
	-rm -f $(APP) *.elf *.gdb *.o
