APP = dialog-control

# Add any other object files to this list below
APP_OBJS = dialog-control.o

all: build

build: $(APP)

$(APP): $(APP_OBJS)
	$(CXX) $(LDFLAGS) -o $@ $(APP_OBJS) $(LDLIBS) -lgpio

clean:
	-rm -f $(APP) *.elf *.gdb *.o
