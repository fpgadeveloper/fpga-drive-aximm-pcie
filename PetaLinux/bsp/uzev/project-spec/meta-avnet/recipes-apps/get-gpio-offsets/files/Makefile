APP = get-gpio-offsets

# Add any other object files to this list below
APP_OBJS = get-gpio-offsets.o

all: build

build: $(APP)

$(APP): $(APP_OBJS)
	$(CXX) $(LDFLAGS) -o $@ $(APP_OBJS) $(LDLIBS)

clean:
	-rm -f $(APP) *.elf *.gdb *.o
